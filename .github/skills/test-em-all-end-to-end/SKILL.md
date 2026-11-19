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
- Handle setup and observation yourself. Ask only for required approvals, challenge solves, necessary simulator selection or Safari manual flows, or fixed-choice observations when needed. Never automate challenge solving or forge responses. Plan the [approval request](#approvals) after selecting targets, and obtain approval before any action that requires it.
- Ask before installing host-level tools, SDK components, emulator images, simulator runtimes, browsers, or third-party apps. Package dependencies may be resolved with installed tools.
- Use disposable devices where possible. Patrol may uninstall apps and clear Android data. On existing devices, check installed app IDs and effective Patrol/Gradle settings. Ask before replacing or uninstalling apps or installing test services, or mark the target `BLOCKED`. Remove only services installed by this run.
- Record PIDs, browser session IDs, and device IDs for resources you start. Stop only those resources using their exact identifiers; never terminate processes by name or broad matching. Ask before changing host or device network settings, and restore their original state during cleanup.

### Sensitive output

Never expose client keys or CAPTCHA tokens in output, screenshots, or reports.

- Load the key only with `--dart-define-from-file="<env>"`, using the original repository's `example/.env`; never copy, source, or print it. Before any live-key launch, apply the [example patch](#prepare-the-example-app), which logs only whether the token is non-null.
- Keep live-key builds in the snapshot and remove them during cleanup. Never use verbose logging, commit, or share these builds.
- Save command and process output to separate logs in `<tmp>`. Do not display raw logs, DOM, or network data; inspect only sanitized evidence. Redact screenshots before sharing them.

Client keys may appear in URLs or the DOM; CAPTCHA tokens may appear in the DOM or app logs.

### Required and optional checks

Required coverage includes the latest and lowest supported Android and iOS targets, Chrome's web matrix, and real Firefox and Safari where the installed SDK and browser versions support the required runtime. Mark unavailable required targets `BLOCKED`; another browser engine or OS does not count as equivalent coverage.

Optional coverage is Edge (follow the Chrome matrix), Playwright's Firefox and WebKit (extra engines, not real Firefox or Safari), and extra physical devices. Complete independent checks even when one required target is blocked. Use the [report template](./report-template.md#verdict-definitions) to decide the verdict.

### Helper scripts

Use these tested helpers instead of writing your own.

| Script | Purpose |
| --- | --- |
| [`patch_example.py`](./scripts/patch_example.py) | Applies the temporary example edits: token-free logs, the Wasm marker, an on-screen event history, a `Probe` button, and option switches. |
| [`patrol_results.py`](./scripts/patrol_results.py) | Prints Patrol test names, outcomes, and a redacted first line of each failure from Android JUnit XML or iOS `xcresulttool` JSON. |
| [`events.sh`](./scripts/events.sh) | Prints, counts, or waits for sanitized events in a `flutter run` log. |
| [`android.sh`](./scripts/android.sh) | Reads, waits for, and taps Android buttons; taps the SmartCaptcha checkbox, `?` icon, or a point in the WebView; records the screen; rotates and restores. |
| [`ios.sh`](./scripts/ios.sh) | Takes screenshots of, taps, and records an iOS simulator (macOS). |
| [`frames.swift`](./scripts/frames.swift) | Extracts PNG frames from a screen recording (macOS, no ffmpeg). |
| [`web.mjs`](./scripts/web.mjs) | Drives Chrome (CDP), Firefox (WebDriver BiDi), and Safari (`safaridriver`) with Node 22+ and no packages. |

`<skill>` is the absolute path of the directory containing this file. Each script prints only sanitized output and documents its usage in its header. The `wait` commands give the bounded waits that the scenarios require; a timeout exits with `1` and prints the last state.

## 1. Prepare

1. Record the commit and `git status --porcelain` output. If a previous report was provided, list its findings for retesting.
2. Record `flutter --version`, `flutter devices`, `flutter emulators`, and `patrol --version`. On macOS with Xcode, also record `xcodebuild -version` and `xcrun simctl list runtimes`; otherwise mark iOS checks `BLOCKED – no macOS/Xcode host`.

   Token-dependent checks on an iOS simulator need a visible simulator for the user to solve challenges in. Xcode 27 replaced `Simulator.app` with `DeviceHub.app`, so check for either app:

   ```bash
   test -d "$(xcode-select -p)/../Applications/DeviceHub.app" || test -d "$(xcode-select -p)/Applications/Simulator.app"
   ```

   If both are missing, simulators run headless: mark token-dependent iOS simulator checks `BLOCKED` now.

3. Use the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table) to confirm that the installed `patrol_cli` matches the `patrol` version in `example/pubspec.lock` (`awk '/^  patrol:/{f=1} f&&/version:/{print;exit}' example/pubspec.lock`) and that Flutter meets their minimum.
4. From the repository root, check `example/.env` without printing its values:

   ```bash
   # Must print 1:
   grep -cE '^CLIENT_KEY=' example/.env
   # Must print 0 (exit status 1 is expected):
   grep -cvE "^[[:space:]]*(#.*)?$|^CLIENT_KEY=(ysc1_[^\"'[:space:]#]+|\"ysc1_[^\"'[:space:]#]+\"|'ysc1_[^\"'[:space:]#]+')[[:space:]]*$" example/.env
   ```

   Expect `1` from the first check and `0` from the second (its exit status of `1` is expected). If the file is missing or either check fails, do not pass it to a command; mark live-key checks `BLOCKED` and continue with key-free checks. Otherwise, use its absolute path as `<env>`.

5. Create the snapshot. Run `mktemp -d` once and record the absolute path it prints as `<tmp>`. From the repository root:

   ```bash
   mkdir -p "<tmp>/objects" &&
     GIT_INDEX_FILE="<tmp>/index" GIT_OBJECT_DIRECTORY="<tmp>/objects" git add -A -- . &&
     GIT_INDEX_FILE="<tmp>/index" GIT_OBJECT_DIRECTORY="<tmp>/objects" git checkout-index -a --prefix="<tmp>/snapshot/" &&
     test -f "<tmp>/snapshot/pubspec.yaml" && test ! -e "<tmp>/snapshot/example/.env" && echo SNAPSHOT_OK
   ```

   The command must print `SNAPSHOT_OK`. The throwaway index and object directory leave the user's index and Git objects unchanged. The snapshot contains nonignored files as they are in the working tree, not staged-only versions. Ignored files, including `example/.env`, are never added. Do not name an ignored path in the pathspec: `git add` then exits with `1` even though it adds the other files, which breaks the command chain. To exclude other sensitive files that are not ignored, append `':(exclude)<path>'`.

   Shell state may not persist between commands, so each command that needs the snapshot directory starts with its own `cd`. Replace placeholders with their values, keeping the quotes; use filename-safe labels, with a distinct `<target>` for each target/build and `<attempt>` for each retry. Run repository-status commands from the repository root.

6. Verify `flutter --version` in the snapshot and ensure Patrol uses the same SDK, including any `PATROL_FLUTTER_COMMAND` override. If the snapshot's SDK differs from the version recorded in item 2, recheck compatibility and report both versions.

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

Prefer emulators and simulators, and record the exact OS version. If a required image or runtime is unavailable, include a download or a physical device with that OS version in the [approval request](#approvals). After that request, if neither can be used, mark the target `BLOCKED` and cover the nearest available version as an extra target. Current Xcode releases may not offer old iOS runtimes: if an approved `xcodebuild -downloadPlatform iOS -buildVersion <version>` fails and no approved physical device has that OS, mark the target `BLOCKED`.

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

Plan the solve budget before asking, using the primary and other targets in [Scenarios](#scenarios): about three solves for each primary target (solve, solve again after reset, and an allowance for invisible mode) and one for every other target or build. A full matrix needs about 20. State the total in the approval prompt.

Collect required approvals in one prompt after selecting targets and before testing or taking any action that needs approval. Include host-level downloads and installations, app replacements, test-service installs, WebView or network changes, Safari automation, macOS Accessibility permission for [`ios.sh`](./scripts/ios.sh) taps, and planned challenge solves. Resolving package dependencies with installed tools in [Prepare](#1-prepare) does not require a separate approval. If another approval is needed, obtain it before the action, for example with the next solve request, or mark the check `BLOCKED`.

### Long-lived processes

`flutter run`, emulators, browsers, `safaridriver`, and static servers must outlive the command that starts them. A process started with `&` or `nohup` in a one-shot shell can die when that shell exits. Start each in its own background session (in agent tools, an async or background shell) and let it replace the shell, so the printed PID is the process itself:

```bash
echo "pid $$"; exec <command> > "<tmp>/<name>-<attempt>.log" 2>&1
```

For commands that change directory, run `cd` before `exec`, as shown below. Record the PID, read it back from the session output when needed, and stop the process with `kill <pid>` when it is no longer needed or during cleanup. Agent sandboxes may reject `kill` unless it gets a literal number, so never pass `$(cat …)` or a variable: read the number first, then run `kill <number>`.

### Start selected native targets

After approvals, obtain approved images or runtimes, start selected emulators or simulators as needed, wait until they are ready, and record their device IDs. When a token-dependent check needs a visible iOS simulator, boot it if it is not already booted:

```bash
xcrun simctl boot "<simulator-id>"
```

Then wait for it, open the available simulator app, and ask the user to select the simulator in its sidebar:

```bash
xcrun simctl bootstatus "<simulator-id>" -b
open -a DeviceHub   # Before Xcode 27: open -a Simulator
```

Once an Android target is running, record its WebView provider and version from `adb -s "<device-id>" shell dumpsys webviewupdate`. Below API 26 that command prints nothing; use `adb -s "<device-id>" shell settings get global webview_provider` and `adb -s "<device-id>" shell dumpsys package <provider> | grep versionName` instead. Ask before updating the provider. If an incompatible provider prevents a check and cannot be updated, mark the check `BLOCKED` due to the environment. `google_apis` images reject Google-signed WebView updates (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), so do not try to sideload one; their old built-in WebView can render SmartCaptcha while ignoring taps on it.

## 3. Run the automated suites

Run these key-free checks first. Save each command's output to its own log in `<tmp>`.

### Package checks

```bash
cd "<tmp>/snapshot" && flutter analyze --no-pub   # also analyzes example/
cd "<tmp>/snapshot" && flutter test --no-pub
cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome
cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome --wasm
```

- The `chrome` backend of `--platform` is deprecated but is the only runner for the `@TestOn('browser')` suites in `test/src/web/`. Do not substitute `-d chrome`: it runs `test/` on the VM and skips them.
- Read test outcomes with `grep -E 'All tests passed|Some tests failed' "<log>" | tail -1`, not from the log's end: browser lanes end with console noise.
- Verify that tests from each browser suite ran, for example with `--reporter expanded`. If a suite cannot run in a browser, mark the lane `BLOCKED`.
- Verify that the `--wasm` lane ran as Wasm; it has no JavaScript fallback.
- If `flutter test --verbose --help` lists `--[no-]deprecated-js-interop` (Flutter 3.50 and later), also run `cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome --no-deprecated-js-interop`; otherwise mark this modern-interop check `N/A`.

### Example checks

```bash
cd "<tmp>/snapshot/example" && flutter test --no-pub
cd "<tmp>/snapshot/example" && flutter build apk --debug --no-pub --dart-define-from-file=.env.example
cd "<tmp>/snapshot/example" && flutter build ios --no-codesign --no-pub --dart-define-from-file=.env.example   # macOS/Xcode
```

### Prepare the example app

After the example checks and before Patrol or any live-key launch, patch the snapshot's example. The patch adds a button, so the example's button-spacing widget test fails afterward; Patrol selectors are unaffected.

```bash
python3 "<skill>/scripts/patch_example.py" apply "<tmp>/snapshot/example/lib/main.dart"
```

It must print `ok`; on an error it changes nothing. Report its edits, all marked `E2E-TEMP`:

- `onChallengeSolved` logs only `token non-null: true|false`, and `onNavigationRequest` logs only the host.
- `main()` logs the [Wasm evidence](#wasm-evidence) line and mirrors allowlisted log lines into an on-screen `E2E: …` event history above the buttons.
- An always-enabled `Probe` button calls `execute`, `reset`, and `destroy`, then logs `called: probe done`. Use it for calls before readiness and after destruction.
- Constant switches for invisible mode, an invalid key, the language, and blocking all navigation. Change one with `python3 "<skill>/scripts/patch_example.py" set "<tmp>/snapshot/example/lib/main.dart" <switch> <value>`, then hot restart, or relaunch where hot restart is unavailable.

### Patrol

Read `patrol.test_directory` in `example/pubspec.yaml` and inspect the tests there. The suite uses native selectors and skips its entire group on web; record web Patrol as `N/A – mobile-only suite`. If `<env>` is unavailable, mark the live-key Patrol checks `BLOCKED` and continue with independent checks. Otherwise, run Patrol once for each booted native target:

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

After each run, record test names, outcomes, and counts from its new result files, not the console, to confirm that the expected tests ran (readiness, challenge shown, and destroy). [`patrol_results.py`](./scripts/patrol_results.py) prints them, with a redacted `reason:` line under each failed case:

- Android: `python3 "<skill>/scripts/patrol_results.py" android "<tmp>/snapshot/example/build/app/outputs/androidTest-results/connected"`.
- iOS: export this attempt's `testNodes` tree, then run `python3 "<skill>/scripts/patrol_results.py" ios "<tmp>/ios-tests-<target>-<attempt>.json"`. The newest bundle is `ls -td "<tmp>/snapshot/example/build/"ios_results_*.xcresult | head -1`. The `summary` command reports totals only. If the tree is unavailable, mark the cases unverified.

  ```bash
  xcrun xcresulttool get test-results tests --path "<tmp>/snapshot/example/build/ios_results_<timestamp>.xcresult" \
    > "<tmp>/ios-tests-<target>-<attempt>.json" 2> "<tmp>/xcresult-<target>-<attempt>.log"
  ```

If a Patrol test times out, retry its failing step in the debug app on the same target during [step 4](#4-explore-the-example-app) before attributing the failure.

## 4. Explore the example app

For each target or build, launch the example using the [long-lived process](#long-lived-processes) instructions, run the scenarios, and keep the device visible. Stop a web server before switching to another build; the same build can be reused across browsers. If `<env>` is unavailable, mark live-key checks `BLOCKED` and continue independent key-free checks.

If SmartCaptcha's [domain validation](https://yandex.cloud/en/docs/smartcaptcha/concepts/domain-validation) is enabled, use `--web-hostname` with an allowed hostname that resolves locally; on native, set the widget's `baseUrl` to an allowed origin if needed. If no allowed origin is available, mark dependent checks `BLOCKED`. Do not change DNS, hosts files, or key settings without approval.

### Launch debug builds

For each native target, start the example in its own background session:

```bash
cd "<tmp>/snapshot/example" && echo "pid $$" && exec flutter run --no-pub -d "<device-id>" --pid-file "<tmp>/run-<target>-<attempt>.pid" \
  --dart-define-from-file="<env>" > "<tmp>/run-<target>-<attempt>.log" 2>&1
```

For web, choose a `<host>` that resolves to `127.0.0.1` and satisfies domain validation if enabled, and loopback ports that are free: `lsof -nP -iTCP:<port> -sTCP:LISTEN` must print nothing, because another program may already use a common port such as `8080`. Run one server at a time, but give each server and build variant its own `<port>`, such as `8090`, `8091`, and so on; the same variant may be reused across browsers. Browsers cache by origin, and the static server answers `304 Not Modified` when a previous variant's cached files are newer, so a reused port can run the wrong build. Start the applicable command for each debug build in its own background session, saving output in separate logs as described in [Sensitive output](#sensitive-output):

```bash
cd "<tmp>/snapshot/example" && echo "pid $$" && exec flutter run --no-pub -d web-server --web-hostname "<host>" --web-port "<port>" \
  --pid-file "<tmp>/run-<target>-<attempt>.pid" --dart-define-from-file="<env>" > "<tmp>/web-debug-js-<browser>-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && echo "pid $$" && exec flutter run --no-pub -d web-server --web-hostname "<host>" --web-port "<port>" --wasm \
  --dart-define-from-file="<env>" > "<tmp>/web-debug-wasm-<browser>-<attempt>.log" 2>&1
```

### Wasm evidence

The [example patch](#prepare-the-example-app) logs the runtime at startup and shows it in the event history:

```dart
debugPrint('Wasm: ${const bool.fromEnvironment('dart.tool.dart2wasm')}');
```

Only `true` proves Wasm execution; `false` in a release `--wasm` build proves the [JS fallback](https://docs.flutter.dev/platform-integration/web/wasm).

Immediately before the Flutter 3.50+ opt-in build, add `wasmAllowList` to the snapshot's existing `example/web/flutter_bootstrap.js`, preserving its other settings, then restore the file after the build. If no bootstrap exists, create one with this [configuration](https://docs.flutter.dev/platform-integration/web/initialization) and remove it after the build:

```js
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: { wasmAllowList: { gecko: true, webkit: true } },
});
```

### Launch release web builds

Build the JS and Wasm release variants in the web matrix into separate directories:

```bash
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-js" > "<tmp>/build-release-js-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --wasm --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-wasm" > "<tmp>/build-release-wasm-<attempt>.log" 2>&1
```

For Flutter 3.50+, add the [opt-in bootstrap](#wasm-evidence) immediately before this build:

```bash
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --wasm --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-wasm-opt-in" > "<tmp>/build-release-wasm-opt-in-<attempt>.log" 2>&1
```

Restore or remove the temporary bootstrap immediately afterward, even if the build fails. Start the static server in its own background session, serving only a build directory, never the project directory:

```bash
cd "<tmp>/snapshot/example" && echo "pid $$" && exec python3 -m http.server "<port>" --bind 127.0.0.1 \
  --directory "<tmp>/web/<variant>" > "<tmp>/http-server-<variant>-<attempt>.log" 2>&1
```

Run the static server once for each release variant, on its own port, and stop it before switching directories. Open `http://<host>:<port>/` in the browser, then confirm in the static server's log that `main.dart.js` or `main.dart.wasm` was served with `200`.

The static server does not set cross-origin isolation headers, so Wasm rendering is single-threaded. Record this limitation rather than treating its warning alone as a package defect.

### App controls

**Hot restart.** On macOS or Linux, read `<tmp>/run-<target>-<attempt>.pid` and, while that run is active, send `kill -USR2 <pid>` with that literal number; on Windows, press `R` in the interactive session. A cold relaunch does not count as a hot restart. A debug `--wasm` web run supports neither hot restart nor `--pid-file`: change a switch and relaunch it, and record its hot-restart check as `N/A`.

**Native events and controls.** Read events with `"<skill>/scripts/events.sh" "<tmp>/run-<target>-<attempt>.log"`, or wait for one with `… wait onCaptchaReady 1 60`. The log keeps events from before a hot restart, so after a restart or for a repeated event, wait with `+1` instead of an absolute count: `… wait onCaptchaReady +1 60`.

- Android: `"<skill>/scripts/android.sh" "<device-id>" <command>`. `state`, `tap <label>`, and `wait <label> enabled|disabled` handle the app's buttons. UiAutomator cannot see inside the WebView, so use `checkbox` to open the challenge, `help` to open the widget's link menu, and `tap-webview <fx> <fy>` for other points, given as fractions of the WebView bounds. On a phone the challenge is a bottom sheet; `tap-webview 0.5 0.2` taps the dimmed area above it and closes it.
- iOS simulator: `"<skill>/scripts/ios.sh" "<simulator-id>" shot <file.png>` prints the screenshot's pixel size; read the target's pixel position from that screenshot and pass it to `tap <x> <y>`. Inside the WebView, which starts right below the app bar, the checkbox is 37 points right and down from its top-left corner, and the `?` icon is 25 points left of its right edge and 110 points down (multiply points by the screenshot's scale, for example 3). Set `E2E_TMP="<tmp>"`. `tap` needs the approved Accessibility permission; do not move or cover the simulator window during a run.
- Readiness arrives within seconds, faster than a UI dump or screenshot, so verify the Load state before readiness from a recording: start `android.sh "<device-id>" record 10 "<tmp>/load-<target>.mp4"` or `ios.sh "<simulator-id>" record 10 "<tmp>/load-<target>.mp4"` in the background, hot restart, wait for `onCaptchaReady +1`, then run `swift "<skill>/scripts/frames.swift" "<tmp>/load-<target>.mp4" 0.25 "<tmp>/frames-<target>"` and view the early frames. Android's recording skips unchanged frames, so its video can be shorter than the wall time.
- For taps that must land before readiness, note the button's position from an earlier `state` or screenshot and send `adb -s "<device-id>" shell input tap <x> <y>` (or `ios.sh … tap`) right after the restart.

Read web events and control states from the patched app's on-screen history with [browser automation](#browser-automation). Keep the widget visible. After a debug edit, hot restart `flutter run` (or relaunch a debug `--wasm` run) and reload the page.

### Browser automation

Use [`web.mjs`](./scripts/web.mjs); it needs only Node 22 or later. The temporary profiles below run alongside the user's own browser windows. Before launching Firefox, create its profile directory with `mkdir -p "<tmp>/firefox-profile"`. Start each command below in a separate background session, not as one script, as described in [Long-lived processes](#long-lived-processes). Record each PID and stop only that PID during cleanup:

```bash
echo "pid $$"; exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9333 \
  --user-data-dir="<tmp>/chrome-profile" --no-first-run --no-default-browser-check \
  --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-background-timer-throttling \
  about:blank > "<tmp>/chrome-<attempt>.log" 2>&1
echo "pid $$"; exec "/Applications/Firefox.app/Contents/MacOS/firefox" --remote-debugging-port 9334 \
  --profile "<tmp>/firefox-profile" --no-remote --new-instance about:blank > "<tmp>/firefox-<attempt>.log" 2>&1
echo "pid $$"; exec safaridriver -p 9335 > "<tmp>/safaridriver-<attempt>.log" 2>&1
```

On other hosts, use the browser's own executable path. For optional Edge, launch it with the Chrome flags and use the `chrome` commands, which speak the same DevTools protocol. Then drive the page, for example:

```bash
node "<skill>/scripts/web.mjs" chrome nav "http://<host>:<port>/"
node "<skill>/scripts/web.mjs" chrome wait onCaptchaReady 1 60
node "<skill>/scripts/web.mjs" chrome checkbox
node "<skill>/scripts/web.mjs" chrome wait onChallengeShown
node "<skill>/scripts/web.mjs" chrome tap Destroy
node "<skill>/scripts/web.mjs" chrome wait Destroy=disabled
```

- `state` and `wait` print the event history and button states. A `warning` field means that the page is hidden; Flutter does not paint hidden pages, so events and taps stall. Keep the tested browser's window visible.
- Chrome: `block` and `unblock` make the SmartCaptcha script fail to load for the `onNetworkError` check without changing host network settings. `window <width> <height>` resizes the window.
- Firefox: the script clicks the cross-origin checkbox inside its frame, because top-level pointer input does not reach it.
- Safari: automation needs approval and Safari's **Allow remote automation** setting. Its preference file is not readable from a sandboxed shell, so check the setting by starting `safaridriver` and running `node "<skill>/scripts/web.mjs" safari state` followed by `… safari end`. If the session starts, the setting was already on; record that and skip enabling. If session creation fails with an error about remote automation, run the one-time `safaridriver --enable` with `sudo -A` (or ask the user to run it) and record that this run enabled it. Set `E2E_TMP="<tmp>"` for every Safari command, end with `node "<skill>/scripts/web.mjs" safari end`, and expect each command to bring Safari to the front. If the first navigation of a session leaves a blank page, navigate again once. The user cannot interact with the automated window, so Safari solves must happen in a normal window (see [Challenge solving](#challenge-solving)).
- If a tap is not registered, check `state` and retry once. A click outside an open challenge popup only closes it.
- Playwright and its MCP server cannot drive branded Firefox or Safari and are not needed for Chrome. Use them only if `web.mjs` cannot run; never print their snapshots or raw logs, and avoid tracing, video, and HAR.

### Challenge solving

With `alwaysShowChallenge: true`, token-dependent checks require the user to solve a challenge. When a scenario requires a solve, group requests, tell the user how many are needed, and handle the controls yourself except for Safari's manual flow below. Open the challenge, ask the user to solve it, then wait for `token non-null: true` with a long timeout (for example, `events.sh … wait "token non-null: true" +1 300` on native; on web, `web.mjs … wait "token non-null: true" <count> 300` with an absolute count, because the on-screen history restarts on each page load). If you cannot observe `onChallengeSolved`, ask for a fixed-choice observation and report it as user-reported.

Safari blocks user input in automated windows. For Safari solves, end the automated session and ask the user to open the URL in a normal Private Window, solve, and run the core flows. Ask for the event history and button states as fixed choices.

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

- **Load.** All controls are disabled before readiness; afterward Execute and Destroy are enabled, while Reset remains disabled. Verify the native loading indicator and `onCaptchaReady`. On native targets, check the state before readiness from a [recording](#4-explore-the-example-app); on Chrome, `block` keeps the widget from becoming ready, so `state` shows that state.
- **Challenge.** In visible mode, open the popup with the checkbox (`android.sh … checkbox`, `ios.sh … tap`, or `web.mjs … checkbox`), not Execute: the README says `execute()` only works in invisible mode. Verify `onChallengeShown` when the popup opens and `onChallengeHidden` when a tap on the dimmed area closes it.
- **Solve.** Follow [Challenge solving](#challenge-solving) to reopen the challenge and request a solve. Expect `onChallengeSolved` with a non-null token. Execute becomes disabled and Reset becomes enabled.
- **Reset.** Execute becomes enabled and Reset becomes disabled. On a primary target, solve again.
- **Destroy.** All controls become disabled. Tap `Probe` after destruction: it should log `called: probe done` with no other events. Do not use the controller after `dispose`. `Probe` also calls `destroy`, so do not tap it while a challenge you still need is open.
- **Invisible mode.** Set the `invisible` switch to `true`, hot restart, and tap Execute; expect `onChallengeShown`. Set it back to `false` afterward.

**Optional edge cases.**

- **Options and validation.** Try language variants, invisible-mode badge settings, and an invalid key (`language` and `bad_key` switches).
- **State and lifecycle.** Test calls before readiness (`Probe`), repeated controller calls, resize or rotation, hot restart, and disposal followed by rebuild. For Android rotation, use `android.sh "<device-id>" rotate landscape`, then `rotate restore`, which restores and reads back the original settings (set `E2E_TMP="<tmp>"` for both).
- **Network and web.** Check `onNetworkError` during script-load failure (Chrome `block`) or connection loss; test page reload, navigation, and native `onNavigationRequest` (open the widget's `?` menu with `android.sh … help` or an `ios.sh` tap, then tap one of its links, such as Support; the `block_nav` switch blocks every navigation, so the widget should stay in place).
- **Token expiry.** Observe `onTokenExpired` when time permits.

### Recording and attributing problems

For each problem, record the target, steps, expected and actual behavior, redacted evidence, reproducibility, and likely cause. Record differences between targets and between JS and Wasm.

- When feasible, retry a failure once and record both outcomes. A passing retry does not erase the initial failure.
- Attribute a behavior to the SmartCaptcha service only when it is identical on a native target and on web, because the native and web adapters load SmartCaptcha through separate code paths. Known service behaviors observed this way:
  - Swiping the native popup away can emit `onChallengeHidden` twice.
  - An invalid key shows Yandex's error text but still emits `onCaptchaReady`, with no error callback.
  - No `onChallengeHidden` after a successful solve. After a reset, the popup can reopen in a resumed state without `onChallengeShown`.
- If attribution remains uncertain, report `UNCLEAR`.

## 5. Clean up

Clean up even after failure or cancellation:

1. While each device is still running, remove live-key apps and test services installed by this run, and restore changed device settings.
2. End only browser sessions and stop only processes and devices started by this run. Restore other changed settings and remove unneeded downloads. `safaridriver` has no option to undo `--enable`; if this run enabled it, ask the user to clear Safari's **Allow remote automation** setting. If the user granted Accessibility permission for `ios.sh`, ask them to revoke it in System Settings > Privacy & Security > Accessibility.
3. Keep sanitized evidence outside `<tmp>` only if requested, then run `rm -rf "<tmp>"` with the recorded path. Do not cite deleted captures.
4. Confirm that `git status --porcelain` matches [step 1](#1-prepare). Report any difference and anything that could not be cleaned up safely.

## 6. Report

Follow [`report-template.md`](./report-template.md); its structure and formatting are mandatory.

Report command outcomes separately from the package verdict: a nonzero exit needs investigation, not an automatic package `FAIL`.

Use the severity levels and previous-findings section in the report template.

Severity: `HIGH` for a crash, token/data loss, or broken core flow; `MEDIUM` for an incorrect callback or state with a workaround; `LOW` for a minor cosmetic or usability issue.

## References

- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Patrol documentation](https://patrol.leancode.co/documentation) and [`patrol test` reference](https://patrol.leancode.co/cli-commands/test)
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/), [WebDriver BiDi](https://w3c.github.io/webdriver-bidi/), and [Safari WebDriver](https://developer.apple.com/documentation/webkit/testing-with-webdriver-in-safari)
- [Playwright CLI](https://playwright.dev/agent-cli/introduction) and [Playwright MCP](https://playwright.dev/mcp/introduction)
