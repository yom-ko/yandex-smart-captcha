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

Read these pages:

- [Integration methods](https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods)
- [Invisible CAPTCHA mode](https://yandex.cloud/en/docs/smartcaptcha/concepts/invisible-captcha)

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

Review these files. Trace referenced code only as far as needed to understand the integration:

- `lib/src/captcha_config.dart` – options passed to `render`.
- `lib/src/captcha_event.dart` – shared event vocabulary and the events passed to `subscribe`.
- `lib/src/captcha_language.dart` and `lib/src/dpn_badge_position.dart` – values passed as `hl` and `shieldPosition`.
- `lib/src/native/captcha_adapter.dart` – WebView HTML/JavaScript: script loading, `render`, `subscribe`, and widget method calls.
- `lib/src/native/captcha_adapter_controller.dart` – event forwarding and widget method calls.
- `lib/src/web/captcha_script_loader_web.dart` – web script loading.
- `lib/src/web/captcha_adapter_web.dart` – JavaScript interop declarations for `window.smartCaptcha` and `render` options.
- `lib/src/web/captcha_adapter_controller_web.dart` – web calls to `render`, `subscribe`, `execute`, `reset`, and `destroy`.

To determine which capabilities the package claims to support, read `README.md`, the public exports in `lib/yandex_smart_captcha.dart`, and the Dartdoc in `lib/src/yandex_smart_captcha.dart`. Focus on the client-side widget; do not treat server-side capabilities as missing.

## 3. Compare and classify findings

Compare the integration with the recorded contract. Check that:

- Script URLs and query parameters match the documentation.
- Event names and callback signatures match the documentation.
- Method names, arguments, and return types match the documentation.
- `render` parameter names, values, and types match the documentation. For example, booleans must not be passed as strings.
- Documented prerequisites are met by the package or, if the consuming app is responsible, explained in the package docs. This includes the data processing notice when the badge is hidden.
- Native and web adapters provide the claimed behavior, accounting for documented platform differences. A documented difference does not by itself establish compliance with Yandex's contract.

For Dart/JavaScript interop use [Dart's interop documentation](https://dart.dev/interop/js-interop) and [Flutter's WebAssembly guidance](https://docs.flutter.dev/platform-integration/web/wasm#js-interop-wasm) to interpret the bridge. Also:

- Compare JavaScript values, not just Dart type names.
- Ignoring an unused return value or event payload is not itself a mismatch.
- An explicit, accurately documented package default may differ from the JavaScript default.
- If the documentation names a value without defining its JavaScript type, such as `WidgetId`, treat it as opaque. It is `OK` if the bridge stores it untyped (for example, as `JSAny`) and passes it back unchanged. A narrower declared type, such as `JSNumber`, is an undocumented assumption; record it as a limitation.

Assign each verifiable item one status:

| Status | Meaning |
| --- | --- |
| `OK` | The integration matches the documented contract. |
| `MISMATCH` | A URL, name, type, value, parameter, or behavior conflicts with the documented contract, or the package claims a documented capability that it does not implement. |
| `DEPRECATED` | A URL, name, type, value, parameter, or behavior used by the integration is explicitly marked as deprecated or outdated in the documentation. |
| `MISSING` | A documented widget capability within the package's scope is neither implemented nor claimed. Informational only; alternative implementations of a supported capability do not count. |

Do not classify an undocumented detail as `OK` or `MISMATCH`; record the limitation instead.

For each non-`OK` finding:

- Cite the code location and documentation URL, and explain the discrepancy.
- For a missing capability, cite the relevant public API or state `Not implemented` instead of a code location.
- Suggest a replacement only if the documentation names one.

> ### Known exclusions
>
> [`known-exclusions.md`](./known-exclusions.md) lists deviations that were reviewed and accepted as intentional. Before reporting any finding:
>
> 1. Check for an exclusion matching the underlying code deviation, not the wording. Use the relevant code location.
> 2. If none matches, report the finding normally. Otherwise, check the **Re-evaluate if** condition.
> 3. If the condition cannot be checked, record the limitation. Do not assume it is unmet.
> 4. If it is not met, omit the finding and name the exclusion in the Summary.
> 5. If it is met, report the finding. Name the exclusion, prove the condition with a quoted documentation sentence or cited code or `README.md` location, and explain why its rationale is no longer sufficient. Related or broader statements are not enough.
>
> Applied exclusions are accepted deviations, not evidence that the excluded behavior matches the contract.

## 4. Decide the verdict

Choose exactly one verdict:

- `ALIGNED` – No non-excluded `MISMATCH` or `DEPRECATED` finding exists. `MISSING` findings do not count.
- `MISALIGNED` – At least one non-excluded `MISMATCH` or `DEPRECATED` finding exists, even if some evidence is unavailable.
- `INCONCLUSIVE` – No non-excluded `MISMATCH` or `DEPRECATED` finding exists, but evidence is insufficient to check a material non-excluded item or applicable material exclusion condition.

## 5. Report

Follow [`report-template.md`](./report-template.md) for every completed audit. Its structure and formatting are mandatory.

- Replace every `{{...}}` placeholder with the actual value. Use backticks for method, event, and parameter names.
- List every non-excluded `MISMATCH`, `DEPRECATED`, and `MISSING` finding (omit `OK`). If there are none, write `None` instead of the table.
- Under Sources, list every documentation page used or attempted. Note any page that was inaccessible or omitted a material detail, and the resulting limitation.
