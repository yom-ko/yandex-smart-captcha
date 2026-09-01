import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'captcha_config.dart';
import 'captcha_event.dart';
import 'web_smart_captcha.dart';

/// A controller for [YandexSmartCaptcha].
///
/// Provides programmatic control over the underlying Web SmartCaptcha instance.
final class CaptchaController {
  InAppWebViewController? _webViewController;

  /// Starts user validation.
  ///
  /// This method should be called after [YandexSmartCaptcha.onCaptchaReady] has been invoked.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#execute
  Future<void> execute() async {
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.execute(window.$widgetIdProp)',
    );
  }

  /// Removes the Web SmartCaptcha widget and its associated event listeners.
  ///
  /// Calling [execute] or otherwise interacting with the controller after calling
  /// this method will have no effect.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#destroy
  Future<void> destroy() async {
    await _webViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.destroy(window.$widgetIdProp)',
    );
  }

  // ignore: use_setters_to_change_properties
  void _attachWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  void _detachWebViewController() {
    _webViewController = null;
  }
}

/// A Flutter widget that configures and displays Yandex SmartCaptcha.
///
/// Wraps an internal WebView executing the Web SmartCaptcha script.
class YandexSmartCaptcha extends StatefulWidget {
  /// The configuration settings for this CAPTCHA instance.
  final CaptchaConfig config;

  /// Called when the user successfully solves a CAPTCHA challenge.
  ///
  /// Provides the verification token string. May be `null` if token extraction fails.
  final void Function(String? token) onChallengeSolved;

  /// A custom widget displayed while the Web SmartCaptcha content is loading.
  final Widget? loadingIndicator;

  /// An optional controller to programmatically interact with the CAPTCHA.
  final CaptchaController? controller;

  /// Called when the CAPTCHA script is fully loaded and initialized.
  final VoidCallback? onCaptchaReady;

  /// Called when the CAPTCHA challenge popup becomes visible.
  final VoidCallback? onChallengeShown;

  /// Called when the CAPTCHA challenge popup is hidden.
  final VoidCallback? onChallengeHidden;

  /// Called when a network error occurs while loading or executing the CAPTCHA.
  final VoidCallback? onNetworkError;

  /// Called when an uncaught JavaScript error occurs inside the CAPTCHA WebView.
  final VoidCallback? onJavaScriptError;

  /// Intercepts navigation requests inside the WebView.
  ///
  /// Return `true` to allow navigation, or `false` to block it.
  final bool Function(String url)? onNavigationRequest;

  const YandexSmartCaptcha({
    required this.config,
    required this.onChallengeSolved,
    this.loadingIndicator,
    this.controller,
    this.onCaptchaReady,
    this.onChallengeShown,
    this.onChallengeHidden,
    this.onNetworkError,
    this.onJavaScriptError,
    this.onNavigationRequest,
    super.key,
  });

  @override
  State<YandexSmartCaptcha> createState() => _YandexSmartCaptchaState();
}

class _YandexSmartCaptchaState extends State<YandexSmartCaptcha> {
  final _webCaptchaReady = ValueNotifier<bool>(false);

  final _webViewSettings = InAppWebViewSettings(
    transparentBackground: true,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
  );

  late final InAppWebViewInitialData _webViewData;

  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();

    final CaptchaConfig(
      :clientKey,
      :alwaysShowChallenge,
      :language,
      :useInvisibleMode,
      :hideBadge,
      :badgePosition,
      :useWebViewMode,
      :initialScale,
      :allowUserScaling,
      :maximumScale,
    ) = widget.config;

    final webCaptcha = WebSmartCaptcha(
      clientKey: clientKey,
      alwaysShowChallenge: alwaysShowChallenge,
      language: language.name,
      useInvisibleMode: useInvisibleMode,
      hideBadge: hideBadge,
      badgePosition: badgePosition.id,
      useWebViewMode: useWebViewMode,
      initialScale: initialScale.clamp(0.1, 10),
      allowUserScaling: allowUserScaling ? 'yes' : 'no',
      maximumScale: maximumScale.clamp(0.1, 10),
    );

    _webViewData = InAppWebViewInitialData(data: webCaptcha.html);
  }

  @override
  void didUpdateWidget(YandexSmartCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detachWebViewController();
      if (_webViewController != null) {
        widget.controller?._attachWebViewController(_webViewController!);
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detachWebViewController();
    _webCaptchaReady.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.config.backgroundColor != null)
          ColoredBox(color: widget.config.backgroundColor!),
        InAppWebView(
          initialData: _webViewData,
          initialSettings: _webViewSettings,
          onPermissionRequest: (_, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          shouldOverrideUrlLoading: (_, navigationAction) async {
            final url = navigationAction.request.url.toString();
            final result = widget.onNavigationRequest?.call(url) ?? true;
            return result
                ? NavigationActionPolicy.ALLOW
                : NavigationActionPolicy.CANCEL;
          },
          onConsoleMessage: (_, message) {
            debugPrint('YandexSmartCaptcha JS console message: $message');
          },
          onWebViewCreated: (controller) {
            _webCaptchaReady.value = false;
            _webViewController = controller;
            widget.controller?._attachWebViewController(controller);

            controller
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.captchaReady.name,
                  callback: (args) {
                    _webCaptchaReady.value = true;
                    widget.onCaptchaReady?.call();
                  })
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.challengeShown.name,
                  callback: (args) {
                    widget.onChallengeShown?.call();
                  })
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.challengeHidden.name,
                  callback: (args) {
                    widget.onChallengeHidden?.call();
                  })
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.networkError.name,
                  callback: (args) {
                    widget.onNetworkError?.call();
                  })
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.javaScriptError.name,
                  callback: (args) {
                    widget.onJavaScriptError?.call();
                  })
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.challengeSolved.name,
                  callback: (args) {
                    var token = args.firstOrNull?.toString();
                    token = token == 'null' ? null : token;
                    widget.onChallengeSolved(token);
                  });
          },
        ),
        if (widget.loadingIndicator != null)
          ValueListenableBuilder<bool>(
            valueListenable: _webCaptchaReady,
            child: widget.loadingIndicator,
            builder: (_, ready, child) =>
                ready ? const SizedBox.shrink() : child!,
          ),
      ],
    );
  }
}
