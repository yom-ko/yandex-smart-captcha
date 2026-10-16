<!-- markdownlint-disable MD033 MD029 -->

# Yandex SmartCaptcha for Flutter

[![Pub Version](https://img.shields.io/pub/v/yandex_smart_captcha.svg?color=f67029)](https://pub.dev/packages/yandex_smart_captcha) [![Pub Points](https://img.shields.io/pub/points/yandex_smart_captcha.svg?color=44cc11)](https://pub.dev/packages/yandex_smart_captcha/score) [![Codecov](https://img.shields.io/codecov/c/github/yom-ko/yandex-smart-captcha?color=44cc11&logo=codecov)](https://codecov.io/github/yom-ko/yandex-smart-captcha) [![Dart Package Docs](https://img.shields.io/badge/documentation-latest-blue.svg)](https://pub.dev/documentation/yandex_smart_captcha/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT) ![Static Badge](https://img.shields.io/badge/NO_SLOP-foundation-555?labelColor=935513) ![Static Badge](https://img.shields.io/badge/HUMAN-reviewed-555?labelColor=f9d9b3)

This package makes it easy to integrate Yandex SmartCaptcha into Flutter-based Android, iOS, and web apps. On Android and iOS, it uses a native in-app WebView. On the web, it uses a DOM element and JavaScript interop. To learn more about the Yandex SmartCaptcha service, visit its [official page](https://yandex.cloud/en/services/smartcaptcha).

## Motivation

One day at work, I urgently needed to integrate Yandex SmartCaptcha into a mobile app, and the `flutter_yandex_smartcaptcha` package came to the rescue. However, I discovered a serious bug and reported it to the author. When they didn’t respond, I decided to create a similar package myself and learn how to publish packages on pub.dev in the process. End of story.

## Usage

Super simple! Here’s the minimal example:

```dart
YandexSmartCaptcha(
  config: CaptchaConfig(
    clientKey: 'your-client-key',
  ),
  onChallengeSolved: (token) {
    // Handle the solved captcha token.
  },
)
```

In most cases, you only need the `YandexSmartCaptcha` and `CaptchaConfig` classes. `CaptchaController` is optional and useful when you need to trigger validation, reset the widget, or destroy it programmatically.

* On mobile, the `YandexSmartCaptcha`'s parent widget should provide enough vertical space to accommodate both the "I'm not a robot" block and the challenge popup, as they are rendered within a single WebView.
* On the web, the parent widget only needs to provide enough vertical space for the "I'm not a robot" block (with a height of around 118px), because Yandex fully controls the challenge popup.

### Web support

> **Note:** The `YandexSmartCaptcha` widget automatically injects the Yandex SmartCaptcha script when mounted, so you don't need to add it to your `index.html`.

On the web, `YandexSmartCaptcha` provides a host element for the Yandex SmartCaptcha HTML widget (the "I'm not a robot" block). Use standard layout widgets such as `Center`, `Padding`, or `SizedBox` to control its position. Yandex fully controls the challenge popup's UI and behavior – just as it does on a regular website.

> **Note:** The height of `YandexSmartCaptcha` is determined by the SmartCaptcha script and cannot be set directly. The calculated height is usually appropriate, but you can adjust the displayed size using `Transform.scale` if needed.

Certain `CaptchaConfig` and `YandexSmartCaptcha` parameters (marked with * in the tables below) have no effect on the web, but the `onChallengeShown`/`onChallengeHidden` callbacks and `CaptchaController` methods remain available.

The web implementation is compatible with [WebAssembly (Wasm)](https://webassembly.org/).

### CaptchaConfig parameters

This is an immutable configuration for Yandex SmartCaptcha and WebView content.

> Ignored on web: `useWebViewMode`, `initialScale`, `allowUserScaling`, `maximumScale`.

| Parameter             | Required | Default       | Description                                                                               |
| :-------------------- | :------: | :------------ | :---------------------------------------------------------------------------------------- |
| `clientKey`           |    ✔     |               | The client-side key passed to SmartCaptcha.                                               |
| `language`            |          | `ru`          | The language used by the SmartCaptcha's UI.                                               |
| `alwaysShowChallenge` |          | `false`       | Whether SmartCaptcha should always display a challenge (normally used for testing).       |
| `useInvisibleMode`    |          | `false`       | Whether SmartCaptcha should run in invisible mode – without the "I'm not a robot" block.  |
| `badgePosition`       |          | `bottomRight` | The position of the Data Processing Notice (DPN) badge when `useInvisibleMode` is `true`. |
| `hideBadge`           |          | `false`       | Whether to hide the DPN badge when `useInvisibleMode` is `true`.                          |
| `useWebViewMode`*     |          | `true`        | Whether to enable a special mobile WebView optimization mode.                             |
| `initialScale`*       |          | `1.0`         | The initial scale factor for the WebView content.                                         |
| `allowUserScaling`*   |          | `false`       | Whether the user can scale the WebView content with gestures.                             |
| `maximumScale`*       |          | `3.0`         | The maximum scale factor when `allowUserScaling` is `true`.                               |

### YandexSmartCaptcha parameters

Control SmartCaptcha's runtime lifecycle, Flutter-level UI customization, and callback registration.

> Ignored on web: `backgroundColor`, `loadingIndicator`, `onNavigationRequest`, `baseUrl`.

| Parameter              | Required | Default | Description                                                                               |
| :--------------------- | :------: | :------ | :---------------------------------------------------------------------------------------- |
| `config`               |    ✔     |         | The configuration for this SmartCaptcha instance.                                         |
| `onChallengeSolved`    |    ✔     |         | Called when the user successfully solves a challenge.                                     |
| `backgroundColor`*     |          | `null`  | The background color of the SmartCaptcha container.                                       |
| `loadingIndicator`*    |          | `null`  | A custom widget displayed while the SmartCaptcha script is loading.                       |
| `onCaptchaReady`       |          | `null`  | Called when the SmartCaptcha script is fully loaded and initialized.                      |
| `onChallengeShown`     |          | `null`  | Called when the challenge popup becomes visible.                                          |
| `onChallengeHidden`    |          | `null`  | Called when the challenge popup is hidden or dismissed.                                   |
| `onTokenExpired`       |          | `null`  | Called when the validation token expires after the challenge is successfully solved.      |
| `onNetworkError`       |          | `null`  | Called when a network error occurs while loading or executing the SmartCaptcha script.    |
| `onJavaScriptError`    |          | `null`  | Called when a JavaScript error occurs while loading or executing the SmartCaptcha script. |
| `onNavigationRequest`* |          | `null`  | Called when a main-frame navigation request is made inside the WebView.                   |
| `controller`           |          | `null`  | A controller for programmatically interacting with the SmartCaptcha instance.             |
| `baseUrl`*             |          | `null`  | An HTTP(S) base URL used for domain validation and resolving origin policy issues.        |

### CaptchaController methods

Provide access to the SmartCaptcha HTML widget's imperative methods.

| Method      | Description                                                                        |
| :---------- | :--------------------------------------------------------------------------------- |
| `execute()` | Starts user validation by showing a challenge popup. Only works in invisible mode. |
| `reset()`   | Resets the SmartCaptcha to its initial state. Only works for a solved challenge.   |
| `destroy()` | Removes the SmartCaptcha widget and its associated event listeners.                |

These methods are exposed on native and web platforms. Call them after `onCaptchaReady` has fired.

## Screenshots

1. SmartCaptcha on a test screen (Android):

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_1.webp"
    alt="The initial state of the Yandex SmartCaptcha container with the 'I'm not a robot' block."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_2.webp"
    alt="The initial state of the Yandex SmartCaptcha pop-up, featuring a challenge for the user to solve."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_3.webp"
    alt="The state of the Yandex SmartCaptcha container with the 'I'm not a robot' box checked, after the user successfully solved the challenge."
    width="250">
</div><br/>

2. SmartCaptcha in a real-world application (Android):

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_laz_1.webp"
    alt="The initial state of the Yandex SmartCaptcha container with the 'I'm not a robot' block, as seen in a real-world application."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_laz_2.webp"
    alt="The initial state of the Yandex SmartCaptcha pop-up, featuring a challenge for the user to solve in a real-world application."
    width="250">
</div><br/>

3. SmartCaptcha on a test screen (Chrome):

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_web.webp"
    alt="The initial state of the Yandex SmartCaptcha pop-up, featuring a challenge for the user to solve. Chrome browser."
    width="250">
</div>
