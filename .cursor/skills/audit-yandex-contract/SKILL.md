---
name: audit-yandex-contract
description: >-
  Audit this Flutter package's integration with the Yandex SmartCaptcha JavaScript API contract against official Yandex Cloud documentation. Use only when the user explicitly asks to run this `audit-yandex-contract` skill or another skill explicitly invokes it.
---

# Auditing the Yandex SmartCaptcha contract

## Main rules

- Assess and report only. Do not modify any files unless the user explicitly asks.
- Do not run tests or execute code. This is a static audit against the documented API contract.
- Treat the official Yandex Cloud documentation as the sole source of truth for SmartCaptcha API behavior and deprecations.
- If relevant documentation is unavailable, unreadable, or silent about a material detail, record its URL and the limitation. Do not guess.

## 1. Read the contract

Read these pages, preferring the Markdown versions for a shorter fetch. If a Markdown version is unavailable, use its HTML page instead:

- Integration methods: [Markdown](https://docs.yandex.cloud/int/en/smartcaptcha/concepts/widget-methods.md) | [HTML](https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods)
- Invisible CAPTCHA mode: [Markdown](https://docs.yandex.cloud/int/en/smartcaptcha/concepts/invisible-captcha.md) | [HTML](https://yandex.cloud/en/docs/smartcaptcha/concepts/invisible-captcha)

Follow other links from the [documentation root](https://yandex.cloud/en/docs/smartcaptcha/) only to verify a specific item.

> If a page has moved, follow the official redirects or links and treat the current page as the source of truth.

Record the documented:

- Script URL and query parameters of each integration method.
- Widget methods, with their parameters, types, return types, and prerequisites, where specified.
- `render` parameters, with their types, defaults, and allowed values, where specified.
- Event names, meanings, and callback signatures, and how to unsubscribe.
- Explicit deprecation notices and their replacements.

Do not infer undocumented types, defaults, or behavior. Do not treat an item as deprecated merely because a page does not mention it.

## 2. Inspect the integration

First determine which client-side capabilities the package claims to support. Read `README.md`, the public exports in `lib/yandex_smart_captcha.dart`, and the Dartdoc in `lib/src/yandex_smart_captcha.dart`. Use these claims to establish the audit scope; do not treat server-side capabilities as missing.

Then review these files. Trace referenced code only as far as needed to understand the integration:

- `lib/src/captcha_config.dart` – options passed to `render`.
- `lib/src/captcha_event.dart` – shared event vocabulary and the events passed to `subscribe`.
- `lib/src/captcha_language.dart` and `lib/src/dpn_badge_position.dart` – values passed as `hl` and `shieldPosition`.
- `lib/src/native/captcha_adapter.dart` – WebView HTML/JavaScript: script loading, `render`, `subscribe`, and widget method calls.
- `lib/src/native/captcha_adapter_controller.dart` – event forwarding and widget method calls.
- `lib/src/web/captcha_script_loader_web.dart` – web script loading.
- `lib/src/web/captcha_adapter_web.dart` – JavaScript interop declarations for `window.smartCaptcha` and `render` options.
- `lib/src/web/captcha_adapter_controller_web.dart` – web calls to `render`, `subscribe`, `execute`, `reset`, and `destroy`.

## 3. Compare and classify findings

Compare the integration with the recorded contract on both native and web. Use this checklist as a starting point, not an exhaustive contract; add any newly documented or implemented items:

- Script URL, query parameters, and loading prerequisites.
- `render`: container and return value; `sitekey`, `callback`, `hl`, `test`, `webview`, `invisible`, `shieldPosition`, and `hideShield`.
- `getResponse`, `execute`, `reset`, `destroy`, and `subscribe`, including unsubscription.
- `challenge-visible`, `challenge-hidden`, `network-error`, `javascript-error`, `success`, and `token-expired`.
- Invisible mode and the data processing notice when the badge is hidden.

Check that:

- Script URLs and query parameters match the documentation.
- Event names and callback signatures match the documentation.
- Method names, arguments, and return types match the documentation.
- `render` parameter names, values, and types match the documentation. For example, booleans must not be passed as strings.
- Documented prerequisites are met by the package or, if the consuming app is responsible, explained in the package docs. Public API Dartdoc and the README count as package documentation. This includes the data processing notice when the badge is hidden.
- Native and web adapters provide the claimed behavior, accounting for documented platform differences. A documented difference does not by itself establish compliance with Yandex's contract.

For Dart/JavaScript interop use [Dart's JS types documentation](https://dart.dev/interop/js-interop/js-types) to interpret the bridge. Consult [Flutter's WebAssembly guidance](https://docs.flutter.dev/platform-integration/web/wasm#js-interop-wasm) if needed for a specific compatibility question. Also:

- Compare JavaScript values, not just Dart type names.
- Ignoring an unused return value or event payload is not itself a mismatch.
- An explicit, accurately documented package default may differ from the JavaScript default.
- If the documentation names a value without defining its JavaScript type, such as `WidgetId`, treat it as opaque. It is `OK` if the bridge stores it untyped (for example, as `JSAny`) and passes it back unchanged. A narrower declared type, such as `JSNumber`, is an undocumented assumption; record it as a limitation and check for a matching exclusion.

### Check known exclusions

Before classifying a potential finding or limitation, check [`known-exclusions.md`](./known-exclusions.md) for a deviation matching the underlying code behavior, not merely the wording:

1. If no exclusion matches, do not apply an exclusion; continue classifying the item normally.
2. If an exclusion matches, check its **Re-evaluate if** condition.
3. If the condition cannot be checked, record the limitation; do not assume it is unmet. When a condition requires a specific documented statement, it is not met if the relevant accessible documentation was checked and does not contain that statement. Silence alone does not establish a type, behavior, deprecation, or removal.
4. If the condition is not met, omit the finding and name the exclusion in the Summary. Record any underlying undocumented assumption as a limitation in Sources; it does not make the verdict inconclusive.
5. If the condition is met, report the finding. Name the exclusion, prove the condition with a quoted documentation sentence or cited code or `README.md` location, and explain why its rationale is no longer sufficient. Related or broader statements are not enough.

Applied exclusions are accepted deviations, not evidence that the excluded behavior matches the contract.

### Assign a status

Assign each remaining verifiable item one status:

| Status | Meaning |
| --- | --- |
| `OK` | The integration matches the documented contract. |
| `MISMATCH` | A URL, name, type, value, parameter, or behavior conflicts with the documented contract, or the package claims a documented capability that it does not implement. |
| `DEPRECATED` | A URL, name, type, value, parameter, or behavior used by the integration is explicitly marked as deprecated or outdated in the documentation. |
| `MISSING` | A documented widget capability within the package's scope is neither implemented nor claimed. Informational only; alternative implementations of a supported capability do not count. |

Do not classify an undocumented detail as `OK` or `MISMATCH`; record the limitation instead.

For each non-`OK` finding that remains after checking exclusions:

- Cite the code location and documentation URL, and explain the discrepancy.
- For a missing capability, cite the relevant public API or state `Not implemented` instead of a code location.
- Suggest a replacement only if the documentation names one.

## 4. Decide the verdict

Choose exactly one verdict:

- `ALIGNED` – No non-excluded `MISMATCH` or `DEPRECATED` finding exists. `MISSING` findings do not count.
- `MISALIGNED` – At least one non-excluded `MISMATCH` or `DEPRECATED` finding exists, even if some evidence is unavailable.
- `INCONCLUSIVE` – No non-excluded `MISMATCH` or `DEPRECATED` finding exists, but evidence is insufficient to check a material non-excluded item or applicable material exclusion condition.

A limitation is material when resolving it could establish a non-excluded `MISMATCH` or `DEPRECATED` finding, or change whether an applicable exclusion applies. An undocumented assumption covered by an exclusion whose re-evaluation condition is checked and not met is not material to the verdict.

## 5. Report

Follow [`report-template.md`](./report-template.md) for every completed audit. Its structure and formatting are mandatory.

- Replace every `{{...}}` placeholder with the actual value. Use backticks for method, event, and parameter names.
- List every non-excluded `MISMATCH`, `DEPRECATED`, and `MISSING` finding (omit `OK`). If there are none, write `None` instead of the table.
- Under Sources, list every documentation page used or attempted. Note any page that was inaccessible or omitted a material detail, and the resulting limitation.
