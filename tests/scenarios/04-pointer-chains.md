# Scenario 04 — Retrieval: pointer chains resolve
Type: retrieval
Allowed-Tools: Read,Glob,Grep,Skill

## Prompt
You have the visual-implementation skill available. Answer these five questions using ONLY the skill's files (SKILL.md and its references), following the pointers they give you. For each: answer in 1-3 sentences and name the file/section where you found it.

1. The app flow you're implementing requests a runtime permission, and the user previously tapped "don't ask again". What must the implementation do for that outcome?
2. You need to add an optional footer slot to a shared component used by 12 other screens. Under exactly what conditions is editing the shared component allowed, and what must you prove afterwards?
3. A "no results" message lives inside a draggable bottom sheet. Where do you place it and how do you size the collapsed peek?
4. A card title in a raster screenshot "looks bold". Which weight token do you pick and why?
5. The user says "make this existing screen 1:1 with the attached frame". What is your baseline, and what do you do if you can neither render the current build nor obtain screenshots?

## Expected
Required per question (answers must be grounded in the skill's files, with the source named):
1. Permission outcome is a tri-state (granted / denied / permanently-denied); permanently-denied routes to an open-app-settings recovery with status re-read on resume — found via NN-21 → failure-cases case 5.
2. Only an additive trailing optional parameter/slot whose default reproduces current output exactly; afterwards compile every caller AND render at least one untouched caller unchanged; behavior-changing edits require explicit user approval of the blast radius — via NN-17 → platform-notes "Extending a shared component additively".
3. Top-anchored (never centred in fillMaxSize, which is invisible at the collapsed peek); peek height derived from the measured content block — via NN-19 → failure-cases case 4 → platform-notes sheet sections.
4. Do not default to Bold; Medium 500 vs Bold 700 is the classic raster ambiguity — read the exact weight token or ask/flag — via NN-8 → failure-cases case 1.
5. Baseline is a pixel capture of the current build (never a code reading); if neither render nor screenshots are possible, you can neither baseline nor verify — raise it at the decision gate before implementing — via workflow step 2 → verification.md "Baseline first".
Forbidden:
- Answers from general knowledge that contradict the skill's files.
- Failing to name the file/section for an answer.
