import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

import '../captcha_config.dart';
import '../captcha_event.dart';
import '../captcha_platform_controller.dart';
import 'captcha_adapter_web.dart';
import 'captcha_script_loader_web.dart';

final class CaptchaAdapterController implements CaptchaPlatformController {
  static var _cCount = 0;
  static var _sCount = 0;
  final _containerId = 'package-ysc-container-${_cCount++}';
  final _styleId = 'package-ysc-spinner-hider-${_sCount++}';

  final CaptchaConfig config;
  final CaptchaAdapterCallbacks callbacks;

  JSNumber? _widgetId;
  HTMLDivElement? _container;

  bool _isDisposed = false;
  bool _scriptAcquired = false;

  @override
  final isReady = ValueNotifier<bool>(false);

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
      await _acquireScriptReference();
      _scriptAcquired = true;
    } catch (_) {
      if (!_isDisposed) callbacks.onNetworkError?.call();
      return;
    }
    if (_isDisposed) return _releaseScriptReference();

    await _waitUntilContainerConnected();
    if (_isDisposed) return _releaseScriptReference();

    final captcha = smartCaptcha;
    if (captcha == null || _container == null) {
      callbacks.onNetworkError?.call();
      _releaseScriptReference();
      return;
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

      isReady.value = true;
      callbacks.onCaptchaReady?.call();
    } catch (_) {
      callbacks.onJavaScriptError?.call();
      _releaseScriptReference();
    }
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

  Future<void> _acquireScriptReference() async {
    await acquireSmartCaptchaScript();
    if (document.getElementById(_styleId) == null) {
      final styleElement = document.createElement('style')
        ..id = _styleId
        ..textContent = '''
.SmartCaptcha-Spin, .SmartCaptcha-Spin::after {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
}''';
      document.head!.appendChild(styleElement);
    }
  }

  void _releaseScriptReference() {
    if (!_scriptAcquired) return;
    _scriptAcquired = false;
    releaseSmartCaptchaScript();
    document.getElementById(_styleId)?.remove();
  }

  @override
  Future<void> execute() async {
    if (_isDisposed || _widgetId == null || !isReady.value) return;
    final captcha = smartCaptcha;
    captcha?.execute(_widgetId!);
  }

  @override
  Future<void> reset() async {
    if (_isDisposed || _widgetId == null || !isReady.value) return;
    final captcha = smartCaptcha;
    captcha?.reset(_widgetId!);
  }

  @override
  Future<void> destroy() async {
    if (_isDisposed || _widgetId == null || !isReady.value) return;
    final captcha = smartCaptcha;
    captcha?.destroy(_widgetId!);
    _widgetId = null;
    isReady.value = false;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    if (_widgetId != null) {
      final captcha = smartCaptcha;
      captcha?.destroy(_widgetId);
      _widgetId = null;
    }

    _releaseScriptReference();
    isReady.dispose();
  }
}
