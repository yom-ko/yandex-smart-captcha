<!-- GENERATED FILE. DO NOT EDIT MANUALLY! Edit source in .agents/ and run build-agent-context.sh -->

# Project overview

This repository is a Flutter package that wraps the Yandex SmartCaptcha Web widget in a mobile WebView. The public API is intentionally small and centered around a single widget: `YandexSmartCaptcha`.

The package is not a full app; it is a reusable library consumed by apps via `package:yandex_smart_captcha`. Most implementation work happens inside the `lib/` tree, while `example/` provides a sample app and integration tests.

## Architecture

- `lib/yandex_smart_captcha.dart`
  - Public package entrypoint.
  - Re-exports the supported API surface.
- `lib/src/captcha_config.dart`
  - Immutable configuration object for the underlying Web SmartCaptcha widget.
  - Keeps runtime flags aligned with the JS options (`sitekey`, `hl`, `test`, `invisible`, etc.).
- `lib/src/yandex_smart_captcha.dart`
  - Main `StatefulWidget` implementation.
  - Creates the `InAppWebView` and bridges JS callbacks to Dart callbacks.
  - Owns `CaptchaController` lifecycle handling.
- `lib/src/web_smart_captcha.dart`
  - Builds the HTML/JS payload injected into the WebView.
  - Contains the Yandex SmartCaptcha script loader and the JavaScript-to-Dart bridge.
- `lib/src/captcha_event.dart`
  - Defines the event names used between JavaScript and Dart.
- `lib/src/captcha_language.dart`, `lib/src/dpn_badge_position.dart`
  - Strongly typed enums for configuration values.

The runtime flow is:

1. `YandexSmartCaptcha` creates a `WebSmartCaptcha` HTML document.
2. The generated page loads the Yandex script from `smartcaptcha.cloud.yandex.ru`.
3. The JS widget emits events via `window.flutter_inappwebview.callHandler(...)`.
4. Dart listens for the handler calls and invokes the widget callbacks (`onCaptchaReady`, `onChallengeSolved`, etc.).
5. `CaptchaController` calls into the live WebView with `evaluateJavascript` for `execute`, `reset`, and `destroy`.

## Important directories

- `lib/` — package implementation
- `lib/src/` — core logic and widget internals
- `test/` — unit/widget tests for config generation, WebView behavior, and event callbacks
- `test/mocks/` — fake WebView platform used in tests
- `example/` — sample app and integration tests demonstrating usage
- `assets/` — screenshots and artwork for the package
- `analysis_options.yaml` — lint configuration
- `pubspec.yaml` — package metadata and dependencies

## Build and test commands

Use the standard Flutter workflow for this package:

```bash
flutter pub get
flutter test
flutter analyze
```

Useful formatting command:

```bash
dart format lib test example
```

For the sample app:

```bash
cd example
flutter test
flutter run
```

The repository currently validates with `flutter test --reporter compact`.

## Preferred libraries and patterns

- Flutter + Dart as the primary stack.
- `flutter_inappwebview` for the underlying WebView and JS bridge.
- `flutter_test` for widget/unit tests.
- `flutter_lints` for static analysis.
- Keep public APIs immutable and strongly typed (`final class` / immutable config classes, typed enums).
- Avoid introducing browser-only APIs or direct DOM manipulation outside the generated HTML payload.

## Coding conventions

- Prefer small, focused, readable changes that fit the existing public API style.
- Keep `final` and immutable values where possible.
- Preserve the package’s public API compatibility unless a breaking change is explicitly requested.
- Keep generated HTML/JS logic in `lib/src/web_smart_captcha.dart`; do not scatter JS snippets across the package.
- Prefer typed enums and named config parameters over raw `String` flags when the package already has a typed model.
- Keep callbacks nullable and optional unless a behavior is required by design.
- When adding public functionality, update exports in `lib/yandex_smart_captcha.dart` and relevant docs/tests.
- Do not leave debug logs or temporary code in the final patch.

## Requirements for completing a change

Before closing a task, ensure all of the following are true:

1. The change matches the package’s Flutter library design and remains compatible with the existing public API.
2. The implementation preserves the WebView/JS bridge behavior (`onCaptchaReady`, `onChallengeSolved`, `onNetworkError`, controller actions, etc.).
3. Tests cover the changed behavior or an equivalent existing test remains green.
4. Formatting and linting pass for the modified codebase (`dart format` and `flutter analyze` if relevant).
5. If the change affects the public API, usage examples or documentation are updated to stay accurate.
6. The final patch is minimal and scoped to the requested feature or fix.

## Change checklist for future work

- Confirm whether the task is a library change or a sample-app change.
- Read the relevant implementation file in `lib/src/` before editing.
- Update tests in `test/` for new behavior or regressions.
- Check if `lib/yandex_smart_captcha.dart` re-exports need adjustment.
- Run the smallest relevant validation command (`flutter test` for the package, or a focused test subset if available).
- Verify the change does not break the JS bridge or WebView lifecycle semantics.
