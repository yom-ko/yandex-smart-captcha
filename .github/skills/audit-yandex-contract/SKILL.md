---
name: audit-yandex-contract
description: >-
  Audit this Flutter package's integration with the Yandex SmartCaptcha JavaScript API contract against official Yandex Cloud documentation. Use only when the user explicitly asks to run this `audit-yandex-contract` skill or another skill explicitly invokes it.
---

# Auditing the Yandex SmartCaptcha contract

## Main rules

- Assess and report only. Do not modify any files unless the user explicitly asks.
- Do not run tests or execute code. This is a static audit against the documented API contract.
- Treat the official Yandex Cloud documentation as the sole source of truth for API behavior and deprecations.
- If a relevant documentation page cannot be opened or read well enough, record its URL and the limitation. Do not guess.

## 1. Read the contract

Read these pages:

- [Integration methods](https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods)
- [Invisible CAPTCHA](https://yandex.cloud/en/docs/smartcaptcha/concepts/invisible-captcha)

Follow other links from the [documentation root](https://yandex.cloud/en/docs/smartcaptcha/) only to verify a specific item.

> If a page has moved, follow the official redirects or links and treat the current page as the source of truth.

Record the documented:

- Script URL and query parameters of each integration method.
- Widget methods, with their parameters, types and return types.
- `render` parameters, with their types, defaults, and allowed values.
- Event names, meanings, and callback signatures, and how to unsubscribe.
- Explicit deprecation notices and their replacements.

Do not treat an item as deprecated merely because a page does not mention it.

## 2. Inspect the integration

Review these files. Trace referenced code only as far as needed to understand the integration:

- `lib/src/captcha_config.dart` – options passed to `render` and the WebView.
- `lib/src/captcha_event.dart` – shared event vocabulary and the events passed to `subscribe`.
- `lib/src/captcha_language.dart` and `lib/src/dpn_badge_position.dart` – values passed as `hl` and `shieldPosition`.
- `lib/src/native/captcha_adapter.dart` – WebView HTML/JavaScript: script loading, `render`, `subscribe`, and widget method calls.
- `lib/src/web/captcha_script_loader_web.dart` – web script loading.
- `lib/src/web/captcha_adapter_web.dart` – JavaScript interop declarations for `window.smartCaptcha` and the `render` options.
- `lib/src/web/captcha_adapter_controller_web.dart` – web calls to `render`, `subscribe`, `execute`, `reset`, and `destroy`.

To determine which capabilities the package claims to support, read `README.md` and the Dartdoc in `lib/src/yandex_smart_captcha.dart`.

## 3. Compare and classify findings

Compare the integration with the recorded contract. Check that:

- Script URLs and query parameters match a documented connection method.
- Method names, arguments, and return types match the documentation.
- Event names and callback signatures match the documentation.
- `render` parameter names, values, and types match the documentation. For example, booleans must not be passed as strings.
- Native and web adapters behave consistently. Platform differences documented in `README.md` are intentional.

Assign each finding exactly one status:

| Status | Meaning |
| --- | --- |
| `OK` | The integration matches the documented contract. |
| `MISMATCH` | A URL, name, type, value, parameter, or behavior conflicts with the documented contract, or the package claims a documented capability that it does not implement. |
| `DEPRECATED` | A URL, name, type, value, parameter, or behavior used by the integration are explicitly marked as deprecated or outdated in the documentation. |
| `MISSING` | A documented capability within the package's scope is not implemented, and the package does not claim to support it. This is informational only. |

For each non-`OK` finding, record the code location, the documentation URL, and the discrepancy. Suggest a replacement only if the documentation names one. Do not invent expected behavior.

> ### Known exclusions
>
> [`known-exclusions.md`](./known-exclusions.md) lists deviations that were reviewed and accepted as intentional. Before reporting any finding:
>
> 1. Match it to an exclusion by the underlying code deviation, not by how the finding is described. For example, a finding about invisible mode on the web that is caused by the web script URL falls under the script-loading exclusion.
> 2. If it matches, drop it, unless the exclusion's **Re-evaluate if** condition is literally met. Prove this with a quoted documentation sentence or a cited code or `README.md` location. A related or broader statement is not enough.
> 3. If you report an excluded deviation, name the exclusion, give the proof, and explain why the rationale no longer holds.

## 4. Decide the verdict

Choose exactly one verdict:

- `ALIGNED` – The documentation was reviewed, and no `MISMATCH` or `DEPRECATED` finding exists. `MISSING` items do not count.
- `MISALIGNED` – At least one confirmed `MISMATCH` or `DEPRECATED` finding exists, even if some documentation was unavailable.
- `INCONCLUSIVE` – No `MISMATCH` or `DEPRECATED` finding exists, but unavailable or unreadable documentation prevents auditing a material part of the integration.

## 5. Report

Follow [`report-template.md`](./report-template.md) for every completed audit. Its structure and format are mandatory.

- Replace every `{{...}}` placeholder with the actual value.
- List every `MISMATCH`, `DEPRECATED`, and `MISSING` finding (omit `OK`). If there are none, write `None` instead of the table.
- Under Sources, list every documentation page you relied on, including pages you could not access and the resulting limitation.
