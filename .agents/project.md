# Project: Yandex SmartCaptcha for Flutter

## Introduction

This repository contains a reusable Flutter package that embeds the Yandex SmartCaptcha widget on Android, iOS, and web.

The package is consumed through `package:yandex_smart_captcha`; it is not a standalone application.

The `example/` directory contains a separate Flutter application with usage examples, widget tests, and device integration tests.

For SmartCaptcha API names, methods, events, configuration semantics, and origin requirements, use the official Yandex documentation as the primary source of truth: <https://yandex.cloud/en/docs/smartcaptcha/>

## Structure

* `lib/` – package implementation.
* `lib/src/` – internal configuration models, enums, widget/controller logic, platform adapters, event definitions, and WebView content.
* `test/` – package unit and widget tests, including fake WebView support and browser-targeted web adapter tests.
* `example/` – example Flutter application, widget tests, and Patrol-based integration tests.
* `assets/` – screenshots and other package artwork.
* `.agents/` – canonical agent context, including this overview, path-scoped rules, and reusable skills.

## Public API

The public entrypoint [`lib/yandex_smart_captcha.dart`](../lib/yandex_smart_captcha.dart) exposes the main package API:

* `YandexSmartCaptcha` – stateful widget that hosts SmartCaptcha and exposes presentation options and callbacks.
* `CaptchaConfig` – immutable configuration for SmartCaptcha JavaScript options (language, visibility, etc.) and WebView content.
* `CaptchaController` – optional interface for imperative `execute`, `reset`, and `destroy` operations.

Keep SmartCaptcha and WebView options on `CaptchaConfig`. Keep Flutter-level concerns and callbacks on `YandexSmartCaptcha`.

## Architecture

The package exposes a shared Dart API with conditional platform adapters:

1. `YandexSmartCaptcha` translates the shared configuration into platform-specific setup, exposing callbacks and controller methods.
2. Native adapters host generated HTML and JavaScript in a WebView provided by the `flutter_inappwebview` package.
3. Web adapters create a DOM host element and use JavaScript interop to load and render SmartCaptcha.
4. `CaptchaEvent` defines the shared event vocabulary used by the platform adapters and Dart.

Keep platform-specific APIs and implementation details inside the appropriate adapters rather than introducing them into shared code.

## Platform differences

On native platforms, `baseUrl` is passed to `InAppWebViewInitialData` and therefore becomes the initial document origin. This allows applications to satisfy SmartCaptcha domain requirements. On the web, the browser's current origin is used instead of `baseUrl`.

In addition, the following options are native-only:

* `backgroundColor`
* `loadingIndicator`
* `onNavigationRequest`

The web adapters leave these concerns to the browser DOM and normal browser behavior.

## Engineering conventions

* Follow existing Flutter, Dart, and platform-adapter patterns unless explicitly instructed otherwise.
* Prefer immutable configuration objects, typed enums, named parameters, and nullable optional callbacks.
* Keep the shared code platform-neutral. Use platform-specific APIs only inside their corresponding adapters.
* When public API or visible behavior changes, update the relevant README, Dartdoc, example usage, and tests, as applicable.

## Testing

Run package unit and native widget tests with:

```bash
flutter test
```

Run browser-targeted web adapter tests separately with:

```bash
flutter test --platform chrome
```

Do not treat a browser-only suite skipped by the default VM runner as passing browser coverage.

For local example app runs and tests, load the real client key from `example/.env` with `--dart-define-from-file=.env`.

## Security policy

Never commit or embed real SmartCaptcha keys (e.g., `example/.env`) in source code, tests, documentation, or generated artifacts.

## Agent context policy

**Context loading:** As an AI agent, use only your provider's directory (e.g., `.github/` for Copilot, `.claude/` for Claude,..) as the sole source of context. Do not inspect other providers’ directories as they contain identical content that would bloat the context window unnecessarily.

**Context updating:** `.agents/` is the canonical source of truth for agent context. Do not read or modify files in that directory unless explicitly asked by the user. After modifying any canonical agent context file, regenerate the provider-specific outputs from the repository root with:

```bash
./build-agent-context.sh
```

If interested, see [`.agents/README.md`](/.agents/README.md) for details.
