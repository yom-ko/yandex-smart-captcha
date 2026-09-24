<!-- markdownlint-disable MD033 MD029 -->

# Yandex SmartCaptcha for Flutter

[![Pub Version](https://img.shields.io/pub/v/yandex_smart_captcha.svg?color=e97436)](https://pub.dev/packages/yandex_smart_captcha) [![Pub Points](https://img.shields.io/pub/points/yandex_smart_captcha.svg?color=53ab36)](https://pub.dev/packages/yandex_smart_captcha/score) [![Dart Package Docs](https://img.shields.io/badge/documentation-latest-blue.svg)](https://pub.dev/documentation/yandex_smart_captcha/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

This package makes it easy to integrate Yandex SmartCaptcha into Flutter-based Android, iOS, and Web apps. On Android and iOS it uses a native WebView; on Web it uses a browser DOM element and JavaScript interop. To learn more about the Yandex SmartCaptcha service, visit its [official page](https://yandex.cloud/en/services/smartcaptcha).

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

### Web support

On Web, `YandexSmartCaptcha` is a lightweight host for the regular Yandex SmartCaptcha browser widget. Place it with standard Flutter layout widgets such as `Center`, `Align`, `Padding`, or `SizedBox` to choose where the "I'm not a robot" block appears. Yandex owns the challenge popup content, position, animation, and overlay behavior, just as it does on a non-Flutter website. You can still use `onChallengeShown` and `onChallengeHidden` to react to that provider-owned UI. All `CaptchaController` methods are also available.

### CaptchaConfig parameters

This is an immutable configuration for Web SmartCaptcha.

> The term "Web SmartCaptcha" refers to the underlying HTML page hosted inside the WebView that instantiates and executes the Yandex SmartCaptcha JavaScript widget. It is relevant only for mobile platforms, since on Web the widget runs in the browser directly.
>
> Ignored on Web (*): `useWebViewMode`, `initialScale`, `allowUserScaling`, `maximumScale`.

| Parameter             | Required | Default       | Description                                                                               |
| :-------------------- | :------: | :------------ | :---------------------------------------------------------------------------------------- |
| `clientKey`           |    ✔     |               | The client-side key passed to Web SmartCaptcha.                                           |
| `language`            |          | `ru`          | The language for the Web SmartCaptcha UI.                                                 |
| `alwaysShowChallenge` |          | `false`       | Whether the CAPTCHA should always display a challenge. Useful for testing.                |
| `useInvisibleMode`    |          | `false`       | Whether to run CAPTCHA in invisible mode – without the "I'm not a robot" checkbox.        |
| `badgePosition`       |          | `bottomRight` | The position of the Data Processing Notice (DPN) badge when `useInvisibleMode` is `true`. |
| `hideBadge`           |          | `false`       | Whether to hide the DPN badge when `useInvisibleMode` is `true`.                          |
| `useWebViewMode` *    |          | `true`        | Whether to enable specialized mobile WebView optimization mode.                           |
| `initialScale` *      |          | `1.0`         | The initial scale factor for the Web SmartCaptcha content.                                |
| `allowUserScaling` *  |          | `false`       | Whether the user can scale the Web SmartCaptcha content using gestures.                   |
| `maximumScale` *      |          | `3.0`         | The maximum scale factor when `allowUserScaling` is `true`.                               |

### YandexSmartCaptcha parameters

Control the SmartCaptcha's runtime lifecycle, Flutter-level UI customizations, and callback registration.

> Ignored on Web (*): `backgroundColor`, `loadingIndicator`, `onNavigationRequest`, `baseUrl`.

| Parameter               | Required | Default | Description                                                                            |
| :---------------------- | :------: | :------ | :------------------------------------------------------------------------------------- |
| `config`                |    ✔     |         | The configuration for this CAPTCHA instance.                                           |
| `onChallengeSolved`     |    ✔     |         | Called when the user successfully solves a CAPTCHA challenge.                          |
| `backgroundColor` *     |          | `null`  | The background color of the native widget container. Has no effect on Web.             |
| `loadingIndicator` *    |          | `null`  | A custom loading widget for native platforms. Has no effect on Web.                    |
| `onCaptchaReady`        |          | `null`  | Called when the CAPTCHA script is fully loaded and initialized.                        |
| `onChallengeShown`      |          | `null`  | Called when the CAPTCHA challenge popup becomes visible.                               |
| `onChallengeHidden`     |          | `null`  | Called when the CAPTCHA challenge popup is hidden.                                     |
| `onTokenExpired`        |          | `null`  | Called when the CAPTCHA token expires or is invalidated.                               |
| `onNetworkError`        |          | `null`  | Called when a network error occurs while loading or executing the CAPTCHA.             |
| `onJavaScriptError`     |          | `null`  | Called when an uncaught JavaScript error occurs inside SmartCaptcha.                   |
| `onNavigationRequest` * |          | `null`  | Called when a navigation request is made inside the native WebView.                    |
| `controller`            |          | `null`  | A controller to programmatically interact with the CAPTCHA.                            |
| `baseUrl` *             |          | `null`  | Native-only HTTP(S) base URL for domain validation and resolving origin policy issues. |

### CaptchaController methods

Provide access to the Web SmartCaptcha's imperative methods.

| Method      | Description                                                             |
| :---------- | :---------------------------------------------------------------------- |
| `execute()` | Starts user validation.                                                 |
| `reset()`   | Resets the Web SmartCaptcha widget to its initial state.                |
| `destroy()` | Removes the Web SmartCaptcha widget and its associated event listeners. |

The controller has the same `execute`, `reset`, and `destroy` API on native
and Web platforms. Call these methods after `onCaptchaReady`.

## Testing

Run the package unit and native widget tests with:

```bash
flutter test
```

The browser adapter tests must run on Chrome because they use browser DOM and
JavaScript interop:

```bash
flutter test --platform chrome
```

The tests under `example/` include device integration coverage and are
separate from these package tests.

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
