#!/usr/bin/env bash
set -euo pipefail

# Deterministic raster measuring aid for visual-analysis.md §§2, 3, 5.
# Pixel evidence supports extraction; named tokens still outrank samples (NN-4).

usage() {
  cat >&2 <<'EOF'
Usage: measure.sh <image.png> <command> [args...]

Commands:
  info                          image WxH, plus px->dp/pt hint when --scale given
  color <x> <y> [radius]       average hex sRGB in a (2r+1)^2 box centered at x,y (default r=2);
                                also print the per-channel values and the sampled box coords
  palette [n]                   top n colors (default 8) with pixel share %, via magick -kmeans
                                (fallback: -colors n + histogram); ignore fully transparent px
  crop <x> <y> <w> <h> <out.png> [zoom]   foveal crop at native resolution; optional integer zoom
                                (point/nearest filter, no resampling blur) for inspection
  tiles <COLSxROWS> <outdir> [zoom]       tile the full frame into a grid of overlapping tiles
                                (10% overlap both axes), named tile-r<row>-c<col>.png, optional zoom;
                                prints an index of tile -> source-pixel rect
  edges <x> <y> <w> <h> <row|col>         luminance projection profile of the strip; print detected
                                edge positions (local gradient maxima above threshold) as absolute
                                image coordinates and the gaps between consecutive edges
  capheight <x> <y> <w> <h>    the box must contain ONE line of text with at least one capital;
                                reports cap-height in px and a font-size ESTIMATE band
  contrast <x1> <y1> <x2> <y2> [radius]   WCAG 2.x contrast ratio between the two sampled colors

Global option (before command): --scale <f>   physical-px-per-logical (e.g. 3 for @3x); when given,
                                every reported px measurement also prints logical dp/pt.
EOF
  exit 1
}

die() {
  echo "Error: $*" >&2
  exit 1
}

require_magick() {
  if ! command -v magick >/dev/null 2>&1; then
    echo "Error: ImageMagick 7 (magick) not found." >&2
    echo "Fall back to declared-uncertainty estimation per references/visual-analysis.md §2." >&2
    exit 1
  fi
}

is_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

is_pos_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

validate_int() {
  is_int "$2" || die "$1 must be a non-negative integer: $2"
}

validate_pos_int() {
  is_pos_int "$2" || die "$1 must be a positive integer: $2"
}

validate_scale() {
  awk -v s="$1" 'BEGIN { exit !(s ~ /^[0-9]+([.][0-9]+)?$/ && s > 0) }' \
    || die "--scale must be a positive number: $1"
}

fmt_px() {
  awk -v v="$1" -v s="$SCALE" 'BEGIN {
    if (s == "") {
      printf "%gpx", v
    } else {
      printf "%gpx (%.2f dp/pt)", v, v / s
    }
  }'
}

hex_from_rgb() {
  awk -v r="$1" -v g="$2" -v b="$3" 'BEGIN { printf "#%02X%02X%02X", r, g, b }'
}

mktemp_dir() {
  TMP_MEASURE="$(mktemp -d "${TMPDIR:-/tmp}/measure.XXXXXX")"
  trap 'rm -rf "$TMP_MEASURE"' EXIT
}

identify_image() {
  local dims
  dims="$(magick identify -quiet -format '%w %h' "$IMAGE")" \
    || die "cannot identify image: $IMAGE"
  read -r IMG_W IMG_H <<<"$dims"
}

validate_point() {
  local x="$1" y="$2"
  validate_int x "$x"
  validate_int y "$y"
  awk -v x="$x" -v y="$y" -v w="$IMG_W" -v h="$IMG_H" 'BEGIN {
    exit !(x >= 0 && y >= 0 && x < w && y < h)
  }' || die "point out of range: ($x,$y) for image ${IMG_W}x${IMG_H}"
}

validate_rect() {
  local x="$1" y="$2" w="$3" h="$4"
  validate_int x "$x"
  validate_int y "$y"
  validate_pos_int w "$w"
  validate_pos_int h "$h"
  awk -v x="$x" -v y="$y" -v rw="$w" -v rh="$h" -v iw="$IMG_W" -v ih="$IMG_H" 'BEGIN {
    exit !(x >= 0 && y >= 0 && rw > 0 && rh > 0 && x + rw <= iw && y + rh <= ih)
  }' || die "rect out of range: ${x},${y} ${w}x${h} for image ${IMG_W}x${IMG_H}"
}

validate_sample_box() {
  local x="$1" y="$2" r="$3"
  validate_point "$x" "$y"
  validate_int radius "$r"
  awk -v x="$x" -v y="$y" -v r="$r" -v iw="$IMG_W" -v ih="$IMG_H" 'BEGIN {
    exit !(x - r >= 0 && y - r >= 0 && x + r < iw && y + r < ih)
  }' || die "sample box radius $r around ($x,$y) exceeds image bounds ${IMG_W}x${IMG_H}"
}

sample_rgb() {
  local x="$1" y="$2" r="$3"
  local box rgb
  box="$(awk -v x="$x" -v y="$y" -v r="$r" 'BEGIN {
    x0 = x - r; y0 = y - r; size = 2 * r + 1;
    printf "%dx%d+%d+%d", size, size, x0, y0
  }')"
  rgb="$(magick "$IMAGE" -crop "$box" +repage -alpha off -colorspace sRGB \
    -filter box -resize 1x1! \
    -format '%[fx:int(255*r+0.5)] %[fx:int(255*g+0.5)] %[fx:int(255*b+0.5)]' info:)"
  printf '%s\n' "$rgb"
}

sample_box_coords() {
  awk -v x="$1" -v y="$2" -v r="$3" 'BEGIN {
    printf "%d,%d -> %d,%d", x - r, y - r, x + r, y + r
  }'
}

sample_size() {
  awk -v r="$1" 'BEGIN { print 2 * r + 1 }'
}

print_info() {
  echo "Image: $IMAGE"
  echo "Size: $(fmt_px "$IMG_W") x $(fmt_px "$IMG_H")"
  if [ -n "$SCALE" ]; then
    awk -v w="$IMG_W" -v h="$IMG_H" -v s="$SCALE" 'BEGIN {
      printf "Logical hint: %.2f x %.2f dp/pt at scale %.4g\n", w / s, h / s, s
    }'
  fi
  echo "Evidence: raster frame size for scale calibration; snap derived values to project tokens (NN-6, NN-4)."
}

cmd_color() {
  [ $# -ge 2 ] && [ $# -le 3 ] || usage
  local x="$1" y="$2" r="${3:-2}" hex rch gch bch
  validate_sample_box "$x" "$y" "$r"
  read -r rch gch bch < <(sample_rgb "$x" "$y" "$r")
  hex="$(hex_from_rgb "$rch" "$gch" "$bch")"
  echo "Color: $hex"
  echo "sRGB: r=$rch g=$gch b=$bch"
  echo "Sample box: $(sample_box_coords "$x" "$y" "$r") ($(fmt_px "$(sample_size "$r")") square)"
  echo "Evidence: sampled raster color; stated design tokens outrank sampled hues (NN-4)."
}

histogram_table() {
  awk -v limit="$1" '
    function chan(v) { return v > 255 ? int(v / 257 + 0.5) : int(v + 0.5) }
    function hex(r,g,b) { return sprintf("#%02X%02X%02X", chan(r), chan(g), chan(b)) }
    /^[[:space:]]*[0-9]+:/ {
      count = $1
      sub(/:/, "", count)
      tuple = $0
      sub(/^[^(]*\(/, "", tuple)
      sub(/\).*/, "", tuple)
      split(tuple, m, ",")
      if (m[1] == "" || m[2] == "" || m[3] == "") next
      a = (m[4] == "" ? 255 : m[4])
      if (a > 255) a = a / 257
      if (a <= 0) next
      n++
      counts[n] = count + 0
      colors[n] = hex(m[1], m[2], m[3])
      rgbs[n] = sprintf("%d,%d,%d", chan(m[1]), chan(m[2]), chan(m[3]))
      total += count
    }
    END {
      if (total <= 0) {
        print "No non-transparent pixels found."
        exit 0
      }
      print "rank\thex\tsRGB\tshare\tpixels"
      for (i = 1; i <= n && i <= limit; i++) {
        printf "%d\t%s\t%s\t%.2f%%\t%d\n", i, colors[i], rgbs[i], counts[i] * 100 / total, counts[i]
      }
    }
  '
}

cmd_palette() {
  [ $# -le 1 ] || usage
  local n="${1:-8}" clustered mode
  validate_pos_int n "$n"
  mktemp_dir
  clustered="$TMP_MEASURE/palette.png"
  mode="kmeans"
  if ! magick "$IMAGE" -alpha on -colorspace sRGB -kmeans "$n" "$clustered" >/dev/null 2>&1; then
    mode="colors"
    magick "$IMAGE" -alpha on -colorspace sRGB +dither -colors "$n" "$clustered"
  fi
  echo "Palette: top $n colors via magick -$mode"
  magick "$clustered" -depth 8 -format '%c' histogram:info:- | sort -nr | histogram_table "$n"
  echo "Evidence: raster palette clusters; use as extraction aid, then map to stated/project tokens (NN-4)."
}

cmd_crop() {
  [ $# -ge 5 ] && [ $# -le 6 ] || usage
  local x="$1" y="$2" w="$3" h="$4" out="$5" zoom="${6:-1}"
  validate_rect "$x" "$y" "$w" "$h"
  validate_pos_int zoom "$zoom"
  if [ "$zoom" = "1" ]; then
    magick "$IMAGE" -crop "${w}x${h}+${x}+${y}" +repage "$out"
  else
    magick "$IMAGE" -crop "${w}x${h}+${x}+${y}" +repage -filter point -resize "${zoom}00%" "$out"
  fi
  echo "Crop: $out"
  echo "Source rect: x=$(fmt_px "$x") y=$(fmt_px "$y") w=$(fmt_px "$w") h=$(fmt_px "$h")"
  echo "Zoom: ${zoom}x point filter"
  echo "Evidence: foveal raster crop for native-resolution inspection; do not infer unobserved content (NN-13)."
}

cmd_tiles() {
  [ $# -ge 2 ] && [ $# -le 3 ] || usage
  local grid="$1" outdir="$2" zoom="${3:-1}" cols rows
  local -a rects
  [[ "$grid" =~ ^([1-9][0-9]*)x([1-9][0-9]*)$ ]] || die "grid must be COLSxROWS: $grid"
  cols="${BASH_REMATCH[1]}"
  rows="${BASH_REMATCH[2]}"
  validate_pos_int zoom "$zoom"
  mkdir -p "$outdir"

  echo "Tile index: $grid from ${IMG_W}x${IMG_H}; 10% overlap; zoom ${zoom}x"
  printf 'tile\tsource rect\n'
  # macOS ships bash 3.2: no mapfile — stream the awk output into a while-read loop.
  local row col x y w h out
  while read -r row col x y w h; do
    out="$outdir/tile-r${row}-c${col}.png"
    if [ "$zoom" = "1" ]; then
      magick "$IMAGE" -crop "${w}x${h}+${x}+${y}" +repage "$out"
    else
      magick "$IMAGE" -crop "${w}x${h}+${x}+${y}" +repage -filter point -resize "${zoom}00%" "$out"
    fi
    printf 'tile-r%s-c%s.png\tx=%s y=%s w=%s h=%s\n' "$row" "$col" "$(fmt_px "$x")" "$(fmt_px "$y")" "$(fmt_px "$w")" "$(fmt_px "$h")"
  done < <(awk -v iw="$IMG_W" -v ih="$IMG_H" -v cols="$cols" -v rows="$rows" 'BEGIN {
    for (r = 0; r < rows; r++) {
      baseY0 = int(r * ih / rows)
      baseY1 = int((r + 1) * ih / rows)
      baseH = baseY1 - baseY0
      ovY = int(baseH * 0.10 + 0.5)
      y0 = baseY0 - (r == 0 ? 0 : ovY)
      y1 = baseY1 + (r == rows - 1 ? 0 : ovY)
      if (y0 < 0) y0 = 0
      if (y1 > ih) y1 = ih
      for (c = 0; c < cols; c++) {
        baseX0 = int(c * iw / cols)
        baseX1 = int((c + 1) * iw / cols)
        baseW = baseX1 - baseX0
        ovX = int(baseW * 0.10 + 0.5)
        x0 = baseX0 - (c == 0 ? 0 : ovX)
        x1 = baseX1 + (c == cols - 1 ? 0 : ovX)
        if (x0 < 0) x0 = 0
        if (x1 > iw) x1 = iw
        printf "%d %d %d %d %d %d\n", r + 1, c + 1, x0, y0, x1 - x0, y1 - y0
      }
    }
  }')
  echo "Evidence: overlapping foveal tiles for region-by-region raster reading (visual-analysis.md §2)."
}

cmd_edges() {
  [ $# -eq 5 ] || usage
  local x="$1" y="$2" w="$3" h="$4" axis="$5" target offset
  validate_rect "$x" "$y" "$w" "$h"
  case "$axis" in
    row) target="${w}x1!"; offset="$x" ;;
    col) target="1x${h}!"; offset="$y" ;;
    *) die "axis must be row or col: $axis" ;;
  esac

  magick "$IMAGE" -crop "${w}x${h}+${x}+${y}" +repage -colorspace Gray \
    -filter box -resize "$target" txt:- |
    awk -v axis="$axis" -v offset="$offset" -v scale="$SCALE" '
      function px(v) {
        return scale == "" ? sprintf("%gpx", v) : sprintf("%gpx (%.2f dp/pt)", v, v / scale)
      }
      function abs(v) { return v < 0 ? -v : v }
      function lum(v) { return v > 255 ? v / 257 : v }
      /^[0-9]+,[0-9]+:/ {
        split($1, xy, /,|:/)
        pos = axis == "row" ? xy[1] : xy[2]
        tuple = $0
        sub(/^[^(]*\(/, "", tuple)
        sub(/\).*/, "", tuple)
        split(tuple, m, ",")
        n++
        coord[n] = offset + pos
        val[n] = lum(m[1])
      }
      END {
        print "Edges: " axis " projection"
        print "Strip: x=" px(offset) " length=" px(n)
        if (n < 3) {
          print "No profile: strip too small."
          print "Evidence: projection profile measures edges/gaps; insufficient pixels here."
          exit 0
        }
        for (i = 2; i <= n; i++) {
          g[i] = abs(val[i] - val[i - 1])
          sum += g[i]
          cnt++
        }
        mean = sum / cnt
        for (i = 2; i <= n; i++) ss += (g[i] - mean) * (g[i] - mean)
        sd = sqrt(ss / cnt)
        threshold = mean + 2 * sd
        print "Threshold: gradient > " sprintf("%.2f", threshold) " (mean+2sd)"
        print "position\tgradient"
        for (i = 3; i <= n - 1; i++) {
          if (g[i] > threshold && g[i] >= g[i - 1] && g[i] > g[i + 1]) {
            cN++
            candPos[cN] = coord[i]
            candG[cN] = g[i]
          }
        }
        for (i = 1; i <= cN; i++) {
          if (eN > 0 && candPos[i] - edgePos[eN] <= 2) {
            if (candG[i] > edgeG[eN]) {
              edgePos[eN] = candPos[i]
              edgeG[eN] = candG[i]
            }
          } else {
            eN++
            edgePos[eN] = candPos[i]
            edgeG[eN] = candG[i]
          }
        }
        if (eN == 0) {
          print "(none)"
        } else {
          for (i = 1; i <= eN; i++) {
            print px(edgePos[i]) "\t" sprintf("%.2f", edgeG[i])
          }
        }
        print "Gaps:"
        if (eN < 2) {
          print "(fewer than two edges)"
        } else {
          for (i = 2; i <= eN; i++) {
            gap = edgePos[i] - edgePos[i - 1]
            print px(edgePos[i - 1]) " -> " px(edgePos[i]) "\t" px(gap)
          }
        }
        print "Evidence: measured edge/gap candidates from luminance projection, not eyeballed spacing (NN-6)."
      }
    '
}

cmd_capheight() {
  [ $# -eq 4 ] || usage
  local x="$1" y="$2" w="$3" h="$4"
  validate_rect "$x" "$y" "$w" "$h"
  magick "$IMAGE" -crop "${w}x${h}+${x}+${y}" +repage -colorspace Gray -auto-level \
    -threshold 50% -filter box -resize "1x${h}!" txt:- |
    awk -v yoff="$y" -v scale="$SCALE" '
      function px(v) {
        return scale == "" ? sprintf("%gpx", v) : sprintf("%gpx (%.2f dp/pt)", v, v / scale)
      }
      function lum(v) { return v > 255 ? v / 257 : v }
      /^[0-9]+,[0-9]+:/ {
        split($1, xy, /,|:/)
        row = xy[2] + 0
        tuple = $0
        sub(/^[^(]*\(/, "", tuple)
        sub(/\).*/, "", tuple)
        split(tuple, m, ",")
        n++
        white[row] = lum(m[1]) / 255
        dark[row] = 1 - white[row]
        sumWhite += white[row]
        sumDark += dark[row]
      }
      END {
        if (n == 0) {
          print "No row profile found."
          exit 1
        }
        useDark = sumDark <= sumWhite
        first = -1
        last = -1
        bands = 0
        inBand = 0
        lastActive = -999
        for (r = 0; r < n; r++) {
          ink = useDark ? dark[r] : white[r]
          active = ink > 0.02
          if (active) {
            if (first < 0) first = r
            last = r
            if (!inBand && r - lastActive > 2) bands++
            inBand = 1
            lastActive = r
          } else if (inBand && r - lastActive > 2) {
            inBand = 0
          }
        }
        print "Cap-height profile: " (useDark ? "dark ink" : "light ink") ", active row threshold >2%"
        if (first < 0) {
          print "No text ink detected in the box."
          print "Evidence: no admissible cap-height measurement from this crop."
          exit 1
        }
        if (bands > 1) {
          print "Refused: row profile contains " bands " separated ink bands; crop appears to include more than one text line."
          print "Evidence: cap-height requires one text line with at least one capital (visual-analysis.md §5)."
          exit 1
        }
        cap = last - first + 1
        low = cap / 0.75
        high = cap / 0.66
        print "Ink rows: " px(yoff + first) " -> " px(yoff + last)
        print "Cap-height: " px(cap)
        if (scale == "") {
          printf "Font-size estimate band: %.1fpx .. %.1fpx (estimate)\n", low, high
        } else {
          printf "Font-size estimate band: %.1fpx .. %.1fpx (%.2f .. %.2f dp/pt, estimate)\n", low, high, low / scale, high / scale
        }
        print "Evidence: cap-height estimate band; a stated type token still outranks this (NN-4)."
      }
    '
}

cmd_contrast() {
  [ $# -ge 4 ] && [ $# -le 5 ] || usage
  local x1="$1" y1="$2" x2="$3" y2="$4" radius="${5:-2}"
  validate_sample_box "$x1" "$y1" "$radius"
  validate_sample_box "$x2" "$y2" "$radius"
  read -r r1 g1 b1 < <(sample_rgb "$x1" "$y1" "$radius")
  read -r r2 g2 b2 < <(sample_rgb "$x2" "$y2" "$radius")
  awk -v r1="$r1" -v g1="$g1" -v b1="$b1" -v r2="$r2" -v g2="$g2" -v b2="$b2" \
    -v h1="$(hex_from_rgb "$r1" "$g1" "$b1")" -v h2="$(hex_from_rgb "$r2" "$g2" "$b2")" \
    -v box1="$(sample_box_coords "$x1" "$y1" "$radius")" -v box2="$(sample_box_coords "$x2" "$y2" "$radius")" '
      function linear(c) {
        c = c / 255
        return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4
      }
      function lum(r,g,b) { return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b) }
      BEGIN {
        l1 = lum(r1, g1, b1)
        l2 = lum(r2, g2, b2)
        light = l1 > l2 ? l1 : l2
        dark = l1 > l2 ? l2 : l1
        ratio = (light + 0.05) / (dark + 0.05)
        print "Color 1: " h1 " sRGB(" r1 "," g1 "," b1 ") box " box1
        print "Color 2: " h2 " sRGB(" r2 "," g2 "," b2 ") box " box2
        printf "Contrast ratio: %.2f:1\n", ratio
        print "AA normal text (4.5:1): " (ratio >= 4.5 ? "pass" : "fail")
        print "AA large text/UI (3:1): " (ratio >= 3 ? "pass" : "fail")
        print "Evidence: WCAG ratio for sampled raster colors; stated tokens/states outrank samples (NN-4)."
      }
    '
}

SCALE=""
if [ $# -eq 0 ]; then
  usage
fi
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
fi
if [ "${1:-}" = "--scale" ]; then
  [ $# -ge 3 ] || usage
  SCALE="$2"
  validate_scale "$SCALE"
  shift 2
fi

[ $# -ge 2 ] || usage
IMAGE="$1"
shift

if [ "${1:-}" = "--scale" ]; then
  [ $# -ge 3 ] || usage
  [ -z "$SCALE" ] || die "--scale specified more than once"
  SCALE="$2"
  validate_scale "$SCALE"
  shift 2
fi

COMMAND="$1"
shift

[ -f "$IMAGE" ] || die "image not found: $IMAGE"
require_magick
identify_image

case "$COMMAND" in
  info)      [ $# -eq 0 ] || usage; print_info ;;
  color)     cmd_color "$@" ;;
  palette)   cmd_palette "$@" ;;
  crop)      cmd_crop "$@" ;;
  tiles)     cmd_tiles "$@" ;;
  edges)     cmd_edges "$@" ;;
  capheight) cmd_capheight "$@" ;;
  contrast)  cmd_contrast "$@" ;;
  *)         usage ;;
esac
