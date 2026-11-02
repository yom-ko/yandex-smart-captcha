# Known exclusions

These deviations were reviewed and accepted as intentional. Apply them as described in [Known exclusions](./SKILL.md#known-exclusions).

| Item | Rationale | Re-evaluate if |
| --- | --- | --- |
| The web adapter loads `captcha.js` without `render=onload&onload=...` and calls `render` after the script's `load` event. This applies to all `render` parameters, including `invisible`. | The adapter avoids a global `onload` function and can reuse an already loaded script. Its container lacks the `smart-captcha` class, so automatic rendering never targets it. As in the advanced method, the widget is configured through `window.smartCaptcha.render`. The statement that Invisible CAPTCHA "is only connected using the advanced method" means that `invisible` requires `render`, because the automatic method's `data-*` attributes cannot set it. | The documentation states that `window.smartCaptcha` or `render` is unavailable, or that a `render` parameter is ignored, without the `render=onload&onload=...` query parameters. |
| The web interop declares `subscribe` as returning `void` instead of `UnsubscribeFunction`. | The package never unsubscribes individual listeners. According to the documentation, `destroy` removes the widget's listeners. | The package needs per-event unsubscription, or `destroy` no longer removes listeners. |
| `onJavaScriptError` does not expose the `javascript-error` payload (`filename`, `message`, `col`, `line`). | The callback is a notification by design. The adapters also invoke it for their own failures, such as exceptions from `render` or widget methods, which have no SmartCaptcha payload. | The package claims to expose error details. |
| `getResponse` is not exposed. | The token is delivered through `onChallengeSolved`. | The package claims to support on-demand token retrieval. |
| The `success` event is not passed to `subscribe`. | It is not dispatched reliably, so success is handled through the `render` `callback` parameter (see `CaptchaEvent.challengeSolved`). | The `callback` render parameter is deprecated or removed. |
