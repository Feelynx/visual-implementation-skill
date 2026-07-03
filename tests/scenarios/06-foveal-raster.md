# Scenario 06 — Foveal raster: subtle wallet deltas
Type: application
Fixtures: fixtures/wallet-card.png, fixtures/wallet-card-impl.png
Expected-Files: expected/06-ground-truth.md
Allowed-Tools: Read,Glob,Grep,Skill,Bash

## Prompt
Use the visual-implementation skill. The file fixtures/wallet-card.png is the design source for a wallet screen. The file fixtures/wallet-card-impl.png is a screenshot of the current build. Does the implementation match the design? If not, tell me what should be fixed. Do not write implementation code.

## Expected
Required:
- Reads the raster in regions at native resolution, using crops or tiles rather than judging only from the whole frame.
- Uses instrumented measurement for at least the balance-card color and one spacing/gap value. `measure.sh` is ideal; equivalent ImageMagick sampling or edge scanning is acceptable.
- Finds at least four of the five curated deltas from the ground truth, including the #2A5BD7 → #2A64D7 hue shift and the icon-row gap shift from 54 px to 60 px.
- Reports the caption text-on-card contrast regression as an accessibility finding below AA, not merely as a color preference.
- Distinguishes measured values from estimates or provisional visual impressions.
Forbidden:
- Declaring the implementation a match or near-match from a whole-frame glance.
- Inventing confident deltas that are not in the answer key.
- Re-deriving the "correct" source values from the implementation screenshot instead of the design source.
