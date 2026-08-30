/// Supported positions for the DPN (Data Processing Notice)
/// badge when invisible mode is enabled.
enum DPNBadgePosition {
  /// Top-left corner
  topLeft('top-left'),

  /// Center-left position
  centerLeft('center-left'),

  /// Bottom-left corner
  bottomLeft('bottom-left'),

  /// Top-right corner
  topRight('top-right'),

  /// Center-right position
  centerRight('center-right'),

  /// Bottom-right corner
  bottomRight('bottom-right');

  const DPNBadgePosition(this.id);

  /// The identifier passed to SmartCaptcha's native `shieldPosition` parameter.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#render
  final String id;
}
