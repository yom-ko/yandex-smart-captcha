---
description: Preserve the SmartCaptcha WebView bridge contract and keep generated HTML/JS centralized.
globs: "**/*.dart"
paths:
  - "lib/src/*.dart"
  - "test/src/*.dart"
applyTo: "lib/src/*.dart,test/src/*.dart"
alwaysApply: false
---

# SmartCaptcha bridge integrity

This package wraps a JavaScript SmartCaptcha widget through a WebView. Preserve that contract carefully.

## Rules

- Keep all generated HTML/JS in [lib/src/web_smart_captcha.dart](/Users/artem_bondarenko/Dev/codebases/own/products/yandex-smart-captcha/lib/src/web_smart_captcha.dart). Do not spread JS snippets across other files.
- Preserve the event contract between JS and Dart: `captchaReady`, `challengeSolved`, `networkError`, and other event names in [lib/src/captcha_event.dart](/Users/artem_bondarenko/Dev/codebases/own/products/yandex-smart-captcha/lib/src/captcha_event.dart).
- Preserve controller actions in [lib/src/yandex_smart_captcha.dart](/Users/artem_bondarenko/Dev/codebases/own/products/yandex-smart-captcha/lib/src/yandex_smart_captcha.dart): `execute`, `reset`, and `destroy`.
- Do not change public widget APIs or configuration semantics unless the change is explicitly required.
- If you modify the generated HTML, JS callback payload, event names, or widget configuration, update the assertions in [test/src/web_smart_captcha_test.dart](/Users/artem_bondarenko/Dev/codebases/own/products/yandex-smart-captcha/test/src/web_smart_captcha_test.dart).

## Avoid

- Adding logging or temporary JS snippets that are not part of the real SmartCaptcha payload.
- Moving JS logic into arbitrary widget methods or unrelated files.
- Renaming callback names without updating the bridge and tests.
- Changing the controller contract silently.
