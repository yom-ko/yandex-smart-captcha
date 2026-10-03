# Project: Yandex SmartCaptcha for Flutter

## Overview

This project is a reusable Flutter package that embeds the Yandex SmartCaptcha widget on Android, iOS, and Web. It is a library consumed through `package:yandex_smart_captcha`, not a standalone application.

The `example/` directory is a separate Flutter app demonstrating package usage and providing widget and device integration tests.

For SmartCaptcha API names, methods, events, configuration semantics and origin requirements, use the official documentation as the primary source of truth: <https://yandex.cloud/en/docs/smartcaptcha/>.

## Public API

The public entrypoint is [`lib/yandex_smart_captcha.dart`](../lib/yandex_smart_captcha.dart). It exports:

- `YandexSmartCaptcha` – the stateful widget that hosts SmartCaptcha in a native WebView or browser DOM element, exposes presentation options and callbacks, and optionally accepts a `CaptchaController`.
- `CaptchaController` – an optional interface for `execute`, `reset`, and `destroy` imperative methods.
- `CaptchaConfig` – an immutable configuration object for SmartCaptcha options such as language, visibility mode, and badge position.

Keep callback and Flutter-level presentation concerns on `YandexSmartCaptcha`, and SmartCaptcha widget options – on `CaptchaConfig`. The package targets Android and iOS through `flutter_inappwebview` and Web – through browser DOM/JavaScript interop.

## Architecture

The package has a shared Dart API with conditional platform adapters:

1. The shared `YandexSmartCaptcha` widget translates `CaptchaConfig` into platform-specific setup and exposes the same callbacks and controller operations on every supported platform.
2. Native adapters host generated HTML and JavaScript in `flutter_inappwebview`; Web creates a DOM host element and uses JavaScript interop to load and render SmartCaptcha.
3. `CaptchaEvent` provides the event vocabulary shared by the platform adapters and Dart.

On native platforms, `baseUrl` becomes the initial document origin through `InAppWebViewInitialData`, allowing applications to meet SmartCaptcha domain requirements. On Web, the browser application's current origin is used and `baseUrl` is ignored. Native-only presentation options include `backgroundColor`, `loadingIndicator`, and `onNavigationRequest`; the Web adapter leaves these options to the browser DOM and normal browser navigation. Files under `lib/src/` are implementation details; tests may import them to inspect generated content and platform behavior.

## Folder structure

- `lib/` – package implementation; `lib/src/` contains configuration models, enums, shared widget/controller logic, platform adapters, event definitions, and generated WebView content.
- `assets/` – screenshots and other package artwork.
- `example/` – sample Flutter app, widget tests, and Patrol-based integration tests.
- `test/` – package unit and widget tests, including fake native WebView support and browser-targeted Web adapter tests.
- `.agents/` – canonical context for AI-agents that includes this high-level project overview, path-scoped rules, and reusable skills.

## Conventions

- Prefer immutable configuration objects, typed enums, named parameters, and nullable optional callbacks.
- Follow the existing Flutter, Dart, and platform-adapter patterns rather than introducing browser-only APIs into shared code.
- When public API or user-visible behavior changes, keep the README, Dartdoc, example usage, tests, and changelog aligned.
- Run native/unit coverage with `flutter test`; run browser adapter coverage with `flutter test --platform chrome`. Do not confuse the browser-only suite being skipped by the default VM runner with a passing browser test.
- Keep real SmartCaptcha client keys out of source code, tests, documentation, and generated artifacts. Local example credentials belong in `example/.env`. Whenever running or testing the example app, load that real client key with `--dart-define-from-file=.env`, but keep it git-ignored and never commit it.

## Agent context

`.agents/` is the canonical source for agent context. Edit `.agents/project.md` for this overview, `.agents/rules/` for path-scoped instructions, and `.agents/skills/` for reusable workflows.

`AGENTS.md`, `.claude/CLAUDE.md`, `.github/copilot-instructions.md`, and provider-specific rule and skill directories are generated outputs. See [`.agents/README.md`](README.md) for the mapping and run `./build-agent-context.sh` after changing canonical context.
