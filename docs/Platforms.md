# Platforms

A cheat sheet per stack. The full notes are in [`platform-notes.md`](../visual-implementation/references/platform-notes.md); load the relevant section once you detect the target stack, and always prefer local project conventions over these defaults.

## Flutter
- Prefer existing widgets, `ThemeData`, `TextTheme`, `ColorScheme`, spacing helpers, and asset wrappers.
- Avoid raw `SizedBox`, `EdgeInsets.all(n)`, raw `Color(0x…)`, and raw `TextStyle` when a token exists.
- **Text-fill gradient:** `ShaderMask` with `LinearGradient(...).createShader(bounds)` or a `Paint()..shader`. Use a transparent end stop for fades.
- **Desktop:** run the real desktop target (`macos`, `windows`, or `linux`), set a deterministic window size, and verify hover, pointer, scrollbar, and min-size behavior.
- **Web:** run the browser target and capture at exact viewport sizes; `flutter screenshot` is not the web truth.

## Android — Jetpack Compose
- Prefer existing composables, `MaterialTheme`, project token wrappers, typography roles, and icon/image abstractions.
- **A `box-shadow` is not an elevation dp.** Reproduce the spec with `Modifier.shadow(elevation, shape, spotColor, ambientColor)`, a `drawBehind` blur, or a project helper — don't approximate `0 4 8 #000/5%` as "≈2dp".
- **Text-fill gradient:** `TextStyle(brush = …)` on a `Text`, or `SpanStyle(brush = …)` for one word. Prefer a `Color.Transparent` terminal stop over a surface color.
- **Wide Android:** tablets, foldables, and Chrome OS are adaptive Android Compose targets; route behavior through `WindowSizeClass` and project pane/list/detail primitives.
- **Pointer Android:** hover and cursor affordances can exist on Chrome OS or pointer-enabled surfaces; keep touch targets unless the target density says otherwise.

## iOS — SwiftUI
- Prefer design tokens, `Color` assets, `Font` styles, reusable views, and asset catalog entries.
- **Shadow mapping:** `.shadow(color:radius:x:y:)` has no spread — reproduce it with an inset/background layer or flag it.
- **Text-fill gradient:** `Text(…).foregroundStyle(LinearGradient(…))`, or `.overlay(gradient).mask(Text(…))`. Use a `.clear` terminal stop.
- **macOS:** name native macOS vs Catalyst, set window sizing at the root, and verify hover, cursor, keyboard focus, and focus rings as visible design surface.
- **Capture:** use the macOS destination and window capture for macOS; previews are still useful for isolated components.

## iOS — UIKit
- Prefer existing view classes, style helpers, asset catalogs, and Auto Layout conventions.
- **Text-fill gradient:** mask a `CAGradientLayer` with the label's rendered text.

## Kotlin Multiplatform / Compose Multiplatform
- Decide whether the screen belongs in shared code, platform-specific code, or an `expect/actual` split.
- Prefer shared design-system tokens and composables when the visual should be consistent across platforms; keep platform-specific insets, resources, and navigation in the established layer.
- A shared text brush lives in common Compose — keep it in the shared text style, not per platform.
- **Desktop JVM:** the `Window` owns the verification size; run the desktop target or an offscreen `ImageComposeScene` capture at that exact size.
- **Web/wasm:** verify in a browser and capture with a headless viewport; treat it like a browser target, not an Android screenshot.

## Wide viewports (desktop & web)
One frame is one width: gate hover/cursor/focus, scrollbar policy, min/max widths, max-content width, and breakpoints; verify at the design width plus narrow and wide stress widths.

## Computed-layout dumps
When the platform exposes layout numbers, compare computed gaps, insets, and estimated values directly against token-mapped expectations; the dump complements the rendered capture.

## Extending a shared component additively (all stacks)
The safe extension is a **trailing optional parameter whose default reproduces current output**, appended so no call site re-binds positionally — e.g. a Compose `(@Composable () -> Unit)? = null` slot, a SwiftUI `@ViewBuilder` defaulting to `EmptyView()`, a Flutter `Widget? footer` defaulting to null. Changing an existing default or making a parameter required is *behavioral*, not additive.
