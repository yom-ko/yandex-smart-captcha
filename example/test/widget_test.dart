@TestOn('vm')
library;

import 'package:example/main.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

import 'in_app_webview_platform_fake.dart';

void main() {
  setUpAll(() {
    InAppWebViewPlatform.instance = InAppWebViewPlatformFake();
  });

  testWidgets('buttons wrap without overflowing on a narrow screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(240, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());

    expect(tester.takeException(), isNull);
    final buttons = [
      find.widgetWithText(ElevatedButton, 'Execute'),
      find.widgetWithText(ElevatedButton, 'Reset'),
      find.widgetWithText(FilledButton, 'Destroy'),
    ];
    expect(
      tester.getTopLeft(buttons.last).dy,
      greaterThan(tester.getTopLeft(buttons.first).dy),
    );
    for (final button in buttons) {
      expect(tester.getRect(button).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(button).right, lessThanOrEqualTo(240));
    }
  });

  testWidgets('buttons are evenly spaced across a wide screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());

    final buttons = [
      tester.getRect(find.widgetWithText(ElevatedButton, 'Execute')),
      tester.getRect(find.widgetWithText(ElevatedButton, 'Reset')),
      tester.getRect(find.widgetWithText(FilledButton, 'Destroy')),
    ];
    expect(buttons.map((button) => button.top).toSet(), hasLength(1));
    final edgeGap = buttons.first.left - 16;
    expect(buttons[1].left - buttons[0].right, closeTo(edgeGap, 0.01));
    expect(buttons[2].left - buttons[1].right, closeTo(edgeGap, 0.01));
    expect(800 - 16 - buttons.last.right, closeTo(edgeGap, 0.01));
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
      anyElement(contains('window.smartCaptcha.reset(window.yscWidgetId)')),
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
