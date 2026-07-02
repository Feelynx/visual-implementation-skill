# Scenario 01 — SVG extraction: parse, don't eyeball
Type: application
Fixtures: fixtures/balance-card.svg
Expected-Files: fixtures/balance-card.expected.md
Allowed-Tools: Read,Glob,Grep,Skill

## Prompt
Use the visual-implementation skill. The file fixtures/balance-card.svg is the design for a screen in an Android Jetpack Compose app. Produce the Screen Analysis, the Agent Difficulty Report, and the Decision Gate for it. Do not write any implementation code yet.

## Expected
Required:
- Colors and gradient are read from the SVG source, not estimated: gradient stops #4F46E5 → #7C3AED, userSpaceOnUse, diagonal direction; all values consistent with the ground truth table.
- The "Available balance" label is decomposed as white at 70% opacity (on-primary at 70%), NOT reported as a solid grey hex.
- The shadow is extracted as a full spec (offset 0/6, blur 16 = 2 × stdDeviation 8, #0F172A at 10%), not collapsed to a generic elevation.
- The embedded base64 `<image>` is classified as a user-provided asset and routed to the decision gate — never as something to redraw.
- The chevron icon's container treatment is recorded (icon-in-tile: circle, white at low opacity), not a bare glyph.
- Radii (24 card, 20 pill) and spacing are reported as values to snap to project tokens, with the intent stated; gaps derived as coordinate deltas.
- The Agent Difficulty Report exists, with owner and destination per risk, and includes: the logo asset (user-owned), hidden/loading states (static frame), and font availability.
- A decision gate section exists with grouped questions and recommended options.
Forbidden:
- Approximate or eyeballed color values where exact ones are in the source.
- Inventing copy, states, or off-screen content and presenting them as observed.
- Proposing to recreate the embedded image/logo in code.
- Claiming any implementation or completion.
