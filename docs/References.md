# References

The skill keeps its detailed protocols in `visual-implementation/references/`. The main `SKILL.md` loads them on demand so the contract stays lean. Here is what each one is for.

## [`visual-analysis.md`](../visual-implementation/references/visual-analysis.md)
How to extract reliable design intent from a source. Includes:
- the source-kind branch (named-token spec / vector / raster / mixed);
- target-class, design-width, DPR, scale & density calibration before any measurement;
- the raster fixation protocol: gestalt pass, native-resolution tiles/crops, instrumented measurement, and measured-vs-estimated provenance;
- exact-value extraction for color, gradients, geometry, and effects (shadows reassembled from `feDropShadow` or split filter chains; borders read from masks);
- raster color, palette, edge, cap-height, and contrast measurement with WCAG AA risk routing when tooling allows;
- outlined-text recovery (per-line/per-span color, weight class, and `url(#…)` gradient fills as a single text brush);
- the rule that a stated token outranks pixel measurement, with the font-metric trap spelled out;
- the system-chrome vs app-chrome split and per-control container treatment;
- the cut-source protocol for occluded content;
- how to feed every uncertainty into the risk ledger.

## [`output-schemas.md`](../visual-implementation/references/output-schemas.md)
The structured text each phase emits: Screen Analysis, Project Scan, Agent Difficulty Report, Decision Gate, Implementation Brief, and Verification Report. Use these so artifacts stay comparable and nothing is dropped.

## [`platform-notes.md`](../visual-implementation/references/platform-notes.md)
Per-stack idioms for Flutter, Android Compose, SwiftUI, UIKit, and Kotlin/Compose Multiplatform, including their desktop/web targets where the stack supports them. Covers which primitives to prefer, what to avoid, how to map a designer `box-shadow` (it is **not** a single elevation dp), how to reproduce a **text-fill gradient** with a brush, wide-viewport behavior, computed-layout dumps, and how to extend a shared component *additively*.

## [`verification.md`](../visual-implementation/references/verification.md)
The render-and-compare gate: baseline first for existing screens, render *your* build, run the ranked regional compare, re-read the foveal crops, check computed layout numbers when available, and complete the **element × property delta table** (copy, type with provenance, fill type, gaps/insets, radius/border/fill, shadow, icon identity, container chrome, contrast/target size, responsive behavior, placement/reuse, occluded items, shared-change blast radius). Includes the wiring check and the isolated-component render fallback.

## [`failure-cases.md`](../visual-implementation/references/failure-cases.md)
The costliest real-session failures, each generalized into a rule and kept with its full reasoning: Bold-by-default, the near-token trap, the state × layout-mode grid, measured placement in stateful containers, the permission tri-state, overflow as a communication problem, redundant chrome, and re-drafted regulated copy. `SKILL.md` cites a case by number (e.g. NN-8 → case #1); read the case when its trigger appears in the task.

## [`worked-example.md`](../visual-implementation/references/worked-example.md)
An end-to-end pass — source → analysis → risk ledger → decision gate → brief → verification — as a concrete model to follow.
