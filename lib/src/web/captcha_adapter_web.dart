import 'dart:js_interop';

const _smartCaptchaObjectName = 'smartCaptcha';

@JS(_smartCaptchaObjectName)
external SmartCaptcha? get smartCaptcha;

extension type SmartCaptcha._(JSObject _) implements JSObject {
  external JSNumber render(String containerId, SmartCaptchaOptions options);

  external void subscribe(JSNumber widgetId, String event, JSFunction callback);

  external void execute(JSNumber widgetId);

  external void reset(JSNumber widgetId);

  external void destroy(JSNumber widgetId);
}

extension type SmartCaptchaOptions._(JSObject _) implements JSObject {
  external factory SmartCaptchaOptions({
    String sitekey,
    String hl,
    bool test,
    bool invisible,
    String shieldPosition,
    bool hideShield,
    bool webview,
    JSFunction callback,
  });
}
