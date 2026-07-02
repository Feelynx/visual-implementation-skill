#!/usr/bin/env bash
set -euo pipefail

# Prepares the render-vs-source comparison for the verification gate
# (references/verification.md): scales the capture to the source's width,
# builds a side-by-side sheet and a pixel diff when ImageMagick is available.
# The output supports — never replaces — the element x property delta table:
# re-read the images yourself and fill the table.

usage() {
  cat >&2 <<'EOF'
Usage: compare.sh <capture.png> <source.png> [outdir]

  capture   screenshot of YOUR built screen (see capture.sh)
  source    the design reference as PNG. An SVG is refused: export the PNG
            from the design tool (QuickLook-style rasterization distorts
            aspect and colour — NN-11).
  outdir    output directory (default: ./compare-out)

Outputs: <outdir>/capture-scaled.png, side-by-side.png + diff.png (ImageMagick
only; without it the scaled pair is produced and the visual comparison is
done by re-reading both images, as the gate requires anyway).
EOF
  exit 1
}

[ $# -ge 2 ] || usage
CAPTURE="$1"; SOURCE="$2"; OUTDIR="${3:-compare-out}"
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

if command -v magick >/dev/null 2>&1; then
  SRC_W="$(magick identify -format '%w' "$SOURCE")"
  magick "$CAPTURE" -resize "${SRC_W}x" "$SCALED"
  magick montage "$SOURCE" "$SCALED" -tile 2x1 -geometry +8+8 -background '#444' "$OUTDIR/side-by-side.png"
  # AE = count of differing pixels; 2% fuzz absorbs antialiasing noise.
  DIFF_PX="$(magick compare -metric AE -fuzz 2% "$SOURCE" "$SCALED" "$OUTDIR/diff.png" 2>&1 || true)"
  echo "Scaled capture:  $SCALED (width $SRC_W)"
  echo "Side-by-side:    $OUTDIR/side-by-side.png"
  echo "Pixel diff:      $OUTDIR/diff.png (differing pixels: $DIFF_PX)"
elif command -v sips >/dev/null 2>&1; then
  SRC_W="$(sips -g pixelWidth "$SOURCE" | awk '/pixelWidth/ {print $2}')"
  cp "$CAPTURE" "$SCALED"
  sips --resampleWidth "$SRC_W" "$SCALED" >/dev/null
  echo "Scaled capture:  $SCALED (width $SRC_W)"
  echo "ImageMagick not found: no montage/diff generated."
  echo "Compare visually: re-read $SOURCE and $SCALED as images and fill the delta table."
else
  echo "Error: neither ImageMagick (magick) nor sips available." >&2
  exit 1
fi

echo "Now complete the element x property delta table (references/verification.md)."
