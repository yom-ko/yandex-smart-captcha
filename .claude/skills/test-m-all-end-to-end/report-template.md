# Report: End-to-end test

**Date:** {{YYYY-MM-DD}}

**Verdict:** {{PASS, FAIL, or INCOMPLETE}}

**Summary:** {{One or two sentences: overall result and the most important findings.}}

**Scope:** {{Commit, and any uncommitted changes under test}}

**Environment:** Flutter {{version}} / Dart {{version}} / patrol_cli {{version}}

## Automated suites

| Suite | Command | Target | Status | Notes |
| --- | --- | --- | --- | --- |
| {{Analyze / package VM / package browser JS / package browser Wasm / example widget / Patrol}} | {{command}} | {{VM, browser, or device and OS version}} | {{status}} | {{Failures, flakiness, or None}} |

## Exploratory coverage

| Platform | Target | Build | Scenarios covered | Status |
| --- | --- | --- | --- | --- |
| {{Android, iOS, or web}} | {{Device or browser and its version; Android System WebView version}} | {{debug or JS; Wasm only with evidence that Wasm actually ran}} | {{Core flows and edge cases exercised}} | {{status}} |

## Findings

<!-- If there are no findings, write "None" instead of a table. -->

| # | Severity | Target(s) | Scenario | Expected | Actual | Evidence | Cause |
| --- | --- | --- | --- | --- | --- | --- | --- |
| {{n}} | {{HIGH, MEDIUM, or LOW}} | {{Affected targets}} | {{Steps}} | {{Expected behavior, with source}} | {{Observed behavior; deterministic or flaky}} | {{Log excerpt or screenshot path, with the client key and tokens redacted}} | {{package, example app, test infrastructure, environment, or external service}} |

## Limitations

- {{Required checks that were UNCLEAR, BLOCKED, or NOT RUN, with reasons; optional checks that were not run; Wasm fallbacks; OS minimums declared by the app but unsupported by the installed SDK; temporary edits made and reverted. Write None if not applicable.}}
