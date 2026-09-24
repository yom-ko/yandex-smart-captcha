@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart';
import 'package:yandex_smart_captcha/src/web/captcha_script_loader_web.dart';

const _smartCaptchaScriptSelector = 'script[src="$smartCaptchaScriptUrl"]';

void main() {
  setUp(() {
    _removeSmartCaptchaScript();
  });

  tearDown(() {
    _removeSmartCaptchaScript();
  });

  test('keeps the script until all references are released', () async {
    final script = _appendSmartCaptchaScript();

    await acquireSmartCaptchaScript();
    await acquireSmartCaptchaScript();
    expect(document.querySelector(_smartCaptchaScriptSelector), same(script));

    releaseSmartCaptchaScript();
    expect(document.querySelector(_smartCaptchaScriptSelector), same(script));

    releaseSmartCaptchaScript();
    expect(document.querySelector(_smartCaptchaScriptSelector), isNull);
  });

  test('does not remove a script when no reference is active', () {
    final script = _appendSmartCaptchaScript();

    releaseSmartCaptchaScript();

    expect(document.querySelector(_smartCaptchaScriptSelector), same(script));
  });
}

HTMLScriptElement _appendSmartCaptchaScript() {
  final script = HTMLScriptElement()..src = smartCaptchaScriptUrl;
  document.head!.append(script);
  return script;
}

void _removeSmartCaptchaScript() {
  document.querySelector(_smartCaptchaScriptSelector)?.remove();
}
