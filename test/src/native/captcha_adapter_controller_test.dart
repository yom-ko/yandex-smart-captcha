@TestOn('vm')
library;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';
import 'package:yandex_smart_captcha/src/captcha_platform_controller.dart';
import 'package:yandex_smart_captcha/src/native/captcha_adapter.dart';
import 'package:yandex_smart_captcha/src/native/captcha_adapter_controller.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

import '../../mocks/in_app_webview_platform_fake.dart';

void main() {
  group('$CaptchaAdapterController', () {
    CaptchaAdapterController createController({
      CaptchaAdapterCallbacks? callbacks,
      String? baseUrl,
    }) {
      return CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: callbacks ??
            CaptchaAdapterCallbacks(
              onChallengeSolved: (_) {},
            ),
        baseUrl: baseUrl,
      );
    }

    test('creates initial data with the configured document origin', () {
      final controller = createController(
        baseUrl: 'https://captcha.example',
      );

      expect(controller.initialData.baseUrl, WebUri('https://captcha.example'));
      expect(controller.initialData.data, contains('sitekey: "client-key"'));

      controller.dispose();
    });

    test('delegates controller operations to the attached WebView', () async {
      final controller = createController();
      final wvController = PlatformInAppWebViewControllerFake();
      controller.attachWebViewController(
        InAppWebViewController.fromPlatform(platform: wvController),
      );
      wvController.emit(CaptchaEvent.captchaReady.name);

      await controller.execute();
      await controller.reset();
      await controller.destroy();

      expect(
        wvController.evaluatedJavascriptSources,
        equals([
          'window.smartCaptcha.execute(window.$widgetIdProp)',
          'window.smartCaptcha.reset(window.$widgetIdProp)',
          'window.smartCaptcha.destroy(window.$widgetIdProp)',
        ]),
      );

      controller.dispose();
    });

    test(
      'does not allow controller operations before ready or after destroy',
      () async {
        final controller = createController();
        final wvController = PlatformInAppWebViewControllerFake();
        controller.attachWebViewController(
          InAppWebViewController.fromPlatform(platform: wvController),
        );

        await controller.execute();
        await controller.reset();
        expect(wvController.evaluatedJavascriptSources, isEmpty);
        expect(controller.isReady.value, isFalse);
        expect(controller.isLoaded.value, isFalse);

        wvController.emit(CaptchaEvent.captchaReady.name);
        expect(controller.isReady.value, isTrue);
        expect(controller.isLoaded.value, isTrue);

        await controller.destroy();

        expect(controller.isReady.value, isFalse);
        expect(controller.isLoaded.value, isTrue);
        expect(
          wvController.evaluatedJavascriptSources,
          equals(['window.smartCaptcha.destroy(window.$widgetIdProp)']),
        );

        await controller.execute();
        await controller.reset();
        await controller.destroy();

        expect(controller.isReady.value, isFalse);
        expect(
          wvController.evaluatedJavascriptSources,
          equals(['window.smartCaptcha.destroy(window.$widgetIdProp)']),
        );

        controller.dispose();
      },
    );

    test('dispatches every bridge event and converts challenge tokens', () {
      final solvedTokens = <String?>[];
      var readyCalls = 0;
      var shownCalls = 0;
      var hiddenCalls = 0;
      var expiredCalls = 0;
      var networkErrorCalls = 0;
      var javaScriptErrorCalls = 0;

      final controller = createController(
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: solvedTokens.add,
          onCaptchaReady: () => readyCalls++,
          onChallengeShown: () => shownCalls++,
          onChallengeHidden: () => hiddenCalls++,
          onTokenExpired: () => expiredCalls++,
          onNetworkError: () => networkErrorCalls++,
          onJavaScriptError: () => javaScriptErrorCalls++,
        ),
      );
      final wvController = PlatformInAppWebViewControllerFake();
      controller.attachWebViewController(
        InAppWebViewController.fromPlatform(platform: wvController),
      );

      wvController.emit(CaptchaEvent.captchaReady.name);
      wvController.emit(CaptchaEvent.challengeShown.name);
      wvController.emit(CaptchaEvent.challengeHidden.name);
      wvController.emit(CaptchaEvent.challengeSolved.name, ['token']);
      wvController.emit(CaptchaEvent.challengeSolved.name, ['null']);
      wvController.emit(CaptchaEvent.challengeSolved.name);
      wvController.emit(CaptchaEvent.tokenExpired.name);
      wvController.emit(CaptchaEvent.networkError.name);
      wvController.emit(CaptchaEvent.javaScriptError.name);

      expect(controller.isReady.value, isTrue);
      expect(readyCalls, 1);
      expect(shownCalls, 1);
      expect(hiddenCalls, 1);
      expect(solvedTokens, equals(['token', null, null]));
      expect(expiredCalls, 1);
      expect(networkErrorCalls, 1);
      expect(javaScriptErrorCalls, 1);

      controller.dispose();
    });

    test('controller operations are safe before WebView attachment', () async {
      final controller = createController();

      await controller.execute();
      await controller.reset();
      await controller.destroy();

      controller.dispose();
    });

    test('dispose is idempotent and ignores late WebView events', () async {
      var readyCalls = 0;
      final controller = createController(
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onCaptchaReady: () => readyCalls++,
        ),
      );
      final wvController = PlatformInAppWebViewControllerFake();

      controller.attachWebViewController(
        InAppWebViewController.fromPlatform(platform: wvController),
      );
      controller.dispose();
      controller.dispose();
      wvController.emit(CaptchaEvent.captchaReady.name);
      await controller.execute();

      expect(readyCalls, isZero);
      expect(wvController.evaluatedJavascriptSources, isEmpty);
    });
  });
}
