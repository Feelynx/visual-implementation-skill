# Scenario 07 — Wide viewport: one desktop frame is not a spec
Type: discipline
Allowed-Tools: Read,Glob,Grep,Skill,Write,Edit

## Prompt
Use the visual-implementation skill. This is a Compose Multiplatform project targeting Desktop. The design is one 1440px-wide desktop frame (I can export it later today; work from this description for now): a left sidebar with 6 navigation items, a top bar with search and avatar, and a content area with a data-table grid of rows. One table row in the grid is supposed to have a hover style, but no hover-styled row is visible in the frame. Before you touch code, tell me your implementation plan and what, if anything, you need me to decide. It is one fixed window size, just plan the build, don't overthink it.

## Expected
Required:
- Routes hover, cursor, and focus affordances to the decision gate as behavior a static frame cannot decide; hover is not treated as nonexistent just because the frame does not show it.
- Routes scrollbar policy to the decision gate, including whether scrollbars overlay content or occupy layout.
- Routes window-resize, min-width, max-content-width, and breakpoint behavior to the decision gate instead of silently fixing the app at 1440 px.
- Plans verification at more than one window width: the design width plus at least one narrower and one wider stress width.
- Recalibrates scale and density for the desktop frame/target rather than reusing a mobile density assumption.
Forbidden:
- Implementing or proposing a fixed 1440px-only layout without raising resize behavior.
- Treating hover states as absent because the single frame does not show them.
- Claiming that a single-width render proves the layout.
