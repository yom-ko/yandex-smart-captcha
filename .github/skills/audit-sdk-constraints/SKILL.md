---
name: audit-sdk-constraints
description: >-
  Audit this Flutter package's minimum Dart and Flutter SDK constraints. Use when reviewing SDK compatibility, dependency upgrades, new language features or APIs, minimum-SDK CI failures, release readiness, or support-policy changes.
---

# Auditing Dart and Flutter SDK constraints

## Principles

Assess and report only unless implementation is explicitly authorized.

Keep the lowest Dart and Flutter SDK constraints the published package can genuinely support and verify. Do not raise them solely because newer SDKs or dependencies are available.

Run dependency resolution and tests in separate isolated copies of the exact source state under review, including uncommitted changes. Preserve the user's working tree, lockfiles, overrides, and SDK setup. Keep dependency resolution independent between verification lanes.

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
      ├─ Floor passes; latest fails → Investigate and retest.
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
3. Inspect SDK constraints, dependency overrides, and `pubspec_overrides.yaml`.
4. Check whether `pubspec.lock` exists, is tracked, or has user changes. Do not read the entire file – inspect only relevant entries.
5. Record the exact Flutter and bundled Dart versions reported by CI. If CI uses an unpinned stable channel and logs are unavailable, record that limitation rather than guessing.
6. Separate the published package from tooling and the example app. The package's code, metadata, SDK constraints, runtime dependencies, and included generated files affect consumers; tooling- and example-only requirements do not necessarily justify raising the package floor.

In a fresh isolated copy using the latest stable Flutter, audit the published package's runtime dependency graph. To model consumer resolution, temporarily disable package-local `dependency_overrides` from `pubspec.yaml` and `pubspec_overrides.yaml` in the audit copy only. Preserve unrelated settings and the original files.

Run:

```bash
flutter pub get --no-example
flutter pub outdated --no-dev-dependencies --transitive --no-dependency-overrides --no-prereleases
```

Use `pub outdated` to compare:

- `Current` – version recorded in `pubspec.lock`; it may reflect local resolution.
- `Upgradable` – latest version allowed by the declared dependency constraints.
- `Resolvable` – latest version resolvable when considering the other dependency constraints.
- `Latest` – latest published stable version, excluding prereleases.

Inspect the SDK constraints and release notes of relevant newer dependency versions.

If a lockfile prevents testing newer compatible dependencies, use `flutter pub upgrade --no-example` in the isolated verification copy and repeat the relevant tests. Never modify the user's original lockfile.

A newer dependency release requiring a higher SDK does not by itself justify a bump if Pub can select an older compatible version that satisfies the package's requirements.

## 2. Choose the candidate

- Use official Dart and Flutter documentation, dependency constraints, and release notes to identify the lowest SDK versions that meet the confirmed requirement. Use the [Flutter SDK archive](https://docs.flutter.dev/install/archive) to verify the Dart version bundled with each candidate Flutter release.
- Update only the minimum SDK constraints that need to change. Ensure the minimum Flutter release bundles a Dart SDK version that satisfies the package's Dart SDK constraint.
- The lower bound of the Dart SDK constraint determines the package's default language version. Raising it from below Dart 3.7 to Dart 3.7 or later opts the package into the newer `dart format` style (the tall style). Run `flutter pub get` before formatting and review any resulting formatting changes.
- As a policy for this Dart 3 package, keep the Dart SDK upper bound below `4.0.0`. Revisit this policy only as part of an explicit Dart 4 compatibility decision. Do not use a Flutter upper bound as a substitute for compatibility testing, as Pub ignores Flutter upper bounds when resolving the package as a dependency.
- Prefer a code or dependency fix that preserves existing SDK support. Report BUMP only when incompatibility with the current minimum is confirmed, no viable fix preserves that support, and both the lowest compatible SDK candidate and latest stable pass verification.

## 3. Verify

Use separate fresh isolated copies of the exact source state under review for minimum and latest verification. Select the intended Flutter SDK for each lane and record the Flutter and bundled Dart versions using `flutter --version`. Test the exact Flutter floor (e.g., `3.24.0`), not a broad range (e.g., `3.24.x`). `flutter pub downgrade` changes dependency resolution, not the SDK version.

### Minimum lane

If a dev-only dependency prevents resolution on the minimum SDK, assess it separately from runtime dependencies. `flutter_lints` 6 requires Dart 3.8; if it is incompatible with the minimum SDK but `flutter_lints` 5 is compatible, add or merge this temporary override into `pubspec_overrides.yaml` in the isolated copy only. Preserve existing overrides and reassess the workaround whenever SDK constraints or dependency manifests change.

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

This resolves the lowest dependency versions allowed by the constraints and overrides, excludes the example app from dependency resolution, and tolerates informational lint differences while keeping warnings and errors fatal. Do not override runtime dependencies merely to make the minimum lane pass.

### Latest lane

Use a fresh isolated copy without the minimum-SDK override and select the latest stable Flutter SDK.

Choose one dependency-resolution command before running the checks:

- `flutter pub get --no-example` to preserve locked versions where possible.
- `flutter pub upgrade --no-example` to test the latest compatible dependency versions, especially if the lockfile pins older versions.

Run:

```bash
flutter --version
flutter analyze --no-pub lib test
flutter test --no-pub
flutter test --no-pub --platform chrome
flutter pub publish --dry-run
```

The latest lane uses the normal analysis strictness. The publish dry run checks package metadata, layout, and the files intended for publication.

Do not treat skipped browser tests as passing. Add platform-specific tests only when the changes require them.

Classify failures before deciding whether to BUMP. Distinguish package incompatibility from dependency-resolution, tooling/example, latest-SDK, and infrastructure issues. A failure on the latest SDK alone does not justify raising the minimum.

## 4. Check CI

Confirm that CI:

- tests the exact minimum Flutter version and latest stable on pull requests and pushes to `main`;
- keeps the minimum matrix entry aligned with the Flutter floor in `pubspec.yaml`;
- gates publishing on successful completion of the required checks.

Report missing or skipped checks separately. CI gaps alone do not justify an SDK bump.

## 5. Report

Follow [`report-template.md`](report-template.md) for every completed audit. Its structure and format are mandatory.

- Replace every `{{...}}` placeholder with the actual value; remove the braces.
- Use backticks where appropriate, such as for commands, file names, versions, and SDK constraints.
- Complete every field concisely without sacrificing clarity or usefulness. Never guess missing facts. Use `N/A — reason` only when a field or check does not apply, `None identified` when no issue was found, and `UNVERIFIED — reason` when a fact or result could not be verified. These labels are not interchangeable.
- Choose exactly one verdict for the published package:
  - `KEEP` — Evidence supports the current minimum; no confirmed package incompatibility requires raising it.
  - `BUMP` — Incompatibility with the current minimum is confirmed, no viable code or dependency fix preserves current support, and both the lowest compatible candidate and latest stable pass verification.
  - `POLICY DECISION` — The proposed change is a support-policy choice, not a technical requirement established by testing.
  - `INCONCLUSIVE` — Evidence or verification is insufficient to establish a reliable minimum-SDK verdict.
- Report tooling, example-app, CI, and latest-SDK-only findings separately from the published package's minimum-SDK verdict.
- Include the `Proposed candidate` row only when a specific candidate was considered for BUMP; omit it otherwise. If candidate verification is blocked or incomplete, retain the row and report the actual results.
- For the current minimum, any proposed candidate, and latest stable, report the exact Flutter and bundled Dart versions, dependency-resolution strategy, and results of every required check. If a version cannot be verified, state `UNVERIFIED — reason`. Never infer an exact version from an unpinned channel.
- For individual checks, use `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`, `UNVERIFIED – reason`, or `N/A – reason` statuses. Use `N/A – reason` only when a check does not apply; `UNVERIFIED – reason` for facts that could not be verified; `NOT RUN` means a required check was not executed; `BLOCKED` means a specific environmental or infrastructure issue prevented execution.
- Assign each verification lane a status using this precedence:
  - `FAIL` if any required check fails.
  - `BLOCKED` if any required check is blocked and none fails.
  - `INCOMPLETE` if any required check was not run or remains unverified, or the target SDK is unverified, and none fails or is blocked.
  - `PASS` only if the target SDK is verified and all applicable required checks pass.
- If implementation is authorized and BUMP is approved, update the relevant SDK constraints, CI minimum, obsolete workarounds, user-facing docs, and changelog. Rerun verification on the final changes. Treat an SDK floor increase as a breaking change according to the project's versioning policy.

## References

- [Dart SDK constraints](https://dart.dev/tools/pub/pubspec#sdk-constraints)
- [Dart language versioning](https://dart.dev/language/versioning)
- [Package dependencies](https://dart.dev/tools/pub/dependencies)
- [Pub get](https://dart.dev/tools/pub/cmd/pub-get)
- [Pub downgrade](https://dart.dev/tools/pub/cmd/pub-downgrade)
- [Pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated)
- [Pub upgrade](https://dart.dev/tools/pub/cmd/pub-upgrade)
- [Flutter releases](https://flutterreleases.com/)
- [Flutter SDK archive](https://docs.flutter.dev/install/archive)

### Package-specific references

- [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)
- [flutter_inappwebview changelog](https://pub.dev/packages/flutter_inappwebview/changelog)
