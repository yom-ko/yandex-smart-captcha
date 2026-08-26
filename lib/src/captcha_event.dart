/// Events related to the Yandex SmartCaptcha lifecycle.
enum CaptchaEvent {
  /// Emitted when the captcha is loaded successfully.
  captchaLoaded('captcha-loaded', subscribable: false),

  /// Emitted when the captcha challenge is shown.
  challengeShown('challenge-visible'),

  /// Emitted when the captcha challenge is hidden.
  challengeHidden('challenge-hidden'),

  /// Emitted when a network error occurs.
  networkError('network-error'),

  /// Emitted when a JavaScript error occurs.
  javaScriptError('javascript-error'),

  /// Emitted when the captcha token expires or is invalidated.
  tokenExpired('token-expired'),

  /// Emitted when the captcha challenge is solved successfully.
  ///
  /// According to the documentation, the `success` event can be subscribed to,
  /// but it doesn't work in reality, so we emit it manually in the `callback` function.
  challengeSolved('success', subscribable: false);

  const CaptchaEvent(this.id, {this.subscribable = true});

  /// Event identifier used with SmartCaptcha's native `subscribe` method.
  /// If the event is not subscribable, this identifier is not actually used.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe.
  final String id;

  /// Whether this event is registered with SmartCaptcha's native `subscribe` method.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe.
  final bool subscribable;
}
