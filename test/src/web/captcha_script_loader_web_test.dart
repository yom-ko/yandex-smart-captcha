@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart';
import 'package:yandex_smart_captcha/src/web/captcha_script_loader_web.dart';

import '../../mocks/script_network_blocker_web.dart';

const _captchaScriptUrl = 'https://smartcaptcha.cloud.yandex.ru/captcha.js';
const _captchaScriptSelector = 'script[src="$_captchaScriptUrl"]';

void main() {
  setUpAll(blockScriptNetwork);
  tearDownAll(restoreScriptNetwork);

  setUp(() {
    _removeCaptchaScripts();
    _globalThis.smartCaptcha = null;
  });

  tearDown(() {
    _removeCaptchaScripts();
    _globalThis.smartCaptcha = null;
  });

  test('shares one script load between concurrent calls and keeps it',
      () async {
    final first = ensureCaptchaObject();
    final second = ensureCaptchaObject();

    final scripts = document.querySelectorAll(_captchaScriptSelector);
    expect(scripts.length, equals(1));

    final smartCaptcha = JSObject();
    _globalThis.smartCaptcha = smartCaptcha;
    scripts.item(0)!.dispatchEvent(Event('load'));
    await Future.wait([first, second]);

    await ensureCaptchaObject();

    expect(document.querySelectorAll(_captchaScriptSelector).length, equals(1));
    expect(_globalThis.smartCaptcha, same(smartCaptcha));
  });

  test(
    'reuses SmartCaptcha provided by the page without adding a script',
    () async {
      final hostScript = _appendCaptchaScript();
      final hostGlobal = JSObject();
      _globalThis.smartCaptcha = hostGlobal;

      await ensureCaptchaObject();

      expect(
          document.querySelectorAll(_captchaScriptSelector).length, equals(1));
      expect(document.querySelector(_captchaScriptSelector), same(hostScript));
      expect(_globalThis.smartCaptcha, same(hostGlobal));
    },
  );

  test('loads the script again when SmartCaptcha is missing after a load',
      () async {
    final firstLoad = ensureCaptchaObject();
    final firstScript = document.querySelector(_captchaScriptSelector)!;
    firstScript.dispatchEvent(Event('load'));
    await firstLoad;

    final secondLoad = ensureCaptchaObject();
    final scripts = document.querySelectorAll(_captchaScriptSelector);
    expect(scripts.length, equals(2));

    final smartCaptcha = JSObject();
    _globalThis.smartCaptcha = smartCaptcha;
    scripts.item(1)!.dispatchEvent(Event('load'));
    await secondLoad;

    await ensureCaptchaObject();
    expect(document.querySelectorAll(_captchaScriptSelector).length, equals(2));
    expect(_globalThis.smartCaptcha, same(smartCaptcha));
  });

  test(
      'removes a script that fails to load and keeps the one from a later retry',
      () async {
    final failedLoad = ensureCaptchaObject();
    final failedScript = document.querySelector(_captchaScriptSelector)!;
    final failure = expectLater(failedLoad, throwsA(isA<StateError>()));

    failedScript.dispatchEvent(Event('error'));
    await failure;

    expect(document.querySelector(_captchaScriptSelector), isNull);

    final retry = ensureCaptchaObject();
    final retryScript = document.querySelector(_captchaScriptSelector);
    expect(retryScript, isNotNull);
    expect(retryScript, isNot(same(failedScript)));

    retryScript!.dispatchEvent(Event('load'));
    await retry;

    expect(document.querySelector(_captchaScriptSelector), same(retryScript));
  });
}

HTMLScriptElement _appendCaptchaScript() {
  final script = HTMLScriptElement()..src = _captchaScriptUrl;
  document.head!.append(script);
  return script;
}

void _removeCaptchaScripts() {
  Element? script;
  while ((script = document.querySelector(_captchaScriptSelector)) != null) {
    script!.remove();
  }
}

@JS('globalThis')
external _GlobalThis get _globalThis;

extension type _GlobalThis._(JSObject _) implements JSObject {
  @JS('smartCaptcha')
  external JSObject? get smartCaptcha;

  @JS('smartCaptcha')
  external set smartCaptcha(JSObject? value);
}
