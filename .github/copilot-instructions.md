<!-- GENERATED FILE. DO NOT EDIT MANUALLY! Edit source in .agents/ and run build-agent-context.sh -->

# Project: Yandex SmartCaptcha for Flutter

## Introduction

This repository contains a reusable Flutter package that embeds the Yandex SmartCaptcha widget on Android, iOS, and web.

The package is consumed through `package:yandex_smart_captcha`; it is not a standalone application.

The `example/` directory contains a separate Flutter application used for usage examples, widget tests, and device integration tests.

For SmartCaptcha API names, methods, events, configuration semantics, and origin requirements, use the official Yandex documentation as the primary source of truth: <https://yandex.cloud/en/docs/smartcaptcha/>

## Public API

The public entrypoint [`lib/yandex_smart_captcha.dart`](../lib/yandex_smart_captcha.dart) exposes the main package API:

* `YandexSmartCaptcha` — stateful widget that hosts SmartCaptcha and exposes presentation options and callbacks.
* `CaptchaConfig` — immutable configuration for SmartCaptcha widget options such as language, visibility mode, and badge position.
* `CaptchaController` — optional interface for imperative `execute`, `reset`, and `destroy` operations.

Keep SmartCaptcha widget options on `CaptchaConfig`. Keep Flutter-level presentation concerns and callbacks on `YandexSmartCaptcha`.

## Architecture

The package exposes one shared Dart API with conditional platform adapters:

1. `YandexSmartCaptcha` translates the shared configuration into platform-specific setup and exposes consistent callbacks and controller operations.
2. Native adapters host generated HTML and JavaScript in `flutter_inappwebview`.
3. The web adapters creates a DOM host element and uses JavaScript interop to load and render SmartCaptcha.
4. `CaptchaEvent` defines the shared event vocabulary used by the platform adapters and Dart.

Keep platform-specific APIs and implementation details inside the appropriate adapters rather than introducing platform-only dependencies into shared code.

## Platform differences

On native platforms, `baseUrl` is passed to `InAppWebViewInitialData` and therefore becomes the initial document origin. This allows applications to satisfy SmartCaptcha domain requirements. On web, the browser application's current origin is used and `baseUrl` is ignored.

In addition, the following options are native-only:

* `backgroundColor`
* `loadingIndicator`
* `onNavigationRequest`

The web adapter leaves these concerns to the browser DOM and normal browser behavior.

## Folder structure

* `lib/` — package implementation.
* `lib/src/` — internal configuration models, enums, shared widget/controller logic, platform adapters, event definitions, and generated WebView content.
* `test/` — package unit and widget tests, including fake native WebView support and browser-targeted web adapter tests.
* `example/` — example Flutter application, widget tests, and Patrol-based integration tests.
* `assets/` — screenshots and other package artwork.
* `.agents/` — canonical agent context, including this project overview, path-scoped rules, and reusable skills.

## Engineering conventions

* Follow existing Flutter, Dart, and platform-adapter patterns.
* Prefer immutable configuration objects, typed enums, named parameters, and nullable optional callbacks.
* Keep the shared code platform-neutral. Use platform-specific APIs only inside their corresponding adapters.
* When public API or user-visible behavior changes, update the relevant README, Dartdoc, example usage, tests, and changelog entries as applicable.

## Testing

Run package unit and native widget tests with:

```bash
flutter test
```

Run browser adapter tests explicitly with:

```bash
flutter test --platform chrome
```

Do not treat a browser-only suite skipped by the default VM runner as passing browser coverage.

## Security policy

Never commit or embed real SmartCaptcha client keys in source code, tests, documentation, or generated artifacts.

For local example-app runs and tests, load the real key from `example/.env` using `--dart-define-from-file=.env`.

Keep `example/.env` git-ignored.

## Agent context

`.agents/` is the canonical source of truth for agent context:

* `.agents/project.md` — general project-wide context.
* `.agents/rules/` — path-scoped rules/instructions.
* `.agents/skills/` — reusable workflows.

See [`.agents/README.md`](README.md) for the complete mapping and explanations.

After changing any canonical agent context files, regenerate the outputs with:

```bash
./build-agent-context.sh
```
