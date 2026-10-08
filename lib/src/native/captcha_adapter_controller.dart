import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../captcha_config.dart';
import '../captcha_event.dart';
import '../captcha_platform_controller.dart';
import 'captcha_adapter.dart';

final class CaptchaAdapterController implements CaptchaPlatformController {
  final CaptchaConfig config;
  final CaptchaAdapterCallbacks callbacks;
  final String? baseUrl;

  late final InAppWebViewInitialData initialData;
  InAppWebViewController? _webViewController;

  bool _isDisposed = false;

  @override
  final isReady = ValueNotifier<bool>(false);
  final isLoaded = ValueNotifier<bool>(false);

  CaptchaAdapterController({
    required this.config,
    required this.callbacks,
    required this.baseUrl,
  }) {
    final smartCaptcha = SmartCaptcha(
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
      data: smartCaptcha.htmlData,
      baseUrl: baseUrl != null ? WebUri(baseUrl!) : null,
    );
  }

  void attachWebViewController(InAppWebViewController controller) {
    if (_isDisposed) return;
    _webViewController = controller;
  }

  void handleEvent(CaptchaEvent event, List<dynamic> args) {
    if (_isDisposed) return;

    switch (event) {
      case CaptchaEvent.captchaReady:
        isReady.value = true;
        isLoaded.value = true;
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

  NavigationActionPolicy decideNavigation(NavigationAction action) {
    final url = action.request.url.toString();
    if (!action.isForMainFrame || _isInitialDocument(url)) {
      return NavigationActionPolicy.ALLOW;
    }

    final isAllowed = callbacks.onNavigationRequest?.call(url) ?? true;
    return isAllowed
        ? NavigationActionPolicy.ALLOW
        : NavigationActionPolicy.CANCEL;
  }

  bool _isInitialDocument(String url) {
    if (url.startsWith('about:')) return true;

    final baseURL = baseUrl;
    if (baseURL == null) return false;
    return _removeSlash(url) == _removeSlash(baseURL);
  }

  static String _removeSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  @override
  Future<void> execute() async {
    if (_isDisposed || _webViewController == null || !isReady.value) return;
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.execute(window.$widgetIdProp)',
    );
  }

  @override
  Future<void> reset() async {
    if (_isDisposed || _webViewController == null || !isReady.value) return;
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.reset(window.$widgetIdProp)',
    );
  }

  @override
  Future<void> destroy() async {
    if (_isDisposed || _webViewController == null || !isReady.value) return;
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.destroy(window.$widgetIdProp)',
    );
    isReady.value = false;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _webViewController = null;
    isLoaded.dispose();
    isReady.dispose();
  }
}
