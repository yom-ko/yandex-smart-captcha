import 'yandex_smart_captcha.dart' show YandexSmartCaptcha;

/// Lifecycle events emitted by [YandexSmartCaptcha].
enum CaptchaEvent {
  /// Emitted when the SmartCaptcha script has fully loaded and initialized.
  captchaReady('captcha-ready', subscribable: false),

  /// Emitted when the challenge popup becomes visible.
  challengeShown('challenge-visible'),

  /// Emitted when the challenge popup is hidden or dismissed.
  challengeHidden('challenge-hidden'),

  /// Emitted when the user successfully solves a challenge.
  ///
  /// Note: Although Yandex SmartCaptcha docs list the `success` event as subscribable,
  /// it is not dispatched reliably, so it is handled manually via the `callback` function.
  challengeSolved('success', subscribable: false),

  /// Emitted when the SmartCaptcha token expires after the challenge is successfully solved.
  tokenExpired('token-expired'),

  /// Emitted when a network error occurs while loading or executing the SmartCaptcha script.
  networkError('network-error'),

  /// Emitted when an uncaught JavaScript error occurs inside the SmartCaptcha script.
  javaScriptError('javascript-error');

  const CaptchaEvent(this.id, {this.subscribable = true});

  /// The event identifier passed to SmartCaptcha's `subscribe` method.
  ///
  /// If [subscribable] is `false`, this identifier is not passed to `subscribe`.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe
  final String id;

  /// Whether this event is registered via SmartCaptcha's `subscribe` method.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe
  final bool subscribable;
}
