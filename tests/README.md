# Test Harness

Scenario-based tests for the `visual-implementation` skill. Each scenario runs a **fresh, context-free agent** against the skill in a throwaway sandbox and grades the transcript against a rubric — the skill-equivalent of an end-to-end test.

The harness exists to stop untested accretion: the skill grew from real session failures, and every rule earns its token cost only if it demonstrably changes agent behavior.

## Layout

```
tests/
├── run-scenario.sh        # headless runner (sandbox + agent + grader)
├── scenarios/             # one markdown file per scenario
│   ├── 01-svg-extraction.md          (application — parse, don't eyeball)
│   ├── 02-pressure-skip-gate.md      (discipline — time pressure + "don't ask")
│   ├── 03-existing-screen-baseline.md(discipline — code is not the baseline)
│   ├── 04-pointer-chains.md          (retrieval — SKILL.md → references)
│   ├── 05-outlined-svg.md            (application — hostile outlined export)
│   ├── 06-foveal-raster.md           (application — measured raster deltas)
│   └── 07-wide-viewport.md           (discipline — desktop width is not a spec)
└── fixtures/
    ├── balance-card.svg              # clean vector + answer key
    ├── balance-card.expected.md
    ├── outlined-hero.svg             # outlined text, gradient runs, rotated icon
    ├── outlined-hero.expected.md
    ├── wallet-card.png               # raster design source for foveal checks
    ├── wallet-card-impl.png          # curated implementation screenshot
    ├── ../expected/06-ground-truth.md  # answer key (outside fixtures/: agents with Bash could find a same-named file)
    ├── make-wallet-fixtures.sh       # deterministically regenerates the pair + key
    └── ExistingBalanceScreen.kt      # fake existing screen with curated deltas
```

## Running a scenario

Requires the [Claude Code CLI](https://claude.com/claude-code) (`claude`) authenticated on this machine. Runs cost tokens.

```bash
tests/run-scenario.sh tests/scenarios/01-svg-extraction.md              # run + grade
tests/run-scenario.sh tests/scenarios/02-pressure-skip-gate.md --model opus
tests/run-scenario.sh tests/scenarios/04-pointer-chains.md --no-grade   # transcript only
tests/run-scenario.sh tests/scenarios/01-svg-extraction.md --dry-run    # parse check, no calls
```

The runner copies `visual-implementation/` into a temp sandbox's `.claude/skills/`, copies the scenario's fixtures, runs the agent headless with a restricted tool allowlist, then has a second headless call grade the transcript against the scenario's `## Expected` rubric (plus any `Expected-Files` ground truth). Exit codes: `0` pass, `2` graded fail, `1` runner error.

## Scenario file contract

```markdown
# Scenario NN — title
Type: application | discipline | retrieval
Fixtures: fixtures/a.svg, fixtures/b.kt      (optional, relative to tests/)
Expected-Files: fixtures/a.expected.md       (optional, inlined for the grader)
Allowed-Tools: Read,Glob,Grep,Skill          (optional, this is the default)

## Prompt
Verbatim prompt for the agent under test.

## Expected
Grading rubric: Required behaviors and Forbidden behaviors, as bullets.
```

## Grading honestly

The grade is LLM-produced: read the per-item breakdown, don't trust the verdict blindly. A transcript can pass the letter of a rubric while missing its point — the rubrics list observable behaviors precisely to limit this, but the final call on a borderline grade is human.

Known caveats:
- User-level skills in `~/.claude/skills` are also visible to the sandboxed agent; in practice a stale copy there CAN shadow the sandbox's project-level copy (observed 2026-07-03: the agent answered from the old user-level install). Sync or remove `~/.claude/skills/visual-implementation` before trusting a run.
- Scenario results are non-deterministic. A single pass is a smoke signal, not proof; for a wording change that targets behavior, run the affected scenario a few times (see the micro-testing guidance in superpowers' writing-skills, if available: 5+ reps, read every transcript).
- A scenario that allows `Bash` cannot filesystem-isolate the agent: it can escape the sandbox and find same-named files in the real repo (observed: an agent located and pasted an answer key). Keep ground truth OUT of `fixtures/` and named unlike the fixtures (`tests/expected/`).
- **Scenario status (2026-07-03):** 06 and 07 encode aspirational bars for the fixation/instrumentation and wide-viewport rules. RED verified for both (pre-change skill: whole-frame near-match verdict with 1/5 deltas; no wide-target gating). Post-change on sonnet: 04 (canary, incl. new pointer chains) PASSES; 06 reaches full protocol compliance (region tiles, measure.sh sampling + edge projection, provenance tags, zero forbidden violations) but has scored 3/5 curated deltas on its best graded run — the masked-second-delta rule added in response is not yet confirmed by a passing run; 07 consistently gates hover but still under-routes cursor/scrollbar/resize/density under the "don't overthink it" pressure. Treat 06/07 failures as signal to strengthen bindings, not to relax rubrics.

## Policy: TDD for skill edits

- **New rule** → write or extend a scenario FIRST that demonstrates the failure the rule prevents (run it against the current skill and watch it fail or come out fragile), then add the rule, then watch the scenario pass. A rule whose scenario never failed is dead weight — don't add it.
- **Editing a rule or moving content between SKILL.md and references** → re-run the affected scenarios plus `04-pointer-chains.md` (the retrieval canary for the pointer architecture).
- **New failure-case** in `references/failure-cases.md` → add a question to `04-pointer-chains.md` or a dedicated scenario exercising its trigger.
- Record what you ran in the PR description.
