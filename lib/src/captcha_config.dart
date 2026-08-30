import 'dart:ui' show Color;

import 'captcha_language.dart';
import 'dpn_badge_position.dart';
import 'yandex_smart_captcha.dart' show YandexSmartCaptcha;

/// Configuration settings for [YandexSmartCaptcha].
///
/// Most options are passed directly to the underlying Web SmartCaptcha instance.
/// See the [Yandex SmartCaptcha documentation](https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#methods)
/// for details.
final class CaptchaConfig {
  /// The client-side key passed to the underlying Web SmartCaptcha.
  ///
  /// Corresponding JavaScript parameter: `sitekey`.
  final String clientKey;

  /// The language for the Web SmartCaptcha UI.
  ///
  /// For languages other than Russian, this setting also affects the CAPTCHA
  /// challenge language (typically switching it to English).
  ///
  /// Corresponding JavaScript parameter: `hl`.
  final CaptchaLanguage language;

  /// Whether the CAPTCHA should always display a challenge.
  ///
  /// Use this option only for debugging or automated testing.
  ///
  /// Corresponding JavaScript parameter: `test`.
  final bool alwaysShowChallenge;

  /// Whether to run CAPTCHA in invisible mode – without the "I'm not a robot" checkbox.
  ///
  /// When enabled, only users whose requests are flagged as suspicious will be shown a challenge.
  ///
  /// Corresponding JavaScript parameter: `invisible`.
  final bool useInvisibleMode;

  /// The position of the Data Processing Notice badge when [useInvisibleMode] is enabled.
  ///
  /// Corresponding JavaScript parameter: `shieldPosition`.
  final DPNBadgePosition badgePosition;

  /// Whether to hide the Data Processing Notice badge when [useInvisibleMode] is enabled.
  ///
  /// Note: Hiding the badge requires you to inform users about data processing
  /// through an alternative method in your app.
  ///
  /// Corresponding JavaScript parameter: `hideShield`.
  final bool hideBadge;

  /// The initial scale factor for the Web SmartCaptcha HTML content.
  ///
  /// Sets the `initial-scale` attribute of the viewport meta tag.
  /// Actual behavior may vary depending on the underlying platform.
  final double initialScale;

  /// Whether the user can zoom in and out of the CAPTCHA content.
  ///
  /// Sets the `user-scalable` attribute of the viewport meta tag.
  /// Actual behavior may vary depending on the underlying platform.
  final bool allowUserScaling;

  /// The maximum scale factor when [allowUserScaling] is `true`.
  ///
  /// Sets the `maximum-scale` attribute of the viewport meta tag.
  /// Actual behavior may vary depending on the underlying platform.
  final double maximumScale;

  /// The background color of the [YandexSmartCaptcha] widget container.
  final Color? backgroundColor;

  /// Whether to enable specialized mobile WebView optimization mode.
  ///
  /// Improves challenge accuracy and rendering on mobile devices.
  ///
  /// Corresponding JavaScript parameter: `webview`.
  final bool useWebViewMode;

  const CaptchaConfig({
    required this.clientKey,
    this.language = CaptchaLanguage.ru,
    this.alwaysShowChallenge = false,
    this.useInvisibleMode = false,
    this.badgePosition = DPNBadgePosition.bottomRight,
    this.hideBadge = false,
    this.initialScale = 1.0,
    this.allowUserScaling = false,
    this.maximumScale = 3.0,
    this.backgroundColor,
    this.useWebViewMode = true,
  });
}
