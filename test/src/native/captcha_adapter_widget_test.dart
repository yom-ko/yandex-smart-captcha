@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';
import 'package:yandex_smart_captcha/src/captcha_platform_controller.dart';
import 'package:yandex_smart_captcha/src/native/captcha_adapter_controller.dart';
import 'package:yandex_smart_captcha/src/native/captcha_adapter_widget.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

import '../../mocks/in_app_webview_platform_fake.dart';

void main() {
  setUpAll(() {
    InAppWebViewPlatform.instance = InAppWebViewPlatformFake();
  });

  testWidgets(
    'registers bridge handlers and hides loading after ready',
    (tester) async {
      var readyCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        baseUrl: null,
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onCaptchaReady: () => readyCalls++,
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CaptchaAdapterWidget(
            controller: controller,
            loadingIndicator: const Text('Loading'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading'), findsOneWidget);

      final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
      final platformWidget = webView.platform as PlatformInAppWebViewWidgetFake;

      platformWidget.controller.emit(CaptchaEvent.captchaReady.name);
      await tester.pump();

      expect(readyCalls, 1);
      expect(find.text('Loading'), findsNothing);

      controller.dispose();
    },
  );
}
