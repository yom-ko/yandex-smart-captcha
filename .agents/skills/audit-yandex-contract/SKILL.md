---
name: audit-yandex-contract
description: >-
  Audit this Flutter package's integration with the Yandex SmartCaptcha JavaScript API contract against official Yandex Cloud documentation. Use when reviewing script URLs, widget methods, events, render parameters, or documented deprecations, especially before releases or after API changes.
---

# Auditing the Yandex SmartCaptcha contract

## Main rules

- Assess and report only. Do not modify files unless the user explicitly asks.
- Do not run tests or execute code. This is a static audit against the documented API contract.
- Treat official Yandex Cloud documentation as the sole source of truth for API behavior and deprecation claims.
- If a relevant documentation page cannot be opened or read well enough, record the URL and the limitation. Do not guess.
- Distinguish API compatibility from feature coverage. An unsupported API feature is not a defect unless the package claims to support it.

## 1. Read the official contract

Open these pages:

- [SmartCaptcha documentation root](https://yandex.cloud/en/docs/smartcaptcha/)
- [SmartCaptcha widget installation methods](https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods)

Follow additional links when needed to verify script loading, render parameters, events, method signatures, or deprecation notices.

> If any linked page has moved or its content has been relocated, follow the official redirects or links to the current Yandex Cloud documentation and treat the updated pages as the source of truth.

Record the documented:

- Script source/URL and required query parameters.
- Widget methods, including parameter types and return types.
- Event names/meaning, callback signatures, and unsubscribe behavior.
- Render parameters, including names, types, defaults, and allowed values (where documented).
- Explicit deprecation notices and their documented replacements.

Do not infer that an item is deprecated merely because it is absent from a page.

## 2. Inspect the current integration

Review these files and the relevant definitions or references they depend on:

- `lib/src/captcha_event.dart` – shared event vocabulary.
- `lib/src/captcha_config.dart` – render options passed to the widget and WebView.
- `lib/src/native/captcha_adapter.dart` – WebView HTML/JavaScript and script loading.
- `lib/src/web/captcha_adapter_web.dart` – web interop extensions for the JavaScript widget.
- `lib/src/web/captcha_script_loader_web.dart` – web script element construction and loading.
- `lib/src/web/captcha_adapter_controller_web.dart` – web controller and widget methods, including `render`, `subscribe`, `execute`, `reset`, and `destroy`.

Inspect relevant public API declarations, exports, or package documentation to determine which capabilities the package claims to support.

Trace referenced code only as far as necessary to understand the actual integration. Do not expand the audit into unrelated code.

## 3. Compare and classify the findings

Compare the integration with the documented contract. Use exactly one status for each finding:

| Status | Meaning |
| --- | --- |
| `OK` | The integration matches the documented contract. |
| `MISMATCH` | A URL, name, type, value, parameter, or behavior conflicts with the documented contract. |
| `DEPRECATED` | The integration uses an item explicitly marked deprecated or outdated by the documentation. Report the documented replacement when available. |
| `MISSING` | A documented API capability relevant to the package's scope is not implemented or exposed. This is informational unless the package claims to support this capability. |

Check that:

- Script URLs and query parameters comply with the documented integration method.
- Native and web adapters expose consistent behavior where it is expected. Account for legitimate platform-specific differences.
- Method names, arguments, return types, event names, callback signatures, and render parameters match the documentation.
- Values preserve their documented types; for example, booleans are not passed as strings.
- Deprecated items are identified only when supported by explicit documentation.

For each non-`OK` finding, identify the affected file and relevant code location, cite the official documentation URL, and explain the discrepancy. Do not invent replacements or expected behavior.

> Before reporting, check [`known-exclusions.md`](./known-exclusions.md). Do not report deviations listed there unless the documentation changes in a way that invalidates their rationale.

## 4. Decide the verdict

Use exactly one overall verdict:

- `ALIGNED` – the relevant documentation was reviewed sufficiently, and no `MISMATCH` or `DEPRECATED` findings remain. Informational `MISSING` findings do not prevent this verdict.
- `MISALIGNED` – at least one confirmed `MISMATCH` or `DEPRECATED` finding exists. Use this verdict even if an unrelated documentation page was unavailable, and disclose the limitation.
- `INCONCLUSIVE` – no confirmed `MISMATCH` or `DEPRECATED` finding establishes misalignment, but unavailable or unreadable documentation prevents completing a material part of the audit.

A `MISSING` finding alone must not produce `MISALIGNED`.

## 5. Report

Use [`report-template.md`](./report-template.md) for every completed audit. Its structure and format are mandatory.

- Report all relevant `MISMATCH`, `DEPRECATED`, and `MISSING` findings. Do not include `OK` items in the Findings table.
- Clearly distinguish confirmed incompatibilities from informational coverage gaps.
- Include the evidence and documentation links required to verify each finding.
- If there are no findings, write `None` in place of the Findings table.
- Record inaccessible documentation and any resulting limitations.
