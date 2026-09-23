import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

const smartCaptchaScriptUrl = 'https://smartcaptcha.cloud.yandex.ru/captcha.js';
const _smartCaptchaScriptSelector = 'script[src="$smartCaptchaScriptUrl"]';

Future<void>? _scriptFuture;
int _activeScriptUsers = 0;

/// Acquires a shared SmartCaptcha script reference for one widget instance.
///
/// The script is loaded only once while one or more widget instances are
/// active. A failed load clears the cached future so a later instance can
/// retry.
Future<void> acquireSmartCaptchaScript() async {
  await (_scriptFuture ??= _loadSmartCaptchaScript());
  _activeScriptUsers++;
}

/// Releases a shared SmartCaptcha script reference.
///
/// The script element is removed after the last active widget releases it.
void releaseSmartCaptchaScript() {
  if (_activeScriptUsers == 0) return;
  if (--_activeScriptUsers > 0) return;

  _scriptFuture = null;
  document.querySelector(_smartCaptchaScriptSelector)?.remove();
}

Future<void> _loadSmartCaptchaScript() {
  final existing = document.querySelector(_smartCaptchaScriptSelector);
  if (existing != null) return Future<void>.value();

  final completer = Completer<void>();
  final script = HTMLScriptElement()..src = smartCaptchaScriptUrl;

  script
    ..onload = ((Event _) {
      completer.complete();
    }).toJS
    ..onerror = ((Event _) {
      script.remove();
      _scriptFuture = null;
      completer.completeError(
        StateError('Failed to load Yandex SmartCaptcha script'),
      );
    }).toJS;

  document.head!.appendChild(script);

  return completer.future;
}
