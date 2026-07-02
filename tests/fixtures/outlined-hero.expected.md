Ground truth for graders. An agent under test must produce values consistent with this table; deviations listed as traps are failures.

# outlined-hero.svg — expected analysis

Source class: **Vector, text converted to outlines** (the hostile export). `viewBox="0 0 390 180"` → logical canvas **390 × 180 pt**. There are **no `<text>` elements and no `font-family` anywhere** (verified: 0 occurrences of each). The markup is not pure raster — each glyph path keeps its `fill` and coordinates — but the copy and the font family are gone.

## Copy & font (§1, §5)
- **Copy is NOT recoverable** from outlined paths. Correct behavior: **flag it** and request a raster/PNG reference or the actual strings. Never invent words, line breaks, or emphasis. (The paths here are abstract letterform blobs, not real letters — any transcription is fabrication.)
- **Font family is unknown** (no `font-family`) → **decision gate**: ask for the exact family. Do not pick a lookalike.

## Per-run fills, baselines, weight (§1 outlines, §5)
Group glyph paths by `fill` and by baseline (y). Three runs:

| Run | baseline y | glyph count | fill | stem width | weight class |
|-----|-----------|-------------|------|-----------|--------------|
| line 1 (`#line1`) | 60 | 5 | **`url(#titleGrad)`** — one shared gradient | ~5 | medium/semibold (relative) |
| line 2 (`#line2`) | 100 | 5 | solid **`#0F1728`** | 8 | **bold** (thick stems) |
| caption (`#caption`) | 140 | 5 | solid **`#757584`** | 2.5 | **regular** (thin stems) |

- **Line 1 = ONE gradient brush across the whole run**, not a different stop per glyph and never flattened to a solid. Every glyph points at the same `#titleGrad`.
  - `titleGrad`: `gradientUnits="userSpaceOnUse"`, `x1=24 y1=48 → x2=240 y2=48`. y1 = y2 → **horizontal** brush.
  - Stops: `#5629F5` @0 → `#7E81F7` @1.
  - Because it is `userSpaceOnUse` anchored 24→240 while the inked glyphs span x≈24→119, the run samples only offset ≈0 → ≈0.44 — it starts at `#5629F5` and does **not** reach the terminal `#7E81F7` within the ink. Reproduce with a text/shape **brush** spanning the run, not an averaged solid, and not per-glyph stops.
- **Line 2** = solid `#0F1728`, **bold** — inferred from stem thickness (stems ≈8 wide), not from any weight attribute.
- **Caption** = solid `#757584`, **regular** — stems ≈2.5 wide. Relative weight only: caption (2.5) vs line 2 (8) ≈ 3× → clearly regular vs bold. Do not default every run to regular, nor all to bold.
- Baseline deltas: line1→line2 = 100−60 = **40**; line2→caption = 140−100 = **40**. Cap heights (ink top→baseline): line1 = 60−44 = 16, line2 = 100−82 = 18, caption = 140−128 = 12.

## Icon (§6, §1)
- Single `<path>` (teardrop pin), `fill="#0D46B4"`, `transform="rotate(15 330 60)"`.
- **Must be flagged as a rotated variant** (15° about (330,60)). An upright source glyph matched against this file is the **wrong asset** — request/verify the correctly-oriented SVG.
- Exact color is **`#0D46B4`**. In a small or rotated raster the hue is easily misread (can read teal/green) — do not recolor by eye; take the exact hex from the vector.

## Measurement warning — bounding boxes from rendered pixels, not raw `d` (§3.4)
- Raw `min`/`max` over the numbers in the icon `d` = x ∈ {330, 300, 360}, y ∈ {92, 60, 50} → raw bbox **x[300, 360] (width 60)**, y[50, 92] (height 42).
- The values **300** and **360** are Bézier **control points that sit well outside the ink** and are never reached. True rendered x-extrema (cubic at t=0.5) = **307.5 and 352.5 → width 45**, not 60. So raw `d` inflates the box by ~33% on x.
- On top of that the icon is rotated 15°, so even the corrected local ink box is not the on-screen box.
- Therefore: isolate the node and **measure geometry from rendered pixels at viewBox scale** — do not `min`/`max` the `d` string. (Same applies to the glyph paths above.)

## Decision-gate items (§8, §10)
- Exact **strings / copy** — request a raster reference; do not transcribe.
- **Font family** — ask; no lookalike.
- The **rotated icon variant** — confirm orientation / request the correct asset.

## Naive-agent traps (failures)
1. Transcribing invented copy from the outlined paths (the words are unrecoverable).
2. Defaulting every run to regular (or every run to bold) instead of reading stem thickness: line 2 bold, caption regular.
3. Reading line 1's gradient per-glyph (a different stop per letter) or flattening it to one solid — it is one shared `#5629F5→#7E81F7` horizontal brush across the run.
4. Recoloring `#0D46B4` by eye (it can read teal/green in raster) instead of taking the exact hex.
5. Trusting the rotated icon as upright — wiring an upright lookalike is the wrong asset; the file is rotated 15°.
6. Measuring geometry by `min`/`max` over path `d` numbers (control points 300/360 inflate the box) instead of from rendered pixels.
