---
description: Preserve the SmartCaptcha platform bridge integrity and keep HTML/JS centralized.
globs: "lib/src/**/*.dart,test/src/**/*.dart"
paths:
  - "lib/src/**/*.dart"
  - "test/src/**/*.dart"
applyTo: "lib/src/**/*.dart,test/src/**/*.dart"
alwaysApply: false
---

# SmartCaptcha platform bridge integrity

This package integrates the SmartCaptcha script and widget through native WebViews on Android/iOS and through DOM and JavaScript interop on the web. Preserve the shared contract and keep platform-specific behavior isolated.

## Rules

* Do not change public widget APIs or configuration semantics unless the task explicitly requires it.
* For native platforms, keep HTML generation in [lib/src/native/captcha_adapter.dart](../../lib/src/native/captcha_adapter.dart), WebView hosting and setup in [lib/src/native/captcha_adapter_widget.dart](../../lib/src/native/captcha_adapter_widget.dart), and controller behavior in [lib/src/native/captcha_adapter_controller.dart](../../lib/src/native/captcha_adapter_controller.dart). For the web, keep DOM host creation in [lib/src/web/captcha_adapter_widget_web.dart](../../lib/src/web/captcha_adapter_widget_web.dart) and browser interop in [lib/src/web/captcha_adapter_web.dart](../../lib/src/web/captcha_adapter_web.dart) and [lib/src/web/captcha_adapter_controller_web.dart](../../lib/src/web/captcha_adapter_controller_web.dart). Do not scatter SmartCaptcha JavaScript across unrelated files.
* Preserve the event contract defined in [lib/src/captcha_event.dart](../../lib/src/captcha_event.dart), including event names and payload semantics.
* Preserve the shared controller actions (`execute`, `reset`, and `destroy`) across native and web adapters.
* Keep `baseUrl` as a native-only configuration. On the web, do not introduce a configurable or synthetic origin.
* Keep native-only behavior such as `backgroundColor`, `loadingIndicator`, and `onNavigationRequest` out of the web adapter.
* Keep native and web adapters behaviorally aligned with the shared widget and controller contract. Platform-specific differences should remain limited to platform capabilities and explicitly defined semantics.
* When changing HTML generation, JS callback payloads, event names, or widget configuration, update the affected native and web contract tests, including [test/src/native/captcha_adapter_test.dart](../../test/src/native/captcha_adapter_test.dart) and [test/src/web/captcha_adapter_controller_web_test.dart](../../test/src/web/captcha_adapter_controller_web_test.dart) where applicable.

## Avoid

* Changing the shared controller or event contract silently.
* Moving SmartCaptcha JavaScript into arbitrary widget methods or unrelated files.
* Making browser tests depend on the real Yandex SmartCaptcha script or network availability.
* Renaming, removing, or changing callback names or payloads without updating the bridge and contract tests.
* Adding temporary JS, debug logging, or callback behavior that changes or obscures the real SmartCaptcha integration payload.
