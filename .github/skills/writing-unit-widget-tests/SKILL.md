---
name: writing-unit-widget-tests
description: >
  Write and maintain focused Dart and Flutter tests for this Yandex SmartCaptcha
  package. Use for plain unit tests, generated HTML/JavaScript assertions,
  native WebView bridge tests, and browser adapter tests. Do not use as the primary guide for
  golden tests, native integration tests, or end-to-end tests.
---

# Writing unit and widget tests

Use this skill when creating or editing tests for the `yandex_smart_captcha` Flutter package. Tests should protect three layers: the public Flutter API (`YandexSmartCaptcha` / `CaptchaConfig`), the `flutter_inappwebview` bridge and handlers, and generated HTML/JavaScript. Prefer focused regression and contract tests over broad implementation-detail coverage.

## Test layout

Mirror `lib/` under `test/` using the `_test.dart` suffix:

| Production code                                   | Test file                                               |
| ------------------------------------------------- | ------------------------------------------------------- |
| `lib/src/captcha_config.dart`                     | `test/src/captcha_config_test.dart`                     |
| `lib/src/captcha_event.dart`                      | `test/src/captcha_event_test.dart`                      |
| `lib/src/captcha_language.dart`                   | `test/src/captcha_language_test.dart`                   |
| `lib/src/dpn_badge_position.dart`                 | `test/src/dpn_badge_position_test.dart`                 |
| `lib/src/native/smart_captcha_html.dart`          | `test/src/native/smart_captcha_html_test.dart`          |
| `lib/src/yandex_smart_captcha.dart`               | `test/yandex_smart_captcha_test.dart`                   |
| `lib/src/native/captcha_adapter_controller.dart`  | `test/src/native/captcha_adapter_controller_test.dart`  |
| `lib/src/native/captcha_adapter_widget.dart`      | `test/src/native/captcha_adapter_widget_test.dart`      |
| `lib/src/web/captcha_adapter_controller_web.dart` | `test/src/web/captcha_adapter_controller_web_test.dart` |
| `lib/src/web/captcha_script_loader_web.dart`      | `test/src/web/captcha_script_loader_web_test.dart`      |
| `lib/src/captcha_platform_controller.dart`        | `test/src/captcha_platform_controller_test.dart`        |

Put reusable WebView test infrastructure in `test/mocks/`, especially [`in_app_webview_platform_fake.dart`](../../../test/mocks/in_app_webview_platform_fake.dart).

Do not add test-only hooks, flags, or APIs to production code. Do not make real network calls in unit or widget tests.

The file mapping above describes the current repository layout; follow the actual project structure if files are moved or split during a refactor.

## Workflow

1. Identify the production code affected by the change and the corresponding test file.
2. Read the relevant implementation, `CaptchaEvent` definitions, and the fake WebView platform before writing assertions.
3. Choose unit and/or widget tests based on the behavior being exercised (see below).
4. Add the smallest test that demonstrates the required behavior or regression.
5. Use the fake WebView platform for native bridge handlers and evaluated JavaScript. Use typed JavaScript interop fakes and DOM elements for browser adapter tests.
6. Run the smallest affected test file while iterating.
7. Run `dart format` on changed Dart files only.
8. Before finishing a change that affects the public API, WebView bridge, or generated HTML/JavaScript, run the full `flutter test` suite and `flutter analyze`.
9. Review the diff and remove brittle snapshots, duplicated expectations, timing assumptions, debug code, and unrelated changes.

Do not replace the global platform instance inside individual tests unless the test explicitly needs to do so and restores the previous instance afterward. Reuse or extend the existing `pumpCaptcha()` helper in [`test/yandex_smart_captcha_test.dart`](../../../test/yandex_smart_captcha_test.dart) instead of duplicating `pumpWidget` setup. Browser-only test files should use `@TestOn('browser')` and native WebView suites should use `@TestOn('vm')` at the library level.

## Choosing the test type

Use `test()` when the behavior does not require Flutter bindings, widget lifecycle, `BuildContext`, or platform APIs. Examples include enum names and IDs, `CaptchaConfig` defaults and value preservation, `SmartCaptchaHTML` serialization, and other pure transformations.

Use `testWidgets()` when the behavior requires Flutter bindings, widget lifecycle, `BuildContext`, `InAppWebView`, controller attachment, DOM setup, or JavaScript-triggered callbacks.

The Web adapter's `captcha_adapter_web.dart` contains only external JavaScript interop declarations, so test its observable use through the browser controller contract rather than adding a declaration-only test. The Web `captcha_adapter_widget_web.dart` wrapper delegates to Flutter's `HtmlElementView` – its platform-view lifecycle is covered by Flutter's framework and is not deterministic in the headless package test harness.

Import `package:flutter_test/flutter_test.dart` for both pure Dart and widget tests.

Register the fake WebView platform once per test file that exercises the platform layer:

```dart
setUpAll(() {
  InAppWebViewPlatform.instance = InAppWebViewPlatformFake();
});
```

Run the native/unit suite with `flutter test`. Run browser adapter tests explicitly with `flutter test --platform chrome`; the default VM runner skips files marked `@TestOn('browser')`.

## Testing contracts

Focus assertions on externally observable behavior and stable contracts rather than incidental implementation structure.

### Generated HTML and JavaScript

Test generated output through the package's supported rendering or serialization API, such as `SmartCaptchaHTML.data`. Do not duplicate production HTML or JavaScript in test-only APIs, and never execute remote Yandex JavaScript in tests.

When generated HTML/JavaScript changes, add or update focused assertions for the affected contract. Depending on the change, this may include:

* document structure and captcha container;
* viewport values;
* script URL;
* widget options (`sitekey`, `hl`, `test`, `invisible`, `shieldPosition`, `hideShield`, `webview`);
* `captchaReady`, `challengeSolved`, and error wiring;
* subscribed event IDs and handler names;
* missing-script protection running before `smartCaptcha.render`.

Prefer narrow assertions such as `contains()`, decoded event JSON, or parsed values over whole-HTML snapshots. Do not assert incidental whitespace, ordering, or formatting unless those details are themselves part of the contract.

### WebView bridge

Treat JavaScript event names, handler names, serialized widget options, and callback payloads as bridge contracts when they are externally observable. Test the relevant side of the boundary when behavior changes; avoid duplicating coverage for internal refactors that preserve the same contract.

For each added or behaviorally changed `CaptchaEvent`, cover the relevant parts of the bridge contract:

1. Generated HTML subscribes to the expected native SmartCaptcha event.
2. The expected JavaScript handler is registered by `YandexSmartCaptcha`.
3. Emitting the event through `PlatformInAppWebViewControllerFake.emit()` invokes the matching Dart callback.
4. Payload conversion is explicit, including nullable payloads where applicable.
5. Optional callbacks remain optional and do not throw when omitted.

```dart
webViewController.emit(CaptchaEvent.challengeSolved.name, ['token']);
expect(receivedToken, equals('token'));
```

Use explicit assertions for externally observable event names and handler names when testing the bridge contract. `CaptchaEvent` may be used to avoid unnecessary duplication for structural coverage, but do not derive both the expected value and the implementation behavior from the same enum when doing so would make the test tautological.

For `challengeSolved`, cover the relevant payload cases: a real token, the string `'null'` mapping to `null`, and no argument mapping to `null`.

### Controller lifecycle

For `CaptchaController`, cover the behavior relevant to the change:

* `execute`, `reset`, and `destroy` are safe before WebView attachment;
* each action performs the expected SmartCaptcha operation;
* replacing a controller detaches the old controller and attaches the new one;
* disposing the widget detaches its controller;
* actions after replacement do not execute against the old WebView.

Inspect `evaluatedJavascriptSources` on `PlatformInAppWebViewControllerFake` instead of relying on sleeps, arbitrary delays, logs, or timing.

Assert the semantic JavaScript operation and its arguments rather than incidental formatting or wrapper syntax, unless the exact generated source is itself part of the contract.

### Browser adapter

For browser adapter tests:

* Do not load the real Yandex script or make network requests.
* Pre-install a script element with `smartCaptchaScriptUrl` and provide a typed JavaScript fake for `smartCaptcha`.
* Verify DOM container sizing, rendered widget options, callback payload conversion, subscribed event dispatch, controller delegation, missing-API errors, and shared script reference cleanup.
* Keep browser tests deterministic and independent of the browser's actual navigation or remote challenge UI.

## Public API and configuration changes

When adding or changing a public option:

1. Test its default in `CaptchaConfig`.
2. Test a non-default value reaching the generated output or observable widget behavior.
3. Test nullable or optional behavior when applicable.
4. Update API documentation or README examples when required by the repository's documentation policy or existing public-API conventions.
5. Preserve existing API coverage unless the change intentionally alters the public contract.

For numeric viewport settings, test both the public configuration value and the clamped value reaching generated HTML. Do not duplicate production clamp logic inside the test helper.

## Regression tests

When fixing a bug, add a regression test that reproduces the externally observable failure and fails before the fix when that behavior is testable at this level. Test the intended behavior rather than encoding the exact implementation detail that caused the bug.

## Assertion hygiene

* Name tests after the behavior being verified. Include the triggering condition when it materially distinguishes the scenario.
* Use appropriate matchers such as `equals`, `same`, `isNull`, `isNotNull`, `isEmpty`, `contains`, `orderedEquals`, and `throwsA`.
* Prefer `expect(actual, equals(expected))` over relying on matcher defaults or raw boolean assertions when the expected value matters.
* Use `setUp()` and `tearDown()` for per-test mutable state.
* Use `setUpAll()` for shared one-time setup such as fake platform registration.
* Reset mutable callback state and counters per test.
* Do not use sleeps, arbitrary delays, real HTTP requests, or debug prints.
* Do not weaken a test merely to match the current implementation when the intended public behavior is clear.
* Avoid duplicating the same expectation through multiple layers unless each layer represents a distinct contract.
* Prefer deterministic assertions over timing, logs, console output, or incidental generated formatting.

## Running tests

Run commands from the package root.

During iteration, run the smallest affected test file first:

```bash
flutter test test/src/native/smart_captcha_html_test.dart
flutter test test/yandex_smart_captcha_test.dart
```

Before finishing a change that affects the public API, WebView bridge, or generated HTML/JavaScript, run:

```bash
flutter test
flutter analyze
```

Format only changed Dart files:

```bash
dart format path/to/changed_file.dart
```

## Avoid

* Moving JavaScript snippets into test-only production APIs.
* Asserting console output instead of observable callback or state behavior.
* Changing event names or controller semantics merely to make a test pass.
* Omitting regression coverage when changing the Dart-to-JavaScript bridge.
* Using a real in-app WebView or remote SmartCaptcha service in unit or widget tests.
* Snapshotting the entire generated HTML when focused assertions can verify the contract.
* Introducing timing-dependent assertions when the fake platform exposes a deterministic state or operation log.
* Deriving expected bridge values solely from the same production enum or constant used by the implementation under test.
* Testing private implementation details when a public callback, serialized value, or rendered HTML contract already covers the behavior.
