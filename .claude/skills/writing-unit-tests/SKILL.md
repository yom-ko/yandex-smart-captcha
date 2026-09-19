---
name: writing-unit-tests
description: >
  Write and maintain focused Dart and Flutter tests for this Yandex SmartCaptcha
  package. Use for plain unit tests, generated HTML/JavaScript assertions, and
  widget tests around the WebView bridge. Do not use as the primary guide for
  golden tests, native integration tests, or end-to-end tests.
---

# Writing Dart and Flutter tests

Use this skill when creating or editing tests for the `yandex_smart_captcha` Flutter package. The package is a small library, but its behavior spans three layers:

```text
YandexSmartCaptcha / CaptchaConfig
        ↕
flutter_inappwebview + handlers
        ↕
generated HTML and JavaScript
```

Tests must protect both the public Flutter API and the WebView bridge contract. Prefer focused regression tests over broad implementation-detail coverage.

## Project test layout

Mirror the `lib/` layout under `test/`:

| Production code                     | Test file                               |
| ----------------------------------- | --------------------------------------- |
| `lib/src/captcha_config.dart`       | `test/src/captcha_config_test.dart`     |
| `lib/src/captcha_event.dart`        | `test/src/captcha_event_test.dart`      |
| `lib/src/captcha_language.dart`     | `test/src/captcha_language_test.dart`   |
| `lib/src/dpn_badge_position.dart`   | `test/src/dpn_badge_position_test.dart` |
| `lib/src/web_smart_captcha.dart`    | `test/src/web_smart_captcha_test.dart`  |
| `lib/src/yandex_smart_captcha.dart` | `test/yandex_smart_captcha_test.dart`   |

Use the `_test.dart` suffix. Keep reusable WebView test infrastructure in `test/mocks/`, especially [`in_app_webview_platform_fake.dart`](../../../test/mocks/in_app_webview_platform_fake.dart).

Do not add test-only hooks, flags, or APIs to production code. Do not use real network calls in unit or widget tests.

## Choosing the test type

### Plain unit tests

Use `test()` whenever the behavior can be exercised without Flutter bindings, widget lifecycle, or platform APIs. For example:

* enum names and IDs;
* `CaptchaConfig` defaults and value preservation;
* `WebSmartCaptcha` HTML serialization;
* event lists and other pure transformations.

```dart
test('serializes invisible mode and badge settings', () {
  // ...
});
```

### Widget tests

Use `testWidgets()` when the behavior requires Flutter bindings, widget lifecycle, `BuildContext`, `InAppWebView`, controller attachment, or callbacks triggered by the widget. Use the existing fake platform instead of a native WebView:

```dart
setUpAll(() {
  InAppWebViewPlatform.instance = InAppWebViewPlatformFake();
});
```

Register the fake platform once per test file. Do not replace the global platform instance inside individual tests.

Prefer the existing `pumpCaptcha()` helper in [`test/yandex_smart_captcha_test.dart`](../../../test/yandex_smart_captcha_test.dart) or extend it when a new callback or configuration needs to be exercised. Keep test setup in helpers rather than duplicating large `pumpWidget` blocks.

## WebView bridge coverage

Every externally observable WebView bridge behavior change should be covered on both sides of the boundary: generated HTML/JavaScript and the corresponding Dart handler or callback behavior. Internal refactors that preserve the existing contract do not require redundant coverage.

### Event callbacks

For each added or changed `CaptchaEvent`, verify:

1. the generated HTML subscribes to the expected native SmartCaptcha event;
2. the JavaScript handler name is registered by `YandexSmartCaptcha`;
3. emitting the event through `PlatformInAppWebViewControllerFake.emit()`
   invokes the matching Dart callback;
4. nullable payload behavior is explicit, especially `challengeSolved`;
5. optional callbacks remain optional and do not throw when omitted.

Use the fake controller to simulate JavaScript:

```dart
webViewController.emit(CaptchaEvent.challengeSolved.name, ['token']);
expect(receivedToken, 'token');
```

For `challengeSolved`, cover at least:

* a normal token;
* the string `'null'`, which maps to Dart `null`;
* no argument, which also maps to Dart `null`.

Keep event-name expectations derived from `CaptchaEvent` where appropriate. Do not duplicate a complete event-name list unless the test explicitly checks the public contract.

Treat JavaScript event names, handler names, serialized widget options, and callback payloads as bridge contracts. Do not assert internal helper structure used to produce those contracts.

### Generated HTML and JavaScript

Keep generated HTML and JavaScript in [`lib/src/web_smart_captcha.dart`](../../../lib/src/web_smart_captcha.dart). Test the rendered output through `WebSmartCaptcha.html`; do not execute remote Yandex JavaScript in unit tests.

When changing the HTML payload, update or add assertions for the affected:

* document structure and captcha container;
* viewport values and script URL;
* widget options (`sitekey`, `hl`, `test`, `invisible`, `shieldPosition`,
  `hideShield`, `webview`);
* `captchaReady`, `challengeSolved`, and error wiring;
* subscribed event IDs and handler names;
* ordering of the missing-script guard before `smartCaptcha.render`.

Prefer stable, narrow assertions such as `contains()` or decoded event JSON. Avoid asserting the entire HTML string or incidental whitespace.

### Controller lifecycle

For `CaptchaController`, cover:

* `execute`, `reset`, and `destroy` before WebView attachment are safe;
* each action evaluates the exact expected SmartCaptcha method;
* replacing a controller detaches the old controller and attaches the new one;
* disposing the widget detaches its controller;
* actions after replacement do not execute on the old WebView.

Inspect `evaluatedJavascriptSources` on `PlatformInAppWebViewControllerFake` rather than relying on timing or logs.

## Public API and configuration coverage

When adding a public option:

1. test its default in `CaptchaConfig`;
2. test that a non-default value reaches generated HTML or widget behavior;
3. test nullable/optional behavior if applicable;
4. update API documentation and the root README when required by the package's
   public API conventions;
5. preserve existing API tests unless the change is intentionally breaking.

For numeric viewport settings, test the public config value and the clamped value passed into the generated HTML when relevant. Do not duplicate clamp logic in the test helper.

## Regression tests

When fixing a bug, add a regression test that reproduces the failure, fails before the fix, and passes after it whenever the behavior is testable at this level. Prefer reproducing the externally observable failure over encoding the exact implementation that caused it.

## Assertions and test hygiene

* Import `package:flutter_test/flutter_test.dart` for Flutter tests.
* Import `package:test/test.dart` only for tests that do not use Flutter APIs.
* Use matcher-based assertions: `equals`, `same`, `isNull`, `isNotNull`,
  `isEmpty`, `contains`, `orderedEquals`, and `throwsA` as applicable.
* Use `expect(actual, equals(expected))` rather than passing raw values as
  matchers.
* Use `setUp()` and `tearDown()` for per-test mutable state; use `setUpAll()`
  only for global platform registration.
* Keep test state local and reset callback counters for every test.
* Do not use sleeps, arbitrary delays, real HTTP requests, or debug prints.
* Do not weaken a test to match the current implementation when the intended
  public behavior is clear.
* Name tests consistently using "action + when-condition" scheme, omitting the when-condition if unnecessary. Minimize articles, preferably omitting them.

## Running tests

Run commands from the package root:

```bash
flutter test
flutter test test/src/web_smart_captcha_test.dart
flutter test test/yandex_smart_captcha_test.dart
flutter analyze
```

During iteration, run the smallest affected test file first. Before finishing a bridge or public API change, run the full test suite and analyzer.

Format only changed Dart files with `dart format`.

## Workflow

1. Identify the production boundary and its existing test file.
2. Read the relevant implementation, event definitions, and fake controller.
3. Add the smallest test that demonstrates the required behavior or regression.
4. Use the fake WebView for handlers and evaluated JavaScript; never use a
   network-backed WebView in a unit or widget test.
5. Run the focused test, then format the changed Dart files.
6. Before finishing a bridge or public API change, run `flutter test` and
   `flutter analyze`.
7. Review the diff for brittle HTML snapshots, duplicated event contracts,
   timing assumptions, and unrelated changes.

## Anti-patterns

Do not:

* test private implementation details when a public callback or rendered HTML
  contract is sufficient;
* move JavaScript snippets into test-only production APIs;
* change event names or controller semantics merely to make a test pass;
* assert on console output instead of callback behavior;
* use a real `InAppWebView` or remote SmartCaptcha service in unit or widget
  tests;
* omit regression coverage when changing the Dart-to-JavaScript bridge.
