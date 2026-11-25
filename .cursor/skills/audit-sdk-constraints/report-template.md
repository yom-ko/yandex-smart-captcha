<!-- markdownlint-disable MD033 -->
<!-- Do not append a trailing period to standalone status or template values
such as "KEEP", "BUMP", "POLICY DECISION", "INCONCLUSIVE", "None" , etc. -->

# Report: SDK constraints audit

**Date:** {{YYYY-MM-DD}}

**Verdict:** {{KEEP, BUMP, POLICY DECISION, or INCONCLUSIVE}}

**Summary:** {{One or two sentences: whether the constraints should change, and why.}}

**Next action:** {{Smallest concrete action, or None}}

## Findings

| Item | Finding |
| --- | --- |
| **Scope** | {{Package / commit or ref / working-tree state, including relevant uncommitted changes.}} |
| **Current constraints** | Dart: {{constraint}} / Flutter: {{constraint}} |
| **Proposed constraints** | {{Unchanged, or Dart: current → proposed / Flutter: current → proposed}} |
| **Requirement and evidence** | {{Confirmed requirement and strongest evidence, with links or reproducible findings; or None identified.}} |
| **Dependency impact** | {{Relevant dependency versions and SDK constraints; whether an older compatible release meets the package's needs.}} |
| **Failure classification** | {{Package incompatibility / dependency resolution / tooling-example / latest-SDK-only / infrastructure, with brief evidence; or None identified.}} |
| **Limitations and blockers** | {{Untested versions or platforms, skipped checks, assumptions, or blockers, or other limitations; or None identified.}} |
| **Other findings** | {{Tooling, example, CI, or latest-SDK-only issues outside the verdict; or None identified.}} |

## Verification

<!-- Include the Proposed candidate row only if a candidate was evaluated. -->

| Lane | SDK versions | Dependency resolution | Checks | Lane status |
| --- | --- | --- | --- | --- |
| **Current minimum** | Flutter {{exact version or UNVERIFIED – reason}} / Dart {{exact version or UNVERIFIED – reason}} | {{Commands and outcomes; versions changed by the upgrade; temporary overrides used}} | <p>Analyze: {{status}}</p><p>Unit/widget tests: {{status}}</p><p>Browser tests: {{status}}</p><p>Upgraded-dependency rerun: {{status}}</p> | {{PASS, FAIL, BLOCKED, or INCOMPLETE – reason}} |
| **Latest stable** | Flutter {{exact version or UNVERIFIED – reason}} / Dart {{exact version or UNVERIFIED – reason}} | {{`flutter pub upgrade --no-example` and outcome}} | <p>Analyze: {{status}}</p><p>Unit/widget tests: {{status}}</p><p>Browser tests (JS): {{status}}</p><p>Browser tests (Wasm): {{status}}</p><p>Publish dry run: {{status}}</p> | {{PASS, FAIL, BLOCKED, or INCOMPLETE – reason}} |
| **Proposed candidate** | Flutter {{exact version or UNVERIFIED – reason}} / Dart {{exact version or UNVERIFIED – reason}} | {{Commands and outcomes; versions changed by the upgrade; temporary overrides used}} | <p>Analyze: {{status}}</p><p>Unit/widget tests: {{status}}</p><p>Browser tests: {{status}}</p><p>Upgraded-dependency rerun: {{status}}</p> | {{PASS, FAIL, BLOCKED, or INCOMPLETE – reason}} |

<!-- Add a button or link labeled "Save the report" that lets the user save the report as a Markdown file named "<skill-name>-report.md". -->
