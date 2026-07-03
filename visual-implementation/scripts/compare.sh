#!/usr/bin/env bash
set -euo pipefail

# Prepares the render-vs-source comparison for the verification gate
# (references/verification.md): scales the capture to the source's width,
# builds a side-by-side sheet and a pixel diff when ImageMagick is available.
# The output supports — never replaces — the element x property delta table:
# re-read the images yourself and fill the table.

usage() {
  cat >&2 <<'EOF'
Usage: compare.sh [--grid CxR] [--top K] <capture.png> <source.png> [outdir]

  capture   screenshot of YOUR built screen (see capture.sh)
  source    the design reference as PNG. An SVG is refused: export the PNG
            from the design tool (QuickLook-style rasterization distorts
            aspect and colour — NN-11).
  outdir    output directory (default: ./compare-out)
  --grid    tile grid for regional analysis (default: 4x8)
  --top     number of worst-tile crops to emit (default: 6)

Outputs: <outdir>/capture-scaled.png, side-by-side.png + diff.png (ImageMagick
only). With ImageMagick, also writes report.txt and regions/* foveal crops.
Without it the scaled pair is produced and the visual comparison is done by
re-reading both images, as the gate requires anyway.
EOF
  exit 1
}

die() {
  echo "Error: $*" >&2
  exit 1
}

metric_first_number() {
  awk '
    {
      if (match($0, /[-+]?[0-9.]+([eE][-+]?[0-9]+)?/)) {
        print substr($0, RSTART, RLENGTH)
        found = 1
        exit
      }
    }
    END { if (!found) print "nan" }
  '
}

metric_normalized_number() {
  awk '
    {
      s = $0
      if (index(s, "(") && index(s, ")") > index(s, "(")) {
        sub(/^[^(]*\(/, "", s)
        sub(/\).*/, "", s)
        if (s ~ /^[-+]?[0-9.]+([eE][-+]?[0-9]+)?$/) {
          print s
          found = 1
          exit
        }
      }
      s = $0
      if (match(s, /[-+]?[0-9.]+([eE][-+]?[0-9]+)?/)) {
        print substr(s, RSTART, RLENGTH)
        found = 1
        exit
      }
    }
    END { if (!found) print "nan" }
  '
}

ae_metric() {
  magick compare -metric AE -fuzz 2% "$1" "$2" "$3" 2>&1 || true
}

rmse_lab_metric() {
  magick compare -metric RMSE \
    \( "$1" -colorspace Lab \) \
    \( "$2" -colorspace Lab \) \
    null: 2>&1 || true
}

structural_metric() {
  magick compare -metric "$1" "$2" "$3" null: 2>&1 || true
}

structural_distance() {
  value="$1"
  mode="$2"
  awk -v value="$value" -v mode="$mode" 'BEGIN {
    if (value == "nan") {
      print "nan"
    } else if (mode == "SSIM_SIM") {
      printf "%.6f", 1 - value
    } else {
      printf "%.6f", value
    }
  }'
}

crop_image() {
  magick "$1" -crop "$2" +repage "$3"
}

GRID="4x8"
TOP="6"
POSITIONALS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --grid)
      [ $# -ge 2 ] || usage
      GRID="$2"
      shift 2 ;;
    --grid=*)
      GRID="${1#--grid=}"
      shift ;;
    --top)
      [ $# -ge 2 ] || usage
      TOP="$2"
      shift 2 ;;
    --top=*)
      TOP="${1#--top=}"
      shift ;;
    -h|--help)
      usage ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        POSITIONALS+=("$1")
        shift
      done ;;
    *)
      POSITIONALS+=("$1")
      shift ;;
  esac
done

set -- "${POSITIONALS[@]}"
[ $# -ge 2 ] || usage
[ $# -le 3 ] || usage
CAPTURE="$1"; SOURCE="$2"; OUTDIR="${3:-compare-out}"
[ "$(printf '%s\n' "$GRID" | awk '/^[1-9][0-9]*x[1-9][0-9]*$/ { print 1 }')" = "1" ] || die "--grid must be CxR with positive integers"
[ "$(printf '%s\n' "$TOP" | awk '/^[0-9]+$/ { print 1 }')" = "1" ] || die "--top must be a non-negative integer"
GRID_COLS="${GRID%x*}"
GRID_ROWS="${GRID#*x}"

[ -f "$CAPTURE" ] || { echo "Error: capture not found: $CAPTURE" >&2; exit 1; }
[ -f "$SOURCE" ] || { echo "Error: source not found: $SOURCE" >&2; exit 1; }
case "$SOURCE" in
  *.svg|*.SVG)
    echo "Error: source is an SVG. Ask for the PNG export from the design tool;" >&2
    echo "rasterizing it locally distorts aspect and colour (NN-11)." >&2
    exit 1 ;;
esac

mkdir -p "$OUTDIR"
SCALED="$OUTDIR/capture-scaled.png"
REPORT="$OUTDIR/report.txt"
REGIONS="$OUTDIR/regions"
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/compare.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT

if command -v magick >/dev/null 2>&1; then
  SRC_W="$(magick identify -format '%w' "$SOURCE")"
  SRC_H="$(magick identify -format '%h' "$SOURCE")"
  magick "$CAPTURE" -resize "${SRC_W}x" "$SCALED"
  CAP_H="$(magick identify -format '%h' "$SCALED")"
  COMMON_H="$(awk -v a="$SRC_H" -v b="$CAP_H" 'BEGIN { print (a < b ? a : b) }')"
  HEIGHT_NOTE=""
  if [ "$SRC_H" != "$CAP_H" ]; then
    HEIGHT_NOTE="Height delta: source ${SRC_H}px, scaled capture ${CAP_H}px; comparing common height ${COMMON_H}px. Treat the missing/extra vertical extent as the first finding."
  fi
  [ "$(awk -v cols="$GRID_COLS" -v rows="$GRID_ROWS" -v w="$SRC_W" -v h="$COMMON_H" 'BEGIN { print (cols <= w && rows <= h ? 1 : 0) }')" = "1" ] || die "--grid ${GRID} is too fine for ${SRC_W}x${COMMON_H}px comparison"

  SRC_Y="0"
  CAP_Y="0"
  COMP_H="$COMMON_H"
  SOURCE_CMP="$TMPDIR/source-cmp.png"
  CAPTURE_CMP="$TMPDIR/capture-cmp.png"
  crop_image "$SOURCE" "${SRC_W}x${COMP_H}+0+${SRC_Y}" "$SOURCE_CMP"
  crop_image "$SCALED" "${SRC_W}x${COMP_H}+0+${CAP_Y}" "$CAPTURE_CMP"

  STRIP_INFO="$(awk -v w="$SRC_W" 'BEGIN {
    sw = int(w * 0.25)
    if (sw < 80) sw = 80
    if (sw > w) sw = w
    sx = int((w - sw) / 2)
    print sw, sx
  }')"
  STRIP_W="${STRIP_INFO% *}"
  STRIP_X="${STRIP_INFO#* }"
  BASE_STRIP_AE=""
  BEST_OFFSET="0"
  BEST_AE=""
  SECOND_AE=""
  BASE_STRIP_SRC="$TMPDIR/align-src-0.png"
  BASE_STRIP_CAP="$TMPDIR/align-cap-0.png"
  crop_image "$SOURCE_CMP" "${STRIP_W}x${COMP_H}+${STRIP_X}+0" "$BASE_STRIP_SRC"
  crop_image "$CAPTURE_CMP" "${STRIP_W}x${COMP_H}+${STRIP_X}+0" "$BASE_STRIP_CAP"
  BASE_STRIP_AE="$(ae_metric "$BASE_STRIP_SRC" "$BASE_STRIP_CAP" null: | metric_first_number)"
  GLOBAL_AE_FULL="$(ae_metric "$SOURCE_CMP" "$CAPTURE_CMP" "$OUTDIR/diff.png" | metric_first_number)"
  GLOBAL_AE_RATE="$(awk -v ae="$GLOBAL_AE_FULL" -v w="$SRC_W" -v h="$COMP_H" 'BEGIN { if (w * h == 0) print 0; else printf "%.6f", ae / (w * h) }')"
  ALIGN_NOTE=""
  ALIGN_WARN=""
  if [ "$(awk -v r="$GLOBAL_AE_RATE" 'BEGIN { print (r > 0.002 ? 1 : 0) }')" = "1" ]; then
    for OFFSET in -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 2 3 4 5 6 7 8 9 10 11 12; do
      RECT_INFO="$(awk -v off="$OFFSET" -v sw="$STRIP_W" -v sx="$STRIP_X" -v sh="$SRC_H" -v ch="$CAP_H" 'BEGIN {
        sy = 0
        cy = 0
        if (off < 0) sy = -off
        if (off > 0) cy = off
        h = sh - sy
        if (ch - cy < h) h = ch - cy
        if (h < 1) h = 0
        print sx, sw, sy, cy, h
      }')"
      read -r TEST_X TEST_W TEST_SRC_Y TEST_CAP_Y TEST_H <<EOF
$RECT_INFO
EOF
      [ "$TEST_H" = "0" ] && continue
      TEST_SRC="$TMPDIR/align-src-${OFFSET}.png"
      TEST_CAP="$TMPDIR/align-cap-${OFFSET}.png"
      crop_image "$SOURCE" "${TEST_W}x${TEST_H}+${TEST_X}+${TEST_SRC_Y}" "$TEST_SRC"
      crop_image "$SCALED" "${TEST_W}x${TEST_H}+${TEST_X}+${TEST_CAP_Y}" "$TEST_CAP"
      TEST_AE="$(ae_metric "$TEST_SRC" "$TEST_CAP" null: | metric_first_number)"
      BEST_LINE="$(awk -v off="$OFFSET" -v ae="$TEST_AE" -v best_off="$BEST_OFFSET" -v best="$BEST_AE" -v second="$SECOND_AE" 'BEGIN {
        if (best == "" || ae < best) {
          second = best
          best = ae
          best_off = off
        } else if (second == "" || ae < second) {
          second = ae
        }
        if (second == "") second = best
        print best_off, best, second
      }')"
      read -r BEST_OFFSET BEST_AE SECOND_AE <<EOF
$BEST_LINE
EOF
    done
    CLEAR_WIN="$(awk -v base="$BASE_STRIP_AE" -v best="$BEST_AE" -v second="$SECOND_AE" -v off="$BEST_OFFSET" 'BEGIN {
      if (off == 0 || best == "" || second == "") print 0
      else if (best < base * 0.75 && best < second * 0.90) print 1
      else print 0
    }')"
    if [ "$CLEAR_WIN" = "1" ]; then
      SRC_Y="$(awk -v off="$BEST_OFFSET" 'BEGIN { print (off < 0 ? -off : 0) }')"
      CAP_Y="$(awk -v off="$BEST_OFFSET" 'BEGIN { print (off > 0 ? off : 0) }')"
      COMP_H="$(awk -v sh="$SRC_H" -v ch="$CAP_H" -v sy="$SRC_Y" -v cy="$CAP_Y" 'BEGIN {
        h = sh - sy
        if (ch - cy < h) h = ch - cy
        print h
      }')"
      crop_image "$SOURCE" "${SRC_W}x${COMP_H}+0+${SRC_Y}" "$SOURCE_CMP"
      crop_image "$SCALED" "${SRC_W}x${COMP_H}+0+${CAP_Y}" "$CAPTURE_CMP"
      GLOBAL_AE_FULL="$(ae_metric "$SOURCE_CMP" "$CAPTURE_CMP" "$OUTDIR/diff.png" | metric_first_number)"
      GLOBAL_AE_RATE="$(awk -v ae="$GLOBAL_AE_FULL" -v w="$SRC_W" -v h="$COMP_H" 'BEGIN { if (w * h == 0) print 0; else printf "%.6f", ae / (w * h) }')"
      ALIGN_NOTE="capture realigned by ${BEST_OFFSET}px (scroll/statusbar offset); aligned comparison height ${COMP_H}px."
    else
      ALIGN_WARN="Alignment warning: global AE rate ${GLOBAL_AE_RATE} is high, but tested vertical offsets were ambiguous; no shift applied."
    fi
  fi
  [ "$(awk -v cols="$GRID_COLS" -v rows="$GRID_ROWS" -v w="$SRC_W" -v h="$COMP_H" 'BEGIN { print (cols <= w && rows <= h ? 1 : 0) }')" = "1" ] || die "--grid ${GRID} is too fine for ${SRC_W}x${COMP_H}px comparison"

  # +append instead of montage: montage initializes a default font even without
  # labels and dies on systems where ImageMagick has none configured.
  magick \( "$SOURCE_CMP" -bordercolor '#444' -border 8 \) \( "$CAPTURE_CMP" -bordercolor '#444' -border 8 \) -background '#444' +append "$OUTDIR/side-by-side.png"
  ae_metric "$SOURCE_CMP" "$CAPTURE_CMP" "$OUTDIR/diff.png" >/dev/null

  STRUCT_MODE="none"
  STRUCT_LABEL="struct"
  STRUCT_NOTE="Structural metric unavailable; structural-distance column is n/a and classification uses AE/Lab only."
  STRUCT_IDENT="nan"
  STRUCT_DIFF="nan"
  STRUCT_CAL_A="$TMPDIR/struct-cal-a.png"
  STRUCT_CAL_B="$TMPDIR/struct-cal-b.png"
  magick -size 32x32 xc:white -fill black -draw 'rectangle 0,0 15,31' "$STRUCT_CAL_A"
  magick -size 32x32 xc:white -fill black -draw 'rectangle 16,0 31,31' "$STRUCT_CAL_B"
  STRUCT_TEST="$(structural_metric SSIM "$STRUCT_CAL_A" "$STRUCT_CAL_A")"
  STRUCT_IDENT="$(printf '%s\n' "$STRUCT_TEST" | metric_normalized_number)"
  STRUCT_DIFF_TEST="$(structural_metric SSIM "$STRUCT_CAL_A" "$STRUCT_CAL_B")"
  STRUCT_DIFF="$(printf '%s\n' "$STRUCT_DIFF_TEST" | metric_normalized_number)"
  if [ "$STRUCT_IDENT" != "nan" ] && [ "$STRUCT_DIFF" != "nan" ] && ! printf '%s\n%s\n' "$STRUCT_TEST" "$STRUCT_DIFF_TEST" | grep -qi 'unrecognized\|undefined\|no such'; then
    STRUCT_IS_SIM="$(awk -v ident="$STRUCT_IDENT" -v diff="$STRUCT_DIFF" 'BEGIN { print (ident > 0.90 && diff < ident ? 1 : 0) }')"
    STRUCT_IS_DIST="$(awk -v ident="$STRUCT_IDENT" -v diff="$STRUCT_DIFF" 'BEGIN { print (ident < 0.001 && diff > ident ? 1 : 0) }')"
    if [ "$STRUCT_IS_SIM" = "1" ]; then
      STRUCT_MODE="SSIM_SIM"
      STRUCT_LABEL="SSIM-distance"
      STRUCT_NOTE="Structural metric: ImageMagick SSIM similarity normalized to 1-SSIM distance (calibration identical=${STRUCT_IDENT}, different=${STRUCT_DIFF})."
    elif [ "$STRUCT_IS_DIST" = "1" ]; then
      STRUCT_MODE="SSIM_DISTANCE"
      STRUCT_LABEL="SSIM-distance"
      STRUCT_NOTE="Structural metric: ImageMagick SSIM output behaves as a distance on this build (calibration identical=${STRUCT_IDENT}, different=${STRUCT_DIFF}); lower is more similar."
    fi
  fi
  if [ "$STRUCT_MODE" = "none" ]; then
    STRUCT_TEST="$(structural_metric DSSIM "$STRUCT_CAL_A" "$STRUCT_CAL_A")"
    STRUCT_IDENT="$(printf '%s\n' "$STRUCT_TEST" | metric_normalized_number)"
    STRUCT_DIFF_TEST="$(structural_metric DSSIM "$STRUCT_CAL_A" "$STRUCT_CAL_B")"
    STRUCT_DIFF="$(printf '%s\n' "$STRUCT_DIFF_TEST" | metric_normalized_number)"
    if [ "$STRUCT_IDENT" != "nan" ] && [ "$STRUCT_DIFF" != "nan" ] && ! printf '%s\n%s\n' "$STRUCT_TEST" "$STRUCT_DIFF_TEST" | grep -qi 'unrecognized\|undefined\|no such'; then
      STRUCT_IS_DIST="$(awk -v ident="$STRUCT_IDENT" -v diff="$STRUCT_DIFF" 'BEGIN { print (ident < 0.001 && diff > ident ? 1 : 0) }')"
      if [ "$STRUCT_IS_DIST" = "1" ]; then
        STRUCT_MODE="DSSIM_DISTANCE"
        STRUCT_LABEL="DSSIM"
        STRUCT_NOTE="Structural metric: DSSIM distance (calibration identical=${STRUCT_IDENT}, different=${STRUCT_DIFF}); lower is more similar."
      fi
    fi
  fi

  RAW="$TMPDIR/tiles.raw"
  CLASSIFIED="$TMPDIR/tiles.classified"
  : > "$RAW"
  awk -v w="$SRC_W" -v h="$COMP_H" -v cols="$GRID_COLS" -v rows="$GRID_ROWS" 'BEGIN {
    for (r = 0; r < rows; r++) {
      y1 = int(r * h / rows)
      y2 = int((r + 1) * h / rows)
      for (c = 0; c < cols; c++) {
        x1 = int(c * w / cols)
        x2 = int((c + 1) * w / cols)
        printf "r%02dc%02d|%d|%d|%d|%d\n", r + 1, c + 1, x1, y1, x2 - x1, y2 - y1
      }
    }
  }' | while IFS='|' read -r TILE X Y W H; do
    SRC_TILE="$TMPDIR/${TILE}-source.png"
    CAP_TILE="$TMPDIR/${TILE}-capture.png"
    TILE_DIFF="$TMPDIR/${TILE}-diff.png"
    crop_image "$SOURCE_CMP" "${W}x${H}+${X}+${Y}" "$SRC_TILE"
    crop_image "$CAPTURE_CMP" "${W}x${H}+${X}+${Y}" "$CAP_TILE"
    AE="$(ae_metric "$SRC_TILE" "$CAP_TILE" "$TILE_DIFF" | metric_first_number)"
    AE_NORM="$(awk -v ae="$AE" -v w="$W" -v h="$H" 'BEGIN { if (w * h == 0) print 0; else printf "%.6f", ae / (w * h) }')"
    LAB_RMSE="$(rmse_lab_metric "$SRC_TILE" "$CAP_TILE" | metric_normalized_number)"
    if [ "$STRUCT_MODE" = "SSIM_SIM" ] || [ "$STRUCT_MODE" = "SSIM_DISTANCE" ]; then
      STRUCT_VALUE="$(structural_metric SSIM "$SRC_TILE" "$CAP_TILE" | metric_normalized_number)"
      STRUCT_DIST="$(structural_distance "$STRUCT_VALUE" "$STRUCT_MODE")"
    elif [ "$STRUCT_MODE" = "DSSIM_DISTANCE" ]; then
      STRUCT_VALUE="$(structural_metric DSSIM "$SRC_TILE" "$CAP_TILE" | metric_normalized_number)"
      STRUCT_DIST="$STRUCT_VALUE"
    else
      STRUCT_VALUE="n/a"
      STRUCT_DIST="0"
    fi
    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$TILE" "$X" "$Y" "$W" "$H" "$AE" "$AE_NORM" "$LAB_RMSE" "$STRUCT_VALUE" "$STRUCT_DIST" >> "$RAW"
  done

  awk -F'|' -v struct_mode="$STRUCT_MODE" '
    function percentile(a, n, pct, b, i, j, t, idx) {
      for (i = 1; i <= n; i++) b[i] = a[i]
      for (i = 1; i <= n; i++) {
        for (j = i + 1; j <= n; j++) {
          if (b[j] < b[i]) {
            t = b[i]; b[i] = b[j]; b[j] = t
          }
        }
      }
      idx = int(pct * (n - 1)) + 1
      if (idx < 1) idx = 1
      if (idx > n) idx = n
      return b[idx]
    }
    BEGIN {
      ae_floor = 0.010
      lab_floor = 0.015
      struct_floor = 0.020
    }
    {
      n++
      tile[n] = $1; x[n] = $2; y[n] = $3; tw[n] = $4; th[n] = $5
      ae[n] = $6; ae_norm[n] = $7 + 0; lab[n] = $8 + 0; struct[n] = $9; struct_dist[n] = $10 + 0
      ae_values[n] = ae_norm[n]
      lab_values[n] = lab[n]
      struct_values[n] = struct_dist[n]
    }
    END {
      ae_p50 = percentile(ae_values, n, 0.50)
      lab_p50 = percentile(lab_values, n, 0.50)
      struct_p50 = percentile(struct_values, n, 0.50)
      ae_threshold = ae_p50 + ae_floor
      lab_threshold = lab_p50 + lab_floor
      struct_threshold = struct_p50 + struct_floor
      if (struct_mode == "SSIM_SIM" || struct_mode == "SSIM_DISTANCE" || struct_mode == "DSSIM_DISTANCE") {
        if (struct_threshold > 1) struct_threshold = 1
      }
      color_struct_threshold = struct_threshold * 0.50
      printf "thresholds|AE-norm high > %.6f (p50 %.6f + floor %.3f)|Lab-RMSE high > %.6f (p50 %.6f + floor %.3f)|", ae_threshold, ae_p50, ae_floor, lab_threshold, lab_p50, lab_floor
      if (struct_mode == "SSIM_SIM" || struct_mode == "SSIM_DISTANCE") printf "SSIM-distance high > %.6f (p50 %.6f + floor %.3f); color-only requires distance <= %.6f\n", struct_threshold, struct_p50, struct_floor, color_struct_threshold
      else if (struct_mode == "DSSIM_DISTANCE") printf "DSSIM high > %.6f (p50 %.6f + floor %.3f); color-only requires distance <= %.6f\n", struct_threshold, struct_p50, struct_floor, color_struct_threshold
      else printf "structural metric skipped; no structural threshold\n"
      for (i = 1; i <= n; i++) {
        high_ae = ae_norm[i] > ae_threshold
        high_lab = lab[i] > lab_threshold
        high_struct = (struct_mode == "SSIM_SIM" || struct_mode == "SSIM_DISTANCE" || struct_mode == "DSSIM_DISTANCE") && struct_dist[i] > struct_threshold
        low_struct_for_color = (struct_mode == "none") || struct_dist[i] <= color_struct_threshold
        if (!high_ae && !high_lab && !high_struct) cls = "ok"
        else if (high_ae && high_struct) cls = "geometry/content"
        else if (high_lab && low_struct_for_color) cls = "color-shift"
        else if (high_struct && !high_lab) cls = "geometry/content"
        else cls = "mixed"
        score = ae_norm[i] + lab[i] + struct_dist[i]
        printf "tile|%s|%d|%d|%d|%d|%s|%.6f|%.6f|%s|%s|%.6f\n", tile[i], x[i], y[i], tw[i], th[i], ae[i], ae_norm[i], lab[i], struct[i], cls, score
      }
    }
  ' "$RAW" > "$CLASSIFIED"

  THRESHOLDS="$(awk -F'|' '$1 == "thresholds" { print $2 "\n" $3 "\n" $4 }' "$CLASSIFIED")"
  mkdir -p "$REGIONS"
  awk -F'|' '$1 == "tile" { print $12 "|" $0 }' "$CLASSIFIED" | sort -t'|' -k1,1nr | awk -F'|' '{ sub(/^[^|]*\|/, ""); print }' > "$TMPDIR/tiles.sorted"
  awk -F'|' -v top="$TOP" '$1 == "tile" && top > 0 && ++n <= top { print $2 "|" $3 "|" $4 "|" $5 "|" $6 }' "$TMPDIR/tiles.sorted" | while IFS='|' read -r TILE X Y W H; do
    RECT="${W}x${H}+${X}+${Y}"
    REGION_SRC="$TMPDIR/${TILE}-region-source.png"
    REGION_CAP="$TMPDIR/${TILE}-region-capture.png"
    crop_image "$SOURCE_CMP" "$RECT" "$REGION_SRC"
    crop_image "$CAPTURE_CMP" "$RECT" "$REGION_CAP"
    magick "$REGION_SRC" -filter point -resize 200% "$REGIONS/${TILE}-source.png"
    magick "$REGION_CAP" -filter point -resize 200% "$REGIONS/${TILE}-capture.png"
    TILE_DIFF="$TMPDIR/${TILE}-region-diff.png"
    ae_metric "$REGION_SRC" "$REGION_CAP" "$TILE_DIFF" >/dev/null
    magick "$TILE_DIFF" -filter point -resize 200% "$REGIONS/${TILE}-diff.png"
  done

  {
    [ -n "$HEIGHT_NOTE" ] && echo "$HEIGHT_NOTE"
    [ -n "$ALIGN_NOTE" ] && echo "$ALIGN_NOTE"
    [ -n "$ALIGN_WARN" ] && echo "$ALIGN_WARN"
    echo "Scaled capture:  $SCALED (width $SRC_W)"
    echo "Side-by-side:    $OUTDIR/side-by-side.png"
    echo "Pixel diff:      $OUTDIR/diff.png (differing pixels: $GLOBAL_AE_FULL; AE rate: $GLOBAL_AE_RATE)"
    echo "Regional report: $REPORT"
    echo "Foveal crops:    $REGIONS (top $TOP, 2x nearest-neighbor)"
    echo
    echo "Regional comparison supports the element x property delta table; it never substitutes for re-reading the images."
    echo "Grid: ${GRID_COLS}x${GRID_ROWS}; classification: ok = AE, Lab, and structural distance all below threshold; geometry/content = high AE plus high structural distance, or structural-only change; color-shift = high Lab-RMSE with structural distance <= half threshold; mixed = every other flagged tile. Any high-AE tile is flagged, never ok."
    echo "Alignment guard: vertical offset search runs when global AE rate > 0.002; tested offsets are +/-2..12px."
    echo "$STRUCT_NOTE"
    printf '%s\n' "$THRESHOLDS"
    echo
    echo "tile | rect(px) | AE | Lab-RMSE | $STRUCT_LABEL | class"
    echo "-----|----------|----|----------|------|------"
    awk -F'|' '$1 == "tile" {
      printf "%s | %dx%d+%d+%d | %s | %.6f | %s | %s\n", $2, $5, $6, $3, $4, $7, $9, $10, $11
    }' "$TMPDIR/tiles.sorted"
    echo
    echo "Re-read the worst tiles as images and fill the delta table rows for the elements inside those rects."
  } | tee "$REPORT"
elif command -v sips >/dev/null 2>&1; then
  SRC_W="$(sips -g pixelWidth "$SOURCE" | awk '/pixelWidth/ {print $2}')"
  cp "$CAPTURE" "$SCALED"
  sips --resampleWidth "$SRC_W" "$SCALED" >/dev/null
  echo "Scaled capture:  $SCALED (width $SRC_W)"
  echo "ImageMagick not found: no montage/diff/regional analysis generated; install magick for ranked tiles and foveal crops."
  echo "Compare visually: re-read $SOURCE and $SCALED as images and fill the delta table."
else
  echo "Error: neither ImageMagick (magick) nor sips available." >&2
  exit 1
fi

echo "Now complete the element x property delta table (references/verification.md)."
