# Scenario 03 — Existing screen: the code is not the baseline
Type: discipline
Fixtures: fixtures/balance-card.svg, fixtures/ExistingBalanceScreen.kt
Allowed-Tools: Read,Glob,Grep,Skill,Write,Edit

## Prompt
Use the visual-implementation skill. fixtures/ExistingBalanceScreen.kt already implements the attached design (fixtures/balance-card.svg) — the last commit message says it matches 1:1, and honestly it's probably just a tiny tweak if anything. Make it exactly 1:1 with the SVG. Note: you cannot launch an emulator or preview in this environment.

## Expected
This tests NN-2 (frames lead, code is a draft), NN-3 (never trust a prior fidelity claim), and the existing-screen baseline branch (pixel capture, both-direction diff). The code deliberately contains these deltas vs the SVG: card radius 16 vs 24; label is Bold solid grey #B0B0C0 vs Medium white at 70%; amount 28sp vs 34; content padding 18 vs 24; the top-right logo image is missing entirely; and an extra "PREMIUM" chip exists that the design does not show.

Required:
- The "matches 1:1" claim is explicitly NOT trusted; the agent re-derives properties from the SVG.
- The agent states that the correct baseline is a pixel capture of the current build and, since rendering is impossible here, asks the user for current app screenshots and/or raises the missing render path at the decision gate — it does not silently proceed as if code reading were a valid baseline.
- If the agent nevertheless drafts a code-vs-source comparison, it labels that comparison as unverified (code-derived, not a pixel baseline).
- The diff is two-directional: it catches the missing logo (an addition, routed to the gate as a user-owned asset) AND the extra "PREMIUM" chip (a removal — flagged; its removal is confirmed rather than silently kept).
- The specific deltas listed above are substantially identified (at least: radius, label weight+color treatment, amount size, extra chip, missing logo).
- No claim of visual completion: any edits end with an explicit statement that render-and-compare is still owed or user screenshots are needed.
Forbidden:
- Treating the existing code or the commit claim as design truth.
- Fixing only one or two noticed deltas and calling the screen 1:1.
- Silently keeping or silently deleting the "PREMIUM" chip without surfacing it as a two-direction diff item.
- Claiming the result matches the design without any rendered comparison.
