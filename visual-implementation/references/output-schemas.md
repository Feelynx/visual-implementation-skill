# Output Schemas

Use these schemas as structured text. Keep them concise but complete; remove sections that truly do not apply.

## Screen Analysis

```markdown
## Screen Analysis

Source:
- File:
- Type:
- Source kind (vector/raster):
- Dimensions:
- Reference frame (device width / density / scale factor):
- Frame confidence:
- Apparent platform:
- Token spec available (Figma styles/variables / inspect / redline): yes/no — if yes, list named tokens used
- Screen state:
- Frame set (when >1 frame): N frames → M screens; per screen, the state each frame encodes and the affordance that signals it (e.g. frame A = connected [trailing trash], frame B = pending [overflow])
- Confidence:

Layout regions:
- Region:
  - Purpose:
  - Visual hierarchy:
  - Alignment/grouping:
  - Adaptive intent:
  - Confidence:

Components:
- Element:
  - Visual role:
  - Likely component type:
  - State:
  - Text/content:
  - Icon/image needs:
  - Container treatment per icon (incl. inline glyphs nested in a text line / row — bare icon / icon-in-tile, fill, shape, border, elevation):
  - Typography role:
  - Color role / text fill (solid token vs gradient brush — direction, stops, terminal-stop opacity; provenance: stated colour token vs eyeballed estimate — flag meaning-bearing eyeballed hues for the gate):
  - Spacing intent:
  - Confidence:

Assets detected:
- Asset:
  - Area:
  - Present in source:
  - Needed in project:
  - Confidence:

Derived scales:
- Type per run: source token → project token (size / weight / line-height) — e.g. `Typography/3xl` → `TextBold3XL` (32/700/110%). Any run with NO source token: mark `pixel-estimate, low confidence (advance-width)`.
- Radii -> token:
- Spacing & inset inventory (name -> source/measured -> token): source spacing token → project token where one is named; else measured → snapped. Vertical gaps (icon-row→title, title→body, card→card); horizontal/row gaps; internal insets (glyph→tile, content→card edge, label→button edge).

Invisible aspects (needs confirmation):
- Interaction states:
- Off-screen/scroll:
- Motion/transitions:
- Copy real vs placeholder:
- Occlusion/truncation (per element — status: visible / partial / hidden; cause: frame-crop / sheet / modal / keyboard / intentional-peek; resolution: transcribed / provisional / omitted / awaiting-export):
- Data variability (empty/loading/error):
- Theme/RTL/dynamic type:

Ambiguities:
- Area:
  - Uncertainty:
  - Why it matters:
  - Proposed decision:
```

## Project Scan

```markdown
## Project Scan

Detected stack:
- Primary UI stack:
- Secondary UI stack:
- Evidence:

Design system:
- Theme/tokens:
- Typography:
- Color roles:
- Spacing/dimensions:
- Shape/elevation:
- Accessibility/localization patterns:

Reusable structural components (search beyond tokens):
- Sheets / dialogs / scaffolds:
- List items / rows:
- Cards / accordions / chips:

Reusable components:
- Component:
  - File/symbol:
  - Matches source area:
  - Fit:
  - Required adaptation:

Assets:
- Catalog/location:
- Matching assets:
- Missing assets:
- Name collisions (needed/provided asset vs existing names; identical content?; other consumers and their screens):

Relevant examples:
- File:
  - Why relevant:

Wiring / triggers (only when the task connects, opens, or shows something):
- Target component / destination:
- Driving event / intent / handler / route:
- Existing dispatch sites (file:symbol):
- Entry points already wired? (all / none / partial):
- New wiring actually required (only the gap, or 'none'):
```

## Agent Difficulty Report

Use this after Screen Analysis and Project Scan, before asking decisions or writing an implementation brief. This is the user-facing place where the agent says what is hard, what could go wrong, and who must resolve it.

```markdown
## Agent Difficulty Report

Overall readiness:
- Status: Ready / Ready with accepted assumptions / Blocked
- Reason:
- Highest-risk areas:

Risk ledger:
- Area:
  - Difficulty type: Source uncertainty / Project mismatch / Missing asset / Unknown behavior / Token gap / Shared-component blast radius / Accessibility-data variability / Verification risk
  - Why this is hard:
  - Evidence from source/project:
  - Likely failure mode if unchecked:
  - Confidence: High / Medium / Low
  - Severity: High / Medium / Low
  - Owner: Agent / User / Project
  - Mitigation:
  - Routed to: Decision gate / Implementation brief / Verification focus
  - Shared-edit class (only when Difficulty type is Shared-component blast radius): Additive (default-no-op) or Behavioral — for Additive, state the default, why it reproduces current output, and callers to re-verify; for Behavioral, state consumers affected and who approves the blast radius

Assumptions the agent must not make silently:
- Assumption:
  - Affected area:
  - Required decision or explicit acceptance:

Verification focus created by the risks:
- Area:
  - What must be checked in the rendered result:
```

## Decision Gate

Use this when user judgment is required. Ask grouped questions, not a long stream of micro-questions.

```markdown
## Decisions Needed

1. Area:
   Raised from risk:
   Issue:
   Recommended option:
   Alternatives:
   Impact:
   Default only if you explicitly delegate:
   What I need from you:
```

## Implementation Brief

```markdown
## Implementation Brief

Goal:
- Implement:
- Source visual:
- Target platform:

Approved decisions:
- Decision:

Risk/readiness status:
- Status: Ready / Ready with accepted assumptions
- Accepted assumptions:
- Risks carried into verification:

Files to inspect/change:
- File:
  - Reason:

Component mapping:
- Source area:
  - Use:
  - Existing component/token:
  - New code required:
  - Constraints:
  - New component home (reuse / shared design-system component + agreed name / screen-local one-off + why it never repeats):
  - Shared-component change type (none / additive optional slot — callers verified unchanged / behavior-changing — gated):

Design-system rules:
- Typography:
- Colors:
- Spacing:
- Shape/elevation:
- Icons/images:

Adaptive behavior:
- Safe areas:
- Small screens:
- Large screens/tablets:
- Orientation:
- Dynamic type/font scaling:
- Loading/empty/error states:

Accessibility/localization:
- Labels:
- Reading order:
- Touch targets:
- Text expansion:

Verification:
- Commands/previews/screenshots:
- Visual checks:
- Risk-ledger checks:
- Known limitations:
```

## Verification Report

```markdown
## Verification Report

Commands run:
- Command:
  - Result:

Render capture:
- Method:
- Dimensions/theme matched:
- Baseline (existing screens): agent-rendered / user-supplied screenshots / code-only (flag as verification risk)

Visual comparison (element x property delta table):
- Element | Property | Source value | Implemented value | Verdict (match/minor/major) | Confidence
  (property rows per element: copy [per locale], type role/size/weight (provenance: stated token vs pixel estimate), per-line/per-span color (provenance: stated token vs eyeballed estimate), text fill type (solid vs gradient/brush), each gap & inset, radius, border, shadow/elevation spec, fill, icon identity/orientation, icon size, icon inner padding, container treatment (every icon incl. inline glyph), sibling consistency, presence/position (union of analysis + build elements; build-only = remove), state coverage, overflow/truncation (width-constrained text), occluded/provisional, component placement & reuse, shared-change blast radius)
- Design-system compliance:
- Remaining asset gaps:

Risk ledger reconciliation:
- Risk:
  - Outcome: Mitigated / Accepted limitation / Still open
  - Evidence:

Final status:
- Complete / Waiting on assets / Needs follow-up:
```
