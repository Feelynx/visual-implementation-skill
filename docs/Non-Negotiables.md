# Non-Negotiables

The hard rules, grouped by the failure each one prevents. The authoritative, numbered list (NN-1 … NN-32) lives in [`SKILL.md`](../visual-implementation/SKILL.md); this page explains the *why*. The recurring failures behind NN-8, NN-9 and NN-19 … NN-23 are kept, with their full reasoning, in [`references/failure-cases.md`](../visual-implementation/references/failure-cases.md).

## Sources of truth (NN-1 … NN-4)

- **The user's language leads.** The whole interaction happens in the language of the user's request; only project-owned text (identifiers, tokens, paths, in-product string values) follows the project.
- **Frames lead; code is an unverified draft.** Reading design intent off the implementation makes you narrate what the code does and call that the design. Analyze the frames first, then diff the code against them.
- **No prior fidelity claim is evidence.** A commit message or a "1:1" note proves nothing; the rendered comparison does.
- **Tokens outrank pixels.** When the source names a type/spacing/radius/colour token, map it to the project scale. Pixel estimation is a declared-uncertainty fallback — and it is biased *low* for type, because font advance width is narrower than generic estimates assume. A token-mapped value is corrected only by a different stated token, never by a ruler or a sampled hue.

## Extraction fidelity (NN-5 … NN-9, NN-31)

- **Don't eyeball a vector or an instrumentable raster.** Parse the SVG for exact colors, gradients, typography, geometry, and `viewBox`; instrument a raster when tooling allows with `scripts/measure.sh` and tag every value as measured or estimated.
- **Calibrate scale before measuring.** Without a reference frame, image pixels cannot become real `dp`/`pt`; cluster observed values and snap them to the project scale.
- **Rhythm-correct beats pixel-perfect.** Tokens, roles, constraints, and proportional relationships — not fixed literals.
- **Never default prominent text to Bold.** Medium 500 and Bold 700 read almost identically in a raster; the exact weight token decides, and genuine ambiguity is asked, not assumed.
- **The exact token, never a plausible neighbour.** A near-token is a defect; grep the theme for the exact value and use the token that carries it.
- **No property verdict from a whole-frame read alone.** A raster is read region by region at native resolution (tiles / crops); a conclusion formed only at whole-frame scale is provisional until confirmed at native resolution. This prevents tiny hue, spacing, icon, and contrast errors from hiding in a scaled-down overview.

## Don't invent (NN-10 … NN-13)

- **No invented assets, logos, icons, fonts, or unreadable copy** — ask the user.
- **A dense illustration or map is an exported asset.** Redrawing it as a vector drawable balloons to megabytes; rasterizing it yourself distorts it. Ask for the PNG and compose only the overlay effects in code.
- **Don't trust an asset by filename.** A name match is a candidate, not a confirmation: open it and compare orientation, rotation, mirror, color, fill style, and `viewBox`.
- **Don't reconstruct content hidden by a crop, sheet, modal, or keyboard.** Transcribe only what is fully visible; flag the rest to the gate. Unreadable means "ask for a clearer source"; cut-off means "ask for the rest of the frame".

## Reuse and scope (NN-14 … NN-18)

- **Search before building** — across every component kind, including sheets and scaffolds.
- **Siblings share one chrome.** A card among cards inherits the established background, border, elevation, radius, and typography — a differing instance is a consistency break to reconcile, not a styling choice.
- **A reusable component is centralized** in the design system under an agreed name, never shipped as a screen-private helper. A repeatable structure or a design-system-grade value is the signal.
- **Fix a screen at the narrowest scope that owns it.** Classify every edit to a shared symbol: a **behavior-changing** edit is gated and confirmed; an **additive** trailing-optional default-no-op extension is allowed once you prove the default leaves existing callers unchanged (compile *and* render one untouched caller).
- **Trace existing wiring before adding plumbing.** Several triggers may already dispatch one shared event; a redundant event is the twin of a duplicated component.

## Behavior & states (NN-19 … NN-21)

- **Placement is measured, never defaulted.** An empty state goes where the frame puts it, not auto-centred — and content inside a draggable sheet or expandable panel must be placed and sized for *each* container state, or it disappears at the collapsed peek.
- **Every layout mode renders every data state.** A map view and a list view over the same data each need loading, empty, no-results, and error: enumerate state × mode as a grid.
- **Every implied branch is reasoned through.** A permission result is a tri-state — granted, denied, permanently-denied — and permanently-denied needs an open-app-settings recovery, not a silent "proceed without". Back, cancel, offline, and error are implied even when no frame draws them.

## Serve the user, not the container (NN-22 … NN-23)

- **Overflow is a communication problem, not a layout one.** Don't resolve it by truncating — reflow (stack, wrap, own line) so the full string stays readable; truncation is a gated last resort, never applied to the one datum the screen exists to show.
- **Question redundant chrome.** An element restating what the same screen already shows may be dropped — but only after confirming the duplication in code and routing the removal through the gate.

## Gates and honesty (NN-24 … NN-27)

- **Surface difficulties as a user-facing risk ledger** before asking decisions or writing code; "I can approximate this" is a risk, not a resolution.
- **Never bypass the decision gate** on anything that could materially change fidelity, reuse, accessibility, or maintainability — and never continue past a material risk with a silent placeholder, nearest asset, or lookalike font.
- **The brief is screen-specific**, executable by another agent — not a generic plan.

## Completion (NN-28 … NN-30, NN-32)

- **A compile or build success is not visual completion**, and neither is rendering the *source* export. Completion requires rendering **your built screen** and comparing it to the source property by property — or telling the user rendering was impossible.
- **An element is correct only after every property is checked** against the token-mapped source value; fixing only the deltas you happened to notice is not an audit.
- **Never drive the user's device or emulator without permission** — it is often shared and mid-review. Read-only screenshots are fine; and confirm the build actually succeeded *before* committing.
- **One frame is one width.** For desktop/web targets, hover/cursor/focus affordances, scrollbar policy, and resize/breakpoint behavior are gate items a static frame cannot decide, and verification captures more than one window width; a single-width match claim is not completion for a resizable target. This prevents a correct-looking 1440px frame from becoming a broken narrow or wide app.
