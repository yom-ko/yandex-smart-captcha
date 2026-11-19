---
name: test-em-all-end-to-end
description: >-
  Perform comprehensive end-to-end testing of this Flutter package and its example app using automated test suites and exploratory testing on Android, iOS, and web. Use only when the user explicitly asks to run this `test-em-all-end-to-end` skill or another skill explicitly invokes it.
---

# Testing the package and example app end to end

## Main rules

- Test and report only; do not fix defects or edit tests unless asked.
- Run every build, test, and app launch in the snapshot from [step 1](#1-prepare), never in the repository. Make temporary edits only in the snapshot and only to the example app: the package under test stays unmodified. Report every edit.
- Derive expectations from the README, Dartdoc, and [Yandex documentation](https://yandex.cloud/en/docs/smartcaptcha/). Crashes and errors are evidence, not proof of a package defect. Report `UNCLEAR` when expectations or attribution cannot be established; never count skipped, filtered, or unrun tests as passing.
- The user solves challenges; never use solvers, image recognition, or tampered responses.
- Ask before installing global tools, system images, simulator runtimes, browsers, or third-party apps, including automatic downloads.
- Prefer disposable devices. Patrol uninstalls the example app (`com.example.example`) and its test app around each run and clears Android app data. On a device you did not create, check for an existing installation and ask before replacing it; without approval, mark the target `BLOCKED`.
- Record the PIDs, browser sessions, and device IDs you start. Stop only those resources, never by process name or broad matching. Ask before changing existing device or host network settings and restore them afterward.

### Secrets

- Load the client key only with `--dart-define-from-file=<env>`, where `<env>` is the absolute path of the repository's `example/.env`. Never copy, source, or print that file.
- Defines are compiled into build outputs: never commit, archive, upload, or share a live-key build. Never add `--verbose` to a live-key command: Flutter then logs the commands that carry the defines.
- Keep client keys and CAPTCHA tokens out of tool output, logs, captures, screenshots, and reports:
  - Before the first live-key launch, change the `onChallengeSolved` log in the snapshot's `example/lib/main.dart` to print `${token != null}` instead of the token.
  - Read app, device, and browser console output only through an allowlist of event names, booleans, and statuses. Redirect the output to a log in `<tmp>` ([step 1](#1-prepare)) and filter it, e.g., `grep -oE 'called: on[A-Za-z]+( with token: (true|false))?' <tmp>/run.log`. If a diagnosis needs unfiltered output, ask the user to inspect it privately, or mark the check `BLOCKED`.
  - Do not dump the DOM or network traffic: the hidden `smart-token` input holds the token, and request URLs can carry the key. For a single request, output only its hostname, path, status, type, and timing, never query strings or bodies.
  - Screenshots must not show keys, tokens, or full URLs.

### Required and optional checks

Every check is required except those on Edge, Playwright's Firefox and WebKit, older browser versions, and extra physical devices. Complete independent checks even when one target is blocked. Use the [report template](./report-template.md#verdict-definitions) to decide the verdict.

## 1. Prepare

1. Record the commit and `git status --porcelain` output. If a previous report was provided, list its findings for retesting.
2. Record `flutter --version`, `flutter devices`, `flutter emulators`, and `patrol --version`; record `node --version` and the Playwright version if used. On macOS with Xcode, also record `xcodebuild -version` and `xcrun simctl list runtimes`. On other hosts, mark the iOS checks `BLOCKED – no macOS/Xcode host`.
3. Use the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table) to confirm that the installed `patrol_cli` matches the `patrol` version in `example/pubspec.lock` and that Flutter meets their minimum.
4. Check `example/.env` without printing its values:

   ```bash
   grep -cE '^CLIENT_KEY=' example/.env   # must print 1
   grep -cvE "^[[:space:]]*(#.*)?$|^CLIENT_KEY=[\"']?ysc1_[^\"'[:space:]#]+[\"']?[[:space:]]*$" example/.env   # must print 0 (exit status 1 is expected)
   ```

   Together they confirm that the file holds one define, a client key (`ysc1_`; `ysc2_` marks the server key), and no line that Flutter would reject and echo. They do not prove that the service accepts the key. If the file is absent or fails a check, never pass it to a command: mark the dependent checks `BLOCKED` and continue with the key-free checks.
5. Create the snapshot. Run `mktemp -d` once and record the absolute path it prints as `<tmp>`. Shell state may not persist between commands, so write that literal path in every later command and start each one with `cd` into the snapshot. From the repository root:

   ```bash
   GIT_INDEX_FILE=<tmp>/index git add -A
   GIT_INDEX_FILE=<tmp>/index git checkout-index -a --prefix=<tmp>/snapshot/
   ```

   The throwaway index leaves the user's index and files unchanged. The snapshot receives tracked, staged, modified, and untracked files as they are in the working tree, but nothing gitignored: no `.env`, caches, or build outputs.
6. Resolve dependencies, enforcing the example lockfile as CI does. Pass `--no-pub` to every later Flutter command:

   ```bash
   cd <tmp>/snapshot && flutter pub get --no-example
   cd <tmp>/snapshot/example && flutter pub get --enforce-lockfile
   ```

   If the lockfile cannot be enforced, report it as a finding and repeat the command without `--enforce-lockfile`.

## 2. Select the targets

Check Flutter's [supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms) and vendor releases; use release notes or page history for an older installed SDK. Ask in one prompt for needed downloads, whether to keep them, approvals to replace apps on existing devices, and availability to solve challenges.

### Native

For Android and iOS, cover the latest stable OS supported by the installed SDK and the lowest OS supported by both Flutter and the example. Report any lower app minimum that the SDK does not support. Find the example's minimum in:

- Android: the effective `minSdkVersion` in `example/android/app/build.gradle`; for `flutter.minSdkVersion`, use the installed SDK's `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`.
- iOS: the Runner's `IPHONEOS_DEPLOYMENT_TARGET` in `example/ios/Runner.xcodeproj/project.pbxproj`, confirmed with `xcodebuild -showBuildSettings`. The Podfile platform applies only to pods.

Prefer emulators and simulators. If a required image or runtime is unavailable, use an approved physical device with that OS version or mark the target `BLOCKED`. Record the exact OS version.

On Android, record the active WebView provider and version from `adb -s <device-id> shell dumpsys webviewupdate` (`Current WebView package`); the provider can be Chrome. Prefer Play-enabled images and ask before updating an old provider. Age alone does not block testing. If Yandex's script fails because of an old provider that cannot be updated, mark the affected checks `BLOCKED` and attribute the failure to the environment.

### Web

Use the installed SDK's browser support matrix. Since Flutter 3.50, a release `--wasm` build runs as Wasm in Firefox and Safari only with a `wasmAllowList` opt-in and otherwise falls back to JavaScript. A debug `--wasm` run has no fallback. Verify the runtime named in each cell:

| Build | Chrome | Firefox and Safari |
| --- | --- | --- |
| Debug JS | JS | JS |
| Debug Wasm | Wasm | `N/A` |
| Release JS | JS | `N/A` – covered by the fallback |
| Release `--wasm` | Wasm | JS fallback |
| Release `--wasm` with opt-in | `N/A` | Wasm |

Mark the opt-in row `N/A` when the browser version cannot run Wasm. Before Flutter 3.50 there is no opt-in: record the runtime that the `--wasm` build actually uses in Firefox and Safari. Edge is optional and follows the Chrome column. Playwright's Firefox and WebKit are optional extra engines, not Firefox or Safari coverage; likewise, Chrome is not Edge coverage.

Record each browser's exact version and build; use `browser.version()` for Playwright and the browser's own version information for Firefox and Safari. Mark unavailable required browsers `BLOCKED`.

## 3. Run the automated suites

Run these key-free checks first. Compare them with the latest-SDK and example jobs in `.github/workflows/main.yml` and report differences. Skip CI's publication and archive steps: they are not runtime coverage. Never publish or upload anything.

From the snapshot root:

```bash
flutter analyze --no-pub   # also analyzes example/
flutter test --no-pub
flutter test --no-pub --platform chrome
flutter test --no-pub --platform chrome --wasm
```

The `chrome` backend of `--platform` is deprecated but is the only runner for the `@TestOn('browser')` suites in `test/src/web/`. Do not substitute `-d chrome`: it runs `test/` on the VM and skips them. Verify that tests from each of those suites ran, e.g., with `--reporter expanded`. If they cannot run in a browser, mark the lane `BLOCKED`. The `--wasm` lane has no JS fallback.

If `flutter test --verbose --help` lists `--[no-]deprecated-js-interop` (Flutter 3.50 and later), also run `flutter test --no-pub --platform chrome --no-deprecated-js-interop`; otherwise mark this modern-interop check `N/A`.

From the snapshot's `example/`:

```bash
flutter test --no-pub
flutter build apk --debug --no-pub --dart-define-from-file=.env.example
flutter build ios --no-codesign --no-pub --dart-define-from-file=.env.example   # macOS/Xcode
```

### Patrol

Read `patrol.test_directory` in `example/pubspec.yaml` and the tests there. The suite uses native selectors and skips its whole group on web: record web Patrol as `N/A – mobile-only suite`. From the snapshot's `example/`, run once per booted native target:

```bash
patrol test --device <device-id> --dart-define-from-file=<env>                          # Android or physical iOS
patrol test --device <simulator-id> --ios <ios-version> --dart-define-from-file=<env>   # iOS simulator
```

Use the simulator's actual runtime version for `--ios`; Patrol defaults to `latest`. Do not pass `--show-flutter-logs`: Patrol hides app logs by default. Confirm that the expected tests ran (readiness, challenge shown, destroy). Patrol neither solves the challenge nor verifies token issuance.

## 4. Explore the example app

Launch from the snapshot's `example/`. Use one free loopback port and one server at a time. Redirect each command's output to a log in `<tmp>` and read it as described in [Secrets](#secrets):

```bash
flutter run --no-pub -d <device-id> --pid-file <tmp>/run.pid --dart-define-from-file=<env>   # native
flutter run --no-pub -d web-server --web-port 8080 --dart-define-from-file=<env>             # debug JS
flutter run --no-pub -d web-server --web-port 8080 --dart-define-from-file=<env> --wasm      # debug Wasm
```

For the release rows of the [web matrix](#web), build once per row and stop the server before rebuilding. Serve only `build/web`, never the project directory:

```bash
flutter build web --release --no-pub --dart-define-from-file=<env>   # add --wasm for the Wasm rows
python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web
```

- **Native:** keep the device visible. Hot restart with `kill -USR2 "$(cat <tmp>/run.pid)"`; a cold relaunch is not evidence of hot restart. A temporary config edit needs a hot restart, not a hot reload.
- **Web:** drive Chrome and the optional engines with an installed `playwright` or `playwright-core` through its [browser API](https://playwright.dev/docs/api/class-browsertype), or with another tool that gives the same control over diagnostics. Launch headed (`{channel: 'chrome', headless: false}` for Chrome) in a fresh `browser.newContext()` per build, without tracing, video, HAR, or saved snapshots, and pass console messages through the allowlist. Open real Firefox and Safari separately, with the user's help if needed, and keep the widget visible. To apply an edit, restart `flutter run` and reload the page.
- **Origin:** SmartCaptcha checks the page's domain against the key's [allowed domains](https://yandex.cloud/en/docs/smartcaptcha/concepts/domain-validation). On web, serve from an allowed hostname that resolves locally (`--web-hostname` for `flutter run`); on native, set the widget's `baseUrl` to an allowed origin if needed. If no allowed origin is available, mark the dependent checks `BLOCKED`. Do not change DNS, hosts files, or the key's settings without approval.
- **Isolation:** `flutter run --wasm` serves the app cross-origin isolated; the static server does not, so release Wasm runs single-threaded and logs a multithreading warning. Record the difference; the warning is not a finding.
- **Wasm evidence:** show `const bool.fromEnvironment('dart.tool.dart2wasm')` in a temporary on-screen status. Only `true` proves Wasm execution; `false` in a release `--wasm` build proves the [JS fallback](https://docs.flutter.dev/platform-integration/web/wasm). For the opt-in row, create `example/web/flutter_bootstrap.js` with this [bootstrap configuration](https://docs.flutter.dev/platform-integration/web/initialization) and rebuild:

  ```js
  {{flutter_js}}
  {{flutter_build_config}}
  _flutter.loader.load({
    config: { wasmAllowList: { gecko: true, webkit: true } },
  });
  ```

Verify events with the allowlisted `called: …` lines. For browsers you cannot automate, add a temporary on-screen event display.

### Challenge solving

With `alwaysShowChallenge: true`, ask the user to solve the challenge once it appears. Without a solve, mark token-dependent checks `BLOCKED`, not the whole target. A client callback is evidence of token delivery, not server-side validation.

### Scenarios

The primary targets – the latest Android, the latest iOS, and Chrome with the debug JS build – get every scenario below. All other targets and builds get only the core flows; release builds skip invisible mode, which needs a rebuild. If a primary target is blocked, promote another target of the same platform. Reuse a result that Patrol already observed on the same target instead of repeating the check. Wait for callbacks or control states with a bounded timeout, not fixed sleeps. Change one option at a time.

**Core flows:**

- loading indicator (native) and `onCaptchaReady`: before readiness all controls are disabled; afterward Execute and Destroy are enabled, while Reset remains disabled;
- `onChallengeShown`, then `onChallengeHidden`;
- `onChallengeSolved` with a non-null token: Execute becomes disabled and Reset becomes enabled;
- `reset`: Execute becomes enabled and Reset becomes disabled, then solve again;
- `destroy`: all controls become disabled. Call the controller after destruction using a temporary control if needed; calls should have no effect. Do not use it after `dispose`;
- `execute` in invisible mode (temporary `useInvisibleMode: true`).

**Edge cases:**

- language variants; in invisible mode also vary badge position and `hideBadge`;
- `onTokenExpired`: wait five minutes from solving (the [documented token lifetime](https://yandex.cloud/en/docs/smartcaptcha/concepts/validation)) plus up to one minute; Execute should enable and Reset disable. Run other checks during the wait only if the app or tab stays active. Investigate a missing event; token TTL does not establish an exact callback deadline;
- rapid or repeated `execute`, `reset`, and `destroy` calls, and calls made before the widget is ready;
- rotation or resize, backgrounding and resuming, hot restart, and widget disposal followed by a rebuild;
- web only: page reload, back/forward navigation, and console errors;
- links inside the widget: native must respect `onNavigationRequest` for main-frame navigations; web must use normal browser behavior. SmartCaptcha's own iframes and the initial document bypass the native callback;
- no network at launch and connection loss during a challenge: check `onNetworkError` for a failed script load or service-emitted `network-error`, then restore the connection and recreate the widget. Do not assume every offline transition emits an event or the widget retries automatically. Use disposable devices or per-session controls; on web, block Yandex by hostname, not URL substring, since package module URLs contain `yandex`;
- `onJavaScriptError`: it has no documented trigger, so investigate and attribute any occurrence;
- small and large viewports, text scaling, dark mode, zoom, keyboard navigation, semantics, and screen-reader behavior where available;
- invalid keys, without `<env>`: use `--dart-define=CLIENT_KEY=` for an empty key, or omit the define to use the app's invalid placeholder.

### Recording and attributing problems

Record each problem's target, steps, expected and actual behavior, redacted evidence, reproducibility, and cause: `package`, `example app`, `test infrastructure`, `environment`, `external service`, or `unresolved`. A result that differs between targets or between JS and Wasm is a problem to record.

Retry a failure once when feasible, recording both outcomes; a passing retry does not erase the first failure. If attribution depends on Yandex, reproduce the problem on a minimal page in `<tmp>` that calls the Yandex JavaScript API directly with the same origin and options; insert the key with a command that does not print it. If attribution remains uncertain, report `UNCLEAR`.

## 5. Clean up

Clean up even after failure or cancellation:

1. Stop only the resources you started, shut down devices you booted, delete devices you created, and restore changed settings. Remove this run's downloads unless they are shared, in use, or approved to keep.
2. Run `rm -rf <tmp>` with the recorded path: it holds the snapshot, live-key builds, logs, and captures. Keep sanitized evidence only if requested, and do not cite deleted screenshots.
3. Confirm that `git status --porcelain` matches [step 1](#1-prepare). Report any difference and anything that could not be cleaned up safely.

## 6. Report

Follow [`report-template.md`](./report-template.md). Its structure and formatting are mandatory.

Report command outcomes separately from the package verdict: a nonzero exit needs investigation, not an automatic package `FAIL`.

- Assign each finding a severity:
  - `HIGH` – crash, data or token loss, or a core flow broken on a supported target;
  - `MEDIUM` – wrong callback, state, or cross-platform inconsistency that has a workaround;
  - `LOW` – cosmetic or minor usability issue.
- If a previous report was provided, fill in the "Previous findings" section: for each old finding, state if it persists, is gone, changed, or could not be verified.

## References

- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Patrol documentation](https://patrol.leancode.co/documentation) and [`patrol test` reference](https://patrol.leancode.co/cli-commands/test)
- [Playwright library](https://playwright.dev/docs/library)
