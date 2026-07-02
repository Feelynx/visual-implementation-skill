# Verification

Structured visual verification closes the loop between the brief and the rendered result. **Do not claim the implementation matches the source by reading the code.** Render it, capture it, compare it property by property.

## The gate

Visual work is not complete until one of these is true:
- the rendered screen has been captured and compared against the source (below), **or**
- rendering is not possible in this project and that limitation has been surfaced to the user as an explicit decision (see "When you cannot render").

## Procedure

**Baseline first (existing screens).** Before editing, capture the current screen as *pixels* — render it yourself, or ask the user for current app screenshots — and run the delta table below against the source, treating the current build as a second, untrusted input. Never reconstruct the current state from code: an extra control or a leftover gap renders but does not announce itself in source. Diff in **both directions**: add what the frame shows and the build lacks, AND remove what the build still shows but the frame dropped (a stale status chip, a leftover segmented toggle, a top-padding refuso) — a removal is a delta. The mismatches are the work — all of them, not the two or three you noticed first; the post-change capture must clear every one. The same table runs at both ends — render only at the end and the user finds the defects instead of you.

1. **Render YOUR built screen** (not the source export) with whatever the project supports: Compose / SwiftUI preview, simulator / emulator, golden / screenshot test, or a debug build.
2. **Capture** a screenshot at the **same logical dimensions, device, and theme** as the source. Matching the frame is what makes the comparison valid.
3. **Compare** the capture against the source:
   - Side-by-side at equal size; overlay / diff if the tooling allows it.
   - Complete the element × property delta table below.
4. **Reconcile the Agent Difficulty Report.** For every risk carried into the brief, mark it mitigated, accepted as a limitation, or still open with evidence.
5. **Self-review multimodally.** Actually re-read your captured screenshot as an image and compare it to the source image — do not infer fidelity from the code diff.
6. **Iterate.** Fix every *major* mismatch and every unmitigated high-severity risk, re-render, re-compare. Repeat until converged or genuinely blocked.
7. **Wiring check (only when this task connected a component to one or more triggers).** Exercise every entry point and confirm each reaches the component — the sheet opens, the route navigates, the state flips. A shared event means all entry points must fan into it, so one verified trigger does not prove the rest: test the ones you did not touch, including pre-existing paths you added no wiring to because it already existed.

## Rendering etiquette & build truth

- **The user's device/emulator is often shared and mid-review.** Read-only screenshots are fine, but do not *drive* it — tapping, typing, swiping, or navigating disrupts their session and can lose their place. Ask before driving it, or wait for an explicit "it's free." When you must reach a state, prefer your own render harness (Compose/SwiftUI preview, an isolated-component capture) over hijacking their live session.
- **Confirm the build actually succeeded before committing or claiming done.** A background job's exit code or a truncated log is not proof: grep the real output for `BUILD SUCCESSFUL` and zero `e:` / `error:` lines. Committing on an assumed-green build ships a broken commit you then amend — the compile is part of verification, run it *before* the commit, not after.

## Element × property delta table (gate before any "match")

Build one table per screen. Every element from the screen analysis is a row group; every property below is a row scored **source value | implemented value | verdict (match / minor / major) | confidence**. An element is **not** "match" until every property row is filled against the token-mapped source value — not a re-invented literal, not the existing code. Fixing only the deltas you happened to notice is not an audit. The table covers every element from the analysis, including regions you did not edit this pass.

Per element, compare:
- **Copy** — every visible string transcribed verbatim from the reference, in every locale the design renders; confirm the correction reached every locale folder, not just the one you read.
- **Type role & emphasis** — score size / weight class / line-height / per-line-or-span color / fill type for *every* text run against its stated token, not just the run you remeasured. Where a token names the value, the source column IS the token's value, and a pixel re-measurement is not admissible evidence to downsize a token-mapped run. Record size provenance (`stated token` vs `pixel estimate`); if you reduced an element's size relative to the existing code, prove the source renders the smaller size — a lower char-width measurement is a font-metric artifact, not evidence, and down-sizing already-correct text is a **major** regression. Confirm fill type: solid token vs gradient/brush (direction, stops, terminal-stop opacity), brush spanning the whole run not tiled per glyph. Two-tone titles, bold labels, and gradient runs stay distinct; a gradient flattened to a solid or faded to the wrong end colour is a *major* mismatch. Re-check after any text-colour or theme change. Record colour provenance alongside size (`stated token` vs `eyeballed estimate`): recolouring a run that was already the correct token to an eyeballed hue (info-blue → teal/green) is a **major** regression, exactly like down-sizing already-correct text, and a sampled hue is not admissible evidence against a stated colour token.
- **Inter-element gaps** — each named gap from the spacing inventory scored individually (icon-row→title, title→body, card→card), not collapsed into one "rhythm" verdict.
- **Internal insets / padding** — padding inside tiles, cards, and buttons (glyph within its icon square, content within a card) matches the source inset, not just outer placement.
- **Radius / border / fill** — per container and inner tile; border width and exact color (often a stroked mask, not a `stroke=`).
- **Shadow / elevation** — offset, blur, color, and opacity (plus spread where the platform supports it) match the source spec, not "an element that casts a shadow." Re-check after any elevation, radius, or fill change.
- **Icon** — identity before size: the right glyph, upright and unmirrored (no unintended rotation, tilt, or flip), correct color and fill style, plus glyph size and inner padding. A correctly-sized icon that is the wrong variant or rotated is a *major* mismatch, not a minor one.
- **Container treatment (every icon)** — each icon matches its container, not just its glyph: bare icon vs icon-in-tile (circle / pill / square), fill, shape, border, elevation. Score chrome controls (top-bar / nav / FAB / bottom-bar) *and* every inline/body glyph inside a text line, row, card, chip, or list item (e.g. a direction arrow in a date line). A flat glyph where the source shows a filled tile — chrome or inline — is a *major* mismatch.
- **Sibling consistency** — a component sharing a visual class with others on the same screen (a card among cards, a row among rows) is scored against those siblings' chrome, not only against the source frame. A background, border, elevation, radius, or content typography that differs from the established same-class instances is a *major* finding even when the element looks plausible in isolation.
- **Overflow / truncation (width-constrained text)** — text in a fixed-width card, carousel item, or a row shared with a trailing control is single-line + ellipsis or capped at its stated max lines, not wrapping or clipping. Prove it with a string longer than the one the source sampled; the conveniently-short frame text hides the regression, so "matches the frame" is not a pass here.
- **Presence / position / state** — the element exists, placement is correct, nested sub-elements are present, and specified states are implemented; nothing extra remains, neither newly added nor carried over from the prior build — *a control the frame no longer shows or a leftover gap the redesign dropped*. A source-driven table emits no row for a build-only element, so for an existing-screen pass the row groups are the **union** of screen-analysis and current-build elements: add one row per current-build element with no source counterpart and score it **remove**. When the source supplied multiple frames as state variants of one screen, render and compare *each* state against its own frame — one state matching does not clear the others.
- **Shared-change blast radius** — if a shared symbol or an existing-name asset that other screens reference was changed instead of a screen-local variant, verify by class. *Behavioral:* confirm the change is exactly what the user approved and that another consumer now renders that approved behavior. *Additive (new trailing optional default-no-op param/slot):* a clean compile of all callers is necessary but **not** sufficient — render at least one untouched caller and confirm its appearance is unchanged. Compiles-clean is not renders-unchanged. A drawable swapped under every consumer's feet is a silent regression, not a local fix.
- **Component placement & reuse** — any genuinely reusable component you added lives in the design system under an agreed name, not as a screen-local private helper; an existing sheet/scaffold/list item/row was reused or additively extended, not rebuilt. A rebuilt sheet or a local copy of a should-be-shared component is a *major* finding even when it renders correctly.
- **Occluded / provisional elements** — an element whose source value was hidden (frame crop, sheet, modal, keyboard) has no observed source to compare against: score it **unverifiable (source occluded)**, never *match*, and carry it to remaining content/asset gaps as provisional awaiting user confirmation.

Anything still off after the table is a **major** mismatch: fix at the narrowest scope that owns this screen and re-compare.

## When you cannot render

If the project has no preview / simulator / screenshot path, do not silently downgrade to "looks right." Surface the decision to the user:
- **Option A** — set up a minimal render/preview harness rendering the smallest unit that proves the screen. A bottom sheet, modal, row, list item, or card can be previewed in isolation even when the full app cannot launch; reach for the isolated-component preview before concluding rendering is impossible — a one-component capture beats none.
- **Option B** — proceed with structural verification only (analyzer / format / tests + manual code-vs-brief review) and record the unverified visual fidelity as an explicit limitation.

## Output

Record results with the Verification Report schema in `references/output-schemas.md`: commands run, the render capture, the element × property delta table with verdicts, design-system compliance, risk-ledger reconciliation, remaining asset gaps, and a final status of Complete / Waiting on assets / Needs follow-up.
