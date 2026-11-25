# Known exclusions

These are accepted deviations, not proof of contract compliance. Apply them as described in [Check known exclusions](./SKILL.md#check-known-exclusions).

Each exclusion covers only the specific behavior described below. Check related implementation errors and misleading claims independently; an exclusion does not suppress them.

## Web script loading (including Invisible CAPTCHA)

- **Excluded:** The web adapter reuses an existing `window.smartCaptcha` or loads `captcha.js` without `render=onload&onload=...` and calls `render` after the script's `load` event. This includes using `invisible: true`.
- **Rationale:** This avoids a global `onload` function and permits script reuse. The container lacks the `smart-captcha` class, so it is not automatically rendered. Yandex's requirement to use the advanced method for Invisible CAPTCHA is already considered; equivalence of this alternative is undocumented.
- **Re-evaluate if:** Yandex explicitly states that, without `render=onload&onload=...`, `window.smartCaptcha` or `render` is unavailable, or a `render` parameter is ignored. Merely requiring the advanced method, showing its URL, or the package claiming web Invisible CAPTCHA support does not meet this condition.

This exclusion concerns the loading sequence only. It does not cover incorrect script URLs, invalid `render` parameters or their values, missing package guidance about hiding the data processing notice, or other failures on web or native.

## Numeric `WidgetId`

- **Excluded:** Web interop declares the `render` return value as `JSNumber` and passes it to widget methods, although Yandex does not specify the JavaScript type of `WidgetId`.
- **Rationale:** The numeric type reflects observed behavior, not a guarantee in Yandex's contract. Record this undocumented assumption as a source limitation.
- **Re-evaluate if:** Yandex explicitly documents that a returned `WidgetId` can be a non-numeric JavaScript value.

## On-demand token

- **Excluded:** The package does not expose `getResponse` for retrieving the current token on demand.
- **Rationale:** The package delivers the token through `onChallengeSolved`; this is not an on-demand retrieval API.
- **Re-evaluate if:** The package claims on-demand token retrieval while still not providing it. A claim that `onChallengeSolved` delivers a token does not meet this condition.

## JavaScript error payload

- **Excluded:** `onJavaScriptError` does not expose the `javascript-error` payload (`filename`, `message`, `col`, and `line`).
- **Rationale:** The callback is a notification and also reports adapter failures that have no SmartCaptcha error payload.
- **Re-evaluate if:** The package claims to expose SmartCaptcha JavaScript error details that it does not provide.

## JavaScript error handling guidance

- **Excluded:** The README and public API Dartdoc omit Yandex's guidance to notify users of a critical `javascript-error` and not mark the challenge completed. This omission alone is not a mismatch, a missing capability, or a material limitation.
- **Rationale:** The package forwards the error notification; application UI and completion decisions belong to the consumer. Yandex's existing warning is already considered, and the omission does not establish compliance with that warning.
- **Re-evaluate if:** Package documentation advises ignoring `javascript-error` or marking the challenge completed despite it, or claims automatic user notification that the package does not provide. Yandex's existing warning alone does not meet this condition.

Check error forwarding and any error treated as successful validation independently; this exclusion covers only the documentation omission.

## Success event

- **Excluded:** The package does not subscribe to the SmartCaptcha `success` event.
- **Rationale:** Both adapters deliver success via the documented `render` `callback` instead. `CaptchaEvent.challengeSolved` records a reliability concern with the subscribed event.
- **Re-evaluate if:** Yandex explicitly deprecates `render`'s `callback` parameter or states that it has been removed or no longer handles successful validation.

Check that both adapters still provide and forward the `callback` independently.

## Unsubscribe function

- **Excluded:** Web interop declares `subscribe` as returning `void` and discards the returned `UnsubscribeFunction`.
- **Rationale:** The package does not unsubscribe individual listeners. Yandex documents that `destroy` removes the widget and its listeners.
- **Re-evaluate if:** The package claims per-listener unsubscription that it cannot perform, or Yandex explicitly states that `destroy` does not remove widget-created listeners.

Check widget destruction and listener cleanup independently; this exclusion does not excuse a broken `destroy` call.
