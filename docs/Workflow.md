# Workflow

The skill runs a ten-phase workflow. Each phase has a structured output (see [output-schemas](../visual-implementation/references/output-schemas.md)).

### 1. Intake the visual source
Identify file type, dimensions, platform, density, theme, and screen state. Classify the source kind (named-token spec / vector / raster / mixed) and **calibrate scale** before measuring anything. Ask whether a named-token spec exists — request token names rather than measuring them. Lock the response language to the user's request.

### 2. Analyze the complete screen
Describe regions, hierarchy, components, typography, color, states, imagery, and copy. Record what a static image *cannot* show (states, off-screen content, motion, real vs placeholder copy, occlusion, variants). For an **existing screen**, render and capture the *current build* first and diff it against the source — the mismatches are the task list.

### 3. Scan the project
Detect the stack. Search for tokens, themes, typography, color roles, spacing scales — **and** structural components (sheets, scaffolds, rows, list items, cards). Locate the render/capture path; if none exists, that is a verification risk to raise now.

### 4. Surface the Agent Difficulty Report
Translate every uncertainty into a routed risk: what is hard, the failure mode if unchecked, confidence, severity, owner, mitigation, and destination.

### 5. Map visual elements to project primitives
For each region: reuse, adapt, compose, create, or ask. Collapse repeated structures into a single component candidate. Decide a new component's **home before its code** — reusable structures belong in the design system.

### 6. Run the decision gate
Stop for choices only the user can make. Group questions; each carries the affected area, a recommended option, alternatives, and impact. Run it **once**, before implementation.

### 7. Implementation readiness check
Classify the work `Ready`, `Ready with accepted assumptions`, or `Blocked`. Blocked means implementing would require inventing assets, brand choices, copy, behavior, or token changes without permission — stop and ask.

### 8. Produce the implementation brief
A screen-specific, executable brief: files to change, components/tokens to reuse, new components (justified), asset requirements, adaptive behavior, accessibility, and verification criteria — plus the resolved risk ledger.

### 9. Implement from the brief
Edit the smallest relevant files, follow local patterns, and use project tokens and components even when the source contains raw values. Mark any user-approved approximations.

### 10. Verify against the source
Render **your build**, capture it at the source's dimensions and theme, and complete the element × property delta table for every element — including regions you did not edit. Reconcile every risk. Fix major mismatches and re-compare. If rendering is impossible, surface that as an explicit limitation rather than silently claiming a match.
