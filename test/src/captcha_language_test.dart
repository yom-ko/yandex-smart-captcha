import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_language.dart';

void main() {
  group('$CaptchaLanguage', () {
    test('contains all supported languages in documented order', () {
      expect(
        CaptchaLanguage.values,
        equals([
          CaptchaLanguage.ru,
          CaptchaLanguage.en,
          CaptchaLanguage.be,
          CaptchaLanguage.kk,
          CaptchaLanguage.tt,
          CaptchaLanguage.uk,
          CaptchaLanguage.uz,
          CaptchaLanguage.tr,
        ]),
      );
    });

    test('uses language codes as enum names', () {
      expect(
        CaptchaLanguage.values.map((language) => language.name),
        equals(['ru', 'en', 'be', 'kk', 'tt', 'uk', 'uz', 'tr']),
      );
    });
  });
}
