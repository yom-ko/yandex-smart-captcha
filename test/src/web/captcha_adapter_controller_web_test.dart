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
const _spinnerStyleSelector = 'style[id^="package-ysc-spinner-hider-"]';

void main() {
  setUp(() {
    _removeSmartCaptchaScript();
    _removeSpinnerStyles();
    _setSmartCaptcha(null);
  });

  tearDown(() {
    _removeSmartCaptchaScript();
    _removeSpinnerStyles();
    _removeAttachedContainers();
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
      addTearDown(controller.dispose);
      final container = _createContainer();

      controller.attachContainer(container);
      await tester.pump();

      expect(container.style.width, equals('100%'));
      expect(container.style.height, equals('100px'));
      expect(container.style.display, equals('block'));
      expect(renderedContainerId, startsWith('package-ysc-container-'));
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

      await controller.execute();
      await controller.reset();
      await controller.destroy();

      expect(executeCalls, equals(1));
      expect(resetCalls, equals(1));
      expect(destroyCalls, equals(1));

      controller.dispose();
    },
  );

  testWidgets(
    'adds spinner CSS after script acquisition and removes it on dispose',
    (tester) async {
      _appendSmartCaptchaScript();
      _installReadySmartCaptcha();

      final controller = _createController();
      addTearDown(controller.dispose);

      controller.attachContainer(_createContainer());

      expect(_spinnerStyleCount, isZero);

      await tester.pump();

      expect(controller.isReady.value, isTrue);
      expect(_spinnerStyleCount, equals(1));
      expect(
        _firstSpinnerStyle!.textContent,
        contains('.SmartCaptcha-Spin'),
      );

      controller.dispose();

      expect(_spinnerStyleCount, isZero);
    },
  );

  testWidgets(
    'disposing one controller keeps another controller spinner CSS active',
    (tester) async {
      _appendSmartCaptchaScript();
      _installReadySmartCaptcha();

      final firstController = _createController();
      final secondController = _createController();
      addTearDown(firstController.dispose);
      addTearDown(secondController.dispose);

      firstController.attachContainer(_createContainer());
      secondController.attachContainer(_createContainer());
      await tester.pump();

      expect(_spinnerStyleCount, equals(2));

      firstController.dispose();

      expect(_spinnerStyleCount, equals(1));
      expect(document.querySelector(_smartCaptchaScriptSelector), isNotNull);

      secondController.dispose();

      expect(_spinnerStyleCount, isZero);
      expect(document.querySelector(_smartCaptchaScriptSelector), isNull);
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
      addTearDown(firstController.dispose);
      final secondController = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(onChallengeSolved: (_) {}),
      );
      addTearDown(secondController.dispose);

      final firstContainer = _createContainer();
      final secondContainer = _createContainer();

      firstController.attachContainer(firstContainer);
      secondController.attachContainer(secondContainer);
      await tester.pump();

      expect(firstContainer.id, startsWith('package-ysc-container-'));
      expect(secondContainer.id, startsWith('package-ysc-container-'));
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
      addTearDown(controller.dispose);

      controller.attachContainer(_createContainer());
      await tester.pump();

      expect(networkErrorCalls, equals(1));
      expect(controller.isReady.value, isFalse);
      expect(_spinnerStyleCount, isZero);
      controller.dispose();
    },
  );

  testWidgets(
    'reports a network error when the SmartCaptcha script fails to load',
    (tester) async {
      var networkErrorCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onNetworkError: () => networkErrorCalls++,
        ),
      );
      addTearDown(controller.dispose);

      controller.attachContainer(_createContainer());
      document
          .querySelector(_smartCaptchaScriptSelector)!
          .dispatchEvent(Event('error'));
      await tester.pump();

      expect(networkErrorCalls, equals(1));
      expect(controller.isReady.value, isFalse);
      expect(_spinnerStyleCount, isZero);
      controller.dispose();
    },
  );

  testWidgets(
    'cleans up on dispose without calling SmartCaptcha destroy without an ID',
    (tester) async {
      _appendSmartCaptchaScript();
      final destroyedIds = <int>[];
      _installReadySmartCaptcha(onDestroy: (id) {
        if (id == null || destroyedIds.contains(id)) {
          throw StateError('Tried to call methods of destroyed widget');
        }
        destroyedIds.add(id);
      });

      final controller = _createController();
      addTearDown(controller.dispose);
      controller.attachContainer(_createContainer());
      await tester.pump();
      expect(controller.isReady.value, isTrue);

      expect(controller.dispose, returnsNormally);

      expect(destroyedIds, equals([1]));
      expect(document.querySelector(_smartCaptchaScriptSelector), isNull);
      expect(_globalThis.smartCaptcha, isNull);
    },
  );

  testWidgets(
    'waits for the container to be attached to the document before rendering',
    (tester) async {
      _appendSmartCaptchaScript();
      final renderedWhileConnected = <bool>[];
      _installReadySmartCaptcha(onRender: (containerId) {
        renderedWhileConnected
            .add(document.getElementById(containerId) != null);
      });

      final controller = _createController();
      addTearDown(controller.dispose);
      final container = document.createElement('div') as HTMLDivElement;

      controller.attachContainer(container);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      expect(renderedWhileConnected, isEmpty);
      expect(controller.isReady.value, isFalse);

      document.body!.append(container);
      addTearDown(() => container.remove());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      expect(renderedWhileConnected, equals([true]));
      expect(controller.isReady.value, isTrue);
    },
  );

  testWidgets(
    'stops waiting for the container when disposed before it is attached',
    (tester) async {
      _appendSmartCaptchaScript();
      var renderCalls = 0;
      _installReadySmartCaptcha(onRender: (_) => renderCalls++);

      final controller = _createController();
      addTearDown(controller.dispose);

      controller.attachContainer(
        document.createElement('div') as HTMLDivElement,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      controller.dispose();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );

      expect(renderCalls, isZero);
      expect(document.querySelector(_smartCaptchaScriptSelector), isNull);
    },
  );
}

final _attachedContainers = <HTMLDivElement>[];

HTMLDivElement _createContainer() {
  final container = document.createElement('div') as HTMLDivElement;
  document.body!.append(container);
  _attachedContainers.add(container);
  return container;
}

void _removeAttachedContainers() {
  for (final container in _attachedContainers) {
    container.remove();
  }
  _attachedContainers.clear();
}

HTMLScriptElement _appendSmartCaptchaScript() {
  final script = HTMLScriptElement()..src = smartCaptchaScriptUrl;
  document.head!.append(script);
  return script;
}

void _removeSmartCaptchaScript() {
  document.querySelector(_smartCaptchaScriptSelector)?.remove();
}

int get _spinnerStyleCount =>
    document.querySelectorAll(_spinnerStyleSelector).length;

Element? get _firstSpinnerStyle =>
    document.querySelector(_spinnerStyleSelector);

void _removeSpinnerStyles() {
  var style = _firstSpinnerStyle;
  while (style != null) {
    style.remove();
    style = _firstSpinnerStyle;
  }
}

CaptchaAdapterController _createController() => CaptchaAdapterController(
      config: const CaptchaConfig(clientKey: 'client-key'),
      callbacks: CaptchaAdapterCallbacks(onChallengeSolved: (_) {}),
    );

void _installReadySmartCaptcha({
  void Function(String containerId)? onRender,
  void Function(int? widgetId)? onDestroy,
}) {
  var nextWidgetId = 0;
  final smartCaptcha = _FakeSmartCaptcha._(JSObject());
  smartCaptcha.render = ((String containerId, JSObject _) {
    onRender?.call(containerId);
    return (++nextWidgetId).toJS;
  }).toJS;
  smartCaptcha.subscribe = ((JSNumber _, String __, JSFunction ___) {}).toJS;
  smartCaptcha.execute = (([JSNumber? _]) {}).toJS;
  smartCaptcha.reset = (([JSNumber? _]) {}).toJS;
  smartCaptcha.destroy = (([JSNumber? id]) {
    onDestroy?.call(id?.toDartInt);
  }).toJS;
  _setSmartCaptcha(smartCaptcha._);
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
