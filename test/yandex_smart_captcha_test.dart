import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';
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

  YandexSmartCaptcha captchaWidget({
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
  }) {
    return YandexSmartCaptcha(
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
        child: captchaWidget(
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
        ),
      ),
    );

    final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
    final platformWidget = webView.platform as PlatformInAppWebViewWidgetFake;
    return platformWidget.controller;
  }

  group('$CaptchaController', () {
    test('does nothing before it is attached to a WebView', () async {
      final captchaController = CaptchaController();

      await captchaController.execute();
      await captchaController.destroy();
    });

    testWidgets('execute runs SmartCaptcha execute script', (tester) async {
      final captchaController = CaptchaController();
      final webViewController = await pumpCaptcha(
        tester,
        config: createConfig(),
        controller: captchaController,
      );

      await captchaController.execute();

      expect(
        webViewController.evaluatedJavascriptSources,
        contains('window.smartCaptcha.execute(window.$widgetIdProp)'),
      );
    });

    testWidgets('destroy runs SmartCaptcha destroy script', (tester) async {
      final captchaController = CaptchaController();
      final webViewController = await pumpCaptcha(
        tester,
        config: createConfig(),
        controller: captchaController,
      );

      await captchaController.destroy();

      expect(
        webViewController.evaluatedJavascriptSources,
        contains('window.smartCaptcha.destroy(window.$widgetIdProp)'),
      );
    });

    testWidgets('moves WebView control to a replacement WebView controller',
        (tester) async {
      final oldController = CaptchaController();
      final newController = CaptchaController();
      final webViewController = await pumpCaptcha(
        tester,
        config: createConfig(),
        controller: oldController,
      );
      await tester.pump();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: captchaWidget(
            config: createConfig(),
            controller: newController,
          ),
        ),
      );
      final replacementWebView =
          tester.widget<InAppWebView>(find.byType(InAppWebView));
      final replacementWebViewController =
          (replacementWebView.platform as PlatformInAppWebViewWidgetFake)
              .controller;

      await oldController.execute();
      expect(webViewController.evaluatedJavascriptSources, isEmpty);

      await newController.execute();
      expect(
        replacementWebViewController.evaluatedJavascriptSources,
        equals(['window.smartCaptcha.execute(window.$widgetIdProp)']),
      );
    });

    testWidgets(
      'detaches its WebView controller when disposed',
      (tester) async {
        final captchaController = CaptchaController();
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          controller: captchaController,
        );
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());
        await captchaController.destroy();

        expect(webViewController.evaluatedJavascriptSources, isEmpty);
      },
    );
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

    group('WebView configuration', () {
      testWidgets('uses the expected WebView settings', (tester) async {
        await pumpCaptcha(tester, config: createConfig());

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        final settings = webView.platform.params.initialSettings!;

        expect(settings.transparentBackground, isTrue);
        expect(settings.useShouldOverrideUrlLoading, isTrue);
        expect(settings.mediaPlaybackRequiresUserGesture, isFalse);
        expect(settings.allowsInlineMediaPlayback, isTrue);
      });

      testWidgets('grants every requested WebView permission', (tester) async {
        final webViewController =
            await pumpCaptcha(tester, config: createConfig());

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        final request = PermissionRequest(
          origin: WebUri('https://captcha.example'),
          resources: [PermissionResourceType.CAMERA],
        );
        final response = await webView.platform.params.onPermissionRequest!(
          InAppWebViewController.fromPlatform(platform: webViewController),
          request,
        );

        expect(response?.action, PermissionResponseAction.GRANT);
        expect(response?.resources, same(request.resources));
      });

      testWidgets('allows navigation by default', (tester) async {
        final webViewController =
            await pumpCaptcha(tester, config: createConfig());

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        final policy = await webView.platform.params.shouldOverrideUrlLoading!(
          InAppWebViewController.fromPlatform(platform: webViewController),
          NavigationAction(
            request: URLRequest(url: WebUri('https://captcha.example')),
            isForMainFrame: true,
          ),
        );

        expect(policy, NavigationActionPolicy.ALLOW);
      });

      testWidgets('uses the navigation callback decision and URL',
          (tester) async {
        String? requestedUrl;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onNavigationRequest: (url) {
            requestedUrl = url;
            return false;
          },
        );

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        final policy = await webView.platform.params.shouldOverrideUrlLoading!(
          InAppWebViewController.fromPlatform(platform: webViewController),
          NavigationAction(
            request: URLRequest(url: WebUri('https://captcha.example/path')),
            isForMainFrame: true,
          ),
        );

        expect(requestedUrl, 'https://captcha.example/path');
        expect(policy, NavigationActionPolicy.CANCEL);
      });

      testWidgets('accepts JavaScript console messages', (tester) async {
        final webViewController =
            await pumpCaptcha(tester, config: createConfig());

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        webView.platform.params.onConsoleMessage!(
          InAppWebViewController.fromPlatform(platform: webViewController),
          ConsoleMessage(message: 'message'),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('event wiring', () {
      testWidgets('shows the loading indicator until captchaReady fires',
          (tester) async {
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          loadingIndicator: const Text('Loading'),
        );

        expect(find.text('Loading'), findsOneWidget);

        webViewController.emit(CaptchaEvent.captchaReady.name);
        await tester.pump();

        expect(find.text('Loading'), findsNothing);
      });

      testWidgets(
        'shows the loading indicator again when the WebView is recreated',
        (tester) async {
          final webViewController = await pumpCaptcha(
            tester,
            config: createConfig(),
            loadingIndicator: const Text('Loading'),
          );
          webViewController.emit(CaptchaEvent.captchaReady.name);
          await tester.pump();

          expect(find.text('Loading'), findsNothing);

          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: captchaWidget(
                config: createConfig(),
                loadingIndicator: const Text('Loading'),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('Loading'), findsOneWidget);
        },
      );

      testWidgets('calls onCaptchaReady when captchaReady fires',
          (tester) async {
        var calls = 0;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onCaptchaReady: () => calls++,
        );

        webViewController.emit(CaptchaEvent.captchaReady.name);

        expect(calls, equals(1));
      });

      testWidgets(
          'keeps the loading indicator hidden after repeated ready events',
          (tester) async {
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          loadingIndicator: const Text('Loading'),
        );

        webViewController.emit(CaptchaEvent.captchaReady.name);
        await tester.pump();
        webViewController.emit(CaptchaEvent.captchaReady.name);
        await tester.pump();

        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('calls onChallengeShown when challengeShown fires',
          (tester) async {
        var calls = 0;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onChallengeShown: () => calls++,
        );

        webViewController.emit(CaptchaEvent.challengeShown.name);

        expect(calls, equals(1));
      });

      testWidgets('calls onChallengeHidden when challengeHidden fires',
          (tester) async {
        var calls = 0;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onChallengeHidden: () => calls++,
        );

        webViewController.emit(CaptchaEvent.challengeHidden.name);

        expect(calls, equals(1));
      });

      testWidgets('calls onNetworkError when networkError fires',
          (tester) async {
        var calls = 0;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onNetworkError: () => calls++,
        );

        webViewController.emit(CaptchaEvent.networkError.name);

        expect(calls, equals(1));
      });

      testWidgets('calls onJavaScriptError when javaScriptError fires',
          (tester) async {
        var calls = 0;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onJavaScriptError: () => calls++,
        );

        webViewController.emit(CaptchaEvent.javaScriptError.name);

        expect(calls, equals(1));
      });

      testWidgets(
        'calls onChallengeSolved with the token from challengeSolved',
        (tester) async {
          String? receivedToken;
          final webViewController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onChallengeSolved: (token) => receivedToken = token,
          );

          webViewController
              .emit(CaptchaEvent.challengeSolved.name, ['a-token']);

          expect(receivedToken, equals('a-token'));
        },
      );

      testWidgets(
        'calls onChallengeSolved with null when the token is the string "null"',
        (tester) async {
          String? receivedToken = 'not-null';
          final webViewController = await pumpCaptcha(
            tester,
            config: createConfig(),
            onChallengeSolved: (token) => receivedToken = token,
          );

          webViewController.emit(CaptchaEvent.challengeSolved.name, ['null']);

          expect(receivedToken, isNull);
        },
      );

      testWidgets('calls onChallengeSolved with null when no token is passed',
          (tester) async {
        String? receivedToken = 'not-null';
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onChallengeSolved: (token) => receivedToken = token,
        );

        webViewController.emit(CaptchaEvent.challengeSolved.name, []);

        expect(receivedToken, isNull);
      });

      testWidgets('stringifies a non-string challenge token', (tester) async {
        String? receivedToken;
        final webViewController = await pumpCaptcha(
          tester,
          config: createConfig(),
          onChallengeSolved: (token) => receivedToken = token,
        );

        webViewController.emit(CaptchaEvent.challengeSolved.name, [42]);

        expect(receivedToken, '42');
      });
    });

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
