# Project map and invariants

- Flutter package `yandex_smart_captcha`, not a standalone app. `lib/` is the package API/implementation; `lib/src/` holds shared logic and platform adapters; `test/` covers package behavior; `example/` is a separate Flutter app with widget and Patrol integration tests.
- Shared API lives at `lib/yandex_smart_captcha.dart`. Keep SmartCaptcha/WebView settings in `CaptchaConfig`; Flutter presentation and callbacks belong on `YandexSmartCaptcha`.
- Keep shared Dart platform-neutral; native WebView and web DOM/JS behavior belong in their adapters. Native `baseUrl` sets document origin; web uses current browser origin.
- For SmartCaptcha API semantics, use official Yandex docs as source of truth. Never commit/embed real captcha keys.
- Read `mem:tech_stack` for SDK/dependencies, `mem:conventions` for architecture/style, and `mem:task_completion` for validation.