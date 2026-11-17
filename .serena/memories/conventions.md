# Conventions

- Prefer immutable configuration, typed enums, named parameters, and nullable optional callbacks. Keep the shared API platform-neutral; implement platform-specific details only in the matching adapter.
- Central API responsibilities: `CaptchaConfig` owns SmartCaptcha and WebView configuration; `YandexSmartCaptcha` owns Flutter-level presentation/callback concerns; `CaptchaEvent` is the shared event vocabulary.
- Native adapters generate HTML/JS for `flutter_inappwebview`; web adapters create a DOM host and use JS interop. Preserve this bridge boundary and avoid duplicating platform bridge/HTML logic.
- When public API or visible behavior changes, update relevant README/Dartdoc, examples, and tests. Follow Flutter/Dart and existing adapter patterns.