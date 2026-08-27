import 'dart:ui' show Color;

import 'captcha_language.dart';
import 'dpn_badge_position.dart';

/// The configuration for the `YandexSmartCaptcha` widget.
/// Most options apply to the underlying Web SmartCaptcha hosted in the WebView.
/// For more information, see the `Yandex SmartCaptcha documentation`(https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#methods).
final class CaptchaConfig {
  /// A client-side key passed to the underlying Web SmartCaptcha.
  ///
  /// Corresponding JavaScript parameter – `sitekey`.
  final String clientKey;

  /// The language for the Web SmartCaptcha UI. For languages other than Russian, this setting
  /// also affects the CAPTCHA challenge language (typically switching it to English).
  ///
  /// Supported values: `ru` | `en` | `be` | `kk` | `tt` | `uk` | `uz` | `tr`
  ///
  /// Corresponding JavaScript parameter – `hl`.
  final CaptchaLanguage language;

  /// If `true`, the user will ALWAYS see a challenge. Use this option only for debugging or testing.
  ///
  /// Corresponding JavaScript parameter – `test`.
  final bool alwaysShowChallenge;

  /// If `true`, the CAPTCHA runs in invisible mode – without the 'I’m not a robot' checkbox.
  /// Only users whose requests are deemed suspicious by Yandex SmartCaptcha will see a challenge.
  ///
  /// Corresponding JavaScript parameter – `invisible`.
  final bool useInvisibleMode;

  /// If `useInvisibleMode` is enabled, this option specifies the position of the badge linking to the Data Processing Notice.
  ///
  /// Supported values: `top-left` | `center-left` | `bottom-left` | `top-right` | `center-right` | `bottom-right`
  ///
  /// Corresponding JavaScript parameter – `shieldPosition`.
  final DPNBadgePosition badgePosition;

  /// If `true` and invisible mode is enabled, the badge linking to the Data Processing Notice will be hidden.
  /// WARNING: You still MUST inform users that their data is processed by Yandex SmartCaptcha. If you hide the DPN badge,
  /// ensure there is an alternative method to notify users about data processing.
  ///
  /// Corresponding JavaScript parameter – `hideShield`.
  final bool hideBadge;

  /// The initial scale factor for the Web SmartCaptcha content.
  /// This value is passed to the `initial-scale` attribute of the HTML document's `viewport` meta tag.
  /// The actual behavior may vary depending on the platform and OS version.
  final double initialScale;

  /// If `true`, the user can zoom in and out of the Web SmartCaptcha content.
  /// This value is passed to the `user-scalable` attribute of the HTML document's `viewport` meta tag.
  /// The actual behavior may vary depending on the platform and OS version.
  final bool allowUserScaling;

  /// If `allowUserScaling` is enabled, this option specifies the maximum scale factor for the content.
  /// This value is passed to the `maximum-scale` attribute of the HTML document's `viewport` meta tag.
  /// The actual behavior may vary depending on the platform and OS version.
  final double maximumScale;

  /// The background color of the `YandexSmartCaptcha` widget.
  final Color? backgroundColor;

  /// If `true`, the CAPTCHA runs in a special WebView mode, improving challenge accuracy on mobile devices.
  /// Since this package is designed for mobile apps, this option should typically be set to `true`.
  ///
  /// Corresponding JavaScript parameter – `webview`.
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
