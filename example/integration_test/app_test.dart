import 'package:example/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

// Since SmartCaptcha is loaded over the network, allow generous timeout.
const _loadTimeout = Duration(seconds: 30);

final _checkbox = Selector(textContains: 'robot');
final _challengeSubmit = Selector(textContains: 'Submit');

void main() {
  group(
    'SmartCaptcha example app',
    skip: kIsWeb ? '`platform.mobile` is unavailable on the web.' : false,
    () {
      patrolTest('loads SmartCaptcha and enables the controls', ($) async {
        await $.pumpWidget(const App());

        expect($(App), findsOne);
        expect($(HomePage), findsOne);
        expect($(YandexSmartCaptcha), findsOne);
        expect($(CircularProgressIndicator), findsOne);
        expect(_isEnabled($, 'Execute'), isFalse);
        expect(_isEnabled($, 'Reset'), isFalse);
        expect(_isEnabled($, 'Destroy'), isFalse);

        await _waitUntilCaptchaReady($);

        expect($(CircularProgressIndicator), findsNothing);
        expect(_isEnabled($, 'Execute'), isTrue);
        expect(_isEnabled($, 'Reset'), isFalse);
        expect(_isEnabled($, 'Destroy'), isTrue);
      });

      patrolTest('shows the challenge when the checkbox is tapped', ($) async {
        await $.pumpWidget(const App());
        await _waitUntilCaptchaReady($);

        await $.platform.mobile.tap(_checkbox, timeout: _loadTimeout);
        await $.platform.mobile.waitUntilVisible(
          _challengeSubmit,
          timeout: _loadTimeout,
        );

        // The challenge cannot be solved automatically, so no token is issued.
        expect(_isEnabled($, 'Reset'), isFalse);
      });

      patrolTest('destroys SmartCaptcha and disables the controls', ($) async {
        await $.pumpWidget(const App());
        await _waitUntilCaptchaReady($);

        await $(_button('Destroy')).tap();
        await _waitUntil($, () => !_isEnabled($, 'Destroy'));

        expect(_isEnabled($, 'Execute'), isFalse);
        expect(_isEnabled($, 'Reset'), isFalse);
        expect(_isEnabled($, 'Destroy'), isFalse);
      });
    },
  );
}

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<ButtonStyleButton>(),
);

bool _isEnabled(PatrolIntegrationTester $, String label) =>
    $.tester.widget<ButtonStyleButton>(_button(label)).enabled;

Future<void> _waitUntilCaptchaReady(PatrolIntegrationTester $) async {
  // Keep pumping frames until ready so the WebView platform view can load.
  await _waitUntil($, () => _isEnabled($, 'Destroy'));
  await $.platform.mobile.waitUntilVisible(_checkbox, timeout: _loadTimeout);
}

Future<void> _waitUntil(
  PatrolIntegrationTester $,
  bool Function() condition, {
  Duration timeout = _loadTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition was not met within $timeout.');
    }
    await $.pump(const Duration(milliseconds: 200));
  }
}
