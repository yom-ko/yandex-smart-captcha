import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/dpn_badge_position.dart';

void main() {
  group('$DPNBadgePosition', () {
    test('contains all supported positions in documented order', () {
      expect(
        DPNBadgePosition.values,
        equals([
          DPNBadgePosition.topLeft,
          DPNBadgePosition.centerLeft,
          DPNBadgePosition.bottomLeft,
          DPNBadgePosition.topRight,
          DPNBadgePosition.centerRight,
          DPNBadgePosition.bottomRight,
        ]),
      );
    });

    test('uses documented position ids', () {
      expect(
        DPNBadgePosition.values.map((position) => position.id),
        equals([
          'top-left',
          'center-left',
          'bottom-left',
          'top-right',
          'center-right',
          'bottom-right',
        ]),
      );
    });
  });
}
