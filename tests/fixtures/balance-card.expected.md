Ground truth for graders. An agent under test must produce values consistent with this table; deviations listed as traps are failures.

# balance-card.svg — expected analysis

Source class: **Vector (SVG branch)** — parse, do not eyeball. One embedded raster asset makes it technically **Mixed** (vector chrome + a raster asset at `<image>`).

## Reference frame (§3)
- `viewBox="0 0 390 220"`, `width=390 height=220` → logical canvas **390 × 220 pt**.
- Logical width **390pt** (iPhone-class). Confidence **high**. No scale factor needed — SVG gives logical units directly.

## Colors (§1, §4)
- **Card fill** = `linearGradient#cardGrad`, `gradientUnits="userSpaceOnUse"`, `x1=20 y1=24 → x2=370 y2=196`.
  - Δx = 350, Δy = 172 → both axes change → **diagonal** (top-left → bottom-right), NOT vertical.
  - Stops: `#4F46E5` @ offset 0 → `#7C3AED` @ offset 1. Two stops, no midpoint.
- **Label** = `fill="#FFFFFF"` with `fill-opacity="0.7"` → **on-primary white at 70%**, resolved as a role (white-on-gradient at 0.7 alpha). NOT a solid grey hex. Do not blend it to `#B9B4EE` or similar.
- **Amount** = `#FFFFFF`, solid (on-primary).
- **Pill fill** = `#FFFFFF` solid.
- **Pill label** = `#4F46E5` (matches gradient stop-0 — the primary).
- **Tile** = `#FFFFFF` at `fill-opacity="0.16"` → white-on-primary at 16% (translucent container), NOT a solid light hex.
- **Chevron glyph** = `#FFFFFF`, `stroke="none"` (solid fill, no stroke).

## Typography runs (§5)
Family **Inter** is present in the source → confirm Inter is available in the project (else decision gate). Weights are exact from the SVG (this is a clean vector, not outlined).

| Run | x, y (baseline) | size / weight | fill | role |
|-----|-----------------|---------------|------|------|
| "Available balance" | 44, 76 | 14 / 500 | #FFFFFF @ 0.7 | label |
| "$2,480.00" | 44, 120 | 34 / 700 | #FFFFFF | display / amount |
| "Add money" | 68, 173 | 14 / 600 | #4F46E5 | button label |

## Shadow (§1, skill format `offsetX offsetY blur spread color/alpha`)
- `feDropShadow dx=0 dy=6 stdDeviation=8 flood-color=#0F172A flood-opacity=0.1`.
- blur = 2 × stdDeviation = 2 × 8 = **16**. spread = 0 (SVG has no spread).
- Spec: **`0 6 16 0 #0F172A/10%`**. Do not collapse to a default elevation token — carry the full spec.

## Radii
- Card `rx=24`. Pill `rx=20`.
- Pill radius 20 = ½ of pill height 40 → **fully rounded / stadium** shape (not an arbitrary 20 corner).

## Spacing & inset inventory — coordinate deltas with arithmetic (§3.5)
- **Card left inset** = 20 (card `x` from viewBox left). Card top inset = 24 (`y`).
- **Content inset** = 44 − 20 = **24** (label/amount/pill `x=44` minus card `x=20`).
- **Label → amount** vertical gap (baseline→baseline) = 120 − 76 = **44**.
- **Amount → pill** gap = pill top 148 − amount baseline 120 = **28**.
- **Pill height** = 40. **Pill width** = 132. Pill right edge = 44 + 132 = 176.
- **Pill bottom inset** = card bottom (24+172=196) − pill bottom (148+40=188) = **8**.
- **Tile diameter** = 2 × r16 = **32**. Tile bbox: cx±r → x[314,346], y[152,184].
- **Tile ↔ card right** inset = card right 370 − tile right 346 = **24**.
- **Tile / pill vertical centering**: tile center cy=168; pill center = 148 + 40/2 = 168 → tile and pill share the same vertical center (168).
- **Image inset from card right** = card right 370 − image right (302+40=342) = **28**; image top inset = 48 − 24 = **24**.
- Card right edge = 20 + 350 = 370; card bottom = 24 + 172 = 196.

## Asset vs drawable classification (§6)
- **Embedded `<image href="data:image/png;base64,…">`** (x302 y48 40×40) → a **user-provided raster asset** → route to the **decision gate** (request the real PNG @1x/2x/3x). **Never redraw it.** (Here the sample is a 1×1 transparent PNG placeholder — invisible in render — standing in for a logo/brand mark.)
- **Tile + chevron** (circle + path) → **drawable from primitives** (translucent circle container + solid glyph).
- **Gradient card, pill, all text** → **drawable** from primitives + tokens.

## Expected decision-gate items (§8, §10)
- The embedded image asset (logo/brand mark) — request the exported raster; do not recreate.
- **Loading / hidden-balance states** — a static frame cannot show them; the amount could be masked (•••) or skeletoned. Raise it.
- **Inter availability** in the project — if not present, ask; do not silently substitute a lookalike.

## Naive-agent traps (failures)
1. Eyeballing the gradient (guessing "purple", vertical, or a single flat color) instead of reading stops `#4F46E5→#7C3AED`, userSpaceOnUse, diagonal.
2. Reading the 70% label as a solid grey hex instead of white-on-primary at 0.7 opacity.
3. Collapsing the shadow to a default elevation instead of `0 6 16 0 #0F172A/10%` (blur = 2×stdDeviation).
4. Redrawing the embedded `<image>` in code instead of requesting the asset.
5. Hardcoding raw 24 / 20 radii and 24 / 44 / 28 gaps instead of snapping to project tokens (or flagging missing tokens at the gate).
6. Giving the chevron a bare borderless icon — silently deleting its translucent circular tile (container treatment, §7).
