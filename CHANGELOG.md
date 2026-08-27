<!-- markdownlint-disable MD041 MD022 MD032 -->
## 5.0.1
- Refactor: Improve code organization for better maintainability.

## 5.0.0
- **BREAKING CHANGE**: API overhaul: rename several `CaptchaConfig` options for better declarativeness and consistency:
  - `invisibleMode` → `useInvisibleMode`
  - `dpnBadgePosition` → `badgePosition`
  - `hideDPNBadge` → `hideBadge`
  - `initialContentScale` → `initialScale`
  - `userScalableContent` → `allowUserScaling`
  - `maximumContentScale` → `maximumScale`
  - `webViewMode` → `useWebViewMode`
- Refactor and optimize core package logic.
- Reduce package download size to ~40 KB by excluding unnecessary assets and example binaries.

## 4.0.0
- **BREAKING CHANGE**: Bump minimum Dart SDK constraint to `>=3.5.0` and Flutter to `>=3.24.0`.
- Clean and improve Example

## 3.1.9
- Update repository URLs

## 3.1.8
- Chore

## 3.1.7
- Chore

## 3.1.6
- Chore

## 3.1.5
- Improve README

## 3.1.4
- Improve README

## 3.1.3
- Improve README
- Improve Doc comments

## 3.1.2
- Improve README

## 3.1.1
- Improve Doc comments

## 3.1.0
- Add options to control the HTML viewport scaling behavior: `initialContentScale`, `userScalableContent`, and `maximumContentScale`.

## 3.0.2
- Improve README

## 3.0.1
- Improve README

## 3.0.0
- BREAKING CHANGE: Major API overhaul: Rename most configuration options to make them more sensible, declarative, and consistent. Since the migration is straightforward, the old names were removed without a deprecation period.
- BREAKING CHANGE: Make the token parameter in the `onChallengeSolved` (formerly `onTokenReceived`) callback nullable.
- Improve Doc comments

## 2.0.26
- Add disposal of the loading state's ValueNotifier in the `YandexSmartCaptcha` widget.
- Improve Example

## 2.0.25
- Minor fixes/improvements

## 2.0.24
- Add tests to the Example app

## 2.0.22
- BREAKING CHANGE: Rename the `siteKey` configuration option to `clientKey` to avoid confusion. Since the migration is straightforward, the old name has been removed without a deprecation period.
- Improve Example

## 1.0.19
- Remove the `async` attribute from the SmartCaptcha `script` tag.
- Improve Doc comments
- Improve Example

## 1.0.18
- Improve Doc comments
- Minor fixes/improvements

## 1.0.17
- Rename the package repository to `yandex_smart_captcha` to avoid confusion.

## 1.0.16
- Fix spelling in README

## 1.0.15
- Fix code formatting one more time (sorry)

## 1.0.14
- Compress screenshots

## 1.0.13
- Fix code formatting

## 1.0.12
- Try to fix pub.dev analysis

## 1.0.11
- Improve README

## 1.0.10
- Improve README

## 1.0.9
- Improve Doc comments
- Minor fixes/improvements

## 1.0.8
- Update Example for iOS
- Improve package metadata

## 1.0.7
- Fix screenshots for README

## 1.0.6
- Add screenshots for README

## 1.0.5
- Remove disposal of `_inAppWebViewController` in the `YandexSmartCaptcha` widget.

## 1.0.4
- Cleanup CHANGELOG

## 1.0.3
- Add disposal of `_inAppWebViewController` in the `YandexSmartCaptcha` widget.
- Improve Example

## 1.0.2
- Fixes to improve pub points

## 1.0.1
- Chore

## 1.0.0
- Initial version
