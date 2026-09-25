<!-- markdownlint-disable MD033 MD029 -->

# Yandex SmartCaptcha for Flutter

[![Pub Version](https://img.shields.io/pub/v/yandex_smart_captcha.svg?color=e97436)](https://pub.dev/packages/yandex_smart_captcha) [![Pub Points](https://img.shields.io/pub/points/yandex_smart_captcha.svg?color=53ab36)](https://pub.dev/packages/yandex_smart_captcha/score) [![Dart Package Docs](https://img.shields.io/badge/documentation-latest-blue.svg)](https://pub.dev/documentation/yandex_smart_captcha/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

This package makes it easy to integrate Yandex SmartCaptcha into Flutter-based Android, iOS, and web apps. On Android and iOS it uses a native WebView; on web it uses a DOM element and JavaScript interop. To learn more about the Yandex SmartCaptcha service, visit its [official page](https://yandex.cloud/en/services/smartcaptcha).

## Motivation

One day at work, I urgently needed to integrate a Yandex CAPTCHA into a mobile app, and the `flutter_yandex_smartcaptcha` package came to the rescue. However, I discovered a serious bug and reported it to the author. When they didn’t respond, I decided to create a similar package myself and learn how to publish packages on pub.dev in the process. End of story.

## Usage

Super simple! Here’s the most basic example:

```dart
YandexSmartCaptcha(
  config: CaptchaConfig(
    clientKey: 'your-client-key',
  ),
  onChallengeSolved: (token) {
    // Handle the solved captcha token
  },
)
```

In most cases, you’ll only need the `YandexSmartCaptcha` and `CaptchaConfig` classes. The `CaptchaController` is entirely optional – it is useful if you need to trigger validation, reset the widget, or destroy it programmatically.

* On mobile, ensure that the `YandexSmartCaptcha`'s ancestor widget provides enough vertical space to accommodate both the main "I'm not a robot" block and the challenge popup, as both are rendered inside a single WebView.
* On web, the vertical space only needs to accommodate the "I'm not a robot" block (fixed height of around 100px). The challenge popup is fully controlled by Yandex, so the ancestor widget does not need to reserve additional space.

### Web support

> You don't need to manually add the Yandex SmartCaptcha script to your `index.html`, as the `YandexSmartCaptcha` widget loads it automatically when mounted into the widget tree.

On web, `YandexSmartCaptcha` hosts the Yandex SmartCaptcha JavaScript widget. Use standard layout widgets such as `Center`, `Padding`, or `SizedBox` to control the position of the "I'm not a robot" block. The challenge popup's UI and behavior, however, are controlled by Yandex (just like on a regular website).

The `onChallengeShown`/`onChallengeHidden` callbacks and `CaptchaController` methods remain fully available.

The web implementation is compatible with [WebAssembly (Wasm)](https://docs.flutter.dev/platform-integration/web/wasm).

### CaptchaConfig parameters

This is an immutable configuration for Web SmartCaptcha.

The term "Web SmartCaptcha" refers to the underlying HTML page hosted inside the WebView that instantiates and executes the Yandex SmartCaptcha JavaScript widget on mobile platforms.

> Ignored on web: `useWebViewMode`, `initialScale`, `allowUserScaling`, `maximumScale`.

| Parameter             | Required | Default       | Description                                                                               |
| :-------------------- | :------: | :------------ | :---------------------------------------------------------------------------------------- |
| `clientKey`           |    ✔     |               | The client-side key passed to Web SmartCaptcha.                                           |
| `language`            |          | `ru`          | The language for the Web SmartCaptcha UI.                                                 |
| `alwaysShowChallenge` |          | `false`       | Whether the CAPTCHA should always display a challenge. Useful for testing.                |
| `useInvisibleMode`    |          | `false`       | Whether to run CAPTCHA in invisible mode – without the "I'm not a robot" checkbox.        |
| `badgePosition`       |          | `bottomRight` | The position of the Data Processing Notice (DPN) badge when `useInvisibleMode` is `true`. |
| `hideBadge`           |          | `false`       | Whether to hide the DPN badge when `useInvisibleMode` is `true`.                          |
| `useWebViewMode`*     |          | `true`        | Whether to enable specialized mobile WebView optimization mode.                           |
| `initialScale`*       |          | `1.0`         | The initial scale factor for the WebView content.                                         |
| `allowUserScaling`*   |          | `false`       | Whether the user can scale the WebView content using gestures.                            |
| `maximumScale`*       |          | `3.0`         | The maximum scale factor when `allowUserScaling` is `true`.                               |

### YandexSmartCaptcha parameters

Control the SmartCaptcha's runtime lifecycle, Flutter-level UI customizations, and callback registration.

> Ignored on web: `backgroundColor`, `loadingIndicator`, `onNavigationRequest`, `baseUrl`.

| Parameter              | Required | Default | Description                                                                            |
| :--------------------- | :------: | :------ | :------------------------------------------------------------------------------------- |
| `config`               |    ✔     |         | The configuration for this CAPTCHA instance.                                           |
| `onChallengeSolved`    |    ✔     |         | Called when the user successfully solves a CAPTCHA challenge.                          |
| `backgroundColor`*     |          | `null`  | The background color of the widget container.                                          |
| `loadingIndicator`*    |          | `null`  | A custom loading widget for platforms.                                                 |
| `onCaptchaReady`       |          | `null`  | Called when the CAPTCHA script is fully loaded and initialized.                        |
| `onChallengeShown`     |          | `null`  | Called when the CAPTCHA challenge popup becomes visible.                               |
| `onChallengeHidden`    |          | `null`  | Called when the CAPTCHA challenge popup is hidden.                                     |
| `onTokenExpired`       |          | `null`  | Called when the CAPTCHA token expires or is invalidated.                               |
| `onNetworkError`       |          | `null`  | Called when a network error occurs while loading or executing the CAPTCHA.             |
| `onJavaScriptError`    |          | `null`  | Called when an uncaught JavaScript error occurs inside SmartCaptcha.                   |
| `onNavigationRequest`* |          | `null`  | Called when a navigation request is made inside the native WebView.                    |
| `controller`           |          | `null`  | A controller to programmatically interact with the CAPTCHA.                            |
| `baseUrl`*             |          | `null`  | Native-only HTTP(S) base URL for domain validation and resolving origin policy issues. |

### CaptchaController methods

Provide access to SmartCaptcha's imperative methods.

| Method      | Description                                                         |
| :---------- | :------------------------------------------------------------------ |
| `execute()` | Starts user validation.                                             |
| `reset()`   | Resets the SmartCaptcha widget to its initial state.                |
| `destroy()` | Removes the SmartCaptcha widget and its associated event listeners. |

The controller has the same API on native and web platforms. Call these methods after `onCaptchaReady`.

## Screenshots

1. SmartCaptcha on a test screen (Android):

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_1.webp"
    alt="The initial state of the Yandex SmartCaptcha container with the 'I'm not a robot' checkbox."
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
    alt="The initial state of the Yandex SmartCaptcha container with the 'I'm not a robot' checkbox, as seen in a real-world application."
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
