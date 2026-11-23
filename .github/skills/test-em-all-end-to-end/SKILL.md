---
name: test-em-all-end-to-end
description: >-
  Run automated and exploratory end-to-end checks for this Flutter package and its example on Android, iOS, and web. Use only when the user explicitly asks to run this `test-em-all-end-to-end` skill or another skill explicitly invokes it.
---

# Testing the package and example app end to end

## Main rules

- Test and report only; do not fix defects or edit tests unless explicitly asked. Run all builds, tests, and app launches in the [step 1](#1-prepare) snapshot, never in the repository. Edit only the snapshot's example app, keep the package under test untouched, and report every edit.

- Derive package expectations from its README and Dartdoc, and use [Yandex documentation](https://yandex.cloud/en/docs/smartcaptcha/) for service behavior. Treat errors as evidence, not proof, of a defect. Report `UNCLEAR` when expected behavior or attribution cannot be established.

- Handle setup and observation yourself. Ask only for required approvals, challenge solves, necessary simulator selection or Safari manual flows, or fixed-choice observations when needed. Never automate challenge solving or forge responses. Plan the [approval request](#approvals) after selecting targets, and obtain approval before any action that requires it.

- Ask before installing host-level tools, SDK components, emulator images, simulator runtimes, browsers, or third-party apps. Package dependencies may be resolved with installed tools. Use disposable devices where possible: Patrol may uninstall apps and clear Android data. On existing devices, check installed app IDs and effective Patrol/Gradle settings. Ask before replacing or uninstalling apps or installing test services, or mark the target `BLOCKED`. Remove only services installed by this run.

- Keep an inventory of the processes, ports, devices, installed apps, recordings, and settings this run starts or changes, with their PIDs, browser session IDs, and device IDs. Stop only those resources by their exact identifiers, after verifying that each PID still belongs to this run. Never terminate processes by name or broad matching, stop another user's simulator, or remove an unrelated app or file. Ask before changing host or device network settings, and restore them during cleanup.

### Sensitive output

Never expose client keys or CAPTCHA tokens in output, screenshots, or reports. Client keys may appear in URLs or the DOM; CAPTCHA tokens may appear in the DOM or app logs.

Load the key only with `--dart-define-from-file="<env>"`, using the original repository's `example/.env`; never copy, source, or print it. Before any live-key launch, apply the [example patch](#preparing-the-example-app), which logs only whether the token is non-null. Keep live-key builds in the snapshot and remove them during cleanup. Never use verbose logging, commit, or share these builds.

Save the output of each command and process to its own log in `<tmp>`. Do not display raw logs, DOM, or network data; inspect only sanitized evidence. Mask sensitive content in screenshots before viewing them, because a viewed image stays in the session transcript after `<tmp>` is deleted. If an image cannot be safely masked, mark the dependent observation `BLOCKED`. Report transcript retention separately from temporary-file cleanup.

### Required and optional checks

Required coverage includes the latest supported Android and iOS targets, Chrome's web matrix, and real Firefox and Safari where the installed SDK and browser versions support the required runtime. Mark unavailable required targets `BLOCKED`; another browser engine or OS does not count as equivalent coverage. Complete independent checks even when one required target is blocked.

Optional coverage is Edge (follow the Chrome matrix), Playwright's Firefox and WebKit (extra engines, not real Firefox or Safari), and extra physical devices. Use the [report template](./report-template.md#verdict-definitions) to decide the verdict.

### Helper scripts

Use these tested helpers instead of writing your own.

| Script | Purpose |
| --- | --- |
| [`patch_example.py`](./scripts/patch_example.py) | Applies the temporary example edits: token-free logs, the Wasm marker, an on-screen event history, a `Probe` button, and option switches. |
| [`patrol_results.py`](./scripts/patrol_results.py) | Prints allowlisted Patrol test names, outcomes, and failure categories from Android JUnit XML or iOS `xcresulttool` JSON. |
| [`snapshot.sh`](./scripts/snapshot.sh) | Creates an isolated working-tree snapshot while excluding known sensitive paths before staging. |
| [`events.sh`](./scripts/events.sh) | Prints, counts, or waits for sanitized events in a `flutter run` log. |
| [`android.sh`](./scripts/android.sh) | Reads, waits for, and taps Android buttons; taps the SmartCaptcha checkbox, `?` icon, or a point in the WebView; records the screen; rotates and restores. |
| [`ios.sh`](./scripts/ios.sh) | Takes screenshots of, taps, and records an iOS simulator (macOS). |
| [`frames.swift`](./scripts/frames.swift) | Extracts PNG frames from a screen recording (macOS, no ffmpeg). |
| [`web.mjs`](./scripts/web.mjs) | Drives Chrome (CDP), Firefox (WebDriver BiDi), and Safari (`safaridriver`) with Node 22+ and no packages. |

`<skill>` is the absolute path of the directory containing this file. Each script prints only sanitized output and documents its usage in its header. The `wait` commands time out with exit status `1` and print the last state. After changing a helper, run `python3 -B -m unittest discover -s "<skill>/tests" -v`.

## 1. Prepare

1. Record the commit and `git status --porcelain` output. If a previous report was provided, list its findings for retesting. If the user requests a subset, run only those checks and their prerequisites. Carry forward other results only when their tested code and relevant environment remain applicable; identify the previous scope and versions, and label carried results separately from rerun results. If applicability cannot be established, mark those checks `NOT RUN` or `UNCLEAR` and do not claim a complete passing verdict.
2. Record `flutter --version`, `flutter devices`, `flutter emulators`, and `patrol --version`. On macOS with Xcode, also record `xcode-select -p`, `xcodebuild -version`, and `xcrun simctl list runtimes`; otherwise mark iOS checks `BLOCKED – no macOS/Xcode host`.

   Because the global Xcode selection can change during a run, record the output of `xcode-select -p` as `<developer-dir>` and prefix every `xcodebuild`, `xcrun`, `swift`, iOS `flutter`, iOS `patrol`, and `ios.sh` command with `DEVELOPER_DIR="<developer-dir>"`. Launch the simulator app from that Xcode. Do not run `xcode-select -s` without approval.

   Token-dependent iOS simulator checks need a visible simulator app: `DeviceHub.app` from Xcode 27, or `Simulator.app` before it. Check for either:

   ```bash
   test -d "$(xcode-select -p)/../Applications/DeviceHub.app" || test -d "$(xcode-select -p)/Applications/Simulator.app"
   ```

   If both are missing, mark token-dependent iOS simulator checks `BLOCKED`.

3. Use the [Patrol compatibility table](https://patrol.leancode.co/documentation/compatibility-table) to confirm that the installed `patrol_cli` matches the `patrol` version in `example/pubspec.lock` (`awk '/^  patrol:/{f=1} f&&/version:/{print;exit}' example/pubspec.lock`) and that Flutter meets their minimum.
4. From the repository root, check `example/.env` without printing its values:

   ```bash
   # Must print 1:
   grep -cE '^CLIENT_KEY=' example/.env
   # Must print 0 (exit status 1 is expected):
   grep -cvE "^[[:space:]]*(#.*)?$|^CLIENT_KEY=(ysc1_[^\"'[:space:]#]+|\"ysc1_[^\"'[:space:]#]+\"|'ysc1_[^\"'[:space:]#]+')[[:space:]]*$" example/.env
   ```

   If the file is missing or either check fails, do not pass it to any command; mark live-key checks `BLOCKED` throughout the run and continue with key-free checks. Otherwise, use its absolute path as `<env>`.

5. Create the snapshot. First identify any other unignored sensitive paths without printing their contents. Run `mktemp -d` once and record the printed absolute path as `<tmp>`. From the repository root:

   ```bash
   bash "<skill>/scripts/snapshot.sh" "<tmp>" [additional-sensitive-path ...]
   ```

   Pass additional paths relative to the repository root; leading `./` and trailing `/` are accepted, but interior `.` components and repeated separators are not. The command must print `SNAPSHOT_OK`. It copies the working tree, including tracked files that match ignore rules, without `example/.env` or the listed paths and their contents, and leaves the user's Git index and objects unchanged.

   Shell state may not persist between commands, so start each snapshot command with its own `cd`, as shown. Replace placeholders with their values, keeping the quotes. Use filename-safe labels, with a distinct `<target>` for each target/build and `<attempt>` for each retry. Run repository-status commands from the repository root.

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

For Android and iOS, cover the latest stable OS supported by the installed SDK. Do not test minimum supported OS versions.

Prefer emulators and simulators, and record the exact OS version. If the required image or runtime is unavailable, include a download or a physical device with that OS version in the [approval request](#approvals). If neither can be used, mark the target `BLOCKED` and cover the nearest available supported version as an extra target.

Inspect existing devices before the approval request, so that it can include any app replacements and test-service installations.

### Web

Use the installed SDK's browser support matrix. In Flutter 3.50 and later, a release `--wasm` build falls back to JavaScript in Firefox and Safari unless `wasmAllowList` opts them in; a debug `--wasm` run has no fallback. Verify the runtime in each matrix cell with the [Wasm evidence](#wasm-evidence):

| Build | Chrome | Firefox and Safari |
| --- | --- | --- |
| Debug JS | JS | JS |
| Debug Wasm | Wasm | `N/A` |
| Release JS | JS | `N/A` – covered by the fallback |
| Release `--wasm` | Wasm | JS fallback |
| Release `--wasm` with opt-in | `N/A` | Wasm |

Mark the opt-in row `N/A` when the browser version cannot run Wasm; its JS checks still apply. If Chrome cannot run Wasm, mark its required Wasm checks `BLOCKED` and expect JS fallback from the release build.

Before Flutter 3.50, there is no opt-in. Mark that row `N/A` and record which runtime the `--wasm` build uses in Firefox and Safari.

Record each browser's version.

### Approvals

Collect required approvals in one prompt after selecting targets and before testing. Include host-level downloads and installations, app replacements, test-service installs, WebView or network changes, Safari automation, macOS Accessibility permission for [`ios.sh`](./scripts/ios.sh) taps, and planned challenge solves.

Plan the solve budget before asking, using the primary and other targets in [Scenarios](#scenarios): about three solves for each primary target (solve, solve again after reset, and an allowance for invisible mode) and one for every other target or build. A full matrix needs about 20. State the total in the approval prompt.

Request any later approval before the action, or mark the check `BLOCKED`.

### Long-lived processes

Start each `flutter run`, emulator, browser, `safaridriver`, and static server in its own background session (an async or background shell in agent tools), and let it replace the shell so that the printed PID is the process itself:

```bash
echo "pid $$"; exec <command> > "<tmp>/<name>-<attempt>.log" 2>&1
```

Run any `cd` before `exec`, as shown below. Record the PID and stop the process with `kill <pid>` when it is no longer needed. Pass a literal number, not `$(cat …)` or a variable, because agent sandboxes may reject them. A Flutter launcher may spawn a separate Dart process rather than replacing itself: record the `--pid-file` PID and any listener PID too. At cleanup, verify each remaining child and listener belongs to the run before stopping it, and check that the run's ports are free.

### Starting selected targets

After approvals, obtain approved images or runtimes, start selected emulators or simulators as needed, wait until they are ready, and record their device IDs. When a token-dependent check needs a visible iOS simulator, boot it if it is not already booted:

```bash
xcrun simctl boot "<simulator-id>"
```

Then wait for it, open the available simulator app from the pinned developer directory, and ask the user to select the simulator in its sidebar:

```bash
xcrun simctl bootstatus "<simulator-id>" -b
open -a "<developer-dir>/../Applications/DeviceHub.app"   # Before Xcode 27: <developer-dir>/Applications/Simulator.app
```

Once an Android target is running, record its WebView provider and version from `adb -s "<device-id>" shell dumpsys webviewupdate`. Below API 26 that command prints nothing; use `adb -s "<device-id>" shell settings get global webview_provider` and `adb -s "<device-id>" shell dumpsys package <provider> | grep versionName` instead. Ask before updating the provider. If an incompatible provider prevents a check and cannot be updated, mark the check `BLOCKED` due to the environment. `google_apis` images reject Google-signed WebView updates (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), so do not try to sideload one; their old built-in WebView can render SmartCaptcha while ignoring taps on it.

## 3. Run the automated suites

Run the key-free package and example checks first, then patch the example and run the live-key Patrol suite.

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
- Verify that the `--wasm` lane ran as Wasm (its log contains `Generated wasm module`); it has no JavaScript fallback.
- If `flutter test --verbose --help` lists `--[no-]deprecated-js-interop` (Flutter 3.50 and later), also run `cd "<tmp>/snapshot" && flutter test --no-pub --platform chrome --no-deprecated-js-interop`; otherwise mark this modern-interop check `N/A`.

### Example checks

```bash
cd "<tmp>/snapshot/example" && flutter test --no-pub
cd "<tmp>/snapshot/example" && flutter build apk --debug --no-pub --dart-define-from-file=.env.example
cd "<tmp>/snapshot/example" && flutter build ios --no-codesign --no-pub --dart-define-from-file=.env.example   # macOS/Xcode
```

### Preparing the example app

After the example checks and before Patrol or any live-key launch, patch the snapshot's example. The patch adds a button, so the example's button-spacing widget test fails afterward; Patrol selectors are unaffected.

```bash
python3 "<skill>/scripts/patch_example.py" apply "<tmp>/snapshot/example/lib/main.dart"
```

The command must print `ok`; on an error it changes nothing. Report its edits, all marked `E2E-TEMP`:

- `onChallengeSolved` logs only `token non-null: true|false`, and `onNavigationRequest` logs only the host.
- `main()` logs the [Wasm evidence](#wasm-evidence) line and mirrors allowlisted log lines into an on-screen `E2E: …` event history above the buttons.
- An always-enabled `Probe` button calls `execute`, `reset`, and `destroy`, then logs `called: probe done`. Use it for calls before readiness and after destruction.
- Constant switches control invisible mode, an invalid key, the language, and blocking all navigation. Change one with `python3 "<skill>/scripts/patch_example.py" set "<tmp>/snapshot/example/lib/main.dart" <switch> <value>`, then hot restart, or relaunch where hot restart is unavailable.

### Patrol

Read `patrol.test_directory` in `example/pubspec.yaml` and inspect the tests there. The suite skips its entire group on web; record web Patrol as `N/A – mobile-only suite`.

Before each Android run, clear only the snapshot's `example/build/app/outputs/androidTest-results/connected/` directory. Before each iOS run, record the existing `example/build/ios_results_*.xcresult` paths; afterward, use only the single new bundle. If there is not exactly one new bundle, mark its cases unverified. Never reuse older results.

Run Patrol once for each booted native target:

```bash
# Android or physical iOS:
cd "<tmp>/snapshot/example" && patrol test --device "<device-id>" \
  --dart-define-from-file="<env>" > "<tmp>/patrol-<target>-<attempt>.log" 2>&1
# iOS simulator:
cd "<tmp>/snapshot/example" && patrol test --device "<simulator-id>" --ios "<ios-version>" \
  --dart-define-from-file="<env>" > "<tmp>/patrol-<target>-<attempt>.log" 2>&1
```

Use the simulator's runtime version for `--ios`; Patrol defaults to `latest`. Patrol neither solves the challenge nor verifies token issuance.

After each run, confirm from its new result files, not the console, that the expected tests ran (readiness, challenge shown, and destroy), and record their names, outcomes, and counts. [`patrol_results.py`](./scripts/patrol_results.py) prints allowlisted names and failure categories:

- Android: `python3 "<skill>/scripts/patrol_results.py" android "<tmp>/snapshot/example/build/app/outputs/androidTest-results/connected"`.
- iOS: export the new bundle's `testNodes` tree with the command below (not `summary`, which reports totals only), then run `python3 "<skill>/scripts/patrol_results.py" ios "<tmp>/ios-tests-<target>-<attempt>.json"`. If the tree is unavailable, mark the cases unverified.

  ```bash
  xcrun xcresulttool get test-results tests --path "<tmp>/snapshot/example/build/ios_results_<timestamp>.xcresult" \
    > "<tmp>/ios-tests-<target>-<attempt>.json" 2> "<tmp>/xcresult-<target>-<attempt>.log"
  ```

The helper's exit status reflects extraction, not test success: check every expected case, its outcome, and Patrol's exit status. Never print raw results to inspect withheld names or failure details.

If a Patrol test times out, retry its failing step in the debug app on the same target during [step 4](#4-explore-the-example-app) before attributing the failure. A test teardown error such as a leaked `SemanticsHandle` cannot be verified in the debug app; record it separately and keep its cause `UNCLEAR` unless the test/harness evidence establishes it.

## 4. Explore the example app

For each target or build, launch the example as a [long-lived process](#long-lived-processes), then run the scenarios with the controls and browser automation below. Keep the device visible.

If SmartCaptcha's [domain validation](https://yandex.cloud/en/docs/smartcaptcha/concepts/domain-validation) is enabled, use `--web-hostname` with an allowed hostname that resolves locally; on native, set the widget's `baseUrl` to an allowed origin if needed. If no allowed origin is available, mark dependent checks `BLOCKED`. Do not change DNS, hosts files, or key settings without approval.

### Launching debug builds

For each native target, start the example in its own background session:

```bash
cd "<tmp>/snapshot/example" && echo "pid $$" && exec flutter run --no-pub -d "<device-id>" --pid-file "<tmp>/run-<target>-<attempt>.pid" \
  --dart-define-from-file="<env>" > "<tmp>/run-<target>-<attempt>.log" 2>&1
```

For web, choose a `<host>` that resolves to `127.0.0.1` and satisfies domain validation if enabled. Run one server at a time, but give each build variant its own free loopback port (`lsof -nP -iTCP:<port> -sTCP:LISTEN` must print nothing), such as `8090`, `8091`, and so on; a reused port can serve a previous variant from the browser cache. The same variant may be reused across browsers. Start the applicable command for each debug build:

```bash
cd "<tmp>/snapshot/example" && echo "pid $$" && exec flutter run --no-pub -d web-server --web-hostname "<host>" --web-port "<port>" \
  --pid-file "<tmp>/run-<target>-<attempt>.pid" --dart-define-from-file="<env>" > "<tmp>/web-debug-js-<browser>-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && echo "pid $$" && exec flutter run --no-pub -d web-server --web-hostname "<host>" --web-port "<port>" --wasm \
  --dart-define-from-file="<env>" > "<tmp>/web-debug-wasm-<browser>-<attempt>.log" 2>&1
```

### Launching release web builds

Build the JS and Wasm release variants in the web matrix into separate directories:

```bash
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-js" > "<tmp>/build-release-js-<attempt>.log" 2>&1
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --wasm --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-wasm" > "<tmp>/build-release-wasm-<attempt>.log" 2>&1
```

For Flutter 3.50+, immediately before the opt-in build, add `wasmAllowList` to the snapshot's existing `example/web/flutter_bootstrap.js`, preserving its other settings. If no bootstrap exists, create one with this [configuration](https://docs.flutter.dev/platform-integration/web/initialization):

```js
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: { wasmAllowList: { gecko: true, webkit: true } },
});
```

Then build:

```bash
cd "<tmp>/snapshot/example" && flutter build web --release --no-pub --wasm --dart-define-from-file="<env>" \
  -o "<tmp>/web/release-wasm-opt-in" > "<tmp>/build-release-wasm-opt-in-<attempt>.log" 2>&1
```

Restore or remove the temporary bootstrap immediately afterward, even if the build fails. Serve each release variant from its build directory, never the project directory, on its own port:

```bash
cd "<tmp>/snapshot/example" && echo "pid $$" && exec python3 -m http.server "<port>" --bind 127.0.0.1 \
  --directory "<tmp>/web/<variant>" > "<tmp>/http-server-<variant>-<attempt>.log" 2>&1
```

Stop the server before switching variants. Open `http://<host>:<port>/` in the browser, then confirm in the server's log that `main.dart.js` or `main.dart.wasm` was served with `200`.

The static server does not set cross-origin isolation headers, so Wasm rendering is single-threaded. Record this limitation; its warning alone is not a package defect.

### Wasm evidence

The [example patch](#preparing-the-example-app) logs `Wasm: true|false` at startup and shows it in the event history. Only `true` proves Wasm execution; `false` in a release `--wasm` build proves the [JS fallback](https://docs.flutter.dev/platform-integration/web/wasm).

### App controls

To hot restart on macOS or Linux, read `<tmp>/run-<target>-<attempt>.pid` and, while that run is active, send `kill -USR2 <pid>` with that literal number. On Windows, press `R` in the interactive session. A cold relaunch does not count as a hot restart. A debug `--wasm` web run supports neither hot restart nor `--pid-file`: change a switch and relaunch it, and record its hot-restart check as `N/A`.

For native events, use `"<skill>/scripts/events.sh" "<tmp>/run-<target>-<attempt>.log"`, or wait for one with `… wait onCaptchaReady 1 60`. The log keeps events from before a hot restart, so before triggering a restart or repeated event, read `… count <event>` and wait for that count plus one.

- Android: set `E2E_TMP="<tmp>"` for every `"<skill>/scripts/android.sh" "<device-id>" <command>`. `state`, `tap <label>`, and `wait <label> enabled|disabled` handle the app's buttons; `centers` prints their screen centers for raw taps. UiAutomator cannot see inside the WebView, so use `checkbox` to open the challenge, `help` to open the widget's link menu, and `tap-webview <fx> <fy>` for other points, given as fractions of the WebView bounds. On a phone the challenge is a bottom sheet; `tap-webview 0.5 0.2` taps the dimmed area above it and closes it.
- iOS simulator: `"<skill>/scripts/ios.sh" "<simulator-id>" shot <file.png>` prints the screenshot's pixel size. Read the target's pixel position from a safely masked screenshot and pass it to `tap <x> <y>`. Inside the WebView, which starts right below the app bar, the checkbox is 37 points right and down from its top-left corner, and the `?` icon is 25 points left of its right edge and 110 points down (multiply points by the screenshot's scale, for example 3). On iOS, `onCaptchaReady` can arrive a few seconds before the widget paints, so wait about 3 seconds before a screenshot.

  Set `E2E_TMP="<tmp>"`, the pinned `DEVELOPER_DIR`, and, for taps, `E2E_SIMULATOR_PID` to the verified PID of the simulator app opened for this run. `tap` needs the approved Accessibility permission; do not move or cover the simulator window during a run. If several device screens make taps ambiguous, select only the test device or mark taps `BLOCKED`; do not shut down unrelated simulators without approval. `tap` caches the screen geometry in `<tmp>`; after rotating, delete `<tmp>/e2e-ios-<simulator-id>.geom`.

Readiness arrives faster than a UI dump or screenshot, so verify the Load state before readiness from a recording. Note the current `onCaptchaReady` count, start `android.sh "<device-id>" record 15 "<tmp>/load-<target>.mp4"` or `ios.sh "<simulator-id>" record 15 "<tmp>/load-<target>.mp4"` in the background, confirm the recorder is running, and hot restart promptly. Wait for the count to increase and the recording to finish, then run `swift "<skill>/scripts/frames.swift" "<tmp>/load-<target>.mp4" 0.1 "<tmp>/frames-<target>"`. Inspect safely masked frames throughout the restart: the earliest frames may show the old ready screen while the restart compiles. If no useful frame was captured, retry with a longer recording if needed. Verify the indicator and all three disabled controls in the same frame before readiness; a missing or ambiguous frame is `UNCLEAR`, not `PASS`. Without macOS, use an installed frame extractor or mark this check `BLOCKED`.

For taps that must land before readiness, read the button's center beforehand with `android.sh "<device-id>" centers` or from an iOS screenshot. Note the current `Wasm:` count, hot restart, wait for that count plus one with `events.sh … wait 'Wasm:' <count>`, which marks the new app's `main()`, and immediately send `adb -s "<device-id>" shell input tap <x> <y>` (or `ios.sh … tap`).

Read web events and control states from the patched app's on-screen history with [browser automation](#browser-automation). After a debug edit, hot restart `flutter run` (or relaunch a debug `--wasm` run) and reload the page: `reload` in Chrome, or `nav` to the same URL in Firefox and Safari. Then `wait onCaptchaReady` before reading `state`.

### Browser automation

Use [`web.mjs`](./scripts/web.mjs). Before launching a browser, check that its debugging port is free (9333, 9334, and 9335 below). If not, select another free port and set `E2E_CHROME_PORT`, `E2E_FIREFOX_PORT`, or `E2E_SAFARI_PORT` for every matching helper call. After startup, verify that the listener belongs to the exact process started by this run; if ownership is ambiguous, mark the target `BLOCKED`. Never connect to a pre-existing endpoint.

Before launching Firefox, run `mkdir -p "<tmp>/firefox-profile"`. Start each command below in a separate background session, as described in [Long-lived processes](#long-lived-processes):

```bash
echo "pid $$"; exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9333 \
  --user-data-dir="<tmp>/chrome-profile" --no-first-run --no-default-browser-check \
  --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-background-timer-throttling \
  about:blank > "<tmp>/chrome-<attempt>.log" 2>&1
echo "pid $$"; exec "/Applications/Firefox.app/Contents/MacOS/firefox" --remote-debugging-port 9334 \
  --profile "<tmp>/firefox-profile" --no-remote --new-instance about:blank > "<tmp>/firefox-<attempt>.log" 2>&1
echo "pid $$"; exec safaridriver -p 9335 > "<tmp>/safaridriver-<attempt>.log" 2>&1
```

Use the selected port in each launch command. On other hosts, use the browser's own executable path. For optional Edge, launch it with the Chrome flags and use the `chrome` commands.

After verifying the Chrome listener, identify the single `about:blank` page in its isolated profile from `/json` without printing the raw response or URLs. Set `E2E_CHROME_TARGET_ID` to its exact ID for every Chrome helper call; if the page or listener ownership cannot be established, mark Chrome `BLOCKED`. Firefox must have exactly one top-level tab in its isolated profile. Then drive the page, for example:

```bash
E2E_CHROME_TARGET_ID="<id>" node "<skill>/scripts/web.mjs" chrome nav "http://<host>:<port>/"
E2E_CHROME_TARGET_ID="<id>" node "<skill>/scripts/web.mjs" chrome wait onCaptchaReady 1 60
E2E_CHROME_TARGET_ID="<id>" node "<skill>/scripts/web.mjs" chrome checkbox
E2E_CHROME_TARGET_ID="<id>" node "<skill>/scripts/web.mjs" chrome wait onChallengeShown
E2E_CHROME_TARGET_ID="<id>" node "<skill>/scripts/web.mjs" chrome tap Destroy
E2E_CHROME_TARGET_ID="<id>" node "<skill>/scripts/web.mjs" chrome wait Destroy=disabled
```

`state` and `wait` print the event history and button states. A `warning` field means that the page is hidden, so Flutter stops painting and events and taps stall; keep the tested browser's window visible. If a tap is not registered, check `state` and retry once. A click outside an open challenge popup only closes it.

- For outside dismissal, verify that the challenge actually closes before attributing a missing `onChallengeHidden` callback. If safe automated visual confirmation is unavailable, ask for a fixed-choice observation of whether it closed. If the automated click was ineffective or ambiguous, retry once: reopen the challenge if needed, note the current callback count, and ask the user to click the dimmed area without solving and report whether it closed. Compare the callback count before and after that action, report the visual observation as user-reported, and keep the result `UNCLEAR` if closure or callback attribution remains ambiguous.
- Chrome: start `block <seconds>` in a separate background session and wait for its `blocking` marker; other helper calls can then inspect the disabled controls and optional `onNetworkError`. Afterward, stop only that blocker process, which ends blocking, then `reload`. `window <width> <height>` resizes the window.
- Safari: automation needs approval and Safari's "Allow remote automation" setting. Check the setting by starting `safaridriver` and running `node "<skill>/scripts/web.mjs" safari state` followed by `… safari end`. If the session starts, the setting was already on. If session creation fails with a remote-automation error, run `safaridriver --enable` with `sudo -A` (or ask the user to run it) and record that this run enabled it. Set `E2E_TMP="<tmp>"` for every Safari command, and end with `node "<skill>/scripts/web.mjs" safari end`. If a session's first navigation leaves a blank page, navigate again once.

Use Playwright or its MCP server only if `web.mjs` cannot run; they cannot drive branded Firefox or Safari. Never print their snapshots or raw logs, and avoid tracing, video, and HAR.

### Challenge solving

With `alwaysShowChallenge: true`, token-dependent checks require the user to solve a challenge. Group solve requests and tell the user how many are needed; handle the controls yourself except in Safari. Before opening the challenge, note the current `token non-null: true` count. Open the challenge, ask the user to solve it, then wait for that count plus one with a long timeout, such as `events.sh … wait "token non-null: true" <count> 300` on native or `web.mjs … wait "token non-null: true" <count> 300` on web. The web history restarts on each page load. If you cannot observe `onChallengeSolved`, ask for a fixed-choice observation and report it as user-reported.

Safari blocks user input in automated windows, so end the automated session and ask the user to open the URL in a normal Private Window, solve, and run the core flows. Ask for each event, button state, build, and the window's `Wasm: true|false` marker as separate fixed choices, including `not observed` and `unsure`; do not preselect successful outcomes. An absent or ambiguous response is not a pass.

Without a solve, mark token-dependent checks `BLOCKED`, not the whole target. A client callback proves token delivery only, not server-side validation.

### Scenarios

Run core flows on every required target. Use the primary targets for additional edge cases:

| Target | Coverage |
| --- | --- |
| Primary: the latest Android, the latest iOS, and Chrome with the debug JS build | Core flows and selected edge cases |
| All other targets and builds | Core flows only, with a single solve. Release builds skip invisible mode, which needs a rebuild |

If a primary target is blocked, promote another target of the same platform. Wait for callbacks and control states with bounded timeouts, never fixed sleeps, and change one option at a time.

For each target/build, record separate outcomes and evidence as you go for pre-readiness, ready state, challenge shown and hidden, solve, reset, destroy, post-destroy Probe, and invisible Execute where required. A scenario without evidence is `NOT RUN` or `UNCLEAR`, never part of a `PASS` row. Record automated and user-reported observations separately.

#### Core flows

```text
Launch
↓
Before readiness: Execute, Reset, Destroy disabled; native loading indicator shown
↓  onCaptchaReady
Ready: Execute, Destroy enabled; Reset disabled
↓  Tap the checkbox (visible mode)
Challenge open → onChallengeShown
↓  Tap the dimmed area
Challenge closed → onChallengeHidden
↓  Reopen with the checkbox; the user solves it
Solved → onChallengeSolved with a non-null token; Execute disabled, Reset enabled
↓  Tap Reset
Reset: Execute enabled, Reset disabled
├─ Primary target → solve again
↓  Tap Destroy
Destroyed: Execute, Reset, Destroy disabled
↓  Tap Probe
Only "called: probe done", no other events
↓  Set invisible to true, hot restart, tap Execute
Invisible challenge → onChallengeShown
↓
Set invisible back to false
```

On native targets, check the state before readiness from a [recording](#4-explore-the-example-app); on Chrome, `block` keeps the widget from becoming ready, so `state` shows that state. Open the challenge with `android.sh … checkbox`, `ios.sh … tap`, or `web.mjs … checkbox`, never Execute: the README says `execute()` only works in invisible mode. Solve as described in [Challenge solving](#challenge-solving). `Probe` also calls `destroy`, so do not tap it while a challenge you still need is open.

#### Optional edge cases

```text
Primary targets
├─ Options and validation
│  ├─ Language variants ─ language switch
│  ├─ Invisible-mode badge settings
│  └─ Invalid key ─ bad_key switch
├─ State and lifecycle
│  ├─ Calls before readiness ─ Probe
│  ├─ Repeated controller calls
│  ├─ Resize or rotation
│  ├─ Hot restart
│  └─ Disposal followed by rebuild
├─ Network and web
│  ├─ onNetworkError ─ script-load failure (Chrome block) or connection loss
│  ├─ Page reload and navigation
│  └─ Native onNavigationRequest ─ open the ? menu, tap a link such as Support
│     └─ block_nav switch on → every navigation blocked, widget stays in place
└─ Token expiry ─ onTokenExpired, when time permits
```

For Android rotation, use `android.sh "<device-id>" rotate landscape`, then `rotate restore`, which restores and reads back the original settings (set `E2E_TMP="<tmp>"` for both). Open the widget's `?` menu with `android.sh … help` or an `ios.sh` tap.

### Recording and attributing problems

For each problem, record the target, steps, expected and actual behavior, redacted evidence, reproducibility, and likely cause. Record differences between targets and between JS and Wasm. When feasible, retry a failure once and record both outcomes; a passing retry does not erase the initial failure.

Identical behavior on native and web is useful evidence but does not by itself prove a service cause: shared package and example code may still be responsible. Verify against official documentation or an independent provider reproduction before attributing it to the service. Previously observed behaviors to investigate include:

- Swiping the native popup away can emit `onChallengeHidden` twice.
- An invalid key shows Yandex's error text but still emits `onCaptchaReady`, with no error callback.
- No `onChallengeHidden` after a successful solve. After a reset, the popup can reopen in a resumed state ("Try again. Additional check") without `onChallengeShown`; take a screenshot instead of waiting for the event.

If attribution remains uncertain, report `UNCLEAR`.

## 5. Clean up

Clean up even after failure or cancellation:

1. While each device is still running, remove live-key apps and test services installed by this run, and restore changed device settings.
2. End only browser sessions and stop only processes and devices started by this run. Restore other changed settings and remove unneeded downloads. Ask the user to close test-only Safari Private Window tabs; do not close unrelated windows. `safaridriver` has no option to undo `--enable`; if this run enabled it, ask the user to clear Safari's "Allow remote automation" setting. If the user granted Accessibility permission for `ios.sh` during this run, ask them to revoke it in System Settings > Privacy & Security > Accessibility; report their confirmation as user-reported.
3. Keep sanitized evidence outside `<tmp>` only if requested, then run `rm -rf "<tmp>"` with the recorded path. Do not cite deleted captures.
4. Confirm that `git status --porcelain` matches [step 1](#1-prepare). Report any difference and anything that could not be cleaned up safely.

## 6. Report

Follow [`report-template.md`](./report-template.md); its structure and formatting are mandatory. If a previous report was provided, report the [step 1](#1-prepare) findings in its previous-findings section.

Report command outcomes separately from the package verdict: a nonzero exit needs investigation, not an automatic package `FAIL`.

Severity: `HIGH` for a crash, token/data loss, or broken core flow; `MEDIUM` for an incorrect callback or state with a workaround; `LOW` for a minor cosmetic or usability issue.

## References

- [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
- [Patrol documentation](https://patrol.leancode.co/documentation) and [`patrol test` reference](https://patrol.leancode.co/cli-commands/test)
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/), [WebDriver BiDi](https://w3c.github.io/webdriver-bidi/), and [Safari WebDriver](https://developer.apple.com/documentation/webkit/testing-with-webdriver-in-safari)
- [Playwright CLI](https://playwright.dev/agent-cli/introduction) and [Playwright MCP](https://playwright.dev/mcp/introduction)
