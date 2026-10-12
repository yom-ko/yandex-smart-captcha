import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import 'captcha_adapter_web.dart' show smartCaptcha;

const _captchaScriptUrl = 'https://smartcaptcha.cloud.yandex.ru/captcha.js';

Future<void>? _pendingLoad;

/// Ensures the SmartCaptcha object is available.
///
/// If the page already provides SmartCaptcha, it is reused.
/// Otherwise, the JS script is added once and stays on the page.
/// Concurrent calls share one load, and a failed load can be retried.
Future<void> ensureCaptchaObject() {
  if (smartCaptcha != null) return Future<void>.value();
  return _pendingLoad ??= _loadCaptchaScript();
}

Future<void> _loadCaptchaScript() {
  final completer = Completer<void>();
  final script = HTMLScriptElement()..src = _captchaScriptUrl;

  script
    ..onload = ((Event _) {
      _pendingLoad = null;
      completer.complete();
    }).toJS
    ..onerror = ((Event _) {
      script.remove();
      _pendingLoad = null;
      completer.completeError(
        StateError('Failed to load Yandex SmartCaptcha script'),
      );
    }).toJS;

  document.head!.appendChild(script);

  return completer.future;
}
