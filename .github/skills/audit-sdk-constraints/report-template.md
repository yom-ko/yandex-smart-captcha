<!-- markdownlint-disable MD033 -->
# Report: SDK constraints audit

**Date:** {{YYYY-MM-DD}}

**Verdict:** {{BUMP, KEEP, POLICY DECISION, or INCONCLUSIVE}}

**Summary:** {{Short conclusion, whether the constraints should change, and why.}}

**Next action:** {{Smallest concrete action, or None}}

## Findings

| Item | Finding |
| --- | --- |
| **Scope** | {{Package name / commit / ref / working-tree state / relevant uncommitted changes}} |
| **Current constraints** | Dart: {{constraint}} / Flutter: {{constraint}} |
| **Proposed constraints** | {{Unchanged, or Dart: current → proposed/unchanged; Flutter: current → proposed/unchanged}} |
| **Failure classification** | {{None identified, or package incompatibility / dependency resolution / tooling-example / latest-SDK-only / infrastructure, with brief evidence.}} |
| **Requirement and evidence** | {{Confirmed requirement and strongest supporting evidence, with links or reproducible findings.}} |
| **Dependency impact** | {{Relevant dependency versions and SDK constraints; whether an older compatible release meets the package's requirements.}} |
| **Limitations and blockers** | {{Untested versions/platforms, skipped checks, assumptions, or blockers; otherwise None identified.}} |
| **Other findings** | {{Tooling/example/CI issues separate from the published package's minimum-SDK verdict, or None identified.}} |

## Verification

| Lane | SDK versions | Dependency resolution | Checks and results | Lane status |
| --- | --- | --- | --- | --- |
| **Current minimum** | Flutter {{exact version or UNVERIFIED – reason}} / Dart {{exact version or UNVERIFIED – reason}} | {{Exact command and outcome; note temporary overrides used in the isolated copy}} | <p>Analyze: {{status}}</p><p>Unit tests: {{status}}</p><p>Browser tests: {{status}}</p><p>Platform checks: {{status}}</p> | {{PASS, FAIL, BLOCKED, or INCOMPLETE – brief reason}} |
| **Proposed candidate** | {{Exact Flutter and Dart versions, or N/A – no candidate evaluated}} | {{Exact command and outcome, or N/A – no candidate evaluated}} | {{Statuses for required checks, or N/A – no candidate evaluated}} | {{PASS, FAIL, BLOCKED, INCOMPLETE, or N/A – reason}} |
| **Latest stable** | Flutter {{exact version or UNVERIFIED – reason}} / Dart {{exact version or UNVERIFIED – reason}} | {{flutter pub get --no-example or flutter pub upgrade --no-example; outcome}} | <p>Analyze: {{status}}</p><p>Unit tests: {{status}}</p><p>Browser tests: {{status}}</p><p>Publish dry-run: {{status}}</p><p>Platform checks: {{status}}</p> | {{PASS, FAIL, BLOCKED, or INCOMPLETE – brief reason}} |
