import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';

void main() {
  group('$CaptchaEvent', () {
    test('defines the supported events and their SmartCaptcha contracts', () {
      expect(
        CaptchaEvent.values.map((e) => (e.name, e.id, e.subscribable)),
        equals([
          ('captchaReady', 'captcha-ready', false),
          ('challengeShown', 'challenge-visible', true),
          ('challengeHidden', 'challenge-hidden', true),
          ('challengeSolved', 'success', false),
          ('tokenExpired', 'token-expired', true),
          ('networkError', 'network-error', true),
          ('javaScriptError', 'javascript-error', true),
        ]),
      );
    });

    test('uses unique SmartCaptcha event identifiers', () {
      final ids = CaptchaEvent.values.map((event) => event.id).toSet();

      expect(ids, hasLength(CaptchaEvent.values.length));
    });
  });
}
