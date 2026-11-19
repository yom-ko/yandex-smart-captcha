---
name: test-em-all-end-to-end
description: >-
  Run automated and exploratory end-to-end checks for this Flutter package and its example on Android, iOS, and web. Use only when the user explicitly asks to run this `test-em-all-end-to-end` skill or another skill explicitly invokes it.
---

# Testing the package and example app end to end

## Main rules

- Test and report only; do not fix defects or edit tests unless explicitly asked.
- Run all builds, tests, and app launches in the [step 1](#1-prepare) snapshot, never in the repository. Edit only its example app; keep the package under test untouched. Report every edit.
- Derive package expectations from its README and Dartdoc; use [Yandex documentation](https://yandex.cloud/en/docs/smartcaptcha/) for service behavior. Treat errors as evidence, not proof, of a defect. Report `UNCLEAR` when expected behavior or attribution cannot be established.
- Handle setup and observation yourself. Ask only for required approvals, challenge solves, or fixed-choice observations when needed. Never automate challenge solving or forge responses.
- Ask before installing host-level tools, SDK components, emulator images, simulator runtimes, browsers, or third-party apps. Package dependencies may be resolved with installed tools.
- Use disposable devices where possible. Patrol may uninstall apps and clear Android data. On existing devices, check installed app IDs and effective Patrol/Gradle settings. Ask before replacing or uninstalling apps or installing test services, or mark the target `BLOCKED`. Remove only services installed by this run.
- Record PIDs, browser session IDs, and device IDs for resources you start. Stop only those resources using their exact identifiers; never terminate processes by name or broad matching. Ask before changing host or device network settings, and restore their original state during cleanup.

### Sensitive output

Never expose client keys or CAPTCHA tokens in output, screenshots, or reports.

- Load the key only with `--dart-define-from-file="<env>"`, using the original repository's `example/.env`; never copy, source, or print it. Before launch, change the snapshot's `onChallengeSolved` log to print whether the token is non-null.
- Keep live-key builds in the snapshot and remove them during cleanup. Never use verbose logging, commit, or share these builds.
- Save command and process output to separate logs in `<tmp>`. Do not display raw logs, DOM, or network data; inspect only sanitized evidence. Redact screenshots before sharing them.

Client keys may appear in URLs or the DOM; CAPTCHA tokens may appear in the DOM or app logs.

### Required and optional checks

Required coverage includes the latest and lowest supported Android and iOS targets, Chrome's web matrix, and real Firefox and Safari where the installed SDK and browser versions support the required runtime. Mark unavailable required targets `BLOCKED`; another browser engine or OS does not count as equivalent coverage.

Optional coverage is Edge (follow the Chrome matrix), Playwright's Firefox and WebKit (extra engines, not real Firefox or Safari), and extra physical devices. Complete independent checks even when one required target is blocked. Use the [report template](./report-template.md#verdict-definitions) to decide the verdict.

## 1. Prepare

1. Record the commit and `git status --porcelain` output. If a previous report was provided, list its findings for retesting.
2. Record `flutter --version`, `flutter devices`, `flutter emulators`, and `patrol --version`. On macOS with Xcode, also record `xcodebuild -version` and `xcrun simctl list runtimes`; otherwise mark iOS checks `BLOCKED – no macOS/Xcode host`.
3. Use the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table) to confirm that the installed `patrol_cli` matches the `patrol` version in `example/pubspec.lock` and that Flutter meets their minimum.
4. From the repository root, check `example/.env` without printing its values:

   ```bash
   # Must print 1:
   grep -cE '^CLIENT_KEY=' example/.env
   # Must print 0 (exit status 1 is expected):
   grep -cvE "^[[:space:]]*(#.*)?$|^CLIENT_KEY=(ysc1_[^\"'[:space:]#]+|\"ysc1_[^\"'[:space:]#]+\"|'ysc1_[^\"'[:space:]#]+')[[:space:]]*$" example/.env
   ```

   Expect `1` from the first check and `0` from the second (its exit status of `1` is expected). If the file is missing or either check fails, do not pass it to a command; mark live-key checks `BLOCKED` and continue with key-free checks.

5. Create the snapshot. Run `mktemp -d` once and record the absolute path it prints as `<tmp>`. From the repository root:

   ```bash
   mkdir -p "<tmp>/objects"
   GIT_INDEX_FILE="<tmp>/index" GIT_OBJECT_DIRECTORY="<tmp>/objects" git add -A -- . ':(exclude)example/.env'
   GIT_INDEX_FILE="<tmp>/index" GIT_OBJECT_DIRECTORY="<tmp>/objects" git checkout-index -a --prefix="<tmp>/snapshot/"
   ```

   The throwaway index and object directory leave the user's index and Git objects unchanged. The snapshot contains nonignored files as they are in the working tree, not staged-only versions; `example/.env` is explicitly excluded. Add pathspec exclusions for any other sensitive files.

   Shell state may not persist between commands, so each command that needs the snapshot directory starts with its own `cd`. Replace placeholders with their values, keeping the quotes; use filename-safe labels, with a distinct `<target>` for each target/build and `<attempt>` for each retry. Run repository-status commands from the repository root.

6. Verify `flutter --version` in the snapshot and ensure Patrol uses the same SDK, including any `PATROL_FLUTTER_COMMAND` override. If the snapshot's SDK differs from step 1, recheck compatibility and report both versions.

   Resolve dependencies, enforcing the example lockfile as CI does. Pass `--no-pub` to later `flutter analyze`, `flutter test`, `flutter build`, and `flutter run` commands:

   ```bash
   cd "<tmp>/snapshot" && flutter pub get --no-example
   cd "<tmp>/snapshot/example" && flutter pub get --enforce-lockfile
   ```

   If the lockfile cannot be enforced, report it as a finding and repeat the command without `--enforce-lockfile`.

## 2. Select the targets

Check Flutter's [supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms) and vendor releases; use release notes or page history for an older installed SDK.

### Native

For Android and iOS, cover the latest stable OS supported by the installed SDK and the lowest OS supported by both Flutter and the example. Report any lower app minimum that the SDK does not support. Find the example's minimum in these locations:

- Android: the effective `minSdkVersion` in `example/android/app/build.gradle`; for `flutter.minSdkVersion`, use the installed SDK's `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`.
- iOS: the Runner's `IPHONEOS_DEPLOYMENT_TARGET` in `example/ios/Runner.xcodeproj/project.pbxproj`, confirmed with `xcodebuild -project "<tmp>/snapshot/example/ios/Runner.xcodeproj" -target Runner -showBuildSettings`. The Podfile platform applies only to pods.

Prefer emulators and simulators. If a required image or runtime is unavailable, use an approved physical device with that OS version, or mark the target `BLOCKED` and cover the nearest available version as an extra target. Record the exact OS version.

On Android, record the WebView provider and version from `adb -s "<device-id>" shell dumpsys webviewupdate`. Ask before updating it. If an incompatible provider prevents a check and cannot be updated, mark the check `BLOCKED` due to the environment.

### Web

Use the installed SDK's browser support matrix. In Flutter 3.50 and later, a release `--wasm` build falls back to JavaScript in Firefox and Safari unless `wasmAllowList` opts them in; a debug `--wasm` run has no fallback. Verify the runtime in each matrix cell with the [Wasm evidence](#wasm-evidence):

| Build | Chrome | Firefox and Safari |
| --- | --- | --- |
| Debug JS | JS | JS |
| Debug Wasm | Wasm | `N/A` |
| Release JS | JS | `N/A` – covered by the fallback |
| Release `--wasm` | Wasm | JS fallback |
| Release `--wasm` with opt-in | `N/A` | Wasm |

- Mark the opt-in row `N/A` when the browser version cannot run Wasm; its JS checks still apply. If Chrome cannot run Wasm, mark its required Wasm checks `BLOCKED` and expect JS fallback from the release build.
- Before Flutter 3.50, there is no opt-in. Mark that row `N/A` and record which runtime the `--wasm` build uses in Firefox and Safari.

Record each browser's version.

### Approvals

Collect required approvals in one prompt before testing. Include downloads, app replacements, test-service installs, WebView or network changes, Safari automation, and planned challenge solves. If another approval is needed, ask with the next solve request or mark the check `BLOCKED`.

## 3. Run the automated suites

Run these key-free checks first:

Package checks:

```bash
cd "<tmp>/snapshot" && flutter analyze --no-pub   # also analyzes example/
cd "<tmp>/snapshot" && flutter test --no-pub
cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome
cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome --wasm
```

- The `chrome` backend of `--platform` is deprecated but is the only runner for the `@TestOn('browser')` suites in `test/src/web/`. Do not substitute `-d chrome`: it runs `test/` on the VM and skips them.
- Verify that tests from each browser suite ran, for example with `--reporter expanded`. If a suite cannot run in a browser, mark the lane `BLOCKED`.
- Verify that the `--wasm` lane ran as Wasm; it has no JavaScript fallback.
- If `flutter test --verbose --help` lists `--[no-]deprecated-js-interop` (Flutter 3.50 and later), also run `cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome --no-deprecated-js-interop`; otherwise mark this modern-interop check `N/A`.

Example checks:

```bash
cd "<tmp>/snapshot/example" && flutter test --no-pub
cd "<tmp>/snapshot/example" && flutter build apk --debug --no-pub --dart-define-from-file=.env.example
cd "<tmp>/snapshot/example" && flutter build ios --no-codesign --no-pub --dart-define-from-file=.env.example   # macOS/Xcode
```

### Patrol

Read `patrol.test_directory` in `example/pubspec.yaml` and inspect the tests there. The suite uses native selectors and skips its entire group on web; record web Patrol as `N/A – mobile-only suite`. Run Patrol once for each booted native target:

Before each Android run, clear only the snapshot's `example/build/app/outputs/androidTest-results/connected/` directory so old results cannot be mistaken for the current run.

```bash
# Android or physical iOS:
cd "<tmp>/snapshot/example" && patrol test --device "<device-id>" \
  --dart-define-from-file="<env>" > "<tmp>/patrol-<target>-<attempt>.log" 2>&1
# iOS simulator:
cd "<tmp>/snapshot/example" && patrol test --device "<simulator-id>" --ios "<ios-version>" \
  --dart-define-from-file="<env>" > "<tmp>/patrol-<target>-<attempt>.log" 2>&1
```

- Use the simulator's runtime version for `--ios`; Patrol defaults to `latest`.
- Patrol neither solves the challenge nor verifies token issuance.

After each run, record test names, outcomes, and counts from its new result files, not the console, to confirm that the expected tests ran (readiness, challenge shown, and destroy):

- Android: the JUnit XML files under `build/app/outputs/androidTest-results/connected/`.
- iOS: use this attempt's `testNodes`/`children` tree from the `tests` command below; `summary` reports totals only. If unavailable, mark the cases unverified.

  ```bash
  xcrun xcresulttool get test-results tests --path "<tmp>/snapshot/example/build/ios_results_<timestamp>.xcresult" \
    > "<tmp>/ios-tests-<target>-<attempt>.json" 2> "<tmp>/xcresult-<target>-<attempt>.log"
  ```

If a Patrol test times out, retry its failing step in the debug app on the same target before attributing the failure.

## 4. Explore the example app

Launch the example on each target. Keep the device visible. On macOS or Linux, read `<tmp>/run-<target>-<attempt>.pid` and, while that run is active, send `kill -USR2 <pid>` to the recorded numeric PID; on Windows, press `R` in the interactive session. A cold relaunch does not count as a hot restart.

For web, choose an available loopback port (the examples use `8080`) and a `<host>` that resolves to `127.0.0.1` and satisfies domain validation if enabled. Run one server at a time. Save command output in separate logs as described in [Sensitive output](#sensitive-output):

```bash
cd "<tmp>/snapshot/example" && flutter run --no-pub -d "<device-id>" --pid-file "<tmp>/run-<target>-<attempt>.pid" \
  --dart-define-from-file="<env>" > "<tmp>/run-<target>-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && flutter run --no-pub -d web-server --web-hostname "<host>" --web-port 8080 \
  --pid-file "<tmp>/run-<target>-<attempt>.pid" --dart-define-from-file="<env>" > "<tmp>/web-debug-js-<browser>-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && flutter run --no-pub -d web-server --web-hostname "<host>" --web-port 8080 --wasm \
  --pid-file "<tmp>/run-<target>-<attempt>.pid" --dart-define-from-file="<env>" > "<tmp>/web-debug-wasm-<browser>-<attempt>.log" 2>&1
```

Build each release variant in the web matrix into a separate directory. For the Flutter 3.50+ opt-in row, add the bootstrap described below. Serve only a build directory, never the project directory:

```bash
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-js" > "<tmp>/build-release-js-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --wasm --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-wasm" > "<tmp>/build-release-wasm-<attempt>.log" 2>&1
# Flutter 3.50+: add the temporary opt-in bootstrap described below, then:
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --wasm --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-wasm-opt-in" > "<tmp>/build-release-wasm-opt-in-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && python3 -m http.server 8080 --bind 127.0.0.1 \
  --directory "<tmp>/web/<variant>" > "<tmp>/http-server-<variant>-<attempt>.log" 2>&1
```

Run the static server once for each release variant and stop it before switching directories. Open `http://<host>:8080/` in the browser.

- If SmartCaptcha's [domain validation](https://yandex.cloud/en/docs/smartcaptcha/concepts/domain-validation) is enabled, use `--web-hostname` with an allowed hostname that resolves locally; on native, set the widget's `baseUrl` to an allowed origin if needed. If no allowed origin is available, mark dependent checks `BLOCKED`. Do not change DNS, hosts files, or key settings without approval.
- The static server does not set cross-origin isolation headers, so Wasm rendering is single-threaded. Record this limitation rather than treating its warning alone as a package defect.
- Verify events with sanitized `called: …` lines. If browser console output is unavailable, temporarily show an event history (names and token presence only) and the Wasm value in the app.
- Use [browser automation](#browser-automation) where available and keep the widget visible. After a debug edit, restart `flutter run` and reload the page.

### Browser automation

Use Playwright CLI over MCP when possible. For Chrome or Edge, select the installed `chrome` or `msedge` channel. Run headed and set `outputDir` under `<tmp>` with `--config`; never print snapshots or raw logs. Otherwise, use the Playwright API in a fresh context, or MCP if it can avoid exposing raw snapshots and logs; avoid tracing, video, and HAR.

Use WebDriver BiDi or geckodriver for installed Firefox and `safaridriver` for Safari; Playwright cannot drive those branded browsers. Automate Safari only with the user's approval.

### Wasm evidence

Log the runtime at startup by temporarily adding this line to the example's `main()`. Read its output through the allowlist:

```dart
debugPrint('Wasm: ${const bool.fromEnvironment('dart.tool.dart2wasm')}');
```

Only `true` proves Wasm execution; `false` in a release `--wasm` build proves the [JS fallback](https://docs.flutter.dev/platform-integration/web/wasm).

For the Flutter 3.50+ opt-in build, add `wasmAllowList` to the snapshot's existing `example/web/flutter_bootstrap.js`, preserving its other settings, then restore the file. If no bootstrap exists, create one with this [configuration](https://docs.flutter.dev/platform-integration/web/initialization) and remove it after the build:

```js
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: { wasmAllowList: { gecko: true, webkit: true } },
});
```

### Challenge solving

With `alwaysShowChallenge: true`, token-dependent checks require the user to solve a challenge. Group solve requests, tell the user how many are needed, and handle all controls yourself. Verify results from `onChallengeSolved`; if you cannot observe one, ask for a fixed-choice observation and report it as user-reported.

Without a solve, mark token-dependent checks `BLOCKED`, not the whole target. A client callback proves token delivery only, not server-side validation.

### Scenarios

Run core flows on every required target. Use the primary targets for additional edge cases:

| Target | Coverage |
| --- | --- |
| Primary: the latest Android, the latest iOS, and Chrome with the debug JS build | Core flows and selected edge cases |
| All other targets and builds | Core flows only, with a single solve. Release builds skip invisible mode, which needs a rebuild |

- If a primary target is blocked, promote another target of the same platform.
- Wait for callbacks or control states with a bounded timeout, not fixed sleeps.
- Change one option at a time.
- Record results as you go and use them to complete the report.

**Core flows:**

- **Load.** All controls are disabled before readiness; afterward Execute and Destroy are enabled, while Reset remains disabled. Verify the native loading indicator and `onCaptchaReady`.
- **Challenge.** Verify `onChallengeShown` when the popup opens and `onChallengeHidden` when it closes.
- **Solve.** `onChallengeSolved` with a non-null token. Execute becomes disabled and Reset becomes enabled.
- **Reset.** Execute becomes enabled and Reset becomes disabled. On a primary target, solve again.
- **Destroy.** All controls become disabled. Call the controller after destruction, using a temporary control if needed: the calls should have no effect. Do not use the controller after `dispose`.
- **Invisible mode.** `execute` with a temporary `useInvisibleMode: true`.

**Optional edge cases.**

- **Options and validation.** Try language variants, invisible-mode badge settings, and an invalid key.
- **State and lifecycle.** Test calls before readiness, repeated controller calls, resize or rotation, hot restart, and disposal followed by rebuild.
- **Network and web.** Check `onNetworkError` during script-load failure or connection loss; test page reload, navigation, and native `onNavigationRequest`.
- **Token expiry.** Observe `onTokenExpired` when time permits.

### Recording and attributing problems

For each problem, record the target, steps, expected and actual behavior, redacted evidence, reproducibility, and likely cause. Record differences between targets and between JS and Wasm.

- When feasible, retry a failure once and record both outcomes. A passing retry does not erase the initial failure.
- If attribution remains uncertain, report `UNCLEAR`.

## 5. Clean up

Clean up even after failure or cancellation:

1. Stop only the processes, browser sessions, and devices you started. Remove live-key apps and test services installed by this run, restore changed settings, and remove unneeded downloads.
2. Run `rm -rf "<tmp>"` with the recorded path. Keep sanitized evidence only if requested; do not cite deleted captures.
3. Confirm that `git status --porcelain` matches [step 1](#1-prepare). Report any difference and anything that could not be cleaned up safely.

## 6. Report

Follow [`report-template.md`](./report-template.md); its structure and formatting are mandatory.

Report command outcomes separately from the package verdict: a nonzero exit needs investigation, not an automatic package `FAIL`.

Use the severity levels and previous-findings section in the report template.

Severity: `HIGH` for a crash, token/data loss, or broken core flow; `MEDIUM` for an incorrect callback or state with a workaround; `LOW` for a minor cosmetic or usability issue.

## References

- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Patrol documentation](https://patrol.leancode.co/documentation) and [`patrol test` reference](https://patrol.leancode.co/cli-commands/test)
- [Playwright CLI](https://playwright.dev/agent-cli/introduction) and [Playwright MCP](https://playwright.dev/mcp/introduction)
