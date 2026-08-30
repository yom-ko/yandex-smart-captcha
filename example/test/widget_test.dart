import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

import 'in_app_webview_platform_fake.dart';

void main() {
  setUp(() {
    InAppWebViewPlatform.instance = InAppWebViewPlatformFake();
  });

  testWidgets('run app widgets test', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(App), findsOne);
    expect(find.byType(HomePage), findsOne);
    expect(find.byType(YandexSmartCaptcha), findsOne);

    final buttonExecute = find.widgetWithText(ElevatedButton, 'Execute');
    final buttonDestroy = find.widgetWithText(FilledButton, 'Destroy');

    expect(buttonExecute, findsOneWidget);
    expect(buttonDestroy, findsOneWidget);

    await tester.tap(buttonExecute);

    await tester.pump(const Duration(seconds: 2));

    await tester.tap(buttonDestroy);
  });
}
