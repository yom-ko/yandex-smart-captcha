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
    final buttonReset = find.widgetWithText(ElevatedButton, 'Reset');
    final buttonDestroy = find.widgetWithText(FilledButton, 'Destroy');

    final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
    final webViewController =
        (webView.platform as PlatformInAppWebViewWidgetFake).controller
          ..emit('captchaReady');

    await tester.pump();

    expect(buttonExecute, findsOneWidget);
    expect(buttonReset, findsOneWidget);
    expect(buttonDestroy, findsOneWidget);
    expect(tester.widget<ElevatedButton>(buttonReset).onPressed, isNull);

    await tester.tap(buttonExecute);
    await tester.pump(const Duration(seconds: 2));

    webViewController.emit('challengeSolved', ['token']);
    await tester.pump();

    expect(tester.widget<ElevatedButton>(buttonReset).onPressed, isNotNull);

    await tester.tap(buttonReset);
    await tester.pump();

    expect(
      webViewController.evaluatedJavascriptSources,
      contains('window.smartCaptcha.reset(window.wscWidgetId)'),
    );
    expect(tester.widget<ElevatedButton>(buttonReset).onPressed, isNull);

    webViewController.emit('challengeSolved', ['token']);
    await tester.pump();

    await tester.tap(buttonDestroy);
    await tester.pump();

    expect(tester.widget<ElevatedButton>(buttonExecute).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(buttonReset).onPressed, isNull);
    expect(tester.widget<FilledButton>(buttonDestroy).onPressed, isNull);
  });
}
