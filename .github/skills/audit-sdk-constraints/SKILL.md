---
name: audit-sdk-constraints
description: >-
  Audit this Flutter package's minimum Dart and Flutter SDK constraints. Use when reviewing SDK compatibility, pubspec environment constraints, dependency upgrades, adoption of new language features or APIs, minimum-SDK CI failures, release readiness, or support-policy changes.
---

# Auditing Dart and Flutter SDK constraints

## Key rules

Assess and report only, unless implementation is explicitly authorized.

Keep the lowest Dart and Flutter SDK constraints the published package genuinely supports and that pass verification. Do not raise them solely because newer SDKs or dependencies are available.

Run dependency resolution and tests in a separate isolated copy of the exact source state under review, including uncommitted changes, for each lane. Never modify the user's working tree, lockfile, overrides, or SDK setup.

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
            ├─ Yes → Verify the fix.
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

## 1. Inspect and audit

1. Check Git status and identify the exact source state under review.
2. Read `pubspec.yaml`, `example/pubspec.yaml`, `.github/workflows/main.yml`, and `.github/workflows/publish.yml`.
3. Inspect SDK constraints, `dependency_overrides`, and any `pubspec_overrides.yaml`.
4. Check whether `pubspec.lock` exists, is tracked, or has user changes. Read only the relevant entries.
5. Record the exact Flutter and bundled Dart versions reported by CI. If CI uses an unpinned stable channel and logs are unavailable, record that limitation rather than guessing.
6. Separate the published package from tooling and the example app. Only the package's code, metadata, SDK constraints, runtime dependencies, and published generated files affect consumers. Tooling- and example-only requirements do not by themselves justify raising the package floor.

In a fresh isolated copy using the latest stable Flutter, audit the published package's runtime dependency graph. To model consumer resolution, remove package-local `dependency_overrides` from `pubspec.yaml` and `pubspec_overrides.yaml` in that copy.

Run:

```bash
flutter pub get --no-example
flutter pub outdated --no-dev-dependencies --transitive --no-dependency-overrides --no-prereleases
```

Use `pub outdated` to compare:

- `Current` – version recorded in `pubspec.lock`; it may reflect local resolution.
- `Upgradable` – latest version allowed by the declared dependency constraints.
- `Resolvable` – latest version resolvable together with all other dependency constraints.
- `Latest` – latest published stable version.

Inspect the SDK constraints and changelogs of relevant newer dependency versions. A newer release requiring a higher SDK does not by itself justify a bump if Pub can select an older compatible version that satisfies the package's requirements.

## 2. Choose the candidate

- Use official Dart and Flutter documentation, dependency constraints, and release notes to identify the lowest SDK versions that meet the confirmed requirement.
- Update only the minimum SDK constraints that need to change. The minimum Flutter release must bundle a Dart version that satisfies the Dart constraint – verify this in the [Flutter SDK archive](https://docs.flutter.dev/install/archive).
- The Dart lower bound sets the package's default language version. Raising it to Dart 3.7 or later opts the package into the tall `dart format` style: run `flutter pub get`, then `dart format .`, and review the resulting changes.
- Keep the Dart upper bound at `<4.0.0`, and revisit it only as part of an explicit Dart 4 compatibility decision. Do not rely on a Flutter upper bound instead of compatibility testing, as Pub ignores it when resolving the package as a dependency.
- Prefer a code or dependency fix that preserves existing SDK support.

## 3. Verify the constraints

For each lane, select the intended Flutter SDK and record the Flutter and bundled Dart versions with `flutter --version`. Test the exact Flutter floor (e.g., `3.24.0`), not a range (e.g., `3.24.x`). `flutter pub downgrade` changes dependency versions, not the SDK version.

### Minimum lane

Assess dev-only dependencies that block resolution on the minimum SDK separately from runtime dependencies. `flutter_lints` 6 requires Dart 3.8. If `flutter_lints` 5 is compatible with the minimum SDK, merge this override into the isolated copy's `pubspec_overrides.yaml`, as CI does. Reassess it whenever SDK constraints or dependency manifests change.

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

This resolves the lowest dependency versions allowed by the constraints, excludes the example app (which requires a newer Flutter), and tolerates informational lints while keeping warnings and errors fatal. Never override runtime dependencies to make this lane pass.

### Latest lane

Use the latest stable Flutter SDK without the minimum-lane override. Resolve dependencies with one of:

- `flutter pub get --no-example` to preserve locked versions where possible.
- `flutter pub upgrade --no-example` to test the latest compatible dependency versions, especially if the lockfile pins older versions.

Run:

```bash
flutter --version
flutter analyze --no-pub lib test
flutter test --no-pub
flutter test --no-pub --platform chrome
flutter test --no-pub --platform chrome --wasm
flutter pub publish --dry-run
```

This lane uses normal analysis strictness, mirrors CI's JS/Wasm runs, and validates package metadata, layout, and published files.

Do not treat skipped browser tests as passing.

Classify failures before deciding whether to BUMP: package incompatibility, dependency resolution, tooling/example, latest-SDK-only, or infrastructure. A latest-SDK-only failure does not justify raising the minimum.

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
- For individual checks, use `PASS`, `FAIL`, `BLOCKED` (an environmental or infrastructure issue prevented execution), `NOT RUN` (a required check was not executed), `UNVERIFIED – reason`, or `N/A – reason` status.
- Assign each verification lane a status using this precedence:
  - `FAIL` if any required check fails.
  - `BLOCKED` if any required check is blocked and none fails.
  - `INCOMPLETE` if any required check was not run or remains unverified, or the target SDK is unverified, and none fails or is blocked.
  - `PASS` only if the target SDK is verified and all applicable required checks pass.
- If implementation is authorized and BUMP is approved, update the SDK constraints, CI minimum, obsolete workarounds, and user-facing docs, and add a `**BREAKING CHANGE**` entry to `CHANGELOG.md`. Rerun verification on the final changes.

## References

- [Flutter SDK archive](https://docs.flutter.dev/install/archive)
- [Dart SDK constraints](https://dart.dev/tools/pub/pubspec#sdk-constraints)
- [Dart language versioning](https://dart.dev/language/versioning)
- [Package dependencies](https://dart.dev/tools/pub/dependencies)
- [Pub get](https://dart.dev/tools/pub/cmd/pub-get)
- [Pub downgrade](https://dart.dev/tools/pub/cmd/pub-downgrade)
- [Pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated)
- [Pub upgrade](https://dart.dev/tools/pub/cmd/pub-upgrade)

### Package-specific references

- [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)
- [flutter_inappwebview changelog](https://pub.dev/packages/flutter_inappwebview/changelog)
