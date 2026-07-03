# wallet-card.png — expected analysis

Fixture generator: `tests/fixtures/make-wallet-fixtures.sh`
Renderer used when this answer key was written: **ImageMagick 7**.
Recorded font for the generated PNGs: **/System/Library/Fonts/Helvetica.ttc**.

The source is a 780 × 1688 px raster representing a @3x phone-screen-like wallet UI. All coordinates below are physical pixels in the PNG.

## Source Geometry And Colors

| Element | Source value |
|---|---|
| Canvas | 780 × 1688 px, background #F6F8FC |
| App bar title | "Wallet" at x=72 y=112, 54 px font, #111827 |
| App bar date | "Friday, July 3" at x=72 y=168, 30 px font, #6B7280 |
| Balance card | x=48 y=222 w=684 h=306 radius=42, fill #2A5BD7 |
| Caption | "Available now" at x=84 y=276, 42 px font, fill #E0E8FF |
| Balance amount | "$24,680.20" at x=84 y=342, 78 px font, fill #FFFFFF |
| Icon tiles | three 188 × 168 rounded rects at x=48/296/544, y=582, radius=30, fill #FFFFFF |
| Icon-row → card gap | tile top 582 − card bottom 528 = 54 px |
| List rows | x=48 y=826 and x=48 y=1002, w=684 h=132, radius=30, fill #FFFFFF |
| Second row leading icon | blue down-arrow glyph centered at (102,1068), inside #E9EEFB circle r=30 |

## Curated Deltas In wallet-card-impl.png

| # | Location | Source | Implementation | Magnitude | Measurement that surfaces it |
|---|---|---|---|---|---|
| 1 | Balance card fill, sample away from text at (390,260) | #2A5BD7 | #2A64D7 | green channel +9; ΔE76 ≈ 7.36 for the requested hue shift | `visual-implementation/scripts/measure.sh fixtures/wallet-card.png color 390 260 2` and same point on impl |
| 2 | Caption text size, crop x=84 y=276 w=280 h=52 | 42 px font | 40 px font | −2 px authored font size; cap-height crop is smaller | `measure.sh <img> capheight 84 276 280 52` |
| 3 | Icon-row → balance-card vertical gap | 54 px | 60 px | +6 px; card bottom remains y=528, tile top moves 582→588 | `measure.sh <img> edges 48 528 684 90 row` or crop/edge scan around card bottom and icon row |
| 4 | Second list row leading glyph, crop x=72 y=1038 w=60 h=60 | down-arrow | calendar glyph | same icon circle and size, different glyph identity | `measure.sh <img> crop 72 1038 60 60 /tmp/second-icon.png` plus native-resolution read/palette |
| 5 | Caption text-on-card contrast | #E0E8FF on #2A5BD7 = 4.80:1 | #E1E8FF on #2A64D7 = 4.40:1 | implementation is below WCAG AA 4.5:1 for normal text | `measure.sh <img> contrast <caption-text-sample> 390 260` after sampling a solid caption pixel with `color` |

## Expected Findings

An implementation audit should not declare the two images a match from a whole-frame glance. It should tile or crop at native resolution, measure at least the card color and icon-row gap, and report at least four of the five deltas above. The hue shift and +6 px gap are required findings. The caption contrast regression must be reported as an accessibility issue, with measured values distinguished from estimates.

Confident extra findings outside this table should be treated as likely hallucinations unless they are explicitly framed as uncertainty needing follow-up.
