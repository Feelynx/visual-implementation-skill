# FAQ

### When should the skill activate?
Whenever you implement or review a mobile, desktop, or web UI from an external visual source — a PNG, SVG, Figma export, screenshot, or mockup — especially when fidelity depends on missing assets, unknown fonts, ambiguous scale, hover states, wide viewports, or mapping the design to a design system.

### Does it support desktop and web?
Yes, for desktop/web targets of the same stacks: Flutter desktop/web, Compose Multiplatform Desktop and web/wasm, and macOS SwiftUI. It is not a React/HTML skill. Wide-viewport behavior is gated and verified at multiple widths.

### Does it work without a design system?
It is strongest with one, because it maps to tokens and components. Without one it still applies the workflow, but more values fall back to measured, declared-uncertainty estimates — and it will flag the absence as a risk.

### Why does it ask for Figma tokens instead of measuring?
Because a stated token gives size, weight, and line-height exactly, while a pixel measurement is biased — character advance width is font-specific, so a real 16sp run can measure like 14sp. The token is ground truth; the ruler is a fallback. And when the session has a programmatic Figma connection (MCP server or API), the skill fetches the tokens itself before asking you at all.

### Why won't it just trust the existing code?
A "1:1" claim — in a commit message, a comment, or the current implementation — is a claim to verify, not evidence. The skill re-derives every visible property from the source and proves the result by rendering.

### Why is it strict about new components?
A reusable structure rebuilt inline becomes N copies to maintain and drift. The skill routes a genuinely new, reusable component to the design system under an agreed name instead of leaving a screen-private helper behind.

### It says it "can't render" — is that a failure?
No — it is honesty. If the project has no preview/simulator/screenshot path, the skill says so rather than claiming a visual match it cannot prove. It will try to render the smallest unit that proves the screen (an isolated sheet, row, or card) before giving up.

### Can it overwrite an icon I provide?
Only carefully. If the target name already exists, it checks who references it: identical content → reuse; only this screen → overwrite after you confirm; referenced elsewhere → it asks whether to overwrite globally or install under a new name.

### Which runtimes does it support?
Any agent runtime that loads folder-based skills. See [Installation](Installation.md) for Claude Code, Codex, and OpenCode paths; other runtimes follow the same copy-the-folder pattern.

### How do I keep it lean when contributing?
Prefer tightening an existing rule to adding a new one, and ground every change in a concrete failure it prevents. The skill's strength is precision, not length.
