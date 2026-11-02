---
name: audit-sdk-constraints
description: >-
  Audit this Flutter package's minimum Dart and Flutter SDK constraints. Use when reviewing SDK compatibility, pubspec environment constraints, dependency upgrades, adoption of new language features or APIs, minimum-SDK CI failures, release readiness, or support-policy changes.
---

# Auditing Dart and Flutter SDK constraints

## Main rules

- Assess and report only, unless implementation is explicitly authorized.
- Keep the lowest Dart and Flutter SDK constraints the published package genuinely supports and that pass verification. Do not raise them solely because newer SDKs or dependencies are available.
- During the audit, run every `flutter`, `dart`, and `pub` command in a [lane](#lanes), never in the repository. Never modify the user's working tree, index, lockfile, overrides, SDK setup, or environment, except for authorized changes in [step 6](#6-implement).

## Decision flow

```text
Inspect package, constraints, dependencies, and CI.
↓
Do findings affect the published package?
├─ No → KEEP. Report tooling/example findings separately.
└─ Yes
   ↓
   Is this a policy-only change?
   ├─ Yes → POLICY DECISION
   └─ No
      ↓
      Verify the current floor + latest stable.
      ├─ Both pass → KEEP
      ├─ Verification blocked → INCONCLUSIVE
      ├─ Floor passes, latest fails → Investigate and retest.
      └─ Floor fails
         ↓
         Classify the failure. Resolve infrastructure or dependency issues first.
         ↓
         Package incompatibility confirmed?
         ├─ No or unresolved → Resolve and retest. If blocked → INCONCLUSIVE
         └─ Yes
            ↓
            Can a fix preserve the current floor?
            ├─ Yes → Verify the fix in lanes.
            │        ├─ Both pass → KEEP
            │        ├─ Floor fails → Reassess compatibility.
            │        ├─ Latest fails → Investigate and retest.
            │        └─ Verification blocked → INCONCLUSIVE
            └─ No
               ↓
               Verify the lowest compatible SDK candidate + latest stable.
               ├─ Both pass → BUMP
               ├─ Candidate passes, latest fails → Investigate and retest.
               ├─ Candidate fails → Classify the failure.
               │  Revise only if incompatibility is confirmed.
               │  Investigate latest separately if it fails.
               └─ Verification blocked → INCONCLUSIVE
```

## Lanes

A lane is a disposable snapshot of the working tree, tested with one Flutter SDK.

| Lane | Flutter SDK | Used for |
| --- | --- | --- |
| `minimum` | The exact `environment.flutter` floor (e.g., `3.24.0`) | [Minimum lane](#minimum-lane) |
| `candidate` | The proposed floor, only when the decision flow requires one | [Candidate lane](#candidate-lane) |
| `latest` | The latest stable release | [Dependency audit](#1-inspect-and-audit) and [Latest lane](#latest-lane) |

To create lanes:

1. Run `mktemp -d` once per audit. Record the absolute path it prints as `<tmp>`, and write that literal path in every later command, because shell variables may not persist between commands.
2. From the repository root, create each lane:

   ```bash
   GIT_INDEX_FILE=<tmp>/<lane>.index git add -A
   GIT_INDEX_FILE=<tmp>/<lane>.index git checkout-index -a --prefix=<tmp>/<lane>/
   ```

   The throwaway index leaves the user's index and files unchanged. The lane receives tracked, staged, modified, and untracked files as they are in the working tree, but no deleted or gitignored files (e.g., `.env`, `pubspec.lock`, `.dart_tool/`, `build/`). Dependencies are therefore resolved from scratch, as for a consumer.
3. Run each lane command as `cd <tmp>/<lane> && <command>`.

While working in lanes:

- **SDK:** Select an installed SDK for each command only: `puro -e <env> flutter …`, `fvm spawn <version> …`, or the absolute path to that SDK's `bin/flutter`. Do not copy SDKs or change the selected SDK (`puro use`, `fvm use`, `flutter channel`, `flutter upgrade`, or `flutter downgrade`). Ask before installing a missing SDK.
- **Changes:** Apply proposed fixes, constraints, and temporary overrides only to lane copies.
- **Environment:** Keep the user's environment. Never override `HOME`: Chrome tests need the macOS login keychain, and without it, a blocking "Keychain Not Found" dialog appears.
- **Dialogs:** Agents cannot see system dialogs. If a run hangs or the user reports a dialog, stop the run and ask the user to click **Cancel**. Never choose an option that resets data. Mark the affected checks `BLOCKED`.
- **Cleanup:** When the audit ends, even if it stops early, stop any lane processes and run `rm -rf <tmp>` with the recorded path.

## 1. Inspect and audit

1. Record `git rev-parse HEAD` and `git status --short` to identify the exact source state under review.
2. Read `pubspec.yaml`, `example/pubspec.yaml`, and every workflow in `.github/workflows/`.
3. Inspect SDK constraints, `dependency_overrides`, and any `pubspec_overrides.yaml`.
4. Record the exact Flutter version used by the latest CI run from its logs, and the bundled Dart version from the [Flutter SDK archive](https://docs.flutter.dev/install/archive). If logs are unavailable, record that limitation rather than guessing.
5. Separate the published package from tooling and the example app. Only the package's code, metadata, SDK constraints, runtime dependencies, and published generated files affect consumers. Tooling- and example-only requirements do not by themselves justify raising the package floor.

Audit the published package's runtime dependency graph in the `latest` lane:

```bash
flutter --version
flutter pub upgrade --no-example
flutter pub outdated --no-dev-dependencies --transitive --no-dependency-overrides --no-prereleases
```

`--no-dev-dependencies` and `--no-dependency-overrides` model consumer resolution, which ignores the package's dev dependencies and overrides. Compare the columns:

- `Current` – version in the lane's `pubspec.lock`. Dev dependencies and overrides still affect it, so it may differ from a consumer's version.
- `Upgradable` – latest version allowed by the declared dependency constraints.
- `Resolvable` – latest version resolvable together with all other dependency constraints.
- `Latest` – latest published stable version.

Inspect the SDK constraints and changelogs of relevant newer dependency versions. A newer release requiring a higher SDK does not by itself justify a bump if Pub can select an older compatible version that satisfies the package's requirements.

## 2. Choose the candidate

Only when the decision flow requires a candidate:

- Use official Dart and Flutter documentation, dependency constraints, and release notes to identify the lowest SDK versions that meet the confirmed requirement.
- Change only the minimum SDK constraints that must change. The minimum Flutter release must bundle a Dart version that satisfies the Dart constraint – verify this in the [Flutter SDK archive](https://docs.flutter.dev/install/archive).
- Keep the Dart upper bound at `<4.0.0`, and revisit it only as part of an explicit Dart 4 compatibility decision. Do not rely on a Flutter upper bound instead of compatibility testing, as Pub ignores it when resolving the package as a dependency.
- Prefer a code or dependency fix that preserves existing SDK support.

## 3. Verify the constraints

Test the exact Flutter floor (e.g., `3.24.0`), not a range (e.g., `3.24.x`). `flutter pub downgrade` changes dependency versions, not the SDK version.

A browser run passes only if it executes tests. Do not treat skipped browser tests as passing.

`--platform chrome` is hidden and marked deprecated, but it is the only runner for the `@TestOn('browser')` tests in `test/`. Do not substitute `-d chrome`: `flutter test` uses devices only for `integration_test/`, so it runs `test/` on the VM and skips the browser tests. If a target SDK no longer supports `--platform chrome`, mark the browser checks `BLOCKED` and report it as a tooling finding.

### Minimum lane

Dev-only dependencies that block resolution on the minimum SDK do not affect consumers. For each one, find the newest release compatible with the lane's SDK and override it in the lane's `pubspec_overrides.yaml`. Create the file if needed; otherwise merge into its existing `dependency_overrides`. For example, `flutter_lints` 6 requires Dart 3.8, so CI uses `flutter_lints` 5 on the minimum SDK:

```yaml
dependency_overrides:
  flutter_lints: ^5.0.0
```

Run:

```bash
flutter --version
flutter pub downgrade --no-example
flutter analyze --no-pub --no-fatal-infos lib test
flutter test --no-pub
flutter test --no-pub --platform chrome
```

This resolves the lowest dependency versions allowed by the constraints, skips the example app (which requires a newer Flutter), and keeps warnings and errors fatal while tolerating informational lints. Never override runtime dependencies to make this lane pass.

### Candidate lane

Apply the proposed constraints to the lane's `pubspec.yaml`, then follow the [minimum lane](#minimum-lane) steps with the candidate SDK. Reassess the dev-only overrides for the candidate Dart version.

If the Dart lower bound becomes 3.7 or later, files at the package's default language version switch to the tall `dart format` style. After resolving dependencies, run `dart format lib test` in the lane and review the resulting changes.

### Latest lane

Reuse the `latest` lane from [step 1](#1-inspect-and-audit), without the minimum-lane override. Run:

```bash
flutter analyze --no-pub lib test
flutter pub publish --dry-run
flutter test --no-pub
flutter test --no-pub --platform chrome
flutter test --no-pub --platform chrome --wasm
```

This mirrors CI: normal analysis strictness, package validation before tests, and both JS and Wasm browser runs.

Classify every failure before deciding whether to BUMP: package incompatibility, dependency resolution, tooling/example, latest-SDK-only, or infrastructure. A latest-SDK-only failure does not justify raising the minimum.

## 4. Check CI

Confirm that CI:

- tests the exact minimum Flutter version and the latest stable on pull requests and pushes to `main`;
- keeps the `minimum` matrix `flutter-version` equal to `environment.flutter` in `pubspec.yaml`;
- gates publishing on successful completion of the required checks.

Report missing or skipped checks separately. CI gaps alone do not justify an SDK bump.

## 5. Report

Follow [`report-template.md`](./report-template.md) for every completed audit. Its structure and format are mandatory.

- Replace every `{{...}}` placeholder with the actual value. Use backticks for commands, file names, and SDK versions.
- Complete every field concisely. Never guess missing facts. Use `N/A – reason` only when a field or check does not apply, `None identified` when no issue was found, and `UNVERIFIED – reason` when a fact or result could not be verified. These labels are not interchangeable.
- Choose exactly one verdict for the published package:
  - `KEEP` – Evidence supports the current minimum; no confirmed package incompatibility requires raising it.
  - `BUMP` – Incompatibility with the current minimum is confirmed, no viable code or dependency fix preserves current support, and both the lowest compatible candidate and latest stable pass verification.
  - `POLICY DECISION` – The proposed change is a support-policy choice, not a technical requirement established by testing.
  - `INCONCLUSIVE` – Evidence or verification is insufficient to establish a reliable minimum-SDK verdict.
- Report tooling, example-app, CI, and latest-SDK-only findings separately from the published package's minimum-SDK verdict.
- Include the `Proposed candidate` row only when a specific candidate was evaluated, even if its verification was blocked or incomplete.
- For each lane, report the exact Flutter and bundled Dart versions, the dependency-resolution command, and the result of every required check. Never infer an exact version from an unpinned channel.
- For individual checks, use `PASS`, `FAIL`, `BLOCKED` (an environmental or infrastructure issue prevented execution), `NOT RUN` (a required check was not executed), `UNVERIFIED – reason`, or `N/A – reason`.
- Assign each lane a status using this precedence:
  - `FAIL` if any required check fails.
  - `BLOCKED` if any required check is blocked and none fails.
  - `INCOMPLETE` if any required check was not run or remains unverified, or the target SDK is unverified, and none fails or is blocked.
  - `PASS` only if the target SDK is verified and all applicable required checks pass.

## 6. Implement

Only if implementation is explicitly authorized, apply a verified fix that preserves the floor, or an approved BUMP, directly in the repository.

For a BUMP:

1. Update the SDK constraints, the CI `minimum` matrix version, obsolete workarounds, and user-facing docs.
2. If the Dart lower bound becomes 3.7 or later, run `flutter pub get --no-example` and `dart format lib test` in the repository with the latest stable SDK, and review the resulting changes.
3. Add a `**BREAKING CHANGE**` entry to `CHANGELOG.md`.

Then create fresh lanes from the final working tree and rerun [verification](#3-verify-the-constraints).

## References

- [Flutter SDK archive](https://docs.flutter.dev/install/archive)
- [Dart SDK constraints](https://dart.dev/tools/pub/pubspec#sdk-constraints)
- [Dart language versioning](https://dart.dev/language/versioning)
- [Package dependencies](https://dart.dev/tools/pub/dependencies)
- [Pub downgrade](https://dart.dev/tools/pub/cmd/pub-downgrade)
- [Pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated)
- [Pub upgrade](https://dart.dev/tools/pub/cmd/pub-upgrade)

### Package-specific references

- [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)
- [flutter_inappwebview changelog](https://pub.dev/packages/flutter_inappwebview/changelog)
