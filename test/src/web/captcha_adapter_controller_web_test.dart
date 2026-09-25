@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart';
import 'package:yandex_smart_captcha/src/captcha_platform_controller.dart';
import 'package:yandex_smart_captcha/src/web/captcha_adapter_controller_web.dart';
import 'package:yandex_smart_captcha/src/web/captcha_script_loader_web.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

const _smartCaptchaScriptSelector = 'script[src="$smartCaptchaScriptUrl"]';

void main() {
  setUp(() {
    _removeSmartCaptchaScript();
    _setSmartCaptcha(null);
  });

  tearDown(() {
    _removeSmartCaptchaScript();
    _setSmartCaptcha(null);
  });

  testWidgets(
    'renders with configured options and dispatches SmartCaptcha callbacks',
    (tester) async {
      final subscriptions = <String, JSFunction>{};
      JSObject? renderOptions;
      var renderedContainerId = '';
      var executeCalls = 0;
      var resetCalls = 0;
      var destroyCalls = 0;

      final smartCaptcha = _FakeSmartCaptcha._(JSObject());
      smartCaptcha.render = ((String containerId, JSObject options) {
        renderedContainerId = containerId;
        renderOptions = options;
        return 1.toJS;
      }).toJS;
      smartCaptcha.subscribe =
          ((JSNumber _, String event, JSFunction callback) {
        subscriptions[event] = callback;
      }).toJS;
      smartCaptcha.execute = (([JSNumber? _]) {
        executeCalls++;
      }).toJS;
      smartCaptcha.reset = (([JSNumber? _]) {
        resetCalls++;
      }).toJS;
      smartCaptcha.destroy = (([JSNumber? _]) {
        destroyCalls++;
      }).toJS;
      _setSmartCaptcha(smartCaptcha._);
      _appendSmartCaptchaScript();

      String? solvedToken;
      var readyCalls = 0;
      var shownCalls = 0;
      var hiddenCalls = 0;
      var expiredCalls = 0;
      var networkErrorCalls = 0;
      var javaScriptErrorCalls = 0;

      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(
          clientKey: 'client-key',
          language: CaptchaLanguage.en,
          alwaysShowChallenge: true,
          useInvisibleMode: true,
          hideBadge: true,
          useWebViewMode: true,
        ),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (token) => solvedToken = token,
          onCaptchaReady: () => readyCalls++,
          onChallengeShown: () => shownCalls++,
          onChallengeHidden: () => hiddenCalls++,
          onTokenExpired: () => expiredCalls++,
          onNetworkError: () => networkErrorCalls++,
          onJavaScriptError: () => javaScriptErrorCalls++,
        ),
      );
      final container = document.createElement('div') as HTMLDivElement;

      controller.attachContainer(container);
      await tester.pump();

      expect(container.style.width, equals('100%'));
      expect(container.style.height, equals('100px'));
      expect(container.style.display, equals('block'));
      expect(renderedContainerId, startsWith('smart-captcha-'));
      expect(controller.isReady.value, isTrue);
      expect(readyCalls, equals(1));
      expect(networkErrorCalls, isZero);

      final options = renderOptions!;
      final optionsObject = _SmartCaptchaOptions._(options);
      expect(optionsObject.sitekey, equals('client-key'));
      expect(optionsObject.hl, equals('en'));
      expect(optionsObject.test, isTrue);
      expect(optionsObject.invisible, isTrue);
      expect(optionsObject.hideShield, isTrue);
      expect(optionsObject.webview, isFalse);

      optionsObject.callback.callAsFunction(null, 'token'.toJS);
      expect(solvedToken, equals('token'));

      subscriptions['challenge-visible']!.callAsFunction(null);
      subscriptions['challenge-hidden']!.callAsFunction(null);
      subscriptions['token-expired']!.callAsFunction(null);
      subscriptions['network-error']!.callAsFunction(null);
      subscriptions['javascript-error']!.callAsFunction(null);

      expect(shownCalls, equals(1));
      expect(hiddenCalls, equals(1));
      expect(expiredCalls, equals(1));
      expect(networkErrorCalls, equals(1));
      expect(javaScriptErrorCalls, equals(1));

      await controller.execute();
      await controller.reset();
      expect(executeCalls, equals(1));
      expect(resetCalls, equals(1));

      await controller.destroy();
      expect(destroyCalls, equals(1));
      expect(controller.isReady.value, isFalse);

      controller.dispose();
    },
  );

  testWidgets(
    'assigns a unique container ID to each controller instance',
    (tester) async {
      _appendSmartCaptchaScript();

      final firstController = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(onChallengeSolved: (_) {}),
      );
      final secondController = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(onChallengeSolved: (_) {}),
      );

      final firstContainer = document.createElement('div') as HTMLDivElement;
      final secondContainer = document.createElement('div') as HTMLDivElement;

      firstController.attachContainer(firstContainer);
      secondController.attachContainer(secondContainer);
      await tester.pump();

      expect(firstContainer.id, startsWith('smart-captcha-'));
      expect(secondContainer.id, startsWith('smart-captcha-'));
      expect(firstContainer.id, isNot(equals(secondContainer.id)));

      firstController.dispose();
      secondController.dispose();
    },
  );

  testWidgets(
    'reports an error when the SmartCaptcha API is unavailable',
    (tester) async {
      _appendSmartCaptchaScript();
      var networkErrorCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onNetworkError: () => networkErrorCalls++,
        ),
      );

      controller.attachContainer(
        document.createElement('div') as HTMLDivElement,
      );
      await tester.pump();

      expect(networkErrorCalls, equals(1));
      expect(controller.isReady.value, isFalse);
      controller.dispose();
    },
  );
}

HTMLScriptElement _appendSmartCaptchaScript() {
  final script = HTMLScriptElement()..src = smartCaptchaScriptUrl;
  document.head!.append(script);
  return script;
}

void _removeSmartCaptchaScript() {
  document.querySelector(_smartCaptchaScriptSelector)?.remove();
}

void _setSmartCaptcha(JSObject? value) {
  _globalThis.smartCaptcha = value;
}

@JS('globalThis')
external _GlobalThis get _globalThis;

extension type _GlobalThis._(JSObject _) implements JSObject {
  @JS('smartCaptcha')
  external JSObject? get smartCaptcha;

  @JS('smartCaptcha')
  external set smartCaptcha(JSObject? value);
}

extension type _FakeSmartCaptcha._(JSObject _) implements JSObject {
  external set render(JSFunction value);

  external set subscribe(JSFunction value);

  external set execute(JSFunction value);

  external set reset(JSFunction value);

  external set destroy(JSFunction value);
}

extension type _SmartCaptchaOptions._(JSObject _) implements JSObject {
  external String get sitekey;

  external String get hl;

  external bool get test;

  external bool get invisible;

  external bool get hideShield;

  external bool get webview;

  external JSFunction get callback;
}
