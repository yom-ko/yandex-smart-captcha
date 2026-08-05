# Yandex SmartCaptcha for Flutter

[![Pub Version](https://img.shields.io/pub/v/yandex_smart_captcha.svg?color=e97436)](https://pub.dev/packages/yandex_smart_captcha) [![Pub Points](https://img.shields.io/pub/points/yandex_smart_captcha.svg?color=53ab36)](https://pub.dev/packages/yandex_smart_captcha/score) [![Dart Package Docs](https://img.shields.io/badge/documentation-latest-blue.svg)](https://pub.dev/documentation/yandex_smart_captcha/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

This package makes it easy to integrate Yandex SmartCaptcha into Flutter mobile apps. To learn more about the Yandex SmartCaptcha service, visit its [official page](https://yandex.cloud/en/services/smartcaptcha).

This package was inspired by [flutter_yandex_smartcaptcha](https://pub.dev/packages/flutter_yandex_smartcaptcha), but it offers several improvements, including bug fixes, slightly better performance, enhanced documentation, and a much [cleaner API](https://pub.dev/documentation/yandex_smart_captcha/latest/yandex_smart_captcha).

## Motivation

One day at work, I urgently needed to integrate a Yandex CAPTCHA into a mobile app, and the `flutter_yandex_smartcaptcha` package came to the rescue. However, I discovered a serious bug and reported it to the author. When they didn’t respond, I decided to create a similar package myself and learn how to publish packages on pub.dev in the process. The end of the magnificent story.

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

#### Configuration parameters

| Parameter | Required | Default | Description |
| :---------- | :-----------: | :------------ | :------------ |
| `clientKey` | ✔ | | The client-side key passed to the Web SmartCaptcha. |
| `alwaysShowChallenge` | | `false` | If `true`, the user will always see a challenge. |
| `language` | | `ru` | The language for the Web SmartCaptcha UI. |
| `invisibleMode` | | `false` | If `true`, the CAPTCHA runs in invisible mode – without the "I’m not a robot" checkbox. |
| `hideDPNBadge` | | `false` | If `true` and `invisibleMode` is enabled, the badge linking to the Data Processing Notice (DPN) will be hidden. |
| `dpnBadgePosition` | | `bottomRight` | If `invisibleMode` is enabled, this option specifies the position of the DPN badge. |
| `webViewMode` | | `true` | If `true`, the CAPTCHA runs in a special WebView mode, improving challenge accuracy on mobile devices. |
| `initialContentScale` | | `1.0` | The initial scale factor for the Web SmartCaptcha content. |
| `userScalableContent` | | `false` | If `true`, the user can zoom in and out of the Web SmartCaptcha content. |
| `maximumContentScale` | | `3.0` | If `userScalableContent` is enabled, this defines the maximum scale factor for the content. |
| `backgroundColor` | | `null` | The background color of the `YandexSmartCaptcha` widget. |

> ✱ "Web SmartCaptcha" refers to the underlying HTML document, hosted in a WebView, that runs the Yandex SmartCaptcha JavaScript code.

## Screenshots

1. SmartCaptcha in a simple test screen:

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_1.webp"
    alt="The initial state of the Yandex SmartCaptcha container with the 'I’m not a robot' checkbox."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_2.webp"
    alt="The initial state of the Yandex SmartCaptcha pop-up, featuring a challenge for the user to solve."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_3.webp"
    alt="The state of the Yandex SmartCaptcha container with the 'I’m not a robot' box checked, after the user successfully solved the challenge."
    width="250">
</div><br/>

2. SmartCaptcha in a real-world application:

<div>
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_laz_1.webp"
    alt="The initial state of the Yandex SmartCaptcha container with the 'I’m not a robot' checkbox, as seen in a real-world application."
    width="250">
  <img
    src="https://raw.githubusercontent.com/yom-ko/yandex-smart-captcha/refs/heads/main/assets/images/screen_laz_2.webp"
    alt="The initial state of the Yandex SmartCaptcha pop-up, featuring a challenge for the user to solve in a real-world application."
    width="250">
</div>
