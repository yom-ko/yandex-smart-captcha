import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../captcha_config.dart';
import '../captcha_event.dart';
import '../captcha_platform_controller.dart';
import 'smart_captcha_html.dart';

final class CaptchaAdapterController implements CaptchaPlatformController {
  final CaptchaConfig config;
  final String? baseUrl;
  final CaptchaAdapterCallbacks callbacks;

  @override
  final isReady = ValueNotifier<bool>(false);

  late final InAppWebViewInitialData initialData;
  InAppWebViewController? _webViewController;

  CaptchaAdapterController({
    required this.config,
    required this.baseUrl,
    required this.callbacks,
  }) {
    final captchaHtml = SmartCaptchaHTML(
      clientKey: config.clientKey,
      alwaysShowChallenge: config.alwaysShowChallenge,
      language: config.language.name,
      useInvisibleMode: config.useInvisibleMode,
      hideBadge: config.hideBadge,
      badgePosition: config.badgePosition.id,
      useWebViewMode: config.useWebViewMode,
      initialScale: config.initialScale.clamp(0.1, 10),
      allowUserScaling: config.allowUserScaling ? 'yes' : 'no',
      maximumScale: config.maximumScale.clamp(0.1, 10),
    );

    initialData = InAppWebViewInitialData(
      data: captchaHtml.data,
      baseUrl: baseUrl != null ? WebUri(baseUrl!) : null,
    );
  }

  @override
  Future<void> execute() async {
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.execute(window.$widgetIdProp)',
    );
  }

  @override
  Future<void> reset() async {
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.reset(window.$widgetIdProp)',
    );
  }

  @override
  Future<void> destroy() async {
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.destroy(window.$widgetIdProp)',
    );
  }

  void attachWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  void handleEvent(CaptchaEvent event, List<dynamic> args) {
    switch (event) {
      case CaptchaEvent.captchaReady:
        isReady.value = true;
        callbacks.onCaptchaReady?.call();
      case CaptchaEvent.challengeShown:
        callbacks.onChallengeShown?.call();
      case CaptchaEvent.challengeHidden:
        callbacks.onChallengeHidden?.call();
      case CaptchaEvent.challengeSolved:
        var token = args.firstOrNull?.toString();
        token = token == 'null' ? null : token;
        callbacks.onChallengeSolved(token);
      case CaptchaEvent.tokenExpired:
        callbacks.onTokenExpired?.call();
      case CaptchaEvent.networkError:
        callbacks.onNetworkError?.call();
      case CaptchaEvent.javaScriptError:
        callbacks.onJavaScriptError?.call();
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    isReady.dispose();
  }
}
