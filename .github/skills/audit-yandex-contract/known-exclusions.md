# Known exclusions

These deviations were reviewed and accepted as intentional. Do not report them as findings unless the documentation changes in a way that invalidates the rationale. In that case, report the finding and mention the outdated exclusion.

| Item | Rationale | Re-evaluate if |
| --- | --- | --- |
| Web adapter loads the plain `captcha.js` URL (no `render=onload&onload=...`) and calls `render` after the script element's `load` event. | The adapter avoids exposing a global `onload` function and reuses an already loaded script. The package container lacks the `smart-captcha` class, so automatic rendering never targets it. | The documentation states that `window.smartCaptcha` or `render` is unavailable without the advanced-method query parameters. |
| Web interop declares `subscribe` as returning `void` instead of `UnsubscribeFunction`. | The package never unsubscribes individually. `destroy` removes the widget's listeners, according to the documentation. | The package needs per-event unsubscription, or `destroy` no longer removes listeners. |
| `onJavaScriptError` exposes no `javascript-error` payload (`filename`, `message`, `col`, `line`). | The callback is a notification by design. The adapters also use it for their own failures, such as exceptions from `render` or widget methods, which have no SmartCaptcha payload. | The package claims to expose error details. |
| `getResponse` is not exposed. | The token is delivered through `onChallengeSolved`. | The package claims to support token retrieval on demand. |
| The `success` event is not passed to `subscribe`. | Success is handled through the `render` `callback` parameter, as documented in `CaptchaEvent.challengeSolved`. | The `callback` render parameter is deprecated or removed. |
