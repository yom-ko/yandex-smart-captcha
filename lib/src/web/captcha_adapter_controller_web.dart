import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

import '../captcha_config.dart';
import '../captcha_event.dart';
import '../captcha_platform_controller.dart';
import 'captcha_adapter_web.dart';
import 'captcha_script_loader_web.dart';

final class CaptchaAdapterController implements CaptchaPlatformController {
  static var _nextId = 0;
  static final _containerId = 'smart-captcha-${_nextId++}';

  final CaptchaConfig config;
  final CaptchaAdapterCallbacks callbacks;
  final String? baseUrl;

  @override
  final isReady = ValueNotifier<bool>(false);

  JSNumber? _widgetId;
  HTMLDivElement? _container;

  bool _isDisposed = false;
  bool _scriptAcquired = false;

  CaptchaAdapterController({
    required this.config,
    required this.callbacks,
    this.baseUrl,
  });

  void attachContainer(HTMLDivElement container) {
    if (_isDisposed || _container != null) return;

    _container = container
      ..id = _containerId
      ..style.width = '100%'
      ..style.height = '100px'
      ..style.display = 'block';

    final styleId = 'hide-native-spinner';
    if (document.getElementById(styleId) == null) {
      final styleElement = document.createElement('style') as HTMLStyleElement;
      styleElement.id = styleId;
      styleElement.textContent = '''
      .SmartCaptcha-Spin, .SmartCaptcha-Spin::after {
        display: none !important;
        visibility: hidden !important;
        opacity: 0 !important;
      }
    ''';
      document.head?.appendChild(styleElement);
    }

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await acquireSmartCaptchaScript();
      _scriptAcquired = true;
      if (_isDisposed) {
        _releaseScriptReference();
        return;
      }

      final captcha = smartCaptcha;
      final container = _container;
      if (captcha == null || container == null) {
        callbacks.onNetworkError?.call();
        _releaseScriptReference();
        return;
      }

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
      callbacks.onNetworkError?.call();
      _releaseScriptReference();
    }
  }

  void _onChallengeSolved(JSString? token) {
    callbacks.onChallengeSolved(token?.toDart);
  }

  void _handleEvent(CaptchaEvent event) {
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

  @override
  Future<void> execute() async {
    if (_isDisposed || _widgetId == null) return;
    final captcha = smartCaptcha;
    captcha?.execute(_widgetId!);
  }

  @override
  Future<void> reset() async {
    if (_isDisposed || _widgetId == null) return;
    final captcha = smartCaptcha;
    captcha?.reset(_widgetId!);
  }

  @override
  Future<void> destroy() async {
    if (_isDisposed || _widgetId == null) return;
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
      captcha?.destroy(_widgetId!);
    }

    _releaseScriptReference();
    isReady.dispose();
  }

  void _releaseScriptReference() {
    if (!_scriptAcquired) return;
    _scriptAcquired = false;
    releaseSmartCaptchaScript();
  }
}
