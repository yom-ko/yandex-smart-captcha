/// The supported positions for the badge that contains a link
/// to the DPN (Data Processing Notice) if invisible mode is enabled.
enum DPNBadgePosition {
  topLeft('top-left'),
  centerLeft('center-left'),
  bottomLeft('bottom-left'),
  topRight('top-right'),
  centerRight('center-right'),
  bottomRight('bottom-right');

  const DPNBadgePosition(this.id);

  /// Position value used with the SmartCaptcha's native `shieldPosition` param.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#render.
  final String id;
}
