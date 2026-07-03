#!/usr/bin/env bash
set -euo pipefail

# Deterministically generates the wallet-card raster fixture pair plus the
# markdown answer key. The primary path uses ImageMagick 7 primitives and text.
# This checkout's CI can run the magick path; the local fallback exists for
# machines where ImageMagick is not installed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/wallet-card.png"
IMPL="$SCRIPT_DIR/wallet-card-impl.png"
EXPECTED="$SCRIPT_DIR/../expected/06-ground-truth.md"

pick_magick_font() {
  local candidate
  for candidate in Helvetica Arial DejaVu-Sans Liberation-Sans; do
    if magick -list font 2>/dev/null | awk -F: '/^[[:space:]]*Font: /{gsub(/^[[:space:]]+/, "", $2); print $2}' | grep -qx "$candidate"; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  for candidate in \
    /System/Library/Fonts/Helvetica.ttc \
    /System/Library/Fonts/SFNS.ttf \
    /Library/Fonts/Arial\ Unicode.ttf \
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
    /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  printf '%s\n' Helvetica
}

draw_with_magick() {
  local out="$1"
  local card_fill="$2"
  local caption_color="$3"
  local caption_size="$4"
  local icon_y="$5"
  local second_icon="$6"
  local font="$7"

  magick -size 780x1688 xc:'#F6F8FC' \
    -font "$font" \
    -fill '#111827' -pointsize 54 -annotate +72+150 'Wallet' \
    -fill '#6B7280' -pointsize 30 -annotate +72+198 'Friday, July 3' \
    -fill "$card_fill" -draw 'roundrectangle 48,222 732,528 42,42' \
    -fill "$caption_color" -pointsize "$caption_size" -annotate +84+322 'Available now' \
    -fill '#FFFFFF' -pointsize 78 -annotate +84+418 '$24,680.20' \
    -fill '#FFFFFF' -draw "roundrectangle 48,$icon_y 236,$((icon_y + 168)) 30,30" \
    -fill '#FFFFFF' -draw "roundrectangle 296,$icon_y 484,$((icon_y + 168)) 30,30" \
    -fill '#FFFFFF' -draw "roundrectangle 544,$icon_y 732,$((icon_y + 168)) 30,30" \
    -fill '#E9EEFB' -draw "circle 142,$((icon_y + 62)) 142,$((icon_y + 26))" \
    -fill '#E9EEFB' -draw "circle 390,$((icon_y + 62)) 390,$((icon_y + 26))" \
    -fill '#E9EEFB' -draw "circle 638,$((icon_y + 62)) 638,$((icon_y + 26))" \
    -stroke '#2A5BD7' -strokewidth 8 -fill none \
    -draw "line 142,$((icon_y + 41)) 142,$((icon_y + 83)) line 121,$((icon_y + 62)) 163,$((icon_y + 62))" \
    -draw "path 'M 377,$((icon_y + 51)) L 390,$((icon_y + 38)) L 403,$((icon_y + 51)) M 390,$((icon_y + 39)) L 390,$((icon_y + 86))'" \
    -draw "path 'M 625,$((icon_y + 39)) L 651,$((icon_y + 39)) L 651,$((icon_y + 85)) L 625,$((icon_y + 85)) Z M 625,$((icon_y + 58)) L 651,$((icon_y + 58))'" \
    -stroke none -fill '#111827' -pointsize 32 -annotate +113+$((icon_y + 132)) 'Send' \
    -fill '#111827' -pointsize 32 -annotate +365+$((icon_y + 132)) 'Pay' \
    -fill '#111827' -pointsize 32 -annotate +608+$((icon_y + 132)) 'Save' \
    -fill '#FFFFFF' -draw 'roundrectangle 48,826 732,958 30,30' \
    -fill '#FFFFFF' -draw 'roundrectangle 48,1002 732,1134 30,30' \
    -fill '#E9EEFB' -draw 'circle 102,892 102,862' \
    -fill '#E9EEFB' -draw 'circle 102,1068 102,1038' \
    -stroke '#2A5BD7' -strokewidth 8 -fill none \
    -draw "path 'M 88,892 L 116,892 M 102,878 L 102,906'" \
    -draw "$(if [ "$second_icon" = arrow ]; then printf "%s" "path 'M 102,1048 L 102,1088 M 87,1073 L 102,1088 L 117,1073'"; else printf "%s" "path 'M 90,1048 L 116,1048 L 116,1088 L 90,1088 Z M 90,1062 L 116,1062 M 96,1041 L 96,1054 M 110,1041 L 110,1054'"; fi)" \
    -stroke none -fill '#111827' -pointsize 39 -annotate +156+882 'Coffee House' \
    -fill '#6B7280' -pointsize 30 -annotate +156+927 'Today, 08:24' \
    -fill '#111827' -pointsize 39 -annotate +156+1058 'Payroll' \
    -fill '#6B7280' -pointsize 30 -annotate +156+1103 'Yesterday, 17:10' \
    "$out"
}

draw_with_python() {
  local source="$1"
  local impl="$2"
  python3 - "$source" "$impl" <<'PY'
from PIL import Image, ImageDraw, ImageFont
import sys

source, impl = sys.argv[1:3]
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"

def font(size):
    try:
        return ImageFont.truetype(FONT_PATH, size=size)
    except OSError:
        return ImageFont.load_default(size=size)

def draw_arrow_down(draw, cx, cy, color):
    draw.line([(cx, cy-20), (cx, cy+20)], fill=color, width=8)
    draw.line([(cx-15, cy+5), (cx, cy+20), (cx+15, cy+5)], fill=color, width=8, joint="curve")

def draw_calendar(draw, cx, cy, color):
    x0, y0, x1, y1 = cx-14, cy-20, cx+14, cy+20
    draw.rounded_rectangle((x0, y0, x1, y1), radius=3, outline=color, width=8)
    draw.line([(x0, cy-6), (x1, cy-6)], fill=color, width=8)
    draw.line([(cx-7, y0-7), (cx-7, y0+5)], fill=color, width=6)
    draw.line([(cx+7, y0-7), (cx+7, y0+5)], fill=color, width=6)

def draw_wallet(path, card_fill, caption_color, caption_size, icon_y, second_icon):
    im = Image.new("RGB", (780, 1688), "#F6F8FC")
    draw = ImageDraw.Draw(im)
    blue = "#2A5BD7"
    text = "#111827"
    muted = "#6B7280"
    tile_bg = "#E9EEFB"

    draw.text((72, 112), "Wallet", fill=text, font=font(54))
    draw.text((72, 168), "Friday, July 3", fill=muted, font=font(30))

    draw.rounded_rectangle((48, 222, 732, 528), radius=42, fill=card_fill)
    draw.text((84, 276), "Available now", fill=caption_color, font=font(caption_size))
    draw.text((84, 342), "$24,680.20", fill="#FFFFFF", font=font(78))

    for x, label in [(48, "Send"), (296, "Pay"), (544, "Save")]:
        draw.rounded_rectangle((x, icon_y, x + 188, icon_y + 168), radius=30, fill="#FFFFFF")
        cx = x + 94
        cy = icon_y + 62
        draw.ellipse((cx - 36, cy - 36, cx + 36, cy + 36), fill=tile_bg)
        draw.text((x + (188 - draw.textlength(label, font=font(32))) / 2, icon_y + 106), label, fill=text, font=font(32))

    cy = icon_y + 62
    draw.line([(142, cy - 21), (142, cy + 21)], fill=blue, width=8)
    draw.line([(121, cy), (163, cy)], fill=blue, width=8)
    draw.line([(390, cy - 23), (390, cy + 24)], fill=blue, width=8)
    draw.line([(377, cy - 11), (390, cy - 24), (403, cy - 11)], fill=blue, width=8, joint="curve")
    draw.rounded_rectangle((625, cy - 23, 651, cy + 23), radius=4, outline=blue, width=8)
    draw.line([(625, cy - 4), (651, cy - 4)], fill=blue, width=8)

    for y in (826, 1002):
        draw.rounded_rectangle((48, y, 732, y + 132), radius=30, fill="#FFFFFF")
    for cx, cy2 in ((102, 892), (102, 1068)):
        draw.ellipse((cx - 30, cy2 - 30, cx + 30, cy2 + 30), fill=tile_bg)

    draw.line([(88, 892), (116, 892)], fill=blue, width=8)
    draw.line([(102, 878), (102, 906)], fill=blue, width=8)
    if second_icon == "arrow":
        draw_arrow_down(draw, 102, 1068, blue)
    else:
        draw_calendar(draw, 102, 1068, blue)

    draw.text((156, 848), "Coffee House", fill=text, font=font(39))
    draw.text((156, 898), "Today, 08:24", fill=muted, font=font(30))
    draw.text((156, 1024), "Payroll", fill=text, font=font(39))
    draw.text((156, 1074), "Yesterday, 17:10", fill=muted, font=font(30))
    im.save(path)

draw_wallet(source, "#2A5BD7", "#E0E8FF", 42, 582, "arrow")
draw_wallet(impl, "#2A64D7", "#E1E8FF", 40, 588, "calendar")
PY
}

write_expected() {
  local renderer="$1"
  local font_label="$2"
  cat > "$EXPECTED" <<EOF
# wallet-card.png — expected analysis

Fixture generator: \`tests/fixtures/make-wallet-fixtures.sh\`
Renderer used when this answer key was written: **$renderer**.
Recorded font for the generated PNGs: **$font_label**.

The source is a 780 × 1688 px raster representing a @3x phone-screen-like wallet UI. All coordinates below are physical pixels in the PNG.

## Source Geometry And Colors

| Element | Source value |
|---|---|
| Canvas | 780 × 1688 px, background #F6F8FC |
| App bar title | "Wallet" at x=72 y=112, 54 px font, #111827 |
| App bar date | "Friday, July 3" at x=72 y=168, 30 px font, #6B7280 |
| Balance card | x=48 y=222 w=684 h=306 radius=42, fill #2A5BD7 |
| Caption | "Available now" at x=84 y=276, 42 px font, fill #E0E8FF |
| Balance amount | "\$24,680.20" at x=84 y=342, 78 px font, fill #FFFFFF |
| Icon tiles | three 188 × 168 rounded rects at x=48/296/544, y=582, radius=30, fill #FFFFFF |
| Icon-row → card gap | tile top 582 − card bottom 528 = 54 px |
| List rows | x=48 y=826 and x=48 y=1002, w=684 h=132, radius=30, fill #FFFFFF |
| Second row leading icon | blue down-arrow glyph centered at (102,1068), inside #E9EEFB circle r=30 |

## Curated Deltas In wallet-card-impl.png

| # | Location | Source | Implementation | Magnitude | Measurement that surfaces it |
|---|---|---|---|---|---|
| 1 | Balance card fill, sample away from text at (390,260) | #2A5BD7 | #2A64D7 | green channel +9; ΔE76 ≈ 7.36 for the requested hue shift | \`visual-implementation/scripts/measure.sh fixtures/wallet-card.png color 390 260 2\` and same point on impl |
| 2 | Caption text size, crop x=84 y=276 w=280 h=52 | 42 px font | 40 px font | −2 px authored font size; cap-height crop is smaller | \`measure.sh <img> capheight 84 276 280 52\` |
| 3 | Icon-row → balance-card vertical gap | 54 px | 60 px | +6 px; card bottom remains y=528, tile top moves 582→588 | \`measure.sh <img> edges 48 528 684 90 row\` or crop/edge scan around card bottom and icon row |
| 4 | Second list row leading glyph, crop x=72 y=1038 w=60 h=60 | down-arrow | calendar glyph | same icon circle and size, different glyph identity | \`measure.sh <img> crop 72 1038 60 60 /tmp/second-icon.png\` plus native-resolution read/palette |
| 5 | Caption text-on-card contrast | #E0E8FF on #2A5BD7 = 4.80:1 | #E1E8FF on #2A64D7 = 4.40:1 | implementation is below WCAG AA 4.5:1 for normal text | \`measure.sh <img> contrast <caption-text-sample> 390 260\` after sampling a solid caption pixel with \`color\` |

## Expected Findings

An implementation audit should not declare the two images a match from a whole-frame glance. It should tile or crop at native resolution, measure at least the card color and icon-row gap, and report at least four of the five deltas above. The hue shift and +6 px gap are required findings. The caption contrast regression must be reported as an accessibility issue, with measured values distinguished from estimates.

Confident extra findings outside this table should be treated as likely hallucinations unless they are explicitly framed as uncertainty needing follow-up.
EOF
}

if command -v magick >/dev/null 2>&1; then
  FONT="$(pick_magick_font)"
  draw_with_magick "$SOURCE" '#2A5BD7' '#E0E8FF' 42 582 arrow "$FONT"
  draw_with_magick "$IMPL" '#2A64D7' '#E1E8FF' 40 588 calendar "$FONT"
  write_expected "ImageMagick 7" "$FONT"
else
  draw_with_python "$SOURCE" "$IMPL"
  write_expected "Python Pillow fallback because ImageMagick 7 was not installed locally" "Helvetica Regular (/System/Library/Fonts/Helvetica.ttc)"
fi

printf 'Generated %s\nGenerated %s\nGenerated %s\n' "$SOURCE" "$IMPL" "$EXPECTED"
