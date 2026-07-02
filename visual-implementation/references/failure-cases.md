# Failure Cases

The costliest real-session failures, each generalized into a non-negotiable. Every case keeps the full reasoning behind its one-line rule in `SKILL.md` — read the matching case **before acting** whenever its trigger appears in your task. These are not hypotheticals: each one has shipped a defect or burned review rounds.

| # | Case | Trigger — read it when… |
|---|------|-------------------------|
| 1 | Bold-by-default | you are assigning a weight token to prominent text from a raster |
| 2 | Near-token instead of the exact one | a stated value almost matches a project token |
| 3 | State × layout-mode grid | one screen has two layout modes over the same data (map/list, expanded/collapsed) |
| 4 | Placement is measured, not defaulted | you are placing an empty/prompt state, or content inside a draggable/expandable container |
| 5 | Permission results are a tri-state | the flow requests any runtime permission |
| 6 | Overflow is a communication problem | a label collides with fixed trailing widgets or a fixed-width container |
| 7 | Redundant chrome | an element restates information already shown elsewhere on the same screen |

## 1. Bold-by-default

**Symptom:** prominent text — names, card titles, section headers — implemented with a `TextBold*` token; the review round comes back "the weight is wrong."

**The failure:** Medium (500) and Bold (700) read almost identically in a raster, and product designs use Medium constantly for exactly these runs. The recurring miss is picking `TextBold*` when the token is `Medium/500` — map `Medium 2xl` → `TextMedium2XL`, not `TextBold2XL`.

**The rule:** "Looks bold" is not the weight; read the exact weight token. When a raster leaves Medium-vs-Bold genuinely ambiguous, ask or flag it — never assume Bold. Coarse weight class (regular/medium/bold) *is* determinable from stem thickness (`visual-analysis.md` §5); the Medium/Bold boundary often is not.

## 2. Near-token instead of the exact one

**Symptom:** the implementation uses a token that is *close* to the stated value — `TextAccentLight` for `text-inverse #FFFFFF`, `TextSecondary` for `text-muted #757584`, `Spacings.XL2` for gap `32`, `BGAccentDark` for gradient `#5629F5 → #7E81F7`.

**The failure:** an exact stated value maps to the exact project token that carries it — never a close cousin. A near-token is not a match; it is a defect.

**The rule:** grep the theme for the exact hex/value and use the token that carries it (`TextInverse`, `TextMuted`, `Spacings.XL3`, `BGSecondary`). The user typically feeds these exact specs **incrementally across review rounds** — each one is authoritative and overrides your earlier approximation, so re-map precisely instead of defending the guess.

## 3. State × layout-mode grid

**Symptom:** the error/empty/no-results branch works in one presentation of the data (the list) and shows a blank, stale, or fake surface in the other (the map).

**The failure:** when a screen has more than one layout mode over the same data — a map view vs a list view, an expanded vs collapsed host — wiring the error/empty/no-results branch into only one host leaves the other broken the instant the real data source fails or returns nothing.

**The rule:** each mode must independently render every data state: loading, empty, no-results, and API error. Enumerate **state × mode as a grid, not a list**, and verify each cell (`verification.md`, presence/state row).

## 4. Placement is measured, not defaulted

**Symptom A — the auto-centred empty state:** an empty / no-results / prompt state centred on the screen "because centring is what you do with empty states," while the frame anchors it in the upper third.

**Symptom B — the invisible sheet content:** content centred with `fillMaxSize` inside a draggable bottom sheet reads correctly expanded but is invisible at the collapsed peek — the peek reveals the *top* of the sheet, the centred content sits below the fold, and the user sees only the drag handle over blank space.

**The failure:** vertical position and anchoring are first-class properties to *measure* against the frame, never defaults. Auto-centre and auto-top-pad are both guesses; the frame decides. And when content lives in a **stateful container** — a draggable sheet, an expandable panel — its placement and size must be defined for *each* container state, not once.

**The rule:** measure placement per state. For sheet content: top-anchor it and size the peek from the measured content block so it is visible collapsed AND reads full when expanded (`platform-notes.md`, "Size a reveal from measured content" and "Map with a draggable results bottom sheet"). One layout that ignores the container's states — like one that ignores the data states (case 3) — is a defect.

## 5. Permission results are a tri-state

**Symptom:** the permission flow models the outcome as `granted: Boolean`, and a user who tapped "don't ask again" is silently routed to "proceed without the feature" — with no way back.

**The failure:** a permission outcome is not a boolean. GRANTED / DENIED (re-promptable) / PERMANENTLY_DENIED (the OS will not prompt again — Android "don't ask again" / second denial, iOS denied or restricted) are three distinct branches. Collapsing to a boolean silently drops permanently-denied, whose only path to grant is the system Settings.

**The rule:** route permanently-denied to an **open-app-settings** recovery and re-read the status on resume when the user returns. Derive the shape from the project's own permission blueprint — if an existing camera/notification flow already splits DENIED vs PERMANENTLY_DENIED and routes to Settings via an existing `openAppSettings()`, carry that exact recovery into the new permission instead of reinventing a two-way branch. The same "enumerate every branch" duty covers back-navigation, cancel, offline, and empty/error — the design implies them even when no frame draws them; surface the ones you cannot resolve at the decision gate rather than shipping the happy path.

## 6. Overflow is a communication problem

**Symptom:** a label colliding with fixed trailing widgets (a meter, a percentage, a chip) gets `maxLines = 1` + ellipsis, and the one datum the screen exists to show is now cut off.

**The failure:** ellipsis, fade, `maxLines` clipping, or shrinking copy to fit optimizes the container, not the message — it hides information from the user. Reaching for ellipsis is the tell that you are solving the layout constraint instead of the user's need.

**The rule:** treat the overflow as a communication problem first: ask what that label must convey, then reflow so the full string always stays readable — stack the label above its trailing controls (a two-line row), let it wrap, or give it its own line — before you ever clip it. Truncation is a last resort you name at the decision gate, never the default fix, and never applied to the one datum the screen exists to show. (Deliberately-constrained text — a fixed-width carousel card — still needs an explicit overflow policy: `visual-analysis.md` §8, data variability.)

## 7. Redundant chrome

**Symptom:** a label, tag, or chip fights for space while restating information already present elsewhere on the same screen — a "focus" pill naming the exact item an on-top "next step" summary already names, both computed from the same source value.

**The failure:** treating every element the source shows as load-bearing. Redundant chrome can be dropped — and dropping it can dissolve a layout constraint (case 6) instead of fighting it — but only when the redundancy is real.

**The rule:** confirm the duplication **in code** (the same derived value, not a lookalike) and route the removal through the decision gate as a two-direction diff item. Never drop content the user still needs, and never infer redundancy from the visual alone.
