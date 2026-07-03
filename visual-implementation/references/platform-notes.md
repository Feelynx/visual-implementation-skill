# Platform Notes

Load the relevant section after detecting the target stack, **plus the cross-cutting sections after the per-stack ones** ("Wide viewports…", "Computed-layout dump…", "Full-bleed scroller…", "Extending a shared component additively…", and the Compose sheet patterns) — they apply on top of every stack and are the ones a stack-only read misses. Prefer local project conventions over these defaults.

## Flutter

- Prefer existing widgets, theme extensions, design tokens, `TextTheme`, `ColorScheme`, spacing helpers, and asset wrappers.
- Avoid raw `SizedBox(width/height: n)`, `EdgeInsets.all(n)`, raw `Color(0x...)`, and raw `TextStyle` when a project token exists.
- Use adaptive layout primitives already present in the app. Otherwise prefer constraints, `SafeArea`, `LayoutBuilder`, `Flexible`, `Expanded`, scrollables, and text scaling-aware layout.
- Check `pubspec.yaml`, `lib/theme`, `lib/core`, `lib/design_system`, `lib/shared`, generated localization, asset folders, and reusable screen examples.
- Verify with `dart format`, `flutter analyze`, relevant widget tests, and screenshots/previews when available.
- **Text fill gradient:** `ShaderMask` with `LinearGradient(...).createShader(bounds)`, or `TextStyle(foreground: Paint()..shader = …)`; transparent end stop for fades; do not approximate with one `color:`.
- **Desktop target is a real target, not a resized phone.** Run `flutter run -d macos|windows|linux`; set deterministic verification size and min size from the app/window layer before comparing.
- **Flutter web capture goes through the browser.** Run `flutter run -d chrome`; capture with headless Chrome `--screenshot --window-size=<w>,<h>` at the exact logical frame size, not a hand-resized browser.
- **Hover and pointer states exist.** Inventory `MouseRegion`, `WidgetStateProperty` hover styles, `SystemMouseCursors`, and `FocusableActionDetector`; `PointerInterceptor` matters only when web platform views (`HtmlElementView`, maps) swallow overlay clicks.
- **Desktop scrollbars can move layout.** `Scrollbar` / `ScrollbarTheme` may be visible by default on desktop; decide overlay vs layout-affecting before measuring full-bleed peeks.
- **Capture path changes by target.** `flutter screenshot` is for attached devices and is not the web truth; desktop golden/widget tests can run headless and assert layout without a launched window.

## Android Kotlin / Jetpack Compose

- Prefer existing composables, `MaterialTheme`, project theme wrappers, spacing/shape tokens, typography roles, and icon/image abstractions.
- Avoid raw `dp`, raw colors, and raw text styles when project tokens exist. Small literal values are acceptable only for intrinsic platform constraints and must be justified.
- Use `Modifier` chains consistent with the project. Respect insets, navigation bars, status bars, dynamic type, content descriptions, and touch target guidance.
- Check modules such as `designsystem`, `ui`, `core-ui`, `theme`, `components`, `common`, and feature screen examples.
- Verify with formatting, static analysis, Compose previews, screenshot tests, unit tests, or Gradle build tasks available in the repo.
- **A box-shadow is not an elevation dp.** A designer `box-shadow` (offset, blur, spread, color%) does not map to one Material `elevation` / `Modifier.shadow(elevation)`: Material derives blur from a single dp with a fixed light direction and ignores explicit offset, spread, and color. Do not approximate `0 4 8 #000/5%` as "≈2dp." Reproduce the spec with `Modifier.shadow(elevation, shape, spotColor, ambientColor)` tuned to it, a `drawBehind` blur, or a project shadow helper — or flag it as an approximation, confirm at the decision gate, and verify visually.
- **Text fill gradient → a `Brush`, not a colour token.** Apply `TextStyle(brush = …)` to a whole `Text`, or `SpanStyle(brush = …)` inside an `AnnotatedString` for one word; build the brush from the source's real direction and stops. Prefer a `Color.Transparent` terminal stop over a surface colour like `Color.White` — a transparent fade survives any surface and theme. Never flatten to one `color =`.
- **A wrapper scaffold may already consume its own `paddingValues` — don't re-apply them.** A project `DefaultXScaffoldScreen` frequently wraps M3 `Scaffold`, applies `.padding(paddingValues)` to its inner content Box, AND passes the same `paddingValues` into the content lambda "for convenience." If your content then also applies `.padding(padding…)`, the top/bottom insets apply twice and the whole screen drops toward mid-screen — a mysterious ~2× top offset that reads like the content is centred. Before consuming a scaffold-provided `paddingValues`, READ the wrapper's source: if it already pads its content, ignore the passed value (`Modifier.fillMaxSize()`), and steer edge-to-edge bleed through the wrapper's `contentWindowInsets` (e.g. `WindowInsets.safeDrawing.only(Horizontal + Top)` so a map reaches the bottom) instead of re-padding. Symptom to recognise instantly: an empty/results/prompt state sitting at ~40–50% instead of just under the top bar.
- **Wide Android is still Android, not CMP desktop.** Tablets, foldables, and Chrome OS use adaptive Android Compose: route width behavior through `WindowSizeClass` and the project's pane/list/detail primitives.
- **Hover exists on Android surfaces with pointers.** Use `Modifier.hoverable`, `MutableInteractionSource`, and `PointerIcon` where the design has hover or cursor affordance; keep touch targets unless the target density says otherwise.
- **Chrome OS verification needs its own width.** Capture a tablet/foldable/Chrome OS size when the source is wide; a phone emulator screenshot does not prove the expanded layout.

## iOS SwiftUI

- Prefer existing design tokens, `Color` assets, `Font` styles, view modifiers, reusable views, and asset catalog entries.
- Avoid fixed frames as layout strategy. Use stacks, alignment guides, `Spacer`, `GeometryReader` only when justified, safe-area handling, Dynamic Type, and environment values.
- Keep assets in asset catalogs and do not invent missing symbols. Use SF Symbols only when they are semantically correct or the user approves substitution.
- Check `DesignSystem`, `Theme`, `Components`, `Resources`, `Assets.xcassets`, localization, and existing screen patterns.
- Verify with SwiftFormat/SwiftLint if present, previews, unit/UI tests, simulator screenshots, or `xcodebuild` when available.
- **Shadow mapping:** `.shadow(color:radius:x:y:)` honors color, offset, and blur (`radius ≈ blur / 2`) but has no spread — reproduce spread with an inset/background layer or flag it. Do not reduce a full box-shadow to a default `.shadow(radius:)`.
- **Text fill gradient:** `Text(…).foregroundStyle(LinearGradient(…))`, or `.overlay(gradient).mask(Text(…))` for effects it cannot express. Use a `.clear` terminal stop, not a surface colour, so the fade survives any theme; do not reduce it to `.foregroundColor`.
- **macOS native and Catalyst are different targets.** SwiftUI on macOS uses AppKit windowing; Catalyst keeps UIKit semantics inside a Mac shell — name which one the design targets.
- **Hover and cursor are first-class.** Use `.onHover`, `.pointerStyle` where available, or `NSCursor` bridging for cursor changes; static frames hide these states.
- **Window sizing is part of the spec.** Set `.frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:)` at the window/root level so verification opens at the design size and refuses impossible shrink states.
- **Keyboard focus is visible chrome.** Focus rings, default buttons, tab order, and sidebar/list focus states are design surface on macOS, not accessibility extras.
- **Verify as macOS when targeting macOS.** Use `xcodebuild -destination 'platform=macOS'`; capture windows with `screencapture -l <windowid>` after finding the real window id. Previews still work for isolated components.

## iOS UIKit

- Prefer existing view classes, style helpers, asset catalogs, typography helpers, and Auto Layout conventions.
- Avoid manual frames unless the project intentionally uses them. Use constraints, layout guides, safe areas, Dynamic Type, and reusable style methods.
- Check storyboard/xib usage before assuming code-only UI.
- Verify with existing build/test/screenshot workflows.
- **Text fill gradient:** mask a `CAGradientLayer` with the label's rendered text; do not collapse it to one `textColor`.

## Kotlin Multiplatform / Compose Multiplatform

- Determine whether the target screen belongs in shared Compose code, Android-specific code, iOS-specific code, or an expect/actual split.
- Prefer shared design-system tokens and composables when the visual should be consistent across platforms.
- Keep platform-specific insets, resources, fonts, and navigation behavior in the established project layer.
- Avoid adding Android-only assumptions to common code.
- Verify common code plus at least the relevant platform target when commands are available.
- A shared text brush lives in common Compose exactly as the Compose case above — keep it in the shared design-system text style, not per platform.
- **Compile the actual platform target to validate bindings, even when the full app can't run on this host.** `./gradlew :<module>:compileKotlinIosSimulatorArm64` (or the XCFramework task) type-checks Kotlin/Native UIKit / Foundation / CoreLocation bindings without a Mac app build. They do NOT map 1:1 to the Obj-C headers — a property such as `popoverPresentationController` may be absent from the binding, and `keyWindow` is deprecated-but-present. Hold platform delegates/callbacks in a strong property (`CLLocationManagerDelegate`, the presenting VC for `UIActivityViewController`) or K/N collects them before the async callback fires. Compiling proves the bindings resolve; runtime behavior still needs a device/simulator, so flag it as such.
- **Desktop JVM target owns its window.** Use `Window(state = rememberWindowState(size = DpSize(...)))` or the project wrapper; run with `./gradlew :composeApp:run` and capture at that exact size. The exact size is for *capture*, not a license for a fixed window — resizability, min-width, and breakpoints are gate items ("Wide viewports" below).
- **Desktop hover and cursor are explicit Compose behavior.** Use `hoverable`, `MutableInteractionSource`, and `PointerIcon`; a clickable desktop control without a cursor affordance is incomplete.
- **Desktop scrollbars are not automatic.** A design showing a scrollbar means adding `VerticalScrollbar` / `HorizontalScrollbar` with `rememberScrollbarAdapter`; do not expect `LazyColumn` to paint one.
- **Offscreen capture can be deterministic.** `ImageComposeScene` can render a composable at a fixed size without a visible JVM window; use it for layout screenshots when the project has no harness.
- **Web target is browser-verified.** wasm/js Compose targets exist; run the project target and capture with a headless browser at the exact viewport, then compare like Flutter web.

## Wide viewports: desktop & web targets (all stacks)

- **One frame is one width.** A desktop/web design must state breakpoint behavior; a single-width frame hides it, so the resize question goes to the decision gate. Verify at the design width plus one narrow and one wide stress width. "It's one fixed window size / don't overthink it" is pressure, not a decision — desktop windows resize by default, so fixed-vs-resizable, min-width, and the multi-width verification plan still reach the gate as explicit questions.
- **Do not letterbox by accident.** A phone layout centered in a 1440px window is a defect unless the design shows exactly that; find the max-content-width + centering pattern and map it to the project's container primitive.
- **Hover, focus-visible, and cursor affordances exist.** Inventory them per interactive element: hover style, pointer cursor, focus ring. Route unknowns to the gate; keyboard traversal is part of the design, not an extra.
- **Scrollbars occupy layout on desktop.** Decide overlay vs layout-affecting before measuring; classic Windows/Linux scrollbars change full-bleed scroller peek math.
- **Pointer precision does not shrink targets automatically.** 44pt/48dp touch targets stay unless the project has an established desktop density; mixed touch+mouse means keep touch targets unless the design says otherwise.
- **Text weight verdicts come from tokens.** Desktop subpixel AA and hinting shift perceived weight against mobile frames; do not correct a token-mapped weight from cross-platform pixels.
- **Density is target-specific.** Desktop is commonly @1x/@2x while mobile frames are @2x/@3x; recalibrate scale per target (`visual-analysis.md` §3), never reuse the mobile scale factor.

## Computed-layout dump — numbers to numbers (all stacks)

When the platform can dump computed layout, compare computed paddings/sizes against token-mapped expected values directly: pixels lie (AA, shadows, scaling), the layout tree does not. The dump complements, never replaces, the rendered comparison; a correct tree can still paint wrong.
- **Flutter:** use `debugDumpRenderTree()` or the DevTools inspector; widget tests can assert `tester.getSize()` and `tester.getTopLeft()` against token values.
- **Compose / Compose Multiplatform:** in Compose tests, use `onRoot().printToLog()` and bounds assertions such as `getBoundsInRoot()` / `assertWidthIsEqualTo`; when tests are unavailable, log measured values with `Modifier.onGloballyPositioned`.
- **SwiftUI / UIKit:** use Xcode's view-hierarchy debugger; at a UIKit breakpoint, `po view.recursiveDescription`; in XCUITest, assert `frame` values for critical elements.
- **Web targets:** use DevTools computed box model; in headless browser runs, query `getBoundingClientRect()` through CDP and compare the returned numbers.
- **Check the numbers that matter.** Gaps/insets from the spacing inventory and every delta-table value scored `estimate` are worth dumping; a numeric dump upgrades confidence to measured.

## Full-bleed scroller within a padded screen (all stacks)

A horizontal carousel inside a laterally-padded screen does NOT inherit the page gutter — it runs edge-to-edge with its OWN start/end inset while every sibling component keeps its lateral padding. A scroller that inherits the page padding clips its cards at the content edge and kills the peek.
- **Compose / Compose Multiplatform:** a `LazyColumn` clips its items to the content area, so a negative-offset / negative-padding modifier to bleed one item past the parent `contentPadding` does NOT escape the clip. Deterministic fix: remove the list's horizontal `contentPadding`, give each non-carousel item its own lateral padding, and let the `LazyRow` span full width with `contentPadding = PaddingValues(horizontal = pageGutter)`. Give every fixed-width child `maxLines = 1` + `TextOverflow.Ellipsis` so a long title cannot wrap.
- **Flutter:** the vertical scrollable carries no horizontal padding for the carousel row; the horizontal `ListView(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: pageGutter))` owns its inset and other rows pad themselves. Fixed-width children use `maxLines: 1, overflow: TextOverflow.ellipsis`.
- **SwiftUI:** the outer container leaves the carousel row un-padded; the inner horizontal `ScrollView` pads its content leading/trailing. Fixed-width children use `.lineLimit(1)`.

## Extending a shared component additively (all stacks)

The safe extension is a **trailing optional parameter whose default reproduces current output**, appended so no call site re-binds positionally.
- **Compose / Compose Multiplatform:** a `(@Composable () -> Unit)?` slot defaulting to `null` (render nothing when null), a `@Composable () -> Unit` slot defaulting to `{}`, or a value defaulting to the current constant.
- **SwiftUI:** an extra `@ViewBuilder` closure or value defaulting to the present layout (e.g. `footer: () -> some View = { EmptyView() }`).
- **Flutter:** a new optional named parameter (`Widget? footer`) defaulting to null/no-op.

Changing an existing default, token, shape, or a modifier every caller inherits — or making an optional parameter required — is behavioral, not additive: revert and wrap screen-locally. Litmus: if any current caller's rendered output moves, it is behavioral. Confirm no existing slot or overload already covers the need before adding a new one — a new optional param is permanent shared surface area.

The default must reproduce current output **exactly**, not merely be optional, and the wiring must reach every variant of the symbol:
- **True no-op default, not a plausible-looking one.** An icon-tint param defaults to the current content colour (Compose `LocalContentColor.current`), NOT `Color.Unspecified` — the latter drops tinting and repaints every existing caller. The default is whatever the code renders *today*, read from the code, not the neutral-looking value.
- **Apply to every overload/variant.** A shared component often has several overloads (value: `String` / `TextFieldValue`, with/without chevron). A param declared on one overload but left unwired in a sibling overload's render is a silent no-op that ships a lie. After adding, grep every overload and confirm the new param actually reaches the pixels in each — compiling clean is not the same as being wired.

## Map with a draggable results bottom sheet (Compose)

A "maps app" screen — full map, a search field, and a results sheet that drags up over the map — is NOT one `BottomSheetScaffold` with the search in its `topBar`: at full expansion that sheet covers the search too. Structure it so the sheet lives only *below* the fixed header:
- A `Column`: the app bar + search field are fixed children at the top; the map + sheet go in a `Box(Modifier.weight(1f))` below them, so the sheet expands only within that box, never over the search.
- Inside the box, use the raw `BottomSheetScaffold` (not the project wrapper, when you need `sheetShape`) with the map as `content` (fillMaxSize, behind) and the results as `sheetContent`.
- For the expanded state to reach the top of the box, the sheet content must fill height — a `LazyColumn(Modifier.fillMaxSize())`, NOT a `verticalScroll` `Column`: `verticalScroll` + `fillMaxSize` conflict (scroll relaxes height to infinity, so `fillMaxSize` can't fill).
- Read `scaffoldState.bottomSheetState.targetValue == SheetValue.Expanded` to make the sheet flush when expanded: drop the drag handle and the top-corner radius so it reads like the plain list; restore them when partial.
- **State-dependent content inside the sheet.** A message state (no-results) shown in the sheet must be **top-anchored and its peek measured**, not centred in `fillMaxSize`: a centred message reads full-screen when the sheet is expanded but is invisible at the collapsed peek (the peek shows the top of the sheet; the centred content is below the fold, so you see only the drag handle over blank space). Top-anchor the message and derive the peek height from its measured block so it is visible collapsed and still reads full when expanded — one layout must satisfy every sheet state.

## Size a reveal from measured content, not a magic number (Compose)

When the design says "the collapsed sheet shows exactly one card" (or a peek reveals a specific element), compute the size at runtime instead of hardcoding a dp. Measure the pieces with `Modifier.onGloballyPositioned { it.size.height }` (drag handle + header + first item; or the whole no-results block), sum them, and drive `sheetPeekHeight` from a state you set in those callbacks — with a small first-frame fallback until measured. Measuring intrinsic `size.height` is stable and does not feed back through the sheet position: the internal distance between two elements inside the same sheet is invariant to the sheet's offset. A fixed peek breaks on the first longer string, larger font scale, or denser card.
