# Visual Implementation

> An agent skill that turns a visual source — PNG, SVG, Figma export, screenshot, or mockup — into **design-system-grounded mobile UI**, surfacing risks and decisions *before* coding and proving fidelity with a render-and-compare gate *after*.

It is built for Flutter, Android (Jetpack Compose), iOS (SwiftUI / UIKit), and Kotlin Multiplatform / Compose Multiplatform projects.

---

## Why it exists

Implementing a screen from a screenshot usually goes wrong in predictable ways:

- pixel-perfect literals get hardcoded instead of mapped to the project's tokens;
- font sizes are *guessed from pixels* and come out wrong (font metrics lie);
- an icon is matched by **filename** and ships rotated or mirrored;
- a reusable row is rebuilt inline instead of becoming a shared component;
- a shared component gets a behavior-changing edit to fix one screen;
- "it compiles" is mistaken for "it looks right".

This skill encodes a disciplined workflow that turns each of those traps into a checked step.

---

## What it does — at a glance

```
Intake  ──►  Analyze  ──►  Project scan  ──►  Difficulty report  ──►  Decision gate
                                                                          │
                                                       (user resolves blocking risks)
                                                                          ▼
                                Verify  ◄──  Implement  ◄──  Implementation brief
                              (render & compare,
                               element × property)
```

Each phase produces a structured artifact (see the [output schemas](visual-implementation/references/output-schemas.md)).

---

## Core principles

- **Design tokens outrank pixels.** When the source names a token (`Typography/md`, a spacing variable), map it to the project scale. Pixel measurement is a declared-uncertainty fallback, biased low.
- **Reuse before building** — including modal sheets, scaffolds, rows, and list items, not just tokens.
- **A new reusable component is centralized** in the design system, never a screen-local one-off.
- **Assets are verified by content, not filename** — orientation, rotation, mirror, color, `viewBox`.
- **Shared-component edits are classified** — additive default-no-op extensions are allowed; behavior-changing edits are gated.
- **Completion = render your build and compare it to the source property by property** — a passing build proves nothing about copy, color, weight, spacing, or geometry.
- **Speak the user's language**, surface uncertainty as a risk ledger, and never invent assets, copy, or content hidden behind a crop.

---

## Supported stacks

| Stack | UI layer |
| --- | --- |
| Flutter | Widgets, `ThemeData`, design tokens |
| Android | Jetpack Compose, `MaterialTheme`, project tokens |
| iOS | SwiftUI / UIKit, asset catalogs, type styles |
| Multiplatform | Kotlin Multiplatform / Compose Multiplatform shared UI |

---

## Installation

This is a folder-based agent skill. Install it by placing the `visual-implementation/` directory into your runtime's skills directory.

### Claude Code

```bash
git clone https://github.com/Feelynx/visual-implementation-skill.git
cp -R visual-implementation-skill/visual-implementation ~/.claude/skills/visual-implementation
```

### Codex

```bash
cp -R visual-implementation-skill/visual-implementation ~/.codex/skills/visual-implementation
```

Restart the runtime (or start a new session) so the skill is discovered.

> Full details, updating, and uninstalling: **[docs/Installation.md](docs/Installation.md)**.

---

## Usage

Invoke the skill when you are implementing or reviewing a screen from a visual source. A typical prompt:

> *Use the visual-implementation skill to build this screen from the attached PNG, using the project's design system. Surface risks and decisions before coding.*

The skill will analyze the source, scan the project, surface a difficulty report, stop at a decision gate for anything it cannot decide alone, then implement and verify.

---

## Repository layout

```
visual-implementation/
├── SKILL.md                      # the skill contract: non-negotiables + workflow
├── agents/
│   └── openai.yaml               # runtime manifest (display name, prompt)
├── scripts/
│   ├── capture.sh                # read-only device/simulator screenshot
│   └── compare.sh                # scale + side-by-side + pixel diff
└── references/
    ├── visual-analysis.md        # extracting design intent from a source
    ├── output-schemas.md         # the structured artifacts each phase emits
    ├── platform-notes.md         # per-stack idioms and mappings
    ├── verification.md           # the render-and-compare gate
    ├── failure-cases.md          # costliest real-session failures, case by case
    └── worked-example.md         # an end-to-end pass
docs/                             # the wiki (start at docs/Home.md)
tests/                            # scenario harness (see tests/README.md)
```

---

## Documentation (wiki)

A deeper guide lives in **[`docs/`](docs/Home.md)**:

- [Home](docs/Home.md) — orientation and index
- [Installation](docs/Installation.md) — per-runtime install, update, uninstall
- [Concepts](docs/Concepts.md) — the mental model
- [Workflow](docs/Workflow.md) — the ten phases, step by step
- [Non-Negotiables](docs/Non-Negotiables.md) — the hard rules and why
- [References](docs/References.md) — what each reference file is for
- [Platforms](docs/Platforms.md) — per-stack cheat sheet
- [FAQ](docs/FAQ.md) — common questions

---

## Contributing

Issues and pull requests are welcome. Keep the skill **lean**: prefer tightening an existing rule to adding a new one, and ground every change in a concrete failure it prevents.

Changes to `SKILL.md` or `references/` should come with evidence from the [test harness](tests/README.md): a new rule needs a scenario that fails without it, and edits should re-run the affected scenarios (at minimum the retrieval canary, `tests/scenarios/04-pointer-chains.md`). Say what you ran in the PR.
