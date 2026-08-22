import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

void main() {
  patrolTest('run integration test', ($) async {
    await $.pumpWidgetAndSettle(const App());

    // Test the main widgets are rendered.
    expect($(App), findsOne);
    expect($(HomePage), findsOne);
    expect($(YandexSmartCaptcha), findsOne);

    // Test the basic user flow for Web SmartCaptcha.
    await $.platformAutomator.tap(Selector(textContains: 'robot'));

    // TODO: Fix text entering later?
    // await $.native.enterTextByIndex(
    //   'НАПОЛЗАЯ ПЕНОЙ',
    //   index: 0,
    // );

    await $.pump(const Duration(seconds: 2));

    await $.platformAutomator.tap(Selector(textContains: 'continue'));

    await $.pump(const Duration(seconds: 2));

    // Test the CaptchaController methods.
    final buttonExecute = $('Execute');
    final buttonDestroy = $('Destroy');

    expect(buttonExecute, findsOneWidget);
    expect(buttonDestroy, findsOneWidget);

    await buttonExecute.tap();

    await $.pump(const Duration(seconds: 2));

    await buttonDestroy.tap();

    await $.pump(const Duration(seconds: 2));
  });
}
