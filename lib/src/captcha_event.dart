import 'yandex_smart_captcha.dart' show YandexSmartCaptcha;

/// Lifecycle events emitted by [YandexSmartCaptcha].
enum CaptchaEvent {
  /// Emitted when the CAPTCHA is fully loaded and initialized.
  captchaReady('captcha-ready', subscribable: false),

  /// Emitted when the CAPTCHA challenge popup becomes visible.
  challengeShown('challenge-visible'),

  /// Emitted when the CAPTCHA challenge popup is hidden or dismissed.
  challengeHidden('challenge-hidden'),

  /// Emitted when a network error occurs while loading or executing the CAPTCHA.
  networkError('network-error'),

  /// Emitted when an uncaught JavaScript error occurs inside the CAPTCHA WebView.
  javaScriptError('javascript-error'),

  /// Emitted when the CAPTCHA token expires or is invalidated.
  tokenExpired('token-expired'),

  /// Emitted when the user successfully solves a CAPTCHA challenge.
  ///
  /// Note: Although Yandex SmartCaptcha docs list the `success` event as subscribable,
  /// it is not dispatched reliably, so it is handled manually via the `callback` function.
  challengeSolved('success', subscribable: false);

  const CaptchaEvent(this.id, {this.subscribable = true});

  /// The event identifier passed to SmartCaptcha's native `subscribe` method.
  ///
  /// If [subscribable] is `false`, this value is not registered with the JS bridge.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe
  final String id;

  /// Whether this event is registered via SmartCaptcha's native `subscribe` method.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe
  final bool subscribable;
}
