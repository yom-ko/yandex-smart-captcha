import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';

void main() {
  group('$CaptchaEvent', () {
    group('values', () {
      test('contains exactly 7 events', () {
        expect(CaptchaEvent.values, hasLength(7));
      });
    });

    group('ids', () {
      test('captchaLoaded has id "captcha-loaded"', () {
        expect(CaptchaEvent.captchaLoaded.id, equals('captcha-loaded'));
      });

      test('challengeShown has id "challenge-visible"', () {
        expect(CaptchaEvent.challengeShown.id, equals('challenge-visible'));
      });

      test('challengeHidden has id "challenge-hidden"', () {
        expect(CaptchaEvent.challengeHidden.id, equals('challenge-hidden'));
      });

      test('networkError has id "network-error"', () {
        expect(CaptchaEvent.networkError.id, equals('network-error'));
      });

      test('javaScriptError has id "javascript-error"', () {
        expect(CaptchaEvent.javaScriptError.id, equals('javascript-error'));
      });

      test('tokenExpired has id "token-expired"', () {
        expect(CaptchaEvent.tokenExpired.id, equals('token-expired'));
      });

      test('challengeSolved has id "success"', () {
        expect(CaptchaEvent.challengeSolved.id, equals('success'));
      });

      test('ids are unique across all events', () {
        final ids = CaptchaEvent.values.map((e) => e.id);

        expect(ids.toSet(), hasLength(CaptchaEvent.values.length));
      });
    });

    group('subscribable', () {
      test('captchaLoaded is not subscribable', () {
        expect(CaptchaEvent.captchaLoaded.subscribable, isFalse);
      });

      test('challengeSolved is not subscribable', () {
        expect(CaptchaEvent.challengeSolved.subscribable, isFalse);
      });

      test('challengeShown is subscribable', () {
        expect(CaptchaEvent.challengeShown.subscribable, isTrue);
      });

      test('challengeHidden is subscribable', () {
        expect(CaptchaEvent.challengeHidden.subscribable, isTrue);
      });

      test('networkError is subscribable', () {
        expect(CaptchaEvent.networkError.subscribable, isTrue);
      });

      test('javaScriptError is subscribable', () {
        expect(CaptchaEvent.javaScriptError.subscribable, isTrue);
      });

      test('tokenExpired is subscribable', () {
        expect(CaptchaEvent.tokenExpired.subscribable, isTrue);
      });
    });
  });
}
