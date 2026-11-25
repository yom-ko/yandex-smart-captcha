<!-- Do not append a trailing period to standalone status or template values
such as "ALIGNED", "MISALIGNED", "INCONCLUSIVE", "MISMATCH", "None", etc. -->

# Report: Yandex contract audit

**Date:** {{YYYY-MM-DD}}

**Verdict:** {{ALIGNED, MISALIGNED, or INCONCLUSIVE}}

**Summary:** {{One or two sentences: why the verdict applies, including any applied exclusions or material limitations.}}

## Findings

<!-- Include only MISMATCH, DEPRECATED, and MISSING findings.
If there are none, write "None" instead of the table. -->

| Item | Status | Location | Official contract | Integration | Suggestion |
| --- | --- | --- | --- | --- | --- |
| {{Script URL, method, event, parameter, or capability}} | {{MISMATCH, DEPRECATED, or MISSING}} | {{file:line, line range, relevant public API; or Not implemented}} | {{Documented behavior or value, with source link}} | {{Observed implementation, with relevant details}} | {{Smallest appropriate change; or None if no change is warranted}} |

## Sources

- {{Documentation page title and URL}} – {{Reviewed successfully / Could not access or verify a material detail – reason}}

<!-- Add a button or link "Save the report" that lets the user save the report as a Markdown file named "<skill-name>-report.md". -->
