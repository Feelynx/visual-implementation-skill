# Visual Analysis

Protocols for extracting reliable design intent from a visual source. The source type decides the method: **vector (SVG) is parsed; raster (PNG/JPG/screenshot) is estimated with declared uncertainty.** Calibrate scale before deriving any spacing, size, or radius.

## 0. Classify the source first

- **Vector:** `.svg`, or any export whose text is selectable and whose coordinates are present. Parse the source.
- **Raster:** `.png`, `.jpg`, `.webp`, screenshots, photos of a screen. Measure with the instrument, estimate perceptually as the fallback (§2).
- **Mixed:** SVG with an embedded `<image>` base64 = vector chrome plus a raster asset. A PDF or Figma link is neither — ask for an exported SVG or PNG (a Figma link is resolvable without asking when a programmatic connection exists; see the named-token spec entry).
- **Named-token spec (outranks vector and raster):** a Figma styles/variables panel, an inspect/redline export, or a values table that *names* design values (type style, spacing variable, radius token). When present it is the highest-priority source: map source token → project token directly and do not re-derive that value from pixels or path coordinates; parse the SVG / estimate the raster only for geometry the tokens do not cover. **Fetch it yourself when you can:** if the session has a programmatic Figma connection (a Figma MCP server or API access — check the available tools before asking the user), pull the styles, variables, and node values for the linked frame directly; what you fetch IS this spec, with the same priority. A bare Figma link with no exported spec and no such connection is not this — ask for the token names or the inspect panel before falling back to measurement.
- **Target class & design width (record at intake):** detect the target class from the frame chrome — browser chrome / scrollbars / cursor = web; traffic-light buttons / window title bar = desktop; otherwise mobile. Record the design width and the device-pixel-ratio (DPR) as intake facts; they scope every later scale conversion (§3), and a wide/desktop/web target pulls in the §8 behaviors a mobile frame never raises.

## 0.5 Reconcile a frame set into screens × states (before analyzing any single frame)

Multiple provided frames are often one screen in different states, not separate screens. Diff the frames pairwise first: identical structure differing only in a trailing control, status line, or copy means *state variants of one screen* — analyze that screen once with a state column, mapping each variant to the state its differing affordance encodes (trailing trash = connected/removable; overflow / 3-dots = request pending; a "received" line = incoming, awaiting your action). Only genuinely different structure makes a frame a distinct screen. Derive the screen set from the frames, never from the existing code.

## 1. SVG branch — parse, do not eyeball

Read the raw SVG as text and extract exact values, not impressions:

- **Colors:** `fill`, `stroke`, `stop-color` + `stop-opacity`, `fill-opacity`, `opacity`. Resolve layered opacity instead of guessing a blended hex.
- **Gradients:** `<linearGradient>` / `<radialGradient>` stops, offsets, coordinates, transforms.
- **Typography:** `font-family`, `font-size`, `font-weight`, `letter-spacing`, `text-anchor`, line height / `dy` on `<text>` / `<tspan>`.
- **Geometry & scale:** `viewBox` is the reference coordinate system (the logical canvas). Element coordinates, `width` / `height`, `rx` / `ry` (corner radius), stroke widths, `transform`.
- **Effects → shadows & borders:** extract the *whole* shadow. From `feDropShadow` read `dx`/`dy` (offset), `stdDeviation` (blur ≈ `2 × stdDeviation` CSS radius), and `flood-color`/`flood-opacity` (color/alpha); a split `feGaussianBlur` + `feOffset` + `feFlood`/`feColorMatrix` chain encodes the same parts — reassemble them. Record one spec `offsetX offsetY blur spread color/alpha` (e.g. `0 4 8 0 #000 5%`); SVG has no spread, so spread is `0` unless `feMorphology` dilates. Never collapse offset+blur into a single elevation guess — carry the full spec to platform-notes. Borders are often a stroked `<mask>` or stroke path, not a `stroke=` attribute — read the mask/stroke geometry for the real width and exact hex. `clipPath` / `mask` → reproduce the *effect*, not the node tree.

**Export junk to ignore or flag (Figma / Sketch / Illustrator):**
- Deeply nested `<g>` with identity transforms, duplicate nodes, redundant clip-paths — structural noise, not design intent.
- **Text converted to outlines/paths** (`<path>` where text should be) → the font *family* is gone, but the markup is not pure raster: each glyph path keeps its `fill` and coordinates. Recover what survives — group glyph paths by `fill` and by baseline (y) to read per-line / per-span color (two different fills across two title lines = a **two-tone title** → separate runs), and compare stem thickness across runs for relative weight (visibly thicker stems = **bold**; do not default every run to regular). The *copy* is also gone: you cannot read words, line breaks, or emphasis from paths — transcribe every string verbatim from a raster/PNG reference, diff it per locale against the project's strings, and never trust the strings, weights, or colors already in the code as ground truth. Ask the user only for the exact font family; route an unknown family to the decision gate. When a glyph's `fill` is a `url(#…)` reference rather than a hex, the run is gradient-filled: resolve the referenced gradient (apply `gradientUnits`/`gradientTransform`, §3.6) and read it as **one** brush across the whole run — an outline export points every glyph at the same shared gradient, so never read a different stop per glyph. Capture the terminal stop exactly: a final `#FFF` is not `stop-opacity=0` — fade-to-white survives only on a white surface, fade-to-transparent on any surface.
- Embedded `<image href="data:...">` → a real raster asset to export, not something to redraw.
- `<mask>` / `clipPath` doing the visual work → reproduce the *effect*, not the node tree.

Map each exact value to the nearest project token. When an exact value has no matching token → decision gate (add a token vs snap to nearest).

## 2. Raster branch — instrument when you can, estimate with declared uncertainty otherwise

With ImageMagick, a raster is *measured* (`scripts/measure.sh`); without it, every value is an *estimate* carrying a confidence — the declared-uncertainty fallback. Either path runs under a fixation protocol: models lose fine detail on a full-frame read, so a conclusion formed only at whole-frame scale is provisional by definition.

1. **Gestalt pass.** One read of the whole frame for layout regions, hierarchy, and reading order — orientation only, no values.
2. **Fixate every tile.** Tile the frame (`measure.sh <img> tiles <COLSxROWS> <outdir>`, or manual crops via `measure.sh <img> crop <x> <y> <w> <h> <out.png>`) and read EVERY tile at native resolution or integer zoom. A value formed only at whole-frame scale stays provisional until confirmed at native res.
3. **Instrument, don't eyeball (ImageMagick present).** Within each region: `measure.sh <img> color <x> <y> [radius]` / `palette` for fills; `measure.sh <img> edges <x> <y> <w> <h> <row|col>` for every gap and inset in the spacing inventory (§3); `measure.sh <img> capheight <x> <y> <w> <h>` for text-size bands (§5); `measure.sh <img> contrast <x1> <y1> <x2> <y2>` for text-on-fill pairs (§4). A regional read that samples only colors is not the protocol — the minimum instrumented set per screen is fills, every named gap/inset, one cap-height per distinct text size, and contrast for the key text-on-fill pairs. No ImageMagick → perceptual estimation, still tiled, at declared uncertainty.
4. **Tag provenance per value — in your notes AND in every report you emit.** Mark each *measured (instrument)* or *estimated (perceptual)*; a numeric claim presented without its provenance tag and the command that produced it reads as an estimate, whatever precision it displays. An eyeballed value where the instrument was available is low-confidence by definition.
5. **Carry the caveats on both paths.** Compression artifacts, anti-aliasing, and `@2x` / `@3x` downscaling shift colors and soften edges — lower confidence near thin strokes, small text, and shadows.

Never emit a precise literal you did not measure — measured literals now exist, and they still snap to tokens per §3.

## 3. Scale & density calibration (run before deriving any spacing)

Without a reference frame, image pixels cannot become real `dp` / `pt`.

1. **Establish the reference frame.**
   - SVG: the `viewBox` gives logical units directly.
   - Raster: you need the **device width** (e.g. 390pt iPhone, 360dp Android) and the **scale factor** (`@1x` / `@2x` / `@3x`). If either is unknown → decision gate; do not assume.
   - **Calibrate scale per target.** Desktop/web frames are commonly `@1x`/`@2x` while mobile frames are `@2x`/`@3x` — never reuse a mobile scale factor for a desktop/web frame of the same product. A browser screenshot's device-pixel-ratio (DPR) is part of this reference-frame question, not a detail to skip.
2. **Convert.** For a device screenshot, `logical = imagePx / scaleFactor`. Otherwise work proportionally: `element / screenWidth`.
3. **Derive scales by clustering, then snap.** Collect observed gaps / sizes / radii, cluster nearby values, and map each cluster to the project's existing spacing / type / radius scale. Prefer the project token over the raw number. This replaces "pixel-perfect" with "rhythm-correct" without inventing literals.
4. **Measure geometry from rendered pixels, not raw path numbers.** Outlined text and icon glyphs arrive as `<path d="…">`; never `min`/`max` over the numbers in `d` — Bezier control points (`C`/`S`/`Q`/`T`) sit outside the visual ink and inflate the bounding box (this is exactly what makes a measured gap or glyph read too large). Isolate the node/group, render only it, and measure at `viewBox` scale. Align related elements (icon-row → title, glyph inside its tile) from the **same** rendered frame, not two separate raw `d` reads.
5. **Build a spacing & inset inventory (first-class pass, equal to color).** Compute every inter-element gap (icon-row→title, title→body, card→card) and every internal inset (glyph→tile, content→card edge, label→button edge) as coordinate deltas — subtract coordinates, do not eyeball; in an outlined SVG these deltas are exact even when copy and font are not. Name each gap/inset, then map it to a token. A color or gradient fix with gaps left unmeasured is an incomplete pass, not a finished one.
6. **Gradients:** read `gradientUnits` before trusting `x1/y1/x2/y2` — `userSpaceOnUse` = absolute `viewBox` coords, `objectBoundingBox` = `0..1` fractions of the element box. Apply any `gradientTransform`, then derive direction (diagonal vs vertical), not the raw numbers.

## 4. Color

- SVG: take exact values (§1). Raster: with ImageMagick, *sample* the value (`measure.sh <img> color <x> <y> [radius]`, multi-point across the fill) rather than estimate it; without it, estimate per §2. Either way the decision is token mapping: a small distance from a project token → snap to the token; a genuinely token-less sampled value → decision gate (add a token vs snap to nearest), exactly as before.
- Decompose visible color: base fill vs overlay opacity vs shadow. A "grey" is often black at low opacity over the background — map to the role, not a one-off hex.
- **Contrast is an analysis output, not an afterthought.** Compute WCAG contrast for the key text-on-fill pairs (`measure.sh <img> contrast <x1> <y1> <x2> <y2>`) and route AA failures to the risk ledger as accessibility risk. A design can ship an AA failure — flag it, never silently "fix" it.
- Flag low confidence on gradients, translucency, and shadowed regions.

## 5. Typography

- Determinable: role (display / title / headline / body / label / caption), relative size, relative weight, alignment, approximate line length.
- **Per-run color and weight:** one text block can carry multiple colors or weights — a two-tone title (line 1 vs line 2) or a bold word/label inside regular copy. Inspect each line / run separately; never collapse a block to one color + one weight. Encode as `AnnotatedString`, multiple `Text` composables, or split string keys. **A run's fill can also be a paint, not a solid:** colour shifting *continuously along the run* (a lead word fading toward one end) is **one brush spanning the run** — record direction, stops+offsets, and the terminal stop's colour *and* opacity, and reproduce it with a text brush (platform-notes), never an averaged solid token; colour changing at a glyph/word boundary is a two-tone run (separate solids). In a raster a fill fading toward the background reads like the text getting lighter, trailing off, or cut at the edge — flag a possible text brush at low confidence and confirm at the gate; do not transcribe the faded end as a lighter solid or drop the faint glyphs.
- **A stated token outranks any pixel measurement, and every run is sized from its own evidence.** When the source exposes a type token or named value (Figma `Typography/md`, a documented sp/pt), look it up or ask for it and map it to the project type scale — the token is ground truth for size, weight, AND line-height (e.g. `Typography/md` = 16sp/400/150% → `TextRegularM`); do not flatten the token's line-height to a default. Absent a token, exact family, fine weight (500 vs 600), and precise letter-spacing/line-height are not reliably determinable; coarse weight class (regular/medium/bold) IS determinable from stem thickness even in raster or outlined sources. **Never back-calculate font size from glyph or character width:** advance width is font-specific (Roboto ≈ 0.43em/char vs the ≈0.5em a generic estimate assumes), so a real 16sp run measures like 14sp and you will wrongly downsize it — pixel font-size estimation is a tagged-low-confidence fallback, biased low. Derive a size for *every* run — title, body, and each subtitle/caption/label — from its own evidence rather than sizing the prominent run and defaulting the rest to the standard body token; tag each `token (stated)` or `estimate (pixel, font-metric uncertainty)`.
- **Cap-height sizing (upgrades the pixel fallback).** Measure the cap height of a clean line (`measure.sh <img> capheight <x> <y> <w> <h>`): the estimate BAND `px/0.75 … px/0.66` is advance-width-independent, so it dodges the back-calc trap above. Report the band and snap to the type-scale token inside it — still a tagged estimate, still outranked by any stated token (NN-4). **Letter-spacing** is measurable at zoom from the inter-glyph gaps of a straight-sided pair (`HH`, `ll`) as a px value; report it only when clearly non-default.
- **Font candidate check (families).** When the family is unknown, before asking, render the project's BUNDLED candidate fonts on the same string at the same size and compare glyph anatomy — single/double-story `a` and `g`, `R` leg, `t`/`f` terminals, digit shapes — against a foveal crop (`measure.sh <img> crop`). A match is a *candidate claim* for the gate, never a silent substitution (NN-10 still governs).
- Map to the project's type roles. A family the source *names* (`font-family="Inter"`) is a claim to verify, not a given: extract it, check the project actually bundles it, and when it is absent raise availability as a risk-ledger item and gate the substitution. If the family is unknown and not inferable from the project → decision gate (ask; do not silently pick a lookalike).

## 6. Asset vs drawable

Classify each visual element, because misclassifying either wastes work or loses fidelity:
- **Exported image / photo** → asset to provide; do not redraw.
- **Logo / brand mark** → asset; never recreate in code unless the user approves.
- **Icon** → project icon set, SF Symbols, or icon-font glyph when semantically correct; otherwise an asset.
- **Simple shape / divider / gradient / badge** → compose from primitives and tokens.
- **Dense illustration / map / textured background** → a **raster asset the user exports from the design tool**, not something you redraw or rasterize yourself. Do NOT convert a large multi-path SVG (a city map, a detailed illustration) to a vector drawable — it balloons to megabytes of path nodes and renders slowly. Do NOT rasterize the SVG with a thumbnail/QuickLook tool — it distorts aspect, crop, and colour. The design already has the exact export: **ask for the PNG (1x / 2x / 3x)**. An overlay effect *on top* of that raster (a white→transparent fade to blend it into the page) IS yours to compose in code with a `Brush` / gradient — you don't need a second exported asset for the fade.

When unsure whether something is an asset or drawable → decision gate.

**Verify the matched file before reuse — open it.** Picking the project's icon set is step one; confirming the specific drawable is step two. Before reusing or overwriting any drawable, open it (as text or rendered) and check it against the source glyph:
- **viewBox:** a non-square or odd box (e.g. `0 0 37 38`) signals a cropped or rotated export — an upright icon is almost always square.
- **Transform / coords:** scan for `transform="rotate(...)"`, a sheared `matrix(...)`, or path coordinates tracing a tilted shape; the source glyph may be upright while the file is angled.
- **Mirror:** check for an unintended flip (negative scale).
- **Color & shape:** confirm color, stroke-vs-fill, outline-vs-solid, and silhouette match the source, not just the subject.

If the file differs on any of these it is the wrong asset — request the correct SVG (asset workflow) instead of wiring the lookalike.

**Installing a provided/generated asset (collision check before you write):** resolve the target filename, then `rg` the basename and its generated accessor across code and resource folders. Branch: **identical** — open both files and compare shape, orientation, color, and `viewBox`; if they match, keep the existing asset and write nothing (a no-op, not a re-import). **Local-only collision** — only the screen under work references the name → overwrite after explicit user confirmation. **Shared collision** — any other screen, theme, or resource references it (e.g. a medical-cross icon shared by a dashboard and a tools list) → do not overwrite; route global-overwrite-and-accept vs install-under-a-new-agreed-name to the decision gate, and agree the new name with the user instead of inventing one. A name match is never a content match — the existing file may be a rotated/tilted variant.

In KMP/Compose Multiplatform, shared drawables live in `commonMain/composeResources/drawable` and are referenced through the generated `Res.drawable.*` accessor, not `R.drawable`. `rg` both the file basename and its generated accessor identifier across all source sets and resource XML — the generated accessor hides call sites from a filename-only search.

## 7. System chrome vs app chrome & safe area

Split three layers before analyzing layout; do not stop after discarding the OS layer:
- **OS chrome — discard:** status bar, notch / dynamic island, home indicator, system nav bar, keyboard. Never reproduce the clock / battery as app UI. Map its space to safe-area insets, not fixed offsets.
- **App chrome — inventory:** the app's own top bar / nav bar / toolbar and every action it holds (back, info, overflow, search, avatar, close), plus FABs and bottom-bar items. This is app content; list each as a component, not decoration.
- **Container treatment per icon (chrome and body):** record the container, not just the glyph, for *every* icon in the frame — bare icon vs icon-in-tile (circle / pill / rounded square), fill + opacity, shape, border, size, elevation. This is not a chrome-only check: a colored tile sits behind an inline glyph in a text line (a direction arrow in a date row), behind an icon inside a card, row, chip, or list item, exactly as behind a toolbar action — scan body icons with the same eye. Defaulting any small glyph, inline or chrome, to a borderless icon silently deletes the tile.

## 7.5 Sibling consistency across same-class containers

When the screen shows more than one of a container class (cards, rows, list items, tiles), read their chrome as ONE spec, not per instance — derive the canonical background, border, elevation, radius, and content typography from the established instances and hold every other instance, including any you will add, to it. Two cards on one screen with different fills, borders, or elevations is almost always a defect to reconcile, not two intended styles; flag a deliberate differentiation at the decision gate, else match the siblings.

## 8. What a static image cannot tell you (feed the decision gate)

A single frame hides most of the screen's behavior. For each item, either infer it from project patterns or raise it at the decision gate:
- **Interaction states:** pressed / hover / focus / disabled / selected / error. A multi-frame set often supplies these directly: two otherwise-identical frames differing only in a trailing control, status line, or copy are one screen in two states, and the differing affordance *names* the state. States a frame actually shows are **observed truth** — render and match each against its own frame; states no frame shows stay inferred. Never split state variants into separate screens, nor collapse them and silently drop a state.
- **Off-screen content:** scroll position, what sits above / below the fold, sticky vs scrolling regions, carousels (peeking edges). A card flush to the screen edge or peeking past the page gutter is ambiguous — a **full-bleed scroller that owns its own start/end inset** (running past the page padding) vs a card simply meeting the content edge — and one frame cannot decide which. Record each scrolling region's gutter model (page-padded vs full-bleed-with-own-contentPadding); a full-bleed scroller breaks the page's lateral-padding rhythm, so resolve the ambiguity with a restate-and-ASCII-sketch confirmation before coding, not a guess.
- **Motion:** transitions, animations, gesture affordances.
- **Copy reality:** real content vs placeholder / lorem; localized strings.
- **Truncation / occlusion — run the cut-source protocol.** Text cut at the frame edge, content behind a sheet/modal/keyboard, or a region cropped away.
  1. Tag every element fully-visible, partial, or hidden.
  2. Transcribe verbatim only fully-visible copy, and measure only the on-frame fragment of a partial element (its leading inset, icon, first label). Never extrapolate a partial element's full width, height, item count, or hidden copy from the visible slice — a half-row is not a measurement of a whole row.
  3. Diagnose the cut before reacting: a **capture artifact** (the full element exists off-frame — request an un-cropped/scrollable export) versus an **intentional peek** signalling scroll (the cut *is* the spec — reproduce the partial reveal, do not pad it into a full item).
  4. Route every partial or hidden element to the decision gate flagged provisional: request the rest of the frame, ship explicitly-flagged provisional content the user confirms, or omit it this pass — never invent hidden copy or structure and present it as observed.
- **Data variability & width-constrained overflow:** long names, large numbers, empty / loading / error states — and, for text inside a fixed-width or space-shared container (carousel card, fixed tile, a label sharing its row with a trailing control), the overflow policy the single sampled string hides. The frame shows one length that happens to fit; decide single-line + ellipsis, a stated max-line cap, or intentional wrap, and verify with a deliberately long value. Width-constrained text with no `maxLines` + overflow set is the default failure — an address wrapping to a second line inside a fixed card is a defect, not the layout.
- **Wide / desktop / web affordances (desktop & web targets):** hover, focus-visible, and cursor affordances; scrollbar policy (overlay vs layout-affecting); window-resize behavior between the shown width and the target's real min/max. A single-width frame decides none of these — route them to the gate for desktop/web targets.
- **Variants:** light / dark theme, RTL, dynamic type / font scaling.

## 9. Confidence calibration

Tag each analyzed area:
- **High** — exact from SVG source, or a large unambiguous raster region matched to a token.
- **Medium** — estimated raster value snapped to a plausible token; role clear, exact value not.
- **Low** — gradients / shadows / translucency, small text, outlined fonts, anything occluded or off-screen.

Low-confidence items that affect fidelity, reuse, accessibility, or assets must reach the decision gate.

## 10. Feed the Agent Difficulty Report

After analysis and project scan, translate uncertainty into implementation risk. Do not leave it as internal reasoning.

Route these failures explicitly:
- **Source extraction risk:** raster scale unknown, small text unreadable, outlined SVG text, blended opacity, compressed shadows, partial screenshots.
- **Reconstruction risk:** visual effect requires a custom drawable, gradient, mask, clipping, or shadow that the project does not already model.
- **Asset risk:** logo, icon, photo, illustration, font, or copy is missing, approximate, brand-sensitive, or legally unsafe to recreate — or an existing project icon matched by name may be the wrong variant (rotated, mirrored, recolored, outdated), or a provided/generated asset's filename collides with an in-use project asset. Route a visual diff of the opened asset vs the source to verification focus, and route any name collision to the decision gate (overwrite globally vs install under a new name).
- **System-fit risk:** source values do not map cleanly to project tokens, reusable components, navigation, localization, accessibility, or platform conventions.
- **Behavior risk:** a static frame hides interaction states, scroll behavior, keyboard/sheet states, animation, loading/empty/error states, or data extremes. When the task says connect/open/trigger X from Y, whether each entry point already dispatches a shared event or needs its own is unknown until traced — route it to the project scan's wiring slot first and escalate to the gate only if the trigger surface (shared vs per-entry) is genuinely ambiguous.
- **Verification risk:** the project lacks a reliable render/capture path, the target device/theme is unknown, or comparison cannot match the source frame.

For every high-severity or low-confidence item, choose one destination:
- **Decision gate** when the user must provide, choose, or explicitly accept something.
- **Implementation brief** when the agent can mitigate it with project primitives and a clear constraint.
- **Verification focus** when the risk can only be proven or disproven after rendering.
