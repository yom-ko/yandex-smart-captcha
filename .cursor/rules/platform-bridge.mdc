---
description: Preserve the SmartCaptcha platform bridge integrity and keep generated HTML/JS centralized.
globs: "**/*.dart"
paths:
  - "lib/src/**/*.dart"
  - "test/src/**/*.dart"
applyTo: "lib/src/**/*.dart,test/src/**/*.dart"
alwaysApply: false
---

# SmartCaptcha platform bridge integrity

This package wraps the JavaScript SmartCaptcha widget through a native WebView
on Android/iOS and through browser DOM/JavaScript interop on Flutter Web.
Preserve the shared contract carefully.

## Rules

- Keep generated native HTML in [lib/src/native/smart_captcha_html.dart](../../lib/src/native/smart_captcha_html.dart), native WebView behavior in [lib/src/native/captcha_adapter_controller.dart](../../lib/src/native/captcha_adapter_controller.dart), and browser interop in [lib/src/web/captcha_adapter_web.dart](../../lib/src/web/captcha_adapter_web.dart) and [lib/src/web/captcha_adapter_controller_web.dart](../../lib/src/web/captcha_adapter_controller_web.dart). Do not scatter JavaScript snippets across unrelated files.
- Preserve the event contract between JS and Dart: `captchaReady`, `challengeSolved`, `networkError`, and other event names in [lib/src/captcha_event.dart](../../lib/src/captcha_event.dart).
- Preserve controller actions (`execute`, `reset`, and `destroy`) across the native and browser platform adapters.
- Keep native-only behavior (`backgroundColor`, `loadingIndicator`, and `onNavigationRequest`) out of the browser adapter.
- Keep `baseUrl` native-only; browser origin behavior must remain tied to the hosting document.
- Do not change public widget APIs or configuration semantics unless the change is explicitly required.
- If you modify generated HTML, JS callback payloads, event names, or widget configuration, update the assertions in [test/src/native/smart_captcha_html_test.dart](../../test/src/native/smart_captcha_html_test.dart) and the relevant browser adapter contract tests in [test/src/web/captcha_adapter_controller_web_test.dart](../../test/src/web/captcha_adapter_controller_web_test.dart).

## Avoid

- Changing the controller contract silently.
- Moving JS logic into arbitrary widget methods or unrelated files.
- Renaming callback names without updating the bridge and tests.
- Making browser tests depend on the real Yandex SmartCaptcha script or network availability.
- Adding logging or temporary JS snippets that are not part of the real Yandex SmartCaptcha payload.
