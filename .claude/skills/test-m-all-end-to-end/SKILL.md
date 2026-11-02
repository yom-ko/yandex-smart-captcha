---
name: test-m-all-end-to-end
description: >-
  Test this Flutter package and its example app end to end with automated suites and exploratory runs on Android, iOS, and web. Use only when explicitly asked for full end-to-end project verification.
---

# Testing the package and example app end to end

## Main rules

- Test and report only. Do not fix defects or edit tests unless the user explicitly asks.
- You may temporarily modify the example app to test edge cases (e.g., set `useInvisibleMode: true` or add `debugPrint` statements). Revert the changes afterward and list them in the report.
- Preserve all pre-existing user changes. Before editing any file, copy it outside the repository, and undo your edits by restoring that copy, never with `git checkout <file>`. Never use a blanket reset (`git reset --hard`, `git checkout .`, `git clean`). Ignored build outputs (e.g., `.dart_tool/`, `build/`) are disposable.
- Derive expected behavior from the README, Dartdoc, and the official [Yandex SmartCaptcha documentation](https://yandex.cloud/en/docs/smartcaptcha/). Crashes, exceptions, and console errors are evidence to investigate, not proof of a package defect. If no source defines the expected behavior, report `UNCLEAR`; do not invent expectations.
- Never treat skipped, filtered, or unrun tests as passing.
- Do not bypass or automate CAPTCHA solving: no solver services, image recognition, or tampered responses. The user solves every challenge.
- Ask before installing global tools, SDK system images, simulator runtimes, browsers, or third-party apps. This includes tools that install themselves, e.g., `playwright-cli` or a first Patrol web run downloading browser binaries. Installing the example app and Patrol's test apps on the selected test devices needs no extra approval.
- Stop every app, server, emulator, simulator, and browser you start. Record the PID of each process and stop it by PID, never by name: the host may be shared.

### Secrets

- Load the real client key only from `example/.env` with `--dart-define-from-file=.env`. Never commit or print it.
- Never let the client key or CAPTCHA tokens reach tool output, logs, network captures, screenshots, or reports. Redact at the source:
  - Before the first app launch, change the example's `called: onChallengeSolved with token: $token` log line to print only `${token != null}`. Keep this change for the whole session; if you revert `example/lib/main.dart` to undo another temporary edit, reapply it.
  - Do not dump full network traffic or the DOM: request URLs carry the key, and the page's hidden `smart-token` input carries the token. Filter output to what you need (e.g., lines containing `called:`).
  - For a network request, output only its hostname, path, status, type, and timing. Never output or screenshot full URLs, query strings, or request and response bodies.

### Required and optional checks

Every check is required, except these optional ones:

- Edge, older browser versions, and physical devices;
- every check on the lowest supported Android and iOS versions, Patrol included (see [step 2](#2-select-the-targets)).

An optional check that was not run is `NOT RUN` and does not affect the verdict. An optional check that runs is reported like any other; a confirmed package defect found by it is still a `FAIL`.

## 1. Prepare

1. Record the commit and `git status --porcelain` output.
2. Record `flutter --version`, `flutter devices`, `flutter emulators`, `patrol --version`, `node --version`, and, if installed, `playwright-cli --version`. On macOS with Xcode, also record `xcodebuild -version` and `xcrun simctl list runtimes`. On other hosts, mark the iOS checks `BLOCKED – no macOS/Xcode host`.
3. Check the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table): the installed `patrol_cli` must be compatible with the `patrol` version in `example/pubspec.lock`, and the Flutter SDK must meet the minimum listed for that pair.
4. Verify that `example/.env` defines `CLIENT_KEY` exactly once with a non-empty value, without printing it. Both commands must print `1`:

   ```bash
   grep -c '^CLIENT_KEY=' example/.env
   grep -cE "^CLIENT_KEY=(\"[^\"]+\"|'[^']+'|[^\"'[:space:]#][^[:space:]]*)" example/.env
   ```

   If the key is missing, ask the user; checks that need the live service stay `BLOCKED` until then. If Flutter rejects the file format, do not convert the file or create a key: mark the affected checks `BLOCKED` as an environment issue.
5. Copy both `pubspec.lock` files outside the repository. They are gitignored, so `git status` cannot show changes, and `flutter test` and `patrol test` resolve dependencies.
6. Run `flutter pub get` in the package root and in `example/`.
7. If the user provided a previous report, list its findings so that you can retest each one.

## 2. Select the targets

Check current versions against Flutter's [supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms) and the vendors' release information. Then ask the user, in one prompt, for every download approval you need, whether to keep the downloads afterward, and whether they are available to solve challenges.

### Native

For both Android and iOS, cover:

- the latest stable OS release that the installed Flutter SDK supports;
- the previous major release. If the installed Flutter SDK does not support it, mark its checks `BLOCKED`;
- optional: the lowest OS version supported by both the example app and the installed Flutter SDK, unless already covered. If it is not run, report runtime coverage at the app's declared minimum as unverified. If the app declares a lower minimum than the SDK supports, report the mismatch and do not claim coverage for that version. The app's minimum is:
  - Android: the effective `minSdkVersion` in `example/android/app/build.gradle`. For `flutter.minSdkVersion`, read the value from `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt` in the installed SDK.
  - iOS: the Runner's `IPHONEOS_DEPLOYMENT_TARGET` in `example/ios/Runner.xcodeproj/project.pbxproj` (confirm with `xcodebuild -showBuildSettings`). The Podfile platform applies only to pods.

Prefer emulators and simulators; include physical devices when connected. If a required image or runtime cannot be obtained, mark the checks on that target `BLOCKED` and say why. For every native target, record:

- the exact OS version; an OS family name alone is not coverage;
- on Android, the active WebView provider and version: the `Current WebView package` line of `adb -s <device-id> shell dumpsys webviewupdate`. The provider may be Chrome rather than Android System WebView. It updates independently of the OS and may be too old for the Yandex widget. Prefer Play-enabled images, and ask before updating the WebView. If Yandex's own script fails because of an old WebView, attribute it to the environment.

### Web

Flutter's supported-platforms page lists Wasm only for Chrome and Edge; Firefox and Safari are supported with the JavaScript build. Cover:

- Chrome with both the JavaScript and Wasm builds;
- Firefox and WebKit through Playwright with the JavaScript build. WebKit approximates Safari but is not Safari: never report Safari coverage from WebKit alone;
- optional: Edge, if installed, with both builds. Never report Edge as covered when only Chrome was tested.

Record the exact version of every browser used and the build actually run on it. Ask the browser itself (e.g., `browser.version()` through `playwright-cli run-code`): `navigator.userAgent` may report a reduced version.

## 3. Run the automated suites

First compare the steps of the latest-SDK lane in `.github/workflows/main.yml` with the commands below. Run any extra CI check the local toolchain can reproduce, and report differences in commands, SDK versions, or environment. Never treat unavailable CI checks as passing.

From the package root:

```bash
flutter analyze
flutter test
flutter test --platform chrome
flutter test --platform chrome --wasm
```

`--platform chrome` is deprecated, but it is the only runner for the `@TestOn('browser')` suites in `test/src/web/`: `flutter test -d chrome` runs `test/` on the VM, skips them, and still exits 0. Confirm that each browser run lists tests from `test/src/web/`. If a Flutter release removes the flag or it stops running these suites, mark them `NOT RUN` and report the tooling limitation; never substitute another runner without confirming that it runs them in a browser. The `--wasm` run serves only a `dart2wasm` build, so unlike an app it cannot fall back to JavaScript.

From `example/`:

```bash
flutter analyze
flutter test
```

If `example/` contains browser-targeted tests, run them in the browser modes that CI requires. Do not force mobile-only tests onto the web.

### Patrol

Read `test_directory` in `example/pubspec.yaml` (Patrol defaults to `patrol_test/`) and confirm that the command targets the intended files. Inspect each test before deciding whether it applies to a platform; mark it `N/A – reason` only when it is genuinely inapplicable (e.g., it is skipped on web or uses `$.platform.mobile`). From `example/`:

```bash
patrol test --device <device-id> --dart-define-from-file=.env   # every selected native target
patrol test --device chrome --dart-define-from-file=.env        # web, if applicable
```

Let a freshly created emulator finish its first boot before running Patrol: an overloaded host causes timeouts. If a test fails, rerun it once when feasible and record both results and whether the failure is flaky. Never hide a failed run or count its unverified assertions as passing. A flaky failure that establishes a package defect is still a `FAIL`; otherwise attribute it as described in [Report](#6-report).

## 4. Explore the example app

Launch from `example/`. Run the JavaScript build on every selected browser and the Wasm build on the browsers required by [step 2](#web). Run only one web server at a time, and confirm that port 8080 is free before starting another:

```bash
flutter run -d <device-id> --dart-define-from-file=.env                            # native
flutter run -d web-server --web-port 8080 --dart-define-from-file=.env             # web, JavaScript
flutter run -d web-server --web-port 8080 --dart-define-from-file=.env --wasm      # web, Wasm
```

- **Native:** drive and inspect the app with tools such as the Dart MCP server, Patrol, `adb`, and `xcrun simctl`. Keep the emulator or simulator window visible for the user. Without an interactive terminal, add `--pid-file <tmp>/flutter-run.pid` to `flutter run` and trigger a hot restart with `kill -USR2 <pid from that file>`. On hosts without POSIX signals, relaunch instead.
- **Web:** prefer [`playwright-cli`](https://playwright.dev/docs/getting-started-cli) over [Playwright MCP](https://playwright.dev/mcp/introduction#playwright-mcp-vs-playwright-cli) to save tokens. Open one browser per session with `playwright-cli open --browser=<chrome|firefox|webkit|msedge> --headed`, after checking that the browser is installed. If a browser is unavailable and no approved alternative exists, mark its checks `NOT RUN`. Keep the viewport within the browser window so the user can reach the widget. To apply a code change, restart the server and reload the page: signals can terminate a `web-server` run instead of restarting it.
- **Wasm evidence:** Flutter may silently fall back to JavaScript (see [Flutter Wasm browser compatibility](https://docs.flutter.dev/platform-integration/web/wasm)). Add a temporary diagnostic that prints `const bool.fromEnvironment('dart.tool.dart2wasm')` and require `true`; a loaded `main.dart.wasm` is supporting evidence. Never report a fallback run as Wasm coverage.

Verify events with the example's `called: …` logs, the browser console, and individual network entries, redacted as described in [Secrets](#secrets).

### Challenge solving

When a challenge appears, ask the user to solve and submit it. Then verify that `onChallengeSolved` fires with a non-null token and that the Execute/Reset states are as expected.

This check is required. If no challenge appears, investigate why; it may be a package defect. If the user cannot complete a challenge, mark the check `BLOCKED` with the reason.

### Scenarios

Cover these on every applicable target and build. Skip a scenario only when it does not apply to the platform (e.g., `loadingIndicator` and `onNavigationRequest` are native-only), and record the reason.

**Core flows:**

- loading indicator (native), `onCaptchaReady`, and the controls becoming enabled;
- `onChallengeShown`, then `onChallengeHidden`;
- `onChallengeSolved` with a non-null token, and the resulting Execute/Reset states;
- `reset`, then solving again;
- `destroy`, then controller calls after destruction;
- `execute` in invisible mode (temporary `useInvisibleMode: true`).

**Edge cases:**

- language, badge position, and `hideBadge` variants;
- `onTokenExpired`: wait for the [documented token lifetime](https://yandex.cloud/en/docs/smartcaptcha/concepts/validation) (five minutes) plus at most one minute; use the wait for checks on other targets. If the event does not fire, investigate;
- rapid or repeated `execute`, `reset`, and `destroy` calls, and calls made before the widget is ready;
- rotation or resize, backgrounding and resuming, hot restart, and widget disposal followed by a rebuild;
- web only: page reload, back/forward navigation, console errors, and JavaScript/Wasm parity;
- links inside the widget: native must respect `onNavigationRequest`; web must use normal browser behavior;
- no network at launch, and connection loss during a challenge: check `onNetworkError`, then recovery after the connection returns. On web, block Yandex by hostname (e.g., a Playwright route matching `url.hostname`), not by URL substring: the package's own module URLs contain `yandex`;
- small and large viewports, text scaling, dark mode, zoom, keyboard navigation, semantics, and screen-reader behavior where available;
- invalid client keys, run **without** `--dart-define-from-file=.env` so the real key cannot leak:
  - empty key: `flutter run -d <device-id> --dart-define=CLIENT_KEY=`;
  - non-empty invalid key: no define, so the app uses its placeholder default.

### Recording and attributing problems

For each problem, record the target, steps, expected and actual behavior, evidence (redacted log excerpt or screenshot path), and reproducibility. Classify the cause as `package`, `example app`, `test infrastructure`, `environment`, `external service`, or `unresolved`.

- **Package or service:** reproduce the problem on a minimal page that calls the Yandex JavaScript API directly. Keep it outside the repository, since it needs the key, and delete it afterward.
- **Defect or overload:** repeat the step once on an idle host; slow emulators cause timeouts and ANRs.
- **Defect or missed input:** before reporting an unresponsive control, retry once, after hovering or confirming the control is on screen. Automated clicks and user taps can fail to register.

## 5. Clean up

1. Stop every process you started, shut down simulators, and delete emulators you created. Keep downloaded images and runtimes only if the user approved keeping them.
2. Restore every file you edited from its saved copy, including `example/lib/main.dart` with the token-log redaction.
3. Restore the saved lockfiles if their contents changed.
4. Delete temporary logs, captures, screenshots, and the minimal page.
5. Confirm that `git status --porcelain` matches the output recorded in [step 1](#1-prepare).

## 6. Report

Follow [`report-template.md`](./report-template.md). Its structure, status definitions, and verdict definitions are mandatory.

- Attribute every error before assigning `FAIL`. Errors caused by the example app, test infrastructure, environment, or an external service must be reported with evidence and cause, but must not contribute to the `FAIL` verdict.
- If an excluded error does not prevent verification and the package's expected behavior is confirmed, mark the check `PASS` and document the error. If it prevents verification, mark it `BLOCKED`. If expected behavior or attribution remains unresolved, mark it `UNCLEAR`. An external error does not excuse a separately confirmed defect in the package's handling of that error.
- Assign each finding a severity:
  - `HIGH` – crash, data or token loss, or a core flow broken on a supported target;
  - `MEDIUM` – wrong callback, state, or cross-platform inconsistency that has a workaround;
  - `LOW` – cosmetic or minor usability issue.
- If a previous report was provided, fill in the template's "Previous findings" section: for each old finding, state whether it persists, is gone, or changed.

## References

- [Flutter supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms)
- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter WebAssembly](https://docs.flutter.dev/platform-integration/web/wasm)
- [Patrol documentation](https://patrol.leancode.co/documentation) and [web testing](https://patrol.leancode.co/documentation/web)
- [Playwright CLI](https://playwright.dev/docs/getting-started-cli) and [Playwright MCP](https://github.com/microsoft/playwright-mcp)
