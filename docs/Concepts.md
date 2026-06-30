# Concepts

The mental model the skill operates with.

## Three sources of truth

- **The visual source** is the source of truth for *intent* — what the screen should look like and communicate.
- **The existing project** is the source of truth for *implementation language* — the tokens, components, and conventions the result must be written in.
- **The user** is the source of truth for *missing assets and ambiguous decisions* — anything the source and project cannot jointly settle.

Most mistakes come from confusing these: inventing an asset (the user's call), hardcoding a literal (the project's call), or "fixing" the design (the source's call).

## Source kinds

The kind of source decides the extraction method:

- **Named-token spec** (Figma styles/variables, an inspect/redline export, a values table) — the highest-priority source. Map token → token; do not re-derive a value the spec already names.
- **Vector (SVG)** — parse exact values: colors, gradients, geometry, `viewBox`, effects. Do not eyeball it.
- **Raster (PNG/JPG/screenshot)** — estimate perceptually, every value carrying a declared confidence.
- **Mixed** — vector chrome plus an embedded raster asset.

## Tokens over pixels

A stated token gives size, weight, **and** line-height exactly. A pixel measurement does not — and is actively misleading for type, because character advance width is font-specific (a real 16sp run can measure like 14sp). So: ask for or look up the token first; measure only what no token names, and tag those values low-confidence.

## Design-system grounding

The output must be written in the project's vocabulary: its tokens, its components, its scaffolds. Raw literals, one-off colors, and rebuilt-from-scratch components are defects even when they render correctly. Reuse is searched **across every component kind** — sheets, scaffolds, rows, list items, cards — not just tokens and buttons.

## The risk ledger

Uncertainty is not hidden in the agent's head; it is surfaced as an **Agent Difficulty Report** — a ledger of what is hard, what could go wrong, who must resolve it, and where it is routed (decision gate, brief, or verification focus). "I can approximate this" is treated as a risk, not a resolution.

## Two gates

- **The decision gate** runs once, before implementation. It stops for things only the user can settle: missing assets, brand choices, copy, new shared components, asset-name collisions, behavior-changing shared edits, ambiguous interpretations. Mismatches the *source already decides* are fix-list items, not gate questions.
- **The verification gate** runs at the end (and as a baseline at the start for existing screens). It is an **element × property delta table**: render your build, capture it at the source's dimensions and theme, and score every property of every element against the token-mapped source value. A passing compile is not verification.

## Additive vs behavioral shared edits

When one screen needs something from a shared component:

- an **additive** change — a *trailing* optional parameter or slot whose default reproduces today's output exactly — is allowed (verify callers compile *and* one untouched caller renders unchanged);
- a **behavior-changing** change — a changed default, token, radius, or a newly-required parameter — is gated: build a screen-local variant and widen the shared symbol only with the user's approval.

The test is the **rendered output of existing callers**, not the shape of the diff.
