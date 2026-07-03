# Scenario 04 — Retrieval: pointer chains resolve
Type: retrieval
Allowed-Tools: Read,Glob,Grep,Skill

## Prompt
You have the visual-implementation skill available. Answer these eight questions using ONLY the skill's files (SKILL.md and its references), following the pointers they give you. For each: answer in 1-3 sentences and name the file/section where you found it.

1. The app flow you're implementing requests a runtime permission, and the user previously tapped "don't ask again". What must the implementation do for that outcome?
2. You need to add an optional footer slot to a shared component used by 12 other screens. Under exactly what conditions is editing the shared component allowed, and what must you prove afterwards?
3. A "no results" message lives inside a draggable bottom sheet. Where do you place it and how do you size the collapsed peek?
4. A card title in a raster screenshot "looks bold". Which weight token do you pick and why?
5. The user says "make this existing screen 1:1 with the attached frame". What is your baseline, and what do you do if you can neither render the current build nor obtain screenshots?
6. A PNG source has subtle color, spacing, and text-size details. Where does the fixation protocol live, what is `measure.sh` for, and when may the raster branch fall back to estimation?
7. A Compose Multiplatform Desktop design is supplied as one 1440px-wide frame. Where do the wide-viewport rules live, and what must happen with resize behavior, hover/cursor/focus states, scrollbars, and scale?
8. Where does the computed-layout dump guidance live, what Compose Multiplatform tools does it name, and how does that guidance relate to `verification.md`'s rendered comparison?

## Expected
Required per question (answers must be grounded in the skill's files, with the source named):
1. Permission outcome is a tri-state (granted / denied / permanently-denied); permanently-denied routes to an open-app-settings recovery with status re-read on resume — found via NN-21 → failure-cases case 5.
2. Only an additive trailing optional parameter/slot whose default reproduces current output exactly; afterwards compile every caller AND render at least one untouched caller unchanged; behavior-changing edits require explicit user approval of the blast radius — via NN-17 → platform-notes "Extending a shared component additively".
3. Top-anchored (never centred in fillMaxSize, which is invisible at the collapsed peek); peek height derived from the measured content block — via NN-19 → failure-cases case 4 → platform-notes sheet sections.
4. Do not default to Bold; Medium 500 vs Bold 700 is the classic raster ambiguity — read the exact weight token or ask/flag — via NN-8 → failure-cases case 1.
5. Baseline is a pixel capture of the current build (never a code reading); if neither render nor screenshots are possible, you can neither baseline nor verify — raise it at the decision gate before implementing — via workflow step 2 → verification.md "Baseline first".
6. The fixation protocol lives in `references/visual-analysis.md` §2; `measure.sh` is the raster measuring instrument (naming several of its measurement commands — color sampling, edge/gap scanning, cap-height, contrast, tiles/crops — suffices; an exhaustive subcommand list is not required); fallback to perceptual estimation is allowed only without ImageMagick/tooling, still tiled/native-resolution and with declared uncertainty.
7. Wide-viewport rules live in `references/platform-notes.md`, after the Compose Multiplatform stack section and in the cross-cutting "Wide viewports: desktop & web targets" section; one frame is one width, so resize/min-width/breakpoints go to the decision gate, hover/focus-visible/cursor and scrollbar policy are inventoried/gated, density is recalibrated for desktop, and verification covers design width plus narrow and wide stress widths.
8. Computed-layout dump guidance lives in `references/platform-notes.md` "Computed-layout dump — numbers to numbers"; for Compose / Compose Multiplatform it names `onRoot().printToLog()`, `getBoundsInRoot()`, `assertWidthIsEqualTo`, and `Modifier.onGloballyPositioned`; it complements but never replaces `verification.md`'s render/capture plus element × property delta table.
Forbidden:
- Answers from general knowledge that contradict the skill's files.
- Failing to name the file/section for an answer.
