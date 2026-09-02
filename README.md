<!-- markdownlint-disable MD033 MD029 -->

# Yandex SmartCaptcha for Flutter

[![Pub Version](https://img.shields.io/pub/v/yandex_smart_captcha.svg?color=e97436)](https://pub.dev/packages/yandex_smart_captcha) [![Pub Points](https://img.shields.io/pub/points/yandex_smart_captcha.svg?color=53ab36)](https://pub.dev/packages/yandex_smart_captcha/score) [![Dart Package Docs](https://img.shields.io/badge/documentation-latest-blue.svg)](https://pub.dev/documentation/yandex_smart_captcha/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

This package makes it easy to integrate Yandex SmartCaptcha into Flutter mobile apps. To learn more about the Yandex SmartCaptcha service, visit its [official page](https://yandex.cloud/en/services/smartcaptcha).

This package was inspired by [flutter_yandex_smartcaptcha](https://pub.dev/packages/flutter_yandex_smartcaptcha), but it offers several improvements, including bug fixes, slightly better performance, enhanced documentation, and a much [cleaner API](https://pub.dev/documentation/yandex_smart_captcha/latest/yandex_smart_captcha).

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

In most cases, you’ll only need the `YandexSmartCaptcha` and `CaptchaConfig` classes. The `CaptchaController` is entirely optional – it's useful if you need to trigger a challenge popup programmatically, but that’s rare.

### CaptchaConfig parameters

This is an immutable configuration for Web SmartCaptcha.

> The term "Web SmartCaptcha" refers to the underlying HTML page hosted inside the WebView that instantiates and executes the Yandex SmartCaptcha JavaScript widget.

| Parameter             | Required | Default       | Description                                                                                                        |
| :-------------------- | :------: | :------------ | :----------------------------------------------------------------------------------------------------------------- |
| `clientKey`           |    ✔     |               | The client-side key passed to Web SmartCaptcha.                                                                    |
| `language`            |          | `ru`          | The language for the Web SmartCaptcha UI.                                                                          |
| `alwaysShowChallenge` |          | `false`       | If true, the user will *always* be presented with a challenge. Useful for testing.                                 |
| `useInvisibleMode`    |          | `false`       | If `true`, runs the CAPTCHA in invisible mode – without the "I'm not a robot" checkbox.                            |
| `badgePosition`       |          | `bottomRight` | If `useInvisibleMode` is enabled, specifies the position of the badge linking to the Data Processing Notice (DPN). |
| `hideBadge`           |          | `false`       | If `true` and `useInvisibleMode` is enabled, hides the DPN badge.                                                  |
| `useWebViewMode`      |          | `true`        | If `true`, runs the CAPTCHA in a mobile-optimized WebView mode to improve challenge accuracy.                      |
| `initialScale`        |          | `1.0`         | The initial scale factor for the Web SmartCaptcha content.                                                         |
| `allowUserScaling`    |          | `false`       | If `true`, the user can scale the Web SmartCaptcha content using gestures or controls.                             |
| `maximumScale`        |          | `3.0`         | If `allowUserScaling` is enabled, specifies the maximum scale factor for the content.                              |

### YandexSmartCaptcha parameters

Control the SmartCaptcha's runtime lifecycle, Flutter-level UI customizations, and callback registration.

| Parameter             | Required | Default | Description                                                                 |
| :-------------------- | :------: | :------ | :-------------------------------------------------------------------------- |
| `config`              |    ✔     |         | The configuration settings for this CAPTCHA instance.                       |
| `onChallengeSolved`   |    ✔     |         | Called when the user successfully solves a CAPTCHA challenge.               |
| `backgroundColor`     |          | `null`  | The background color of the widget container.                               |
| `loadingIndicator`    |          | `null`  | A custom widget displayed while the Web SmartCaptcha content is loading.    |
| `onCaptchaReady`      |          | `null`  | Called when the CAPTCHA script is fully loaded and initialized.             |
| `onChallengeShown`    |          | `null`  | Called when the CAPTCHA challenge popup becomes visible.                    |
| `onChallengeHidden`   |          | `null`  | Called when the CAPTCHA challenge popup is hidden.                          |
| `onNetworkError`      |          | `null`  | Called when a network error occurs while loading or executing the CAPTCHA.  |
| `onJavaScriptError`   |          | `null`  | Called when an uncaught JavaScript error occurs inside the CAPTCHA WebView. |
| `onNavigationRequest` |          | `null`  | Called when a navigation request is made inside the WebView.                |
| `controller`          |          | `null`  | A controller to programmatically interact with the CAPTCHA.                 |

### CaptchaController methods

Provide access to the Web SmartCaptcha's imperative methods.

| Method      | Description                                                             |
| :---------- | :---------------------------------------------------------------------- |
| `execute()` | Starts user validation.                                                 |
| `destroy()` | Removes the Web SmartCaptcha widget and its associated event listeners. |

## Screenshots

1. SmartCaptcha in a simple test screen:

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

2. SmartCaptcha in a real-world application:

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_laz_1.webp"
    alt="The initial state of the Yandex SmartCaptcha container with the 'I'm not a robot' checkbox, as seen in a real-world application."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_laz_2.webp"
    alt="The initial state of the Yandex SmartCaptcha pop-up, featuring a challenge for the user to solve in a real-world application."
    width="250">
</div>
