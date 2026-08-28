import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

void main() {
  patrolTest('run app integration test', ($) async {
    await $.pumpWidgetAndSettle(const App());

    // Test the main widgets are rendered.
    expect($(App), findsOne);
    expect($(HomePage), findsOne);
    expect($(YandexSmartCaptcha), findsOne);

    // Test the basic user flow for Web SmartCaptcha.
    await $.platform.mobile.tap(Selector(textContains: 'robot'));

    await $.pump(const Duration(seconds: 2));

    await $.platform.mobile.tap(Selector(textContains: 'continue'));

    // Test the CaptchaController methods.
    final buttonExecute = $('Execute');
    final buttonDestroy = $('Destroy');

    expect(buttonExecute, findsOneWidget);
    expect(buttonDestroy, findsOneWidget);

    await buttonExecute.tap();

    await $.pump(const Duration(seconds: 2));

    await buttonDestroy.tap();
  });
}
