---
name: writing-unit-widget-tests
description: >
  Write and maintain focused Dart and Flutter tests for this Yandex SmartCaptcha package.
  Use it for unit tests, widget tests, HTML/JavaScript assertions, WebView bridge tests,
  and web adapter tests. Do not use it as the primary guide for native integration,
  end-to-end, or golden tests.
---

# Writing unit and widget tests

Use this skill when creating or editing unit or widget tests for the `yandex_smart_captcha` Flutter package.

## Scope

Cover externally observable behavior and stable contracts. Prefer the smallest deterministic test that demonstrates the required behavior or regression.

Do not couple tests to private implementation details when the same behavior is observable through a public API, callback, serialized value, generated HTML/JavaScript, or other stable contract.

## File mapping

Use the corresponding test target. For file-specific tests, mirror `lib/` under
`test/` and use the `_test.dart` suffix. Public API and platform implementation
details may instead be covered through a package-level or contract-level test:

| Production file                                   | Test target                                             |
| ------------------------------------------------- | ------------------------------------------------------- |
| `lib/src/captcha_config.dart`                     | `test/src/captcha_config_test.dart`                     |
| `lib/src/captcha_event.dart`                      | `test/src/captcha_event_test.dart`                      |
| `lib/src/captcha_language.dart`                   | `test/src/captcha_language_test.dart`                   |
| `lib/src/dpn_badge_position.dart`                 | `test/src/dpn_badge_position_test.dart`                 |
| `lib/src/native/captcha_adapter.dart`             | `test/src/native/captcha_adapter_test.dart`             |
| `lib/src/native/captcha_adapter_controller.dart`  | `test/src/native/captcha_adapter_controller_test.dart`  |
| `lib/src/native/captcha_adapter_widget.dart`      | `test/src/native/captcha_adapter_widget_test.dart`      |
| `lib/src/web/captcha_adapter_controller_web.dart` | `test/src/web/captcha_adapter_controller_web_test.dart` |
| `lib/src/web/captcha_adapter_web.dart`            | `test/src/web/captcha_adapter_controller_web_test.dart` |
| `lib/src/web/captcha_script_loader_web.dart`      | `test/src/web/captcha_script_loader_web_test.dart`      |
| `lib/src/captcha_platform_controller.dart`        | `test/src/captcha_platform_controller_test.dart`        |
| `lib/yandex_smart_captcha.dart`                   | `test/yandex_smart_captcha_test.dart`                   |
| `lib/src/yandex_smart_captcha.dart`               | `test/yandex_smart_captcha_test.dart`                   |

Keep reusable WebView test infrastructure in `test/mocks/`, especially [`in_app_webview_platform_fake.dart`](../../../test/mocks/in_app_webview_platform_fake.dart).

This mapping reflects the repository layout at the time of writing. Follow the actual project structure if files are moved during a refactor.

## Workflow

1. Identify the production code affected by the change and its corresponding test file(s).
2. Inspect the implementation, bridge contracts, and available mocks, fakes, helpers.
3. Choose `test()` or `testWidgets()` according to the behavior being exercised.
4. Add the smallest test that demonstrates the required behavior or regression.
5. Run the smallest affected test target while iterating.
6. Apply the validation rules in [Running tests](#running-tests).
7. Review the diff and remove brittle assertions, duplicated coverage, timing assumptions, debug code, and unrelated changes.

## Test selection

Use `test()` when the behavior does not require Flutter bindings, widget lifecycle, `BuildContext`, or platform APIs. Examples include enum names and IDs, `CaptchaConfig` defaults and value preservation, `SmartCaptcha` serialization, and other pure transformations.

Use `testWidgets()` when the behavior requires Flutter bindings, widget lifecycle, `BuildContext`, `InAppWebView`, controller attachment, DOM setup, or JavaScript-triggered callbacks.

## Test design and hygiene

Name tests after the behavior being verified. Include the triggering condition when it materially distinguishes the scenario.

Use explicit matchers when they make the expected contract clear, such as `equals`, `same`, `isNull`, `isNotNull`, `isEmpty`, `contains`, `orderedEquals`, and `throwsA`.

Use `setUpAll()` for shared one-time setup such as fake platform registration. Use `setUp()` and `tearDown()` for per-test mutable state. Reset mutable callback state and counters for each test.

Keep tests deterministic. Do not use sleeps, arbitrary delays, real HTTP requests, debug prints, logs, or timing-based assertions when a deterministic fake state or operation log is available.

Avoid duplicating the same expectation across multiple layers unless each layer represents a distinct contract.

Do not weaken a test merely to match the current implementation when the intended public behavior is clear.

Do not snapshot entire generated HTML when focused assertions can verify the contract. Avoid asserting incidental whitespace, ordering, formatting, or wrapper syntax unless those details are themselves part of the contract.

Do not derive expected bridge values solely from the same production enum or constant used by the implementation under test.

Do not change event names or controller semantics merely to make a test pass.

Do not use a real in-app WebView or the remote SmartCaptcha service in unit or widget tests.

## Regression tests

When fixing a bug, add a regression test that reproduces the externally observable failure and fails before the fix when the behavior is testable at this level.

Test the intended behavior rather than the exact implementation detail that caused the bug.

## Public configuration

When adding or changing a public configuration option:

1. Test its default in `CaptchaConfig`.
2. Test nullable or optional behavior when applicable.
3. Test a non-default value reaching the generated output or other observable widget behavior.
4. Preserve existing public API coverage unless the public contract intentionally changes.
5. Update API documentation and/or README examples when required by the current policy or API conventions.

## HTML and JavaScript

When generated HTML or JavaScript changes, add or update focused assertions for the affected contract. Depending on the change, this may include:

* script URL;
* viewport values;
* document structure and captcha container;
* safely escaped JavaScript string configuration values;
* widget options: `sitekey`, `hl`, `test`, `invisible`, `shieldPosition`, `hideShield`, and `webview`;
* native bridge readiness, including initialization after `flutterInAppWebViewPlatformReady`;
* `captchaReady`, `challengeSolved`, script-load errors, and missing-API wiring;
* subscribed event IDs and native handler names for subscribable events;
* missing-script protection before `smartCaptcha.render`.

Prefer narrow assertions such as `contains()`, decoded event JSON, or parsed values over whole-HTML snapshots.

## Platform bridge

Treat JavaScript event names, handler names, serialized widget options, and callback payloads as bridge contracts when they are externally observable.

When bridge behavior changes, test the affected side of the boundary rather than duplicating coverage for internal refactors that preserve the same contract.

For each added or behaviorally changed `CaptchaEvent`, cover the applicable contract:

1. For subscribable events, verify that generated JavaScript subscribes to the expected SmartCaptcha event ID.
2. For non-subscribable events such as `captchaReady` and `challengeSolved`, verify the dedicated callback or bridge wiring.
3. On native platforms, verify that `YandexSmartCaptcha` registers the expected JavaScript handler and that `PlatformInAppWebViewControllerFake.emit()` invokes the matching Dart callback.
4. On the web, invoke the relevant typed JavaScript fake callback or subscription and verify the matching Dart callback.
5. Verify payload conversion explicitly, including nullable payloads where applicable.
6. Verify that optional callbacks remain optional and do not throw when omitted.

For `challengeSolved`, cover:

* a real token;
* the string `'null'` mapping to `null`;
* no argument mapping to `null`.

The native bridge maps the string `'null'` and a missing argument to `null`; web interop receives a nullable JavaScript string. Test the conversion supported by each platform rather than assuming both representations are identical.

Register the fake WebView platform once per test file that exercises the platform layer. Do not replace the global platform instance inside individual tests unless the test explicitly requires it and restores the previous instance afterward.

## Controller lifecycle

For `CaptchaController`, cover the behavior relevant to the change:

* `execute`, `reset`, and `destroy` are safe before WebView attachment;
* each action performs the expected SmartCaptcha operation;
* replacing a controller detaches the old controller and attaches the new one;
* disposing the widget detaches its controller;
* actions after replacement do not execute against the old WebView.

Inspect `evaluatedJavascriptSources` on `PlatformInAppWebViewControllerFake` instead of relying on sleeps, delays, logs, or timing. Assert the semantic JavaScript operation and its arguments, not incidental formatting or wrapper syntax, unless the exact generated source is part of the contract.

## Web implementations

Do not load the real Yandex script or make network requests.

Pre-install a script element with `smartCaptchaScriptUrl` and provide a typed JavaScript fake for `smartCaptcha`.

Verify only the behavior relevant to the change, including DOM container sizing, rendered widget options, callback payload conversion, subscribed event dispatch, controller delegation, missing-API errors, and shared script-reference cleanup.

Keep browser tests deterministic and independent of actual browser navigation or remote challenge UI.

## Shared test conventions

Browser-only test files should use `@TestOn('browser')`. Native WebView suites should use `@TestOn('vm')` at the library level.

Reuse or extend the existing `pumpCaptcha()` helper in [`test/yandex_smart_captcha_test.dart`](../../../test/yandex_smart_captcha_test.dart) instead of duplicating `pumpWidget` setup.

`lib/src/web/captcha_adapter_web.dart` contains only external JavaScript interop declarations. Its observable use is covered by the browser controller contract in [`test/src/web/captcha_adapter_controller_web_test.dart`](../../../test/src/web/captcha_adapter_controller_web_test.dart); do not add declaration-only tests.

`lib/src/web/captcha_adapter_widget_web.dart` delegates to Flutter's `HtmlElementView`. Its platform-view lifecycle is covered by Flutter's framework and is not deterministic in the headless package test harness; do not add tests that depend on that lifecycle here.

## Running tests

Run commands from the package root.

During iteration, run the smallest affected test file first:

```bash
flutter test test/src/native/captcha_adapter_test.dart
flutter test test/yandex_smart_captcha_test.dart
```

When the change affects the web adapter, run the relevant browser tests explicitly:

```bash
flutter test --platform chrome
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
