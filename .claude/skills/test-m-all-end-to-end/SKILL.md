---
name: test-m-all-end-to-end
description: >-
  Exhaustively test this Flutter package and its example app with automated suites and exploratory runs on Android, iOS, and web. Use only when asked for full end-to-end project verification.
---

# Testing the package and example app end to end

## Main rules

- Test and report only. Do not fix defects or edit tests unless the user explicitly asks.
- You may temporarily change the example app to reach edge cases (e.g., set `useInvisibleMode: true` flag or add `debugPrint`-s). Revert the changes afterward and list them in the report.
- Preserve all pre-existing user changes. Revert only changes introduced by this testing session, including temporary source or configuration edits and generated dependency-file changes such as `pubspec.lock`. Never use a blanket reset (`git reset --hard`, `git checkout .`, `git clean`) or discard unrelated working-tree changes.
- Load the real client key only from `example/.env` with `--dart-define-from-file=.env`. Never commit it.
- Never reproduce the client key or CAPTCHA tokens in reports, your own output, quoted logs, saved network captures, or screenshots. Redact both wherever they appear. The example app itself prints the token in its `called: onChallengeSolved with token:` log line, so redact it when quoting.
- Do not bypass or automate the solving of CAPTCHA challenges. Do not use solver services, image recognition, or tampered responses. If a step requires solving a challenge, ask the user to solve it or mark the step as `BLOCKED`.
- Derive expected behavior from the README, Dartdoc, and the official [Yandex SmartCaptcha documentation](https://yandex.cloud/en/docs/smartcaptcha/). Baseline expectations always apply: no crash, no uncaught exception, and no unhandled console error. Beyond that, if no source defines the expected behavior, report the check as `UNCLEAR`; do not invent an expectation or declare a defect.
- Every check is required unless this skill marks it *optional*. Optional checks that were not run may be reported as `NOT RUN` without affecting the verdict; required checks may not.
- Ask before installing global tools, SDK system images, simulator runtimes, or browsers. This includes tools that install themselves automatically: a first Patrol web run can install Node.js packages and Playwright browser binaries.
- Stop any apps, servers, emulators, simulators, and browsers you start.
- Never treat skipped, filtered, or unrun tests as passing.

## 1. Prepare

1. Record the Git commit and the `git status --porcelain` output, so that pre-existing changes can be distinguished from changes made during testing.
2. Record the output of `flutter --version`, `flutter devices`, `flutter emulators`, and `patrol --version`. On macOS with Xcode installed, also record `xcrun simctl list runtimes`. On other hosts, mark the iOS checks `BLOCKED – no macOS/Xcode host`.
3. Check the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table). The installed `patrol_cli` must be compatible with the `patrol` version resolved in `example/pubspec.lock`, and the installed Flutter SDK must meet the table's minimum Flutter version for that pair.
4. Verify that `example/.env` defines a non-empty `CLIENT_KEY` without printing its value, for example with `grep -c '^CLIENT_KEY=.' example/.env`. If the key is missing, ask the user. Any check that requires the live service is `BLOCKED` until a key is available. If the installed Flutter SDK rejects the file format, do not silently convert the file or create a new key. Instead, mark the affected checks `BLOCKED` and report it as an environment or configuration issue.
5. Run `flutter pub get` in the package root and in `example/`.

## 2. Select the targets

Check current versions against Flutter's [supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms) and the platform vendors' release information. Do not rely on remembered version numbers.

### Native

For both Android and iOS, cover at least:

- the latest stable OS release that the installed Flutter SDK supports;
- the lowest OS version supported by both the example app and the installed Flutter SDK. If the app declares a lower minimum than the SDK supports, report the mismatch and do not claim coverage for that OS version. The app's minimum is:
  - Android: the effective `minSdkVersion` in `example/android/app/build.gradle`. If it is `flutter.minSdkVersion`, read the value from the installed SDK's `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`.
  - iOS: the Runner's `IPHONEOS_DEPLOYMENT_TARGET` in `example/ios/Runner.xcodeproj/project.pbxproj`, which can be confirmed with `xcodebuild -showBuildSettings`. The Podfile platform applies only to pods.

Optional: the two previous major releases, when their images are already installed or the user approves downloading them. Prefer emulators and simulators. Physical devices are optional and should be included when connected. On Android, record the Android System WebView version, since it can be updated independently of the OS.

### Web

Flutter supports the latest two versions of Chrome, Firefox, and Edge, plus Safari from a documented minimum version. Flutter lists Wasm support only for Chrome and Edge; Firefox and Safari are supported with the JavaScript build. Cover:

- Chrome with both JavaScript and Wasm builds;
- Firefox and WebKit through Playwright with the JavaScript build. WebKit approximates Safari but is not Safari;
- optional: Edge, if installed, with both builds. Do not report Edge as covered when only Chrome was tested.

Older browser versions are optional – test them only when they are already available.

## 3. Run the automated suites

Before running any checks in this section, inspect `.github/workflows/main.yml` and identify the latest-SDK lane. Compare its analyze and test steps with the commands below. Run any missing checks that can be reproduced with the available toolchain, and report differences in commands, SDK versions, or execution environment. Do not treat unavailable CI checks as passing.

From the package root:

```bash
flutter analyze
flutter test
flutter test --platform chrome
flutter test --platform chrome --wasm
```

From `example/`:

```bash
flutter analyze
flutter test
```

If `example/` contains browser-targeted tests, run them in the applicable browser modes required by CI. Do not force mobile-only tests to run on web.

Inspect `example/pubspec.yaml` for Patrol's `test_directory` configuration and locate the actual Patrol test files before running the suite. Ensure that the command targets the intended tests. Patrol defaults to `patrol_test/` unless configured otherwise.

Run the Patrol suite on every native target selected in [step 2](#2-select-the-targets). On web, run applicable Patrol tests on Chrome using `patrol test --device chrome --dart-define-from-file=.env`. Before deciding whether a test applies to web, inspect its code. Mark only genuinely platform-inapplicable tests as `N/A`, with a reason (for example, `$.platform.mobile` actions throw `UnsupportedError` on web). Follow the installation-approval rule in [Main rules](#main-rules).

If a test fails, rerun the failing test once when feasible. Record both results and whether the failure is flaky. A flaky test is still a `FAIL`.

## 4. Explore the example app

**Browser automation.** Prefer [`playwright-cli`](https://playwright.dev/docs/getting-started-cli) over [Playwright MCP](https://playwright.dev/mcp/introduction#playwright-mcp-vs-playwright-cli) when its capabilities are sufficient, to reduce token usage. Select one browser per session with `playwright-cli open --browser=chrome` (or `firefox`, `webkit`, or `msedge`). Use Playwright MCP only when the CLI lacks a required capability or MCP materially helps with complex exploratory checks; its browser is selected at server start.

Check that the required browser is already available before launching it: the CLI may download browser binaries on first use. Ask for approval before installing the CLI or downloading browsers. If the required browser is unavailable, use an already configured alternative where suitable; otherwise, ask for approval or mark affected checks as `NOT RUN`.

Launch from `example/`:

```bash
# Open http://localhost:8080 using the selected browser tool.
flutter run -d web-server --web-port 8080 --dart-define-from-file=.env

# Stop the JavaScript server and confirm that port 8080 is free before starting the Wasm build.
flutter run -d web-server --web-port 8080 --dart-define-from-file=.env --wasm
```

Run only one web server at a time. Run the JavaScript build on each selected browser target and the Wasm build on the targets required by [Step 2 - Web](#web). Record the actual build used for each browser/build combination.

Flutter may fall back to JavaScript when the browser lacks the required Wasm features or the engine is not enabled in `wasmAllowList`. See [Flutter Wasm browser compatibility](https://docs.flutter.dev/platform-integration/web/wasm). The primary evidence is a temporary diagnostic that prints the compile-time value of `const bool.fromEnvironment('dart.tool.dart2wasm')`. Loading `main.dart.wasm` in the network panel is supporting evidence. Remove temporary diagnostics afterward. Never report a fallback run as Wasm coverage.

**Native automation.** Drive and inspect the app with available tools such as the Dart MCP server, Patrol, `adb`, and `xcrun simctl`.

Launch from `example/`:

```bash
flutter run -d <device-id> --dart-define-from-file=.env
```

### Scenarios

Cover the scenarios below on every applicable target/build combination. Skip a scenario only when it does not apply to that platform, and record the reason (e.g., `loadingIndicator` and `onNavigationRequest` apply only to native platforms).

**Core flows:**

- loading indicator, `onCaptchaReady`, and controller readiness enabling the buttons;
- `onChallengeShown`, then `onChallengeHidden`;
- `onChallengeSolved` with a non-null token, and the resulting Execute/Reset button states;
- `reset`, then solving again;
- `destroy`, followed by controller calls after destruction;
- `execute` in invisible mode, which requires the temporary `useInvisibleMode` configuration.

**Edge cases:**

- language, badge position, and `hideBadge` variants;
- `onTokenExpired`, which requires waiting for the token to expire;
- rapid or repeated `execute`, `reset`, and `destroy` calls, and calls made before the widget is ready;
- rotation or resize, backgrounding and resuming, hot restart, and widget disposal followed by rebuilding;
- page reload, back/forward navigation, console errors, and parity between the JavaScript and Wasm builds on web;
- links inside the widget: native navigation must respect `onNavigationRequest`, and web must use normal browser behavior;
- no network at launch, and connection loss during a challenge: check `onNetworkError` and script-load errors, then check recovery after the connection returns;
- small and large viewports, text scaling, dark mode, zoom settings, keyboard navigation, semantic accessibility, and screen-reader behavior where a screen reader is available;
- invalid client keys, without `--dart-define-from-file=.env` so that the real key cannot leak into the run:
  - empty key: `flutter run -d <device-id> --dart-define=CLIENT_KEY=`;
  - non-empty invalid key: no define, so the app uses its placeholder default (`flutter run -d <device-id>`).

The example app logs callbacks using the `called:…` format. Use these logs, together with the browser console and network panel, to verify events. Redact client keys and CAPTCHA tokens from all evidence.

For each problem, record the target, steps, expected and actual behavior, evidence (redacted log excerpt or screenshot path), and reproducibility. Classify the cause as one of: package, example app, test infrastructure, environment, or external service.

## 5. Report

Follow [`report-template.md`](./report-template.md). Its structure and format are mandatory.

- Use these statuses for each check: `PASS`, `FAIL`, `UNCLEAR` (the check ran, but no source defines the expected behavior), `BLOCKED` (an environment or service issue prevented the check), `NOT RUN` (the check was not executed), or `N/A – reason`.
- Assign each finding a severity:
  - `HIGH` – crash, data or token loss, or a core flow broken on a supported target;
  - `MEDIUM` – wrong callback, state, or cross-platform inconsistency that has a workaround;
  - `LOW` – cosmetic or minor usability issue.
- Choose exactly one verdict:
  - `PASS` – every required check is `PASS` or `N/A`, and no defect was found;
  - `FAIL` – at least one check failed or a defect was confirmed;
  - `INCOMPLETE` – nothing failed, but at least one required check is `UNCLEAR`, `BLOCKED`, or `NOT RUN`.
- Before reporting, revert only the changes made during this session, following [Main rules](#main-rules). Then confirm that `git status --porcelain` matches the output recorded in [step 1](#1-prepare).

## References

- [Yandex SmartCaptcha documentation](https://yandex.cloud/en/docs/smartcaptcha/)
- [Flutter supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms)
- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter WebAssembly](https://docs.flutter.dev/platform-integration/web/wasm)
- [Patrol documentation](https://patrol.leancode.co/documentation) and [web testing](https://patrol.leancode.co/documentation/web)
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
- [Playwright CLI](https://playwright.dev/docs/getting-started-cli)
