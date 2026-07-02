---
name: visual-implementation
description: Use when implementing or reviewing a mobile UI from an external visual source such as a PNG, SVG, Figma export, screenshot, mockup, or design reference, especially for Flutter, Android Kotlin/Jetpack Compose, iOS SwiftUI/UIKit, or Kotlin Multiplatform/Compose Multiplatform projects; also use when visual fidelity depends on missing assets, unknown fonts, ambiguous scale, design-system mapping, or screenshot verification.
---

# Visual Implementation

Use this skill to turn a visual source into design-system-grounded mobile UI work. Treat the visual source as the source of truth for intent, the existing project as the source of truth for implementation language, and the user as the source of truth for missing assets and ambiguous decisions.

## Non-Negotiables

Hard rules, numbered for citation (NN-x) in the Agent Difficulty Report, decision gate, and verification report. Each rule states the constraint; the linked reference carries the procedure — read it before acting on the rule.

### Sources of truth

- **NN-1 — The user's language leads.** Conduct the entire interaction — clarifying questions, Agent Difficulty Report, decision gate, verification report, final summary — in the language of the user's request, locked from their first message; never default to English. Exempt only project-owned text: code identifiers, token names, file paths, commands, and in-product string *values*, which follow the project's own localization (Italian copy lands in `values-it`, not in your reply). If the request and the in-product copy differ in language, follow the user.
- **NN-2 — Frames lead; code is an unverified draft.** Never implement from memory or read design intent off the implementation. When frames are provided the order is fixed: analyze every frame exhaustively, then find the screens already rendering this flow, then diff, reconcile, and only then build. Opening the code first makes you narrate what it does and call that the design.
- **NN-3 — Never trust a prior fidelity claim** — commit message, PR title, code comment, or a "1:1 / matches the design" note. Re-derive every visible property from the source; the rendered comparison is the only evidence.
- **NN-4 — Named design tokens outrank pixels and sampled hues.** When the source carries token names (Figma styles/variables, an inspect/redline export), ask for them or look them up, and map each to the project token scale; pixel/hue estimation is the declared-uncertainty fallback for values no token names. A token-mapped value is corrected only by a different stated token — never by a ruler, never by an eyeballed colour. (`references/visual-analysis.md` §0, §5)

### Extraction

- **NN-5 — Parse an SVG, never eyeball it** — exact colors, gradients, typography, geometry, `viewBox`. Estimate perceptually only for raster sources, and declare the uncertainty. (`references/visual-analysis.md` §1–2)
- **NN-6 — Calibrate scale and density before deriving any spacing, size, or radius.** Cluster observed values and snap them to the project scale instead of inventing literals. (`references/visual-analysis.md` §3)
- **NN-7 — Tokens over pixel-perfect literals.** Prefer tokens, theme values, existing spacing scales, typography roles, constraints, safe-area behavior, adaptive layout, and proportional relationships to fixed measurements.
- **NN-8 — Never default prominent text to Bold.** Medium 500 read as Bold 700 is the recurring raster miss; read the exact weight token, and when the source leaves it ambiguous, ask or flag — never assume Bold. (`references/failure-cases.md` #1)
- **NN-9 — The exact token, never a plausible neighbour.** An exact stated value maps to the exact project token that carries it; a near-token is a defect, and later user-fed specs override your earlier approximations. (`references/failure-cases.md` #2)

### Don't invent

- **NN-10 — No invented assets, logos, icons, fonts, or unreadable copy.** Ask the user to decide or provide them.
- **NN-11 — A dense illustration, map, or textured background is an exported asset.** Do not redraw it as a vector drawable or rasterize it with a thumbnail tool: ask the user for the PNG (1x/2x/3x) and compose only the overlay effects (e.g. a fade brush) in code. (`references/visual-analysis.md` §6)
- **NN-12 — A filename match is a candidate, not a confirmation.** Open the matched drawable and compare orientation, rotation, mirror, color, fill style, and `viewBox` against the source glyph before reuse; run the collision check before writing any provided or generated asset. (`references/visual-analysis.md` §6)
- **NN-13 — Content hidden by a crop, sheet, modal, keyboard, or overlay is unobserved, not inferable.** Transcribe only what is fully visible; flag every partial or hidden element to the gate. Unreadable means ask for a clearer source; cut-off means ask for the rest of the frame. (`references/visual-analysis.md` §8)

### Reuse & scope

- **NN-14 — Search before building.** No new UI primitive before searching for reusable or approximately reusable project components — structural containers (sheets, scaffolds, rows, list items, cards) with the same weight as tokens and buttons. (workflow step 3)
- **NN-15 — Siblings share one chrome.** A new element of an already-present visual class inherits its same-class siblings' exact background, border, elevation, radius, and content typography, lifted into one shared style so neither drifts; a deliberate difference is flagged at the gate. (`references/visual-analysis.md` §7.5)
- **NN-16 — A justified new component is born where it belongs.** Repeatable structure or design-system-grade values make it a design-system member: route it through the gate, then build it centralized under an agreed name — never as a screen-private helper. (workflow step 5)
- **NN-17 — Narrowest scope owns the fix; classify every shared-symbol edit.** `rg` the other call sites first. Behavior-changing (any existing caller's rendered output moves) = full stop: screen-local variant unless the user approves the blast radius. Additive (trailing optional default-no-op) = allowed when genuinely needed: announced at the gate, then proven by compiling every caller AND rendering one untouched caller unchanged. (`references/platform-notes.md`, "Extending a shared component additively")
- **NN-18 — Trace existing wiring before adding plumbing.** When the task connects, opens, or triggers a component, the events, handlers, navigation, and state are often already there; a redundant event paralleling existing wiring is the behavioral twin of a duplicated component.

### Behavior & states

- **NN-19 — Placement is measured, never defaulted.** Vertical position and anchoring are read from the frame, and defined per *container state* for content in a draggable or expandable host — an auto-centred empty state and a below-the-fold sheet message are both defects. (`references/failure-cases.md` #4)
- **NN-20 — Every layout mode renders every data state.** Two presentations of the same data (map/list, expanded/collapsed) each need loading, empty, no-results, and error: enumerate state × mode as a grid, not a list. (`references/failure-cases.md` #3)
- **NN-21 — Reason through every branch a flow implies, autonomously** — a happy-path-only flow is a defect. A permission result is a tri-state (granted / denied / permanently-denied → open-app-settings recovery); back-navigation, cancel, offline, and empty/error are implied even when no frame draws them. Surface the branches you cannot resolve at the gate. (`references/failure-cases.md` #5)

### Serve the user, not the container

- **NN-22 — Never resolve text overflow by truncating the content.** Ask what the label must convey, then reflow so the full string stays readable; truncation is a last resort named at the gate, never the default, never applied to the one datum the screen exists to show. (`references/failure-cases.md` #6)
- **NN-23 — Question redundant chrome instead of fighting it.** An element restating what the same screen already shows may be dropped — but only after confirming the duplication in code and gating the removal; never infer redundancy from the visual alone. (`references/failure-cases.md` #7)

### Gates & honesty

- **NN-24 — Do not hide uncertainty.** Surface your own implementation difficulties as a user-facing risk ledger (the Agent Difficulty Report) before asking decisions or writing code; "I can approximate this" is a risk, not a resolution.
- **NN-25 — Never bypass the decision gate** when a missing or ambiguous item could materially change fidelity, reuse, accessibility, or maintainability.
- **NN-26 — Never continue past a material risk by silently choosing** a placeholder, nearest asset, lookalike font, raw value, or unverified behavior.
- **NN-27 — Produce a screen-specific implementation brief** that another agent could execute, not a generic plan.

### Completion

- **NN-28 — A build success is not visual completion** — and neither is rendering the source export. Completion requires rendering YOUR built screen, capturing it, and comparing it to the source property by property, or explicitly telling the user rendering was impossible. (`references/verification.md`)
- **NN-29 — An element is correct only after EVERY property is compared** to the token-mapped source value; the element × property delta table gates the "match" claim, and fixing only the deltas you happened to notice is not an audit. (`references/verification.md`)
- **NN-30 — Never operate the user's device or emulator without explicit permission.** Read-only screenshots are fine; tapping, typing, swiping, or navigating hijacks a session that is often shared and mid-review — use your own render harness or wait for a go-ahead. Confirm the build actually succeeded (grep the real output) *before* committing, not after. (`references/verification.md`, "Rendering etiquette & build truth")

## Required Workflow

1. **Intake the visual source**
   - Identify file type, dimensions, apparent platform, density, orientation, theme mode, system UI visibility, and screen state.
   - Classify the source kind — named-token spec / vector / raster / mixed — and calibrate scale before measuring anything; unknown density or scale goes to the decision gate. (`references/visual-analysis.md` §0–3)
   - Ask whether a named-token spec exists (Figma styles/variables, an inspect/redline export, a values table) and request token names rather than measuring them (NN-4) — fetching them yourself first when the session has a Figma MCP/API connection (`references/visual-analysis.md` §0). Record the spec's absence as a verification risk for the Agent Difficulty Report.
   - If the source is missing or unreadable, request a usable PNG/SVG/screenshot before proceeding.
   - Set your response language to the user's request language now (NN-1), before emitting any analysis.

2. **Analyze the complete screen**
   - Describe layout regions, hierarchy, navigation structure, content groups, component candidates, typography roles, color roles, interaction states, imagery, iconography, and visible copy — as relationships and rhythm (emphasis, density, grouping, alignment), not hardcoded sizes.
   - Apply the extraction protocols in `references/visual-analysis.md` (color, typography, asset-vs-drawable, system chrome) and record what a static image cannot show: states, off-screen content, motion, real vs placeholder copy, occlusion, data/theme variants (§8).
   - Emit the screen analysis schema from `references/output-schemas.md`.
   - **Existing-screen / redesign / "make it 1:1" branch:** the baseline is a *pixel capture* of the current build — rendered by you or supplied by the user — never a reading of the code. Run the delta table against the source, diffing in both directions; the mismatches are your task list. If you can neither render nor obtain screenshots, you can neither baseline nor verify — raise it at the gate now, not after implementing. (`references/verification.md`, "Baseline first")

3. **Scan the project before designing anything**
   - Detect stack and UI layer: Flutter, Android Compose, SwiftUI/UIKit, KMP/Compose Multiplatform, or mixed.
   - Search design tokens, themes, typography, color roles, and spacing scales — and, with equal weight, structural components (sheets, dialogs, scaffolds, list items, rows, cards, accordions, chips), plus screen examples, asset catalogs, icon sets, localization, and navigation patterns. Grep by structure, not only by name (e.g. `rg -l 'BottomSheet|Sheet|Scaffold|ListItem|Row|SectionCard|Accordion|Dialog'`), and read the hits; a create-new decision is valid only after reuse is ruled out across every component kind (NN-14).
   - Prefer `rg`/fast project search. Cite concrete files and symbols in the implementation brief.
   - Regulated copy (legal, consent, medical) is searched before it is drafted — a validated multi-locale translation almost always already exists in a mirror or sibling flow. (`references/failure-cases.md` #8)
   - Locate the **render / capture path** now — preview, simulator/emulator, screenshot/golden test, or debug build. If none exists, raise it as a verification risk at intake instead of discovering it after implementing.

4. **Surface the agent difficulty report**
   - Produce the Agent Difficulty Report schema from `references/output-schemas.md` after analysis and scan, before the decision gate and before implementation.
   - List where you are likely to struggle, not only where the user must act: source uncertainty, project mismatch, missing assets, unknown behavior, token gaps, accessibility/data variability, verification risk.
   - Per difficulty: likely failure mode if unchecked, confidence, severity, owner (`agent`/`user`/`project`), mitigation, destination (decision gate / implementation brief / verification focus), and the NN-x at stake where one applies.
   - "I can approximate this" is a risk, not a resolution, when it affects fidelity, reuse, accessibility, localization, brand correctness, or maintainability (NN-24).
   - Two risks are routinely under-reported — include them as ledger items whenever applicable, with owner and destination: a font family the source names but the project may not bundle (verify, never assume), and the data states of the screen's key value that a static frame hides (loading, empty, masked/privacy). A mention under "invisible aspects" in the analysis does not count as routing them.

5. **Map visual elements to project primitives**
   - Per region or component: reuse an existing component, adapt a near match, compose from existing primitives, create a new component, or ask for an asset/decision. Collapse repeated visual structures into a single component candidate — repetition is itself the signal it should be one reusable component, not N ad-hoc elements.
   - Decide a new component's home before its code (NN-16): repeatable structure or a design-system-grade value (e.g. a measurement on the project grid) → gate it, then centralize under an agreed name; screen-local only for a genuinely single-use, non-tokenized shape that will never repeat.
   - Justify every new component, record confidence per area (high/medium/low), and connect each low-confidence or high-impact choice to the Agent Difficulty Report.

6. **Run the decision gate**
   - Stop before implementation when assets, fonts, copy, component choices, token additions, a new shared/design-system component, an asset-name collision referenced beyond this screen, a behavior-changing shared edit, or visual interpretations require user judgment (NN-25).
   - Mismatches the source already decides — wrong copy, color, size, radius, weight, a missing element (add it), a leftover element (remove it) — are fix-list items, not gate questions: just fix them. Run the gate once, before implementation, never mid-pass; a late "should I fix the rest?" means you parked mismatches you should have audited up front.
   - Group related questions; each carries the affected screen area, recommended option, alternatives, and impact — including the unresolved invisible aspects from the analysis (interaction states, off-screen behavior, motion, copy reality, asset-vs-drawable calls, unknown fonts, unknown scale/density).
   - Route every user-owned or high-severity risk from the Agent Difficulty Report into this gate. Nothing material may remain hidden in the brief.
   - Handle shared-symbol edits by class (NN-17): a behavior-changing edit is a full stop — present its blast radius, proceed only on explicit approval; an additive edit is lighter but never silent — announce the param/slot and the callers you will re-verify. An unannounced additive edit is treated as behavioral.
   - Continue only after the user decides, unless the user explicitly allows placeholders.

7. **Run the implementation readiness check**
   - Classify the work before writing the brief: `Ready` — no material risk requires user input and every agent-owned risk has a mitigation and verification check; `Ready with accepted assumptions` — the user explicitly delegated or accepted placeholders/approximations, listed in the brief and final report; `Blocked` — implementation would require inventing assets, brand choices, copy, behavior, or token changes without permission: stop and ask.

8. **Produce the implementation brief**
   - Use `references/output-schemas.md`: files likely to change, components/tokens to reuse, justified new components, asset requirements, adaptive behavior, accessibility requirements, and visual verification criteria — plus the resolved Agent Difficulty Report (decisions, accepted assumptions, remaining verification focus).
   - Include platform-specific notes from `references/platform-notes.md` for the detected stack.
   - When a region's padding or overflow model is subtle — full-bleed scroller vs page-padded row, a scroll *peek* vs a *padding clip*, overlapping or peeking layers — restate the spatial model in plain words plus a one-line ASCII sketch of the edges, page gutters, and what crosses them, and confirm it before writing code. A targeted check for spatial ambiguity, not ceremony for every screen; skip it where the frame is unambiguous. (`references/visual-analysis.md` §8; the deterministic fix: `references/platform-notes.md`, "Full-bleed scroller within a padded screen")

9. **Implement only from the brief**
   - Edit the smallest relevant files.
   - Follow local patterns and code style.
   - Use project tokens and components even when the visual source contains raw values.
   - Keep temporary approximations visibly marked in the final report when the user allowed them.

10. **Verify against the source (gate)**
   - Follow `references/verification.md`: render YOUR built screen (not the source export), capture at the same logical dimensions and theme, and complete the element × property delta table for every element from the screen analysis — including regions you did not edit this pass. The table gates the "match" claim (NN-28, NN-29).
   - Re-read your captured screenshot as an image; never infer fidelity from the code alone.
   - Reconcile every Agent Difficulty Report risk: mitigated, accepted by the user, or reported as a remaining gap. Fix major mismatches and re-compare; if rendering is impossible, surface it to the user as an explicit decision instead of silently claiming a match.
   - Run the relevant formatter, analyzer, tests, and build when available. Report unresolved gaps honestly.

## Reference Loading

- Read `references/visual-analysis.md` during intake and analysis, to apply the source-type branch, scale calibration, and extraction protocols.
- Read `references/failure-cases.md` when a non-negotiable cites it and its trigger appears in the task — assigning a weight token (NN-8), near-matching a stated value (NN-9), multi-mode or stateful-container layouts (NN-19, NN-20), permission or branch-heavy flows (NN-21), overflowing or duplicated content (NN-22, NN-23).
- Read `references/output-schemas.md` whenever producing the screen analysis, Agent Difficulty Report, decision gate, implementation brief, or verification report.
- Read `references/platform-notes.md` after detecting the target stack or when the user names Flutter, Android Compose, SwiftUI/UIKit, or KMP/Compose Multiplatform — and always before editing a shared component (NN-17, "Extending a shared component additively").
- Read `references/verification.md` before claiming visual completion.
- Read `references/worked-example.md` for an end-to-end pass (SVG → analysis → Agent Difficulty Report → decision gate → brief → verification) when you want a concrete model to follow.

## Completion Criteria

The task is not complete until the agent has either:

- produced the screen analysis, project scan, Agent Difficulty Report, and decision gate, then is waiting for user choices, or
- produced an Agent Difficulty Report and determined the work is blocked before implementation, or
- implemented from an approved brief and completed the verification gate in `references/verification.md` — either a render-and-compare result or an explicit, user-acknowledged limitation — reporting any remaining visual, risk, or asset gaps.
