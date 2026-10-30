# Report: End-to-end test

**Date:** {{YYYY-MM-DD}}

**Verdict:** {{PASS, FAIL, or INCOMPLETE}}

**Summary:** {{One or two sentences: package-focused conclusion, confirmed package defects, and important excluded errors or checks.}}

**Scope:** {{Commit and any pre-existing uncommitted changes under test}}

**Environment:** Host {{OS and version}} / Flutter {{version}} / Dart {{version}} / patrol_cli {{version}}

## Automated suites

| Suite | Command | Target | Status | Notes |
| --- | --- | --- | --- | --- |
| {{Analyze / package VM / package browser JS / package browser Wasm / example widget / Patrol}} | {{command}} | {{VM, browser, or device and OS version}} | {{status}} | {{Actual command outcome, failures, flakiness, attribution, and excluded errors; or None}} |

## Exploratory coverage

| Platform | Target | Build | Scenarios covered | Status |
| --- | --- | --- | --- | --- |
| {{Android, iOS, or web}} | {{Device or browser and its version; Android System WebView version}} | {{debug, JS, or Wasm with execution evidence}} | {{Core flows and edge cases exercised}} | {{status}} |

## Findings

<!-- If there are no findings or excluded errors, write "None" instead of a table. -->

| # | Severity | Target(s) | Scenario | Expected | Actual | Evidence | Cause | Verdict impact |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {{n}} | {{HIGH, MEDIUM, or LOW}} | {{Affected targets}} | {{Steps}} | {{Expected behavior, with source}} | {{Observed behavior; deterministic or flaky}} | {{Log excerpt or screenshot path, with client keys and tokens redacted}} | {{package, example app, test infrastructure, environment, external service, or unresolved}} | {{FAIL – confirmed package defect / Excluded – reason / INCOMPLETE – required check remains BLOCKED or UNCLEAR}} |

Severity describes the impact of the observed behavior, independently of whether it is attributable to the package.

## Limitations

- {{Required checks with `UNCLEAR`, `BLOCKED`, or `NOT RUN` statuses, with reasons}}
- {{Optional checks not run, if relevant}}
- {{Wasm fallbacks or builds not verified as Wasm}}
- {{OS minimums declared by the app but unsupported by the installed SDK}}
- {{Other environment or service limitations}}

Write None if there are no limitations.

## Temporary changes

{{List temporary changes made during testing and confirm that they were reverted. Write None if no changes were made.}}

## Status definitions

- `PASS` – Expected behavior was verified.
- `FAIL` – A defect in the Flutter package itself was confirmed.
- `UNCLEAR` – The check ran, but expected behavior or attribution to a package defect could not be established.
- `BLOCKED` – An issue outside the package prevented verification.
- `NOT RUN` – The check was not executed.
- `N/A – reason` – The check does not apply to the target.

## Verdict definitions

- `PASS` – Every required check is `PASS` or `N/A`, and no package defect within this package's control was confirmed.
- `FAIL` – At least one package defect within this package's control was confirmed.
- `INCOMPLETE` – No package defect was confirmed, but at least one required check is `UNCLEAR`, `BLOCKED`, or `NOT RUN`.
