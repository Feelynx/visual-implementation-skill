# Worked Example

One end-to-end pass on a real source: a wallet home "balance" hero card. It shows how the protocols in `visual-analysis.md` and `verification.md` produce the schemas in `output-schemas.md` — including the Agent Difficulty Report that turns uncertainty into routed risk. The implementation excerpt is Flutter; the analysis and verification are stack-neutral. Sections are abbreviated to the illustrative parts.

## The source (SVG)

```svg
<svg width="390" height="220" viewBox="0 0 390 220" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="card" x1="0" y1="0" x2="390" y2="220" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#4F46E5"/>
      <stop offset="1" stop-color="#7C3AED"/>
    </linearGradient>
  </defs>
  <rect x="20" y="24" width="350" height="172" rx="24" fill="url(#card)"/>
  <text x="44" y="76" font-family="Inter" font-size="14" font-weight="500" fill="#FFFFFF" fill-opacity="0.7">Available balance</text>
  <text x="44" y="120" font-family="Inter" font-size="34" font-weight="700" fill="#FFFFFF">$2,480.00</text>
  <image x="300" y="48" width="40" height="40" href="data:image/png;base64,iVBORw0KGgo..."/>
  <rect x="44" y="148" width="120" height="40" rx="20" fill="#FFFFFF"/>
  <text x="74" y="173" font-family="Inter" font-size="14" font-weight="600" fill="#4F46E5">Add money</text>
</svg>
```

## 1. Analysis (parse, do not eyeball — it is an SVG)

- **Source kind:** vector. Parse exact values; confidence High.
- **Reference frame:** `viewBox` 390×220 → 390pt logical width (iPhone-class). No scale-factor guesswork needed for a vector.
- **Colors (exact):**
  - Card = linear gradient `#4F46E5` → `#7C3AED`.
  - "Available balance" = `#FFFFFF` at `fill-opacity 0.7` — **not** a grey hex. Decompose to "onPrimary at 70%", map to the role, not a one-off color.
  - Amount = `#FFFFFF` (onPrimary). Button label = `#4F46E5` (the brand/primary), button fill = `#FFFFFF`.
- **Typography (exact family present):** Inter 14/500 → label role; Inter 34/700 → display role; Inter 14/600 → button-label role. Map to project type roles, do not hardcode 34.
- **Derived scales (cluster → snap):** card inset 20, content padding 24 (`44−20`), corner radius 24 (card) and 20 (pill). Cluster {20, 24} and {20, 24} radii, snap to the project spacing/radius scale rather than emitting 20/24 literally.
- **Asset vs drawable:** the `<image href="data:...">` at top-right is an embedded raster → a **brand/card-network logo asset to provide, not to redraw**. The gradient card, the pill, and the text are drawable from primitives and tokens.

## 2. Agent Difficulty Report

Turn the uncertainty above into routed risk, before asking decisions or writing code:

```markdown
## Agent Difficulty Report

Overall readiness:
- Status: Blocked
- Reason: One user-owned brand asset is required for full fidelity.
- Highest-risk areas: top-right logo asset; hidden/loading balance behavior.

Risk ledger:
- Area: Top-right logo
  - Difficulty type: Missing asset
  - Why this is hard: embedded base64 raster; recreating a brand mark in code is wrong and brand-unsafe
  - Evidence from source/project: <image href="data:..."> in the SVG; no matching entry in the asset catalog
  - Likely failure mode if unchecked: I invent a lookalike logo or draw it as shapes
  - Confidence: High | Severity: High | Owner: User
  - Mitigation: request the asset; placeholder only if explicitly approved
  - Routed to: Decision gate
- Area: Brand gradient token
  - Difficulty type: Token gap
  - Why this is hard: exact gradient #4F46E5→#7C3AED has no existing token
  - Likely failure mode if unchecked: hardcode a raw gradient instead of adding a token
  - Confidence: High | Severity: Medium | Owner: Project
  - Mitigation: reuse a brand gradient token if present, else add one
  - Routed to: Implementation brief
- Area: Amount display role
  - Difficulty type: Project mismatch
  - Why this is hard: 34/700 may not map exactly to an existing display role
  - Likely failure mode if unchecked: pick a role one step off and break hierarchy
  - Confidence: Medium | Severity: Low | Owner: Agent
  - Mitigation: choose nearest role, confirm in render
  - Routed to: Verification focus
- Area: Hidden/loading balance states
  - Difficulty type: Unknown behavior
  - Why this is hard: a static frame hides privacy toggle and loading
  - Likely failure mode if unchecked: ship a static amount, missing real behavior
  - Confidence: Medium | Severity: Medium | Owner: User
  - Mitigation: confirm whether the screen has these states
  - Routed to: Decision gate

Assumptions the agent must not make silently:
- Assumption: the top-right mark can be approximated -> NO; needs the real asset or explicit acceptance.
- Assumption: 34px equals the existing display role -> verify; do not assume exact.

Verification focus created by the risks:
- Amount: the chosen display role matches the source hierarchy.
- Logo region: the real asset is rendered (not a placeholder) before claiming complete.
```

## 3. Decision gate (fed by the user-owned risks)

```markdown
## Decisions Needed

1. Area: Top-right logo (embedded base64 image)
   Raised from risk: Missing asset (Owner: User, Severity: High)
   Issue: Source embeds a raster I must not recreate in code.
   Recommended option: You provide the asset (card-network/brand mark) for the asset catalog.
   Alternatives: Omit until provided; temporary placeholder if you approve.
   Impact: Fidelity + correct branding.
   Default only if you explicitly delegate: render a neutral placeholder, clearly marked.
   What I need from you: The logo file, or approval to placeholder.

2. Area: Balance amount
   Raised from risk: Unknown behavior (Owner: User, Severity: Medium)
   Issue: No visible privacy/hide-balance toggle or loading state in the frame.
   Recommended option: Add shimmer loading + a hide/show affordance per app convention.
   Alternatives: Static amount only (lower fidelity to real behavior).
   Impact: Real-world behavior, accessibility.
   Default only if you explicitly delegate: static amount, states deferred.
   What I need from you: Confirm whether this screen has those states.
```

## 4. Implementation brief (excerpt — Flutter)

```markdown
Risk/readiness status:
- Status: Ready with accepted assumptions (after you approve a placeholder) or Blocked (until the logo is provided)
- Accepted assumptions: none yet — pending decision-gate answers
- Risks carried into verification: amount display role; logo asset presence

Component mapping:
- Source area: Balance card
  - Use: compose from existing card/container + project gradient token
  - Existing component/token: AppCard or Container; ColorScheme.primary/onPrimary; spacing + radius tokens
  - Constraints: gradient #4F46E5→#7C3AED → map to brand gradient token (add token if missing, per risk ledger)
- Source area: "Available balance" label
  - Use: Text with TextTheme labelMedium, color onPrimary at 70% via theme token (not a literal grey)
- Source area: Amount
  - Use: Text with TextTheme displaySmall (the 34/700 role), color onPrimary
- Source area: "Add money" pill
  - Use: existing PillButton / FilledButton.tonal with primary label on surface fill
- Source area: Top-right logo
  - Use: Image.asset from catalog — BLOCKED on asset decision

Design-system rules:
- Spacing: map content padding to spacing token (≈24 → spacing.lg); do not hardcode
- Shape: card/pill radius → radius tokens; do not hardcode 24/20
- Adaptive: SafeArea; amount uses Flexible + FittedBox so large balances or font scaling do not overflow
```

## 5. Verification (excerpt)

Render in a preview/simulator, capture at 390pt width and the same theme, then:

```markdown
Visual comparison (element × property delta table):
- Element | Property | Source value | Implemented value | Verdict | Confidence
- Card        | fill/gradient   | token (stops + direction) | gradient token        | match | High
- Card        | radius          | radius token              | radius token          | match | High
- Card        | shadow          | 0 6 16 #000/8%            | Modifier.shadow tuned | match | Medium
- Balance label | copy          | "Balance" (per locale)    | matches               | match | High
- Balance label | color/weight  | onPrimary 70%, regular    | onPrimary @0.7        | match | High
- Amount      | copy            | "$1,240.00"               | matches               | match | High
- Amount      | type role/size  | display                   | one step smaller      | minor | Medium
- Pill button | radius/fill     | pill, accent              | radius token          | match | High
- Pill button | label copy/weight | "Add money", bold       | matches               | match | High
- Top-bar icons | container     | bare glyph                | bare icon             | match | High
- Top-right logo | asset         | brand mark                | placeholder shown     | major | High
- Loading/hide states | state    | deferred to decision gate | deferred              | n/a   | —

Risk ledger reconciliation:
- Top-right logo asset
  - Outcome: Still open
  - Evidence: placeholder rendered; real asset not yet provided
- Amount display role
  - Outcome: Still open
  - Evidence: render reads one step small vs source; needs role bump
- Brand gradient token
  - Outcome: Mitigated
  - Evidence: token added/reused; gradient matches source

Final status: Waiting on assets (logo) + amount type-role tweak
```

## What this example demonstrates

- An SVG is **parsed** for exact gradient stops, opacity, and type — no eyeballing.
- A translucent label is decomposed to a **role at opacity**, not a grey literal.
- The `viewBox` gives the reference frame for free; raster would have needed device width + scale factor.
- Uncertainty becomes a **routed risk ledger** with owners and destinations, not hidden reasoning.
- The embedded image is correctly classified as an **asset** and routed to the decision gate.
- Spacing/radius are **snapped to tokens**, never hardcoded.
- Verification is an **element × property delta table** — every property (copy per locale, weight, per-run color, each gap/inset, radius, border, shadow, container chrome) scored against the token-mapped source — and **reconciles every risk**, honest about the unresolved asset and the type-role mismatch.
