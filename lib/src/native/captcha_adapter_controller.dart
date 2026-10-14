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
    initialData = InAppWebViewInitialData(
      data: SmartCaptcha(config).htmlData,
      baseUrl: baseUrl != null ? WebUri(baseUrl!) : null,
    );
  }

  void attachWebViewController(InAppWebViewController controller) {
    if (_isDisposed) return;
    _webViewController = controller;

    isReady.value = false;
    isLoaded.value = false;

    for (final event in CaptchaEvent.values) {
      _webViewController!.addJavaScriptHandler(
        handlerName: event.name,
        callback: (args) {
          _handleEvent(event, args);
        },
      );
    }
  }

  void _handleEvent(CaptchaEvent event, List<dynamic> args) {
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
    final url = action.request.url?.toString();
    if (!action.isForMainFrame || url == null || _isInitialDocument(url)) {
      return NavigationActionPolicy.ALLOW;
    }

    final isAllowed = callbacks.onNavigationRequest?.call(url) ?? true;
    return isAllowed
        ? NavigationActionPolicy.ALLOW
        : NavigationActionPolicy.CANCEL;
  }

  bool _isInitialDocument(String url) {
    if (url.startsWith('about:')) return true;

    final baseURL = initialData.baseUrl?.toString();
    if (baseURL == null) return false;
    return _removeSlash(url) == _removeSlash(baseURL);
  }

  static String _removeSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Future<void> _callWidgetMethod(String method) async {
    final webViewController = _webViewController;
    if (_isDisposed || webViewController == null || !isReady.value) return;
    try {
      await webViewController.evaluateJavascript(
        source: SmartCaptcha.callWidgetMethod(method),
      );
    } catch (_) {
      if (!_isDisposed) callbacks.onJavaScriptError?.call();
    }
  }

  @override
  Future<void> execute() async {
    return _callWidgetMethod('execute');
  }

  @override
  Future<void> reset() async {
    return _callWidgetMethod('reset');
  }

  @override
  Future<void> destroy() async {
    if (_isDisposed || !isReady.value) return;
    final pending = _callWidgetMethod('destroy');
    isReady.value = false;
    return pending;
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
