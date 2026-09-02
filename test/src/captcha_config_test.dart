import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

void main() {
  group('$CaptchaConfig', () {
    test('uses documented defaults', () {
      const config = CaptchaConfig(clientKey: 'client-key');

      expect(config.clientKey, 'client-key');
      expect(config.language, CaptchaLanguage.ru);
      expect(config.alwaysShowChallenge, isFalse);
      expect(config.useInvisibleMode, isFalse);
      expect(config.badgePosition, DPNBadgePosition.bottomRight);
      expect(config.hideBadge, isFalse);
      expect(config.initialScale, 1.0);
      expect(config.allowUserScaling, isFalse);
      expect(config.maximumScale, 3.0);
      expect(config.useWebViewMode, isTrue);
    });

    test('retains explicitly configured values', () {
      const config = CaptchaConfig(
        clientKey: 'another-key',
        language: CaptchaLanguage.tr,
        alwaysShowChallenge: true,
        useInvisibleMode: true,
        badgePosition: DPNBadgePosition.topLeft,
        hideBadge: true,
        initialScale: 1.5,
        allowUserScaling: true,
        maximumScale: 4,
        useWebViewMode: false,
      );

      expect(config.clientKey, 'another-key');
      expect(config.language, CaptchaLanguage.tr);
      expect(config.alwaysShowChallenge, isTrue);
      expect(config.useInvisibleMode, isTrue);
      expect(config.badgePosition, DPNBadgePosition.topLeft);
      expect(config.hideBadge, isTrue);
      expect(config.initialScale, 1.5);
      expect(config.allowUserScaling, isTrue);
      expect(config.maximumScale, 4.0);
      expect(config.useWebViewMode, isFalse);
    });
  });
}
