# Platforms

A cheat sheet per stack. The full notes are in [`platform-notes.md`](../visual-implementation/references/platform-notes.md); load the relevant section once you detect the target stack, and always prefer local project conventions over these defaults.

## Flutter
- Prefer existing widgets, `ThemeData`, `TextTheme`, `ColorScheme`, spacing helpers, and asset wrappers.
- Avoid raw `SizedBox`, `EdgeInsets.all(n)`, raw `Color(0x…)`, and raw `TextStyle` when a token exists.
- **Text-fill gradient:** `ShaderMask` with `LinearGradient(...).createShader(bounds)` or a `Paint()..shader`. Use a transparent end stop for fades.

## Android — Jetpack Compose
- Prefer existing composables, `MaterialTheme`, project token wrappers, typography roles, and icon/image abstractions.
- **A `box-shadow` is not an elevation dp.** Reproduce the spec with `Modifier.shadow(elevation, shape, spotColor, ambientColor)`, a `drawBehind` blur, or a project helper — don't approximate `0 4 8 #000/5%` as "≈2dp".
- **Text-fill gradient:** `TextStyle(brush = …)` on a `Text`, or `SpanStyle(brush = …)` for one word. Prefer a `Color.Transparent` terminal stop over a surface color.

## iOS — SwiftUI
- Prefer design tokens, `Color` assets, `Font` styles, reusable views, and asset catalog entries.
- **Shadow mapping:** `.shadow(color:radius:x:y:)` has no spread — reproduce it with an inset/background layer or flag it.
- **Text-fill gradient:** `Text(…).foregroundStyle(LinearGradient(…))`, or `.overlay(gradient).mask(Text(…))`. Use a `.clear` terminal stop.

## iOS — UIKit
- Prefer existing view classes, style helpers, asset catalogs, and Auto Layout conventions.
- **Text-fill gradient:** mask a `CAGradientLayer` with the label's rendered text.

## Kotlin Multiplatform / Compose Multiplatform
- Decide whether the screen belongs in shared code, platform-specific code, or an `expect/actual` split.
- Prefer shared design-system tokens and composables when the visual should be consistent across platforms; keep platform-specific insets, resources, and navigation in the established layer.
- A shared text brush lives in common Compose — keep it in the shared text style, not per platform.

## Extending a shared component additively (all stacks)
The safe extension is a **trailing optional parameter whose default reproduces current output**, appended so no call site re-binds positionally — e.g. a Compose `(@Composable () -> Unit)? = null` slot, a SwiftUI `@ViewBuilder` defaulting to `EmptyView()`, a Flutter `Widget? footer` defaulting to null. Changing an existing default or making a parameter required is *behavioral*, not additive.
