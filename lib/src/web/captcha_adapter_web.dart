import 'dart:js_interop';
import 'dart:js_interop_unsafe' show JSObjectUnsafeUtilExtension;

const _smartCaptchaObjectName = 'smartCaptcha';

@JS(_smartCaptchaObjectName)
external SmartCaptcha? get smartCaptcha;

extension type SmartCaptcha._(JSObject _) implements JSObject {
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#render
  external JSNumber render(String containerId, SmartCaptchaOptions options);

  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#subscribe
  external void subscribe(JSNumber widgetId, String event, JSFunction callback);

  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#execute
  external void execute([JSNumber? widgetId]);

  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#reset
  external void reset([JSNumber? widgetId]);

  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#destroy
  external void destroy([JSNumber? widgetId]);
}

extension type SmartCaptchaOptions._(JSObject _) implements JSObject {
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#render
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

void deleteCaptchaObject() {
  globalContext.delete(_smartCaptchaObjectName.toJS);
}
