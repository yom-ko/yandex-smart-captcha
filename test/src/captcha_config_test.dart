import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

void main() {
  group('$CaptchaConfig', () {
    test('uses documented defaults', () {
      const config = CaptchaConfig(clientKey: 'client-key');

      expect(config.clientKey, equals('client-key'));
      expect(config.language, equals(CaptchaLanguage.ru));
      expect(config.alwaysShowChallenge, isFalse);
      expect(config.useInvisibleMode, isFalse);
      expect(config.badgePosition, equals(DPNBadgePosition.bottomRight));
      expect(config.hideBadge, isFalse);
      expect(config.initialScale, equals(1.0));
      expect(config.allowUserScaling, isFalse);
      expect(config.maximumScale, equals(3.0));
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

      expect(config.clientKey, equals('another-key'));
      expect(config.language, equals(CaptchaLanguage.tr));
      expect(config.alwaysShowChallenge, isTrue);
      expect(config.useInvisibleMode, isTrue);
      expect(config.badgePosition, equals(DPNBadgePosition.topLeft));
      expect(config.hideBadge, isTrue);
      expect(config.initialScale, equals(1.5));
      expect(config.allowUserScaling, isTrue);
      expect(config.maximumScale, equals(4.0));
      expect(config.useWebViewMode, isFalse);
    });

    test('considers configurations equal when all values match', () {
      const first = CaptchaConfig(clientKey: 'client-key');
      const second = CaptchaConfig(clientKey: 'client-key');

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });

    test('considers configurations different when any value differs', () {
      const config = CaptchaConfig(clientKey: 'client-key');
      const configurationsWithDifferentValues = <CaptchaConfig>[
        CaptchaConfig(clientKey: 'another-key'),
        CaptchaConfig(clientKey: 'client-key', language: CaptchaLanguage.en),
        CaptchaConfig(clientKey: 'client-key', alwaysShowChallenge: true),
        CaptchaConfig(clientKey: 'client-key', useInvisibleMode: true),
        CaptchaConfig(
          clientKey: 'client-key',
          badgePosition: DPNBadgePosition.topLeft,
        ),
        CaptchaConfig(clientKey: 'client-key', hideBadge: true),
        CaptchaConfig(clientKey: 'client-key', initialScale: 1.5),
        CaptchaConfig(clientKey: 'client-key', allowUserScaling: true),
        CaptchaConfig(clientKey: 'client-key', maximumScale: 4),
        CaptchaConfig(clientKey: 'client-key', useWebViewMode: false),
      ];

      for (final differentConfig in configurationsWithDifferentValues) {
        expect(config, isNot(equals(differentConfig)));
      }
    });
  });
}
