import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/web_smart_captcha.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

import 'mocks/in_app_webview_platform_fake.dart';

void main() {
  setUpAll(() {
    InAppWebViewPlatform.instance = InAppWebViewPlatformFake();
  });

  CaptchaConfig createConfig({
    CaptchaLanguage language = CaptchaLanguage.ru,
    bool alwaysShowChallenge = false,
    bool useInvisibleMode = false,
    DPNBadgePosition badgePosition = DPNBadgePosition.bottomRight,
    bool hideBadge = false,
    double initialScale = 1,
    bool allowUserScaling = false,
    double maximumScale = 3,
    Color? backgroundColor,
    bool useWebViewMode = true,
  }) {
    return CaptchaConfig(
      clientKey: 'client-key',
      language: language,
      alwaysShowChallenge: alwaysShowChallenge,
      useInvisibleMode: useInvisibleMode,
      badgePosition: badgePosition,
      hideBadge: hideBadge,
      initialScale: initialScale,
      allowUserScaling: allowUserScaling,
      maximumScale: maximumScale,
      backgroundColor: backgroundColor,
      useWebViewMode: useWebViewMode,
    );
  }

  /// Pumps a [YandexSmartCaptcha] widget and returns the
  /// [PlatformInAppWebViewControllerFake] backing its WebView,
  /// so tests can inspect the generated HTML, simulate JavaScript
  /// events, and verify evaluated JavaScript sources.
  Future<PlatformInAppWebViewControllerFake> pumpCaptcha(
    WidgetTester tester, {
    required CaptchaConfig config,
    void Function(String? token)? onChallengeSolved,
    CaptchaController? controller,
    VoidCallback? onCaptchaReady,
    VoidCallback? onChallengeShown,
    VoidCallback? onChallengeHidden,
    VoidCallback? onNetworkError,
    VoidCallback? onJavaScriptError,
    bool Function(String url)? onNavigationRequest,
    Widget? loadingIndicator,
  }) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: YandexSmartCaptcha(
          config: config,
          onChallengeSolved: onChallengeSolved ?? (_) {},
          controller: controller,
          onCaptchaReady: onCaptchaReady,
          onChallengeShown: onChallengeShown,
          onChallengeHidden: onChallengeHidden,
          onNetworkError: onNetworkError,
          onJavaScriptError: onJavaScriptError,
          onNavigationRequest: onNavigationRequest,
          loadingIndicator: loadingIndicator,
        ),
      ),
    );

    final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
    final platformWidget = webView.platform as PlatformInAppWebViewWidgetFake;
    return platformWidget.controller;
  }

  group('$CaptchaController', () {
    testWidgets('execute runs the SmartCaptcha execute script', (tester) async {
      final captchaController = CaptchaController();
      final fakeController = await pumpCaptcha(
        tester,
        config: createConfig(),
        controller: captchaController,
      );

      await captchaController.execute();

      expect(
        fakeController.evaluatedJavascriptSources,
        contains('window.smartCaptcha.execute(window.$widgetIdProp)'),
      );
    });

    testWidgets('destroy runs the SmartCaptcha destroy script', (tester) async {
      final captchaController = CaptchaController();
      final fakeController = await pumpCaptcha(
        tester,
        config: createConfig(),
        controller: captchaController,
      );

      await captchaController.destroy();

      expect(
        fakeController.evaluatedJavascriptSources,
        contains('window.smartCaptcha.destroy(window.$widgetIdProp)'),
      );
    });
  });

  group('$YandexSmartCaptcha', () {
    test('stores its configuration and callbacks', () {
      final config = createConfig();
      void onChallengeSolved(String? token) {}
      final controller = CaptchaController();
      void onCaptchaReady() {}
      void onChallengeShown() {}
      void onChallengeHidden() {}
      void onNetworkError() {}
      void onJavaScriptError() {}
      bool onNavigationRequest(String url) => true;
      const loadingIndicator = SizedBox.shrink();

      final widget = YandexSmartCaptcha(
        config: config,
        onChallengeSolved: onChallengeSolved,
        controller: controller,
        onCaptchaReady: onCaptchaReady,
        onChallengeShown: onChallengeShown,
        onChallengeHidden: onChallengeHidden,
        onNetworkError: onNetworkError,
        onJavaScriptError: onJavaScriptError,
        onNavigationRequest: onNavigationRequest,
        loadingIndicator: loadingIndicator,
      );

      expect(widget.config, same(config));
      expect(widget.config.clientKey, equals('client-key'));
      expect(widget.onChallengeSolved, same(onChallengeSolved));
      expect(widget.controller, same(controller));
      expect(widget.onCaptchaReady, same(onCaptchaReady));
      expect(widget.onChallengeShown, same(onChallengeShown));
      expect(widget.onChallengeHidden, same(onChallengeHidden));
      expect(widget.onNetworkError, same(onNetworkError));
      expect(widget.onJavaScriptError, same(onJavaScriptError));
      expect(widget.onNavigationRequest, same(onNavigationRequest));
      expect(widget.loadingIndicator, same(loadingIndicator));
    });

    test('creates a state for the widget', () {
      final widget = YandexSmartCaptcha(
        config: createConfig(),
        onChallengeSolved: (_) {},
      );

      expect(widget.createState(), isA<State<YandexSmartCaptcha>>());
    });

    group('generated WebView HTML', () {
      testWidgets('reflects the widget configuration', (tester) async {
        await pumpCaptcha(
          tester,
          config: createConfig(
            language: CaptchaLanguage.en,
            badgePosition: DPNBadgePosition.topLeft,
            useInvisibleMode: true,
            useWebViewMode: false,
          ),
        );

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        final html = webView.platform.params.initialData?.data ?? '';

        expect(html, contains('sitekey: "client-key"'));
        expect(html, contains('hl: "en"'));
        expect(html, contains('shieldPosition: "top-left"'));
        expect(html, contains('invisible: true'));
        expect(html, contains('webview: false'));
      });

      testWidgets('converts allowUserScaling true to "yes"', (tester) async {
        await pumpCaptcha(
          tester,
          config: createConfig(allowUserScaling: true),
        );
        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));

        expect(
          webView.platform.params.initialData?.data,
          contains('user-scalable=yes'),
        );
      });

      testWidgets('converts allowUserScaling false to "no"', (tester) async {
        await pumpCaptcha(
          tester,
          config: createConfig(),
        );
        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));

        expect(
          webView.platform.params.initialData?.data,
          contains('user-scalable=no'),
        );
      });

      testWidgets('clamps initialScale and maximumScale to the [0.1, 10] range',
          (tester) async {
        await pumpCaptcha(
          tester,
          config: createConfig(initialScale: 20, maximumScale: 0.01),
        );

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        final html = webView.platform.params.initialData?.data ?? '';

        expect(html, contains('initial-scale=10.0'));
        expect(html, contains('maximum-scale=0.1'));
      });
    });

    group(
      'event wiring',
      () {
        testWidgets('shows the loading indicator until captchaReady fires',
            (tester) async {
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            loadingIndicator: const Text('Loading'),
          );

          expect(find.text('Loading'), findsOneWidget);

          fakeController.emit(CaptchaEvent.captchaReady.name);
          await tester.pump();

          expect(find.text('Loading'), findsNothing);
        });

        testWidgets('calls onCaptchaReady when captchaReady fires',
            (tester) async {
          var calls = 0;
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onCaptchaReady: () => calls++,
          );

          fakeController.emit(CaptchaEvent.captchaReady.name);

          expect(calls, equals(1));
        });

        testWidgets('calls onChallengeShown when challengeShown fires',
            (tester) async {
          var calls = 0;
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onChallengeShown: () => calls++,
          );

          fakeController.emit(CaptchaEvent.challengeShown.name);

          expect(calls, equals(1));
        });

        testWidgets('calls onChallengeHidden when challengeHidden fires',
            (tester) async {
          var calls = 0;
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onChallengeHidden: () => calls++,
          );

          fakeController.emit(CaptchaEvent.challengeHidden.name);

          expect(calls, equals(1));
        });

        testWidgets('calls onNetworkError when networkError fires',
            (tester) async {
          var calls = 0;
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onNetworkError: () => calls++,
          );

          fakeController.emit(CaptchaEvent.networkError.name);

          expect(calls, equals(1));
        });

        testWidgets('calls onJavaScriptError when javaScriptError fires',
            (tester) async {
          var calls = 0;
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onJavaScriptError: () => calls++,
          );

          fakeController.emit(CaptchaEvent.javaScriptError.name);

          expect(calls, equals(1));
        });

        testWidgets(
          'calls onChallengeSolved with the token from challengeSolved',
          (tester) async {
            String? receivedToken;
            final fakeController = await pumpCaptcha(
              tester,
              config: createConfig(),
              onChallengeSolved: (token) => receivedToken = token,
            );

            fakeController.emit(CaptchaEvent.challengeSolved.name, ['a-token']);

            expect(receivedToken, equals('a-token'));
          },
        );

        testWidgets(
          'calls onChallengeSolved with null when the token is the string "null"',
          (tester) async {
            String? receivedToken = 'not-null';
            final fakeController = await pumpCaptcha(
              tester,
              config: createConfig(),
              onChallengeSolved: (token) => receivedToken = token,
            );

            fakeController.emit(CaptchaEvent.challengeSolved.name, ['null']);

            expect(receivedToken, isNull);
          },
        );

        testWidgets('calls onChallengeSolved with null when no token is passed',
            (tester) async {
          String? receivedToken = 'not-null';
          final fakeController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onChallengeSolved: (token) => receivedToken = token,
          );

          fakeController.emit(CaptchaEvent.challengeSolved.name, []);

          expect(receivedToken, isNull);
        });
      },
    );

    group('rendering', () {
      testWidgets(
        'does not render a background when no color is configured',
        (tester) async {
          await pumpCaptcha(tester, config: createConfig());

          expect(find.byType(ColoredBox), findsNothing);
        },
      );

      testWidgets(
        'renders the configured background color',
        (tester) async {
          await pumpCaptcha(
            tester,
            config: createConfig(backgroundColor: Colors.red),
          );

          final coloredBox = tester.widget<ColoredBox>(find.byType(ColoredBox));
          expect(coloredBox.color, equals(Colors.red));
        },
      );

      testWidgets(
        'does not render a loading indicator when none is provided',
        (tester) async {
          await pumpCaptcha(tester, config: createConfig());

          expect(find.text('Loading'), findsNothing);
        },
      );
    });
  });
}
