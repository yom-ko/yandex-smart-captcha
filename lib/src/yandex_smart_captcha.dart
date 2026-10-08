import 'package:flutter/material.dart';

import 'captcha_config.dart';
import 'captcha_platform_controller.dart';
import 'native/captcha_adapter_controller.dart'
    if (dart.library.js_interop) 'web/captcha_adapter_controller_web.dart';
import 'native/captcha_adapter_widget.dart'
    if (dart.library.js_interop) 'web/captcha_adapter_widget_web.dart';

/// A controller for [YandexSmartCaptcha].
///
/// Provides programmatic control over the SmartCaptcha JavaScript widget
/// by exposing its imperative methods.
final class CaptchaController {
  CaptchaPlatformController? _platformController;

  /// Creates a controller for [YandexSmartCaptcha].
  CaptchaController();

  /// Starts user validation.
  ///
  /// This method should be called after [YandexSmartCaptcha.onCaptchaReady] has been invoked.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#execute
  Future<void> execute() async {
    await _platformController?.execute();
  }

  /// Resets the SmartCaptcha widget to its initial state.
  ///
  /// This method should be called after [YandexSmartCaptcha.onCaptchaReady] has been invoked.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#reset
  Future<void> reset() async {
    await _platformController?.reset();
  }

  /// Removes the SmartCaptcha widget and its associated event listeners.
  ///
  /// This method should be called after [YandexSmartCaptcha.onCaptchaReady] has been invoked.
  /// Calling [execute] or otherwise interacting with the controller after calling this method
  /// will have no effect.
  ///
  /// See https://yandex.cloud/en/docs/smartcaptcha/concepts/widget-methods#destroy
  Future<void> destroy() async {
    await _platformController?.destroy();
  }

  void _attach(CaptchaPlatformController controller) {
    _platformController = controller;
  }

  void _detach(CaptchaPlatformController controller) {
    if (identical(_platformController, controller)) {
      _platformController = null;
    }
  }
}

/// A Flutter widget that configures and displays Yandex SmartCaptcha.
///
/// On Android and iOS, it hosts SmartCaptcha in a native WebView. On the web,
/// it renders SmartCaptcha into a browser DOM element at this widget's location.
/// The challenge UI / overlay are fully controlled by Yandex.
class YandexSmartCaptcha extends StatefulWidget {
  /// The configuration for this SmartCaptcha instance.
  final CaptchaConfig config;

  /// Called when the user successfully solves a SmartCaptcha challenge.
  ///
  /// Provides the verification token string. May be `null` if token extraction fails.
  final void Function(String? token) onChallengeSolved;

  /// The background color of the widget container on native platforms.
  ///
  /// Ignored on the web, where the browser document controls presentation.
  final Color? backgroundColor;

  /// A custom widget displayed while SmartCaptcha is loading on native platforms.
  ///
  /// Ignored on the web, where the browser document controls presentation.
  final Widget? loadingIndicator;

  /// Called when the SmartCaptcha script is fully loaded and initialized.
  final VoidCallback? onCaptchaReady;

  /// Called when the challenge popup becomes visible.
  final VoidCallback? onChallengeShown;

  /// Called when the challenge popup is hidden or dismissed.
  final VoidCallback? onChallengeHidden;

  /// Called when the SmartCaptcha token expires after the challenge is successfully solved.
  final VoidCallback? onTokenExpired;

  /// Called when a network error occurs while loading or executing the SmartCaptcha script.
  final VoidCallback? onNetworkError;

  /// Called when an uncaught JavaScript error occurs inside the SmartCaptcha script.
  final VoidCallback? onJavaScriptError;

  /// Intercepts navigation requests inside the native WebView.
  ///
  /// Return `true` to allow navigation, or `false` to block it.
  ///
  /// Called only for main-frame navigations away from the SmartCaptcha document.
  /// SmartCaptcha's own iframes and the initial `about:blank` or [baseUrl]
  /// document are always allowed.
  ///
  /// Ignored on the web, where the browser controls navigation.
  final bool Function(String url)? onNavigationRequest;

  /// An optional controller for programmatically interacting with the SmartCaptcha instance.
  final CaptchaController? controller;

  /// An HTTP(S) base URL used as the SmartCaptcha document origin on native platforms.
  ///
  /// Commonly used for domain validation and resolving origin policy issues.
  /// Ignored on the web, where the browser's current origin is always used.
  final String? baseUrl;

  /// Creates a Yandex SmartCaptcha widget.
  const YandexSmartCaptcha({
    required this.config,
    required this.onChallengeSolved,
    this.backgroundColor,
    this.loadingIndicator,
    this.onCaptchaReady,
    this.onChallengeShown,
    this.onChallengeHidden,
    this.onTokenExpired,
    this.onNetworkError,
    this.onJavaScriptError,
    this.onNavigationRequest,
    this.controller,
    this.baseUrl,
    super.key,
  });

  @override
  State<YandexSmartCaptcha> createState() => _YandexSmartCaptchaState();
}

class _YandexSmartCaptchaState extends State<YandexSmartCaptcha> {
  late final CaptchaAdapterCallbacks _callbacks;
  late CaptchaAdapterController _adapterController;

  @override
  void initState() {
    super.initState();

    _callbacks = CaptchaAdapterCallbacks(
      onChallengeSolved: widget.onChallengeSolved,
    );
    _syncCallbacks();

    _adapterController = _createAdapterController();
    widget.controller?._attach(_adapterController);
  }

  @override
  void didUpdateWidget(YandexSmartCaptcha oldWidget) {
    super.didUpdateWidget(oldWidget);

    _syncCallbacks();

    final configChanged = oldWidget.config != widget.config ||
        oldWidget.baseUrl != widget.baseUrl;
    final controllerChanged = oldWidget.controller != widget.controller;

    if (configChanged) {
      final newAdapterController = _createAdapterController();
      final oldAdapterController = _adapterController;

      oldWidget.controller?._detach(oldAdapterController);
      oldAdapterController.dispose();

      _adapterController = newAdapterController;
      widget.controller?._attach(_adapterController);
    } else if (controllerChanged) {
      oldWidget.controller?._detach(_adapterController);
      widget.controller?._attach(_adapterController);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(_adapterController);
    _adapterController.dispose();

    super.dispose();
  }

  void _syncCallbacks() {
    _callbacks.update(
      onChallengeSolved: widget.onChallengeSolved,
      onCaptchaReady: widget.onCaptchaReady,
      onChallengeShown: widget.onChallengeShown,
      onChallengeHidden: widget.onChallengeHidden,
      onTokenExpired: widget.onTokenExpired,
      onNetworkError: widget.onNetworkError,
      onJavaScriptError: widget.onJavaScriptError,
      onNavigationRequest: widget.onNavigationRequest,
    );
  }

  CaptchaAdapterController _createAdapterController() =>
      CaptchaAdapterController(
        config: widget.config,
        callbacks: _callbacks,
        baseUrl: widget.baseUrl,
      );

  @override
  Widget build(BuildContext context) => CaptchaAdapterWidget(
        key: ObjectKey(_adapterController),
        controller: _adapterController,
        backgroundColor: widget.backgroundColor,
        loadingIndicator: widget.loadingIndicator,
      );
}
