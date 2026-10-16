import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart';

import '../captcha_config.dart';
import '../captcha_event.dart';
import '../captcha_platform_controller.dart';
import 'captcha_adapter_web.dart';
import 'captcha_script_loader_web.dart';

final class CaptchaAdapterController implements CaptchaPlatformController {
  static const _styleId = 'package-ysc-spinner-hider';
  static var _styleUsers = 0;
  static var _cCount = 0;

  final _containerId = 'package-ysc-container-${_cCount++}';

  final CaptchaConfig config;
  final CaptchaAdapterCallbacks callbacks;

  JSNumber? _widgetId;
  HTMLDivElement? _container;

  bool _isDisposed = false;
  bool _domReady = false;

  final _isReady = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isReady => _isReady;

  CaptchaAdapterController({
    required this.config,
    required this.callbacks,
    String? baseUrl,
  });

  void attachContainer(HTMLDivElement container) {
    if (_isDisposed || _container != null) return;

    _container = container
      ..id = _containerId
      ..style.width = '100%'
      ..style.height = '100px'
      ..style.display = 'block';

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _setupDom();
    } catch (_) {
      if (!_isDisposed) callbacks.onNetworkError?.call();
      return _cleanupDom();
    }
    if (_isDisposed) return _cleanupDom();

    await _waitUntilContainerConnected();
    if (_isDisposed) return _cleanupDom();

    final captcha = smartCaptcha;
    if (captcha == null || _container == null) {
      callbacks.onNetworkError?.call();
      return _cleanupDom();
    }

    try {
      _widgetId = captcha.render(
        _containerId,
        SmartCaptchaOptions(
          sitekey: config.clientKey,
          hl: config.language.name,
          test: config.alwaysShowChallenge,
          invisible: config.useInvisibleMode,
          shieldPosition: config.badgePosition.id,
          hideShield: config.hideBadge,
          webview: false,
          callback: _onChallengeSolved.toJS,
        ),
      );

      for (final event in CaptchaEvent.values.where((e) => e.subscribable)) {
        captcha.subscribe(
          _widgetId!,
          event.id,
          (() => _handleEvent(event)).toJS,
        );
      }
    } catch (_) {
      callbacks.onJavaScriptError?.call();
      _destroyJSWidget();
      return _cleanupDom();
    }

    _isReady.value = true;
    callbacks.onCaptchaReady?.call();
  }

  void _onChallengeSolved(JSString? token) {
    if (_isDisposed) return;
    callbacks.onChallengeSolved(token?.toDart);
  }

  void _handleEvent(CaptchaEvent event) {
    if (_isDisposed) return;

    switch (event) {
      case CaptchaEvent.captchaReady:
        break;
      case CaptchaEvent.challengeShown:
        callbacks.onChallengeShown?.call();
      case CaptchaEvent.challengeHidden:
        callbacks.onChallengeHidden?.call();
      case CaptchaEvent.challengeSolved:
        break;
      case CaptchaEvent.tokenExpired:
        callbacks.onTokenExpired?.call();
      case CaptchaEvent.networkError:
        callbacks.onNetworkError?.call();
      case CaptchaEvent.javaScriptError:
        callbacks.onJavaScriptError?.call();
    }
  }

  Future<void> _waitUntilContainerConnected() async {
    while (!_isDisposed && _container?.isConnected == false) {
      final completer = Completer<void>();
      window.requestAnimationFrame(((JSNumber _) => completer.complete()).toJS);
      await completer.future;
    }
  }

  Future<void> _setupDom() async {
    await ensureCaptchaObject();
    _domReady = true;
    _styleUsers++;

    if (document.getElementById(_styleId) == null) {
      final styleElement = document.createElement('style')
        ..id = _styleId
        ..textContent = '''
.SmartCaptcha-Spin {
  display: none !important;
}''';
      document.head!.appendChild(styleElement);
    }
  }

  void _destroyJSWidget() {
    final widgetId = _widgetId;
    _widgetId = null;
    if (widgetId == null) return;

    try {
      smartCaptcha?.destroy(widgetId);
    } catch (_) {
      // A failing destroy must not break cleanup.
    }
  }

  void _cleanupDom() {
    if (!_domReady) return;
    _domReady = false;

    if (--_styleUsers == 0) {
      document.getElementById(_styleId)?.remove();
    }
  }

  void _callWidgetMethod(void Function(SmartCaptcha, JSNumber) method) {
    if (_isDisposed || _widgetId == null || !_isReady.value) return;
    final captcha = smartCaptcha;
    if (captcha == null) return;

    try {
      method(captcha, _widgetId!);
    } catch (_) {
      callbacks.onJavaScriptError?.call();
    }
  }

  @override
  Future<void> execute() async {
    _callWidgetMethod((captcha, id) => captcha.execute(id));
  }

  @override
  Future<void> reset() async {
    _callWidgetMethod((captcha, id) => captcha.reset(id));
  }

  @override
  Future<void> destroy() async {
    _callWidgetMethod((captcha, id) => captcha.destroy(id));
    if (_isDisposed || !_isReady.value) return;
    _widgetId = null;
    _isReady.value = false;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _destroyJSWidget();
    _isReady.dispose();
    _cleanupDom();
  }
}
