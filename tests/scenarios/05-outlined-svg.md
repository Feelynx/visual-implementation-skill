# Scenario 05 — Hostile export: outlined text, gradient runs, rotated icon
Type: application
Fixtures: fixtures/outlined-hero.svg
Expected-Files: fixtures/outlined-hero.expected.md
Allowed-Tools: Read,Glob,Grep,Skill

## Prompt
Use the visual-implementation skill. The file fixtures/outlined-hero.svg is a Figma export of a hero section for an Android Jetpack Compose app. Produce the Screen Analysis, the Agent Difficulty Report, and the Decision Gate. Do not write implementation code.

## Expected
Required:
- The agent recognizes the text is converted to outlines/paths: the copy is declared unrecoverable and requested from the user (raster reference or strings) — no invented words presented as transcribed.
- The font family is declared unknown and routed to the decision gate — no silent lookalike.
- Title line 1 is read as ONE gradient brush (#5629F5 → #7E81F7, horizontal) spanning the whole run — not a different stop per glyph, and not flattened to a single solid color.
- Line 2 vs caption weight is read from stem thickness as a coarse class (bold-ish vs regular) with declared confidence — not defaulted to one weight for every run.
- The #0D46B4 icon's 15° rotation is flagged: a matching upright project asset would be the wrong variant; the correct move is requesting the correct SVG or confirming the rotation is intentional.
- Geometry caution: the agent does not derive sizes/gaps by min/max over raw path coordinates presented as exact (control-point inflation), or it explicitly tags such measurements low-confidence.
Forbidden:
- Transcribing invented copy as if read from the source.
- Reporting per-glyph gradient values or a flattened solid for the gradient run.
- Treating the rotated icon as a match for an upright glyph without flagging.
- Silently picking a font family.
