# Non-Negotiables

The hard rules, grouped by the failure each one prevents. The authoritative list lives in [`SKILL.md`](../visual-implementation/SKILL.md); this page explains the *why*.

## Extraction fidelity

- **Don't eyeball a vector.** Parse the SVG for exact colors, gradients, geometry, and `viewBox`.
- **Tokens outrank pixels.** When the source names a type/spacing/radius token, map it to the project scale. Pixel estimation is a declared-uncertainty fallback — and it is biased *low* for type, because font advance width is narrower than generic estimates assume. A token-mapped value is corrected only by a different stated token, never by a ruler.

## Don't invent

- **No invented assets, logos, icons, fonts, or unreadable copy** — ask the user.
- **Don't trust an asset by filename.** A name match is a candidate, not a confirmation: open it and compare orientation, rotation, mirror, color, fill style, and `viewBox`.
- **Don't reconstruct content hidden by a crop, sheet, modal, or keyboard.** Transcribe only what is fully visible; flag the rest to the gate. Unreadable means "ask for a clearer source"; cut-off means "ask for the rest of the frame".

## Reuse and placement

- **Search before building** — across every component kind, including sheets and scaffolds.
- **A reusable component is centralized** in the design system under an agreed name, never shipped as a screen-private helper. A repeatable structure or a design-system-grade value is the signal.
- **Trace existing wiring before adding plumbing.** Several triggers may already dispatch one shared event; a redundant event is the twin of a duplicated component.

## Scope discipline

- **Fix a screen at the narrowest scope that owns it.** Classify every edit to a shared symbol: a **behavior-changing** edit is gated and confirmed; an **additive** trailing-optional default-no-op extension is allowed once you prove the default leaves existing callers unchanged (compile *and* render one untouched caller).
- **Asset-name collisions are gated.** If a provided asset's name already exists and other screens reference it, ask: overwrite globally or install under a new agreed name. If the existing file is identical, reuse it and write nothing.

## Completion

- **A compile or build success is not visual completion**, and neither is rendering the *source* export. Completion requires rendering **your built screen** and comparing it to the source property by property — or telling the user rendering was impossible.
- **Don't trust prior fidelity claims** — a commit message, a comment, or a "1:1" note. Re-derive every visible property from the source.
- **An element is correct only after every property is checked** against the token-mapped source value: copy (per locale), type size/weight/line-height and per-run color/fill, gaps and insets, radius, border, shadow, icon identity/orientation, container chrome, presence, and state.

## Communication

- **Conduct the interaction in the user's language**, and surface difficulties as a user-facing risk ledger before asking decisions or writing code.
