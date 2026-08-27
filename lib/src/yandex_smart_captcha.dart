import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'captcha_config.dart';
import 'captcha_event.dart';
import 'web_smart_captcha.dart';

/// The controller for the [YandexSmartCaptcha] widget.
/// It is primarily designed to manage the underlying Web SmartCaptcha hosted in the WebView.
final class CaptchaController {
  InAppWebViewController? _inAppWebViewController;
  VoidCallback? _onControllerReady;

  /// Returns `true` if the underlying WebView controller is fully initialized.
  bool get isReady => _inAppWebViewController != null;

  /// Starts user validation and is commonly used to trigger the invisible CAPTCHA test
  /// during events like when the user clicks the submit button on a form.
  Future<dynamic> execute() async {
    return _inAppWebViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.execute(window.$widgetIdProp)',
    );
  }

  /// Removes the Web SmartCaptcha JavaScript widgets hosted in the WebView,
  /// along with any listeners they create.
  Future<dynamic> destroy() async {
    return _inAppWebViewController?.evaluateJavascript(
      source: 'window.smartCaptcha.destroy(window.$widgetIdProp)',
    );
  }

  /// Sets a callback to be invoked when the underlying WebView controller is ready.
  // ignore: use_setters_to_change_properties
  void setReadyCallback(VoidCallback readyCallback) {
    _onControllerReady = readyCallback;
  }

  void _setController(InAppWebViewController controller) {
    _inAppWebViewController = controller;
    _onControllerReady?.call();
  }
}

/// The Flutter widget for Yandex SmartCaptcha.
/// It essentially wraps the WebView that executes the Web SmartCaptcha HTML/JavaScript code.
class YandexSmartCaptcha extends StatefulWidget {
  /// The configuration for the [YandexSmartCaptcha] widget.
  final CaptchaConfig config;

  /// Called when the user successfully solves a CAPTCHA challenge. The callback usually receives
  /// a token string as an argument. WARNING: In very rare cases, if something goes completely wrong,
  /// the passed value may be `null`.
  final void Function(String? token) onChallengeSolved;

  /// The controller for the [YandexSmartCaptcha] widget.
  final CaptchaController? controller;

  /// Called when the CAPTCHA is loaded and ready.
  final VoidCallback? onCaptchaLoaded;

  /// Called when the CAPTCHA challenge popup is shown.
  final VoidCallback? onChallengeShown;

  /// Called when the CAPTCHA challenge popup is hidden.
  final VoidCallback? onChallengeHidden;

  /// Called when a network error is encountered.
  final VoidCallback? onNetworkError;

  /// Called when a JavaScript error is encountered.
  final VoidCallback? onJavaScriptError;

  /// Called when a navigation request is made in the underlying WebView. Return `false`
  /// from the callback to block the request; otherwise, return `true` to allow it.
  final bool Function(String url)? onNavigationRequest;

  /// A widget to display while the Web SmartCaptcha is loading.
  final Widget? loadingIndicator;

  const YandexSmartCaptcha({
    required this.config,
    required this.onChallengeSolved,
    this.controller,
    this.onCaptchaLoaded,
    this.onChallengeShown,
    this.onChallengeHidden,
    this.onNetworkError,
    this.onJavaScriptError,
    this.onNavigationRequest,
    this.loadingIndicator,
    super.key,
  });

  @override
  State<YandexSmartCaptcha> createState() => _YandexSmartCaptchaState();
}

class _YandexSmartCaptchaState extends State<YandexSmartCaptcha> {
  late final InAppWebViewSettings _webViewSettings;
  late final InAppWebViewInitialData _webViewData;
  late final CaptchaController? _captchaController;

  final _webCaptchaLoaded = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    _webViewSettings = InAppWebViewSettings(
      transparentBackground: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
    );

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

    _captchaController = widget.controller;
  }

  @override
  void dispose() {
    _webCaptchaLoaded.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.config.backgroundColor != null)
          SizedBox.expand(
            child: ColoredBox(color: widget.config.backgroundColor!),
          ),
        if (widget.loadingIndicator != null) ...[
          ValueListenableBuilder(
            valueListenable: _webCaptchaLoaded,
            child: widget.loadingIndicator,
            builder: (_, loaded, child) =>
                loaded ? const SizedBox.shrink() : child!,
          ),
        ],
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
            _captchaController?._setController(controller);

            controller
              ..addJavaScriptHandler(
                  handlerName: CaptchaEvent.captchaLoaded.name,
                  callback: (args) {
                    _webCaptchaLoaded.value = true;
                    widget.onCaptchaLoaded?.call();
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
      ],
    );
  }
}
