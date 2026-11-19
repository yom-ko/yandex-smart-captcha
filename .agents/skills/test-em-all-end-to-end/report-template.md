<!-- Do not append a trailing period to standalone status or template values
such as "PASS", "FAIL", "INCOMPLETE", "HIGH", "MEDIUM", "LOW", "None", etc. -->

# Report: End-to-end testing

**Date:** {{YYYY-MM-DD}}

**Verdict:** {{PASS, FAIL, or INCOMPLETE}}

**Summary:** {{One or two sentences: package-focused conclusion, confirmed package defects, and important excluded errors or checks.}}

**Scope:** {{Commit and any pre-existing uncommitted changes under test}}

**Environment:** Host {{OS and version}} / Flutter {{version}} / Dart {{version}} / patrol_cli {{version}} / patrol {{version}} / Xcode {{version, or N/A}}

## Automated suites

| Suite | Command | Target | Status | Notes |
| --- | --- | --- | --- | --- |
| {{Analyze / VM / browser JS / modern interop / browser Wasm / example widget / build / Patrol}} | {{command without secrets}} | {{VM, browser, or device and OS version}} | {{status}} | {{Exit result; tests passed, failed, or skipped where applicable; retry outcome and attribution}} |

## Exploratory coverage

Use separate rows for different statuses; never hide a blocked or unrun scenario in a `PASS` row.

| Platform | Target | Build | Scenarios covered | Scenarios not covered | Status |
| --- | --- | --- | --- | --- | --- |
| {{Android, iOS, or web}} | {{Device or exact browser/engine and version; Android WebView provider and version}} | {{debug or release; JS, default fallback, or opt-in Wasm with execution evidence}} | {{Core flows and edge cases exercised}} | {{Required scenarios not run, blocked, or N/A, with reasons; or None}} | {{status}} |

## Findings

<!-- If there are no findings or excluded errors, write "None" instead of a table. -->

| # | Severity | Target(s) | Scenario | Expected | Actual | Evidence | Cause | Verdict impact |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {{n}} | {{HIGH, MEDIUM, or LOW}} | {{Affected targets}} | {{Steps}} | {{Expected behavior, with source}} | {{Observed behavior; deterministic or flaky}} | {{Log excerpt or screenshot path, with client keys and tokens redacted}} | {{package, example app, test infrastructure, environment, external service, or unresolved}} | {{FAIL – confirmed package defect / Excluded – reason / INCOMPLETE – required check remains BLOCKED or UNCLEAR}} |

Severity describes the impact of the observed behavior, independently of whether it is attributable to the package.

## Previous findings

<!-- Include this section only if a previous report was provided. -->

| Previous # | Finding | Now | Evidence |
| --- | --- | --- | --- |
| {{n}} | {{Short description}} | {{Persists, Gone, Changed – how, or NOT RUN/BLOCKED/UNCLEAR – why}} | {{Targets retested and result}} |

## Limitations

<!-- If there are no limitations, write "None" instead of a list. -->

- {{Required checks marked `UNCLEAR`, `BLOCKED`, or `NOT RUN`, with reasons. Distinguish an expected JS fallback from a missing required Wasm result.}}
- {{Optional checks not run or not passing, with reasons}}
- {{Other environment or service limitations, including unsupported app minimums}}

## Temporary changes

<!-- If no changes were made, write "None" instead of a list. -->

- {{Snapshot edits, devices, downloads, and settings: what was removed or restored, and what remains and why}}

## Status definitions

- `PASS` – Expected behavior was verified.
- `FAIL` – A defect in the Flutter package itself was confirmed.
- `UNCLEAR` – The check ran, but expected behavior or attribution to a package defect could not be established.
- `BLOCKED` – An issue outside the package prevented verification.
- `NOT RUN` – The check was not executed.
- `N/A – reason` – The check does not apply to the target.

## Verdict definitions

Optional checks affect the verdict only when they confirm a package defect.

- `PASS` – Every required check is `PASS` or `N/A`, and no package defect within this package's control was confirmed.
- `FAIL` – At least one package defect within this package's control was confirmed, by any check, optional ones included.
- `INCOMPLETE` – No package defect was confirmed, but at least one required check is `UNCLEAR`, `BLOCKED`, or `NOT RUN`.
