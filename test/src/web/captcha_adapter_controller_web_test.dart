@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart';
import 'package:yandex_smart_captcha/src/captcha_platform_controller.dart';
import 'package:yandex_smart_captcha/src/web/captcha_adapter_controller_web.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

import '../../mocks/script_network_blocker_web.dart';

const _captchaScriptUrl = 'https://smartcaptcha.cloud.yandex.ru/captcha.js';
const _captchaScriptSelector = 'script[src="$_captchaScriptUrl"]';
const _spinnerStyleSelector = 'style#package-ysc-spinner-hider';
const _frameBudget = 300;

void main() {
  setUpAll(blockScriptNetwork);
  tearDownAll(restoreScriptNetwork);

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

      final target = container.firstElementChild! as HTMLDivElement;
      expect(container.style.width, equals('100%'));
      expect(container.style.height, equals('100%'));
      expect(target.getAttribute('style'), isNull);
      expect(renderedContainerId, equals(target.id));
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
      _installReadySmartCaptcha();

      final controller = _createController();
      addTearDown(controller.dispose);
      final spinner = document.createElement('div')
        ..className = 'SmartCaptcha-Spin';
      document.body!.append(spinner);
      addTearDown(() => spinner.remove());

      controller.attachContainer(_createContainer());

      expect(_spinnerStyleCount, isZero);

      await tester.pump();

      expect(controller.isReady.value, isTrue);
      expect(_spinnerStyleCount, equals(1));
      expect(window.getComputedStyle(spinner).display, equals('none'));

      controller.dispose();

      expect(_spinnerStyleCount, isZero);
      expect(window.getComputedStyle(spinner).display, isNot(equals('none')));
    },
  );

  testWidgets(
    'shares one spinner style between controllers until the last one is disposed',
    (tester) async {
      _installReadySmartCaptcha();

      final firstController = _createController();
      final secondController = _createController();
      addTearDown(firstController.dispose);
      addTearDown(secondController.dispose);

      firstController.attachContainer(_createContainer());
      secondController.attachContainer(_createContainer());
      await tester.pump();

      expect(_spinnerStyleCount, equals(1));

      firstController.dispose();

      expect(_spinnerStyleCount, equals(1));

      secondController.dispose();

      expect(_spinnerStyleCount, isZero);
    },
  );

  testWidgets(
    'assigns a unique container ID to each controller instance',
    (tester) async {
      _installReadySmartCaptcha();

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

      final firstTargetId = firstContainer.firstElementChild!.id;
      final secondTargetId = secondContainer.firstElementChild!.id;
      expect(firstTargetId, startsWith('package-ysc-container-'));
      expect(secondTargetId, startsWith('package-ysc-container-'));
      expect(firstTargetId, isNot(equals(secondTargetId)));

      firstController.dispose();
      secondController.dispose();
    },
  );

  testWidgets(
    'reports an error when the SmartCaptcha API is unavailable',
    (tester) async {
      _installReadySmartCaptcha();
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
      _setSmartCaptcha(null);
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
          .querySelector(_captchaScriptSelector)!
          .dispatchEvent(Event('error'));
      await tester.pump();

      expect(networkErrorCalls, equals(1));
      expect(controller.isReady.value, isFalse);
      expect(_spinnerStyleCount, isZero);
      expect(document.querySelector(_captchaScriptSelector), isNull);
    },
  );

  testWidgets(
    'keeps the loaded script and SmartCaptcha for later controllers after dispose',
    (tester) async {
      final firstController = _createController();
      addTearDown(firstController.dispose);

      firstController.attachContainer(_createContainer());
      _installReadySmartCaptcha();
      document
          .querySelector(_captchaScriptSelector)!
          .dispatchEvent(Event('load'));
      await tester.pump();

      expect(firstController.isReady.value, isTrue);

      final smartCaptcha = _globalThis.smartCaptcha;
      firstController.dispose();

      expect(
          document.querySelectorAll(_captchaScriptSelector).length, equals(1));
      expect(_globalThis.smartCaptcha, same(smartCaptcha));
      expect(_spinnerStyleCount, isZero);

      final secondController = _createController();
      addTearDown(secondController.dispose);
      secondController.attachContainer(_createContainer());
      await tester.pump();

      expect(secondController.isReady.value, isTrue);
      expect(
          document.querySelectorAll(_captchaScriptSelector).length, equals(1));
    },
  );

  testWidgets(
    'cleans up on dispose without calling SmartCaptcha destroy without an ID',
    (tester) async {
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
      expect(_spinnerStyleCount, isZero);
    },
  );

  testWidgets(
    'waits for the container to be attached to the document before rendering',
    (tester) async {
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
      var renderCalls = 0;
      var destroyCalls = 0;
      _installReadySmartCaptcha(
        onRender: (_) => renderCalls++,
        onDestroy: (_) => destroyCalls++,
      );

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
      expect(destroyCalls, isZero);
    },
  );

  testWidgets(
    'reports a JavaScript error and does not become ready when rendering throws',
    (tester) async {
      _installReadySmartCaptcha(onRender: (_) => throw StateError('render'));
      var readyCalls = 0;
      var javaScriptErrorCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onCaptchaReady: () => readyCalls++,
          onJavaScriptError: () => javaScriptErrorCalls++,
        ),
      );
      addTearDown(controller.dispose);

      controller.attachContainer(_createContainer());
      await tester.pump();

      expect(javaScriptErrorCalls, equals(1));
      expect(readyCalls, isZero);
      expect(controller.isReady.value, isFalse);
      expect(_spinnerStyleCount, isZero);
    },
  );

  testWidgets(
    'destroys the rendered widget and is not ready when subscribing throws',
    (tester) async {
      final destroyedIds = <int>[];
      _installReadySmartCaptcha(
        onSubscribe: () => throw StateError('subscribe'),
        onDestroy: (id) => destroyedIds.add(id!),
      );
      var readyCalls = 0;
      var javaScriptErrorCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onCaptchaReady: () => readyCalls++,
          onJavaScriptError: () => javaScriptErrorCalls++,
        ),
      );
      addTearDown(controller.dispose);

      controller.attachContainer(_createContainer());
      await tester.pump();

      expect(destroyedIds, equals([1]));
      expect(javaScriptErrorCalls, equals(1));
      expect(readyCalls, isZero);
      expect(controller.isReady.value, isFalse);

      controller.dispose();
      expect(destroyedIds, equals([1]));
    },
  );

  testWidgets(
    'stays ready and keeps its spinner style when the onCaptchaReady callback throws',
    (tester) async {
      _installReadySmartCaptcha();
      var javaScriptErrorCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onCaptchaReady: () => throw StateError('callback'),
          onJavaScriptError: () => javaScriptErrorCalls++,
        ),
      );
      addTearDown(controller.dispose);

      final uncaughtErrors = <Object>[];
      runZonedGuarded(
        () => controller.attachContainer(_createContainer()),
        (error, _) => uncaughtErrors.add(error),
      );
      await tester.pump();

      expect(uncaughtErrors, hasLength(1));
      expect(uncaughtErrors.single, isA<StateError>());
      expect(controller.isReady.value, isTrue);
      expect(javaScriptErrorCalls, isZero);
      expect(_spinnerStyleCount, equals(1));
    },
  );

  testWidgets(
    'reports JavaScript errors thrown by controller methods',
    (tester) async {
      var destroyCalls = 0;
      _installReadySmartCaptcha(
        onExecute: () => throw StateError('execute'),
        onReset: () => throw StateError('reset'),
        onDestroy: (_) {
          destroyCalls++;
          throw StateError('destroy');
        },
      );
      var javaScriptErrorCalls = 0;
      final controller = CaptchaAdapterController(
        config: const CaptchaConfig(clientKey: 'client-key'),
        callbacks: CaptchaAdapterCallbacks(
          onChallengeSolved: (_) {},
          onJavaScriptError: () => javaScriptErrorCalls++,
        ),
      );
      addTearDown(controller.dispose);
      controller.attachContainer(_createContainer());
      await tester.pump();
      expect(controller.isReady.value, isTrue);

      await expectLater(controller.execute(), completes);
      await expectLater(controller.reset(), completes);
      expect(javaScriptErrorCalls, equals(2));
      expect(controller.isReady.value, isTrue);

      await expectLater(controller.destroy(), completes);
      expect(javaScriptErrorCalls, equals(3));
      expect(controller.isReady.value, isFalse);

      controller.dispose();
      expect(destroyCalls, equals(1));
    },
  );

  testWidgets(
    'completes disposal and releases resources when SmartCaptcha destroy throws',
    (tester) async {
      _installReadySmartCaptcha(onDestroy: (_) => throw StateError('destroy'));
      final controller = _createController();
      addTearDown(controller.dispose);
      controller.attachContainer(_createContainer());
      await tester.pump();
      expect(controller.isReady.value, isTrue);

      expect(controller.dispose, returnsNormally);

      expect(_spinnerStyleCount, isZero);
    },
  );

  testWidgets(
    'reserves the default height, or a minimal one in the invisible mode, up front',
    (tester) async {
      final visible = _createController();
      addTearDown(visible.dispose);
      final invisible = CaptchaAdapterController(
        config: const CaptchaConfig(
          clientKey: 'client-key',
          useInvisibleMode: true,
        ),
        callbacks: CaptchaAdapterCallbacks(onChallengeSolved: (_) {}),
      );
      addTearDown(invisible.dispose);

      expect(visible.contentHeight.value, equals(118));
      expect(invisible.contentHeight.value, equals(1));
    },
  );

  testWidgets(
    'follows the height of the container controlled by the script',
    (tester) async {
      _installReadySmartCaptcha(
        onRender: (containerId) => _setHeight(containerId, 150),
      );
      final controller = _createController();
      addTearDown(controller.dispose);
      final host = _createContainer();

      controller.attachContainer(host);
      await _waitFor(tester, () => controller.contentHeight.value == 150);
      expect(controller.contentHeight.value, equals(150));

      _setHeight(host.firstElementChild!.id, 80.5);
      await _waitFor(tester, () => controller.contentHeight.value == 80.5);
      expect(controller.contentHeight.value, equals(80.5));
    },
  );

  testWidgets(
    'keeps the last height while the container is empty',
    (tester) async {
      _installReadySmartCaptcha(
        onRender: (containerId) => _setHeight(containerId, 150),
      );
      final controller = _createController();
      addTearDown(controller.dispose);
      final host = _createContainer();

      controller.attachContainer(host);
      await _waitFor(tester, () => controller.contentHeight.value == 150);

      _setHeight(host.firstElementChild!.id, 0);
      await _settleFrames(tester);

      expect(controller.contentHeight.value, equals(150));
    },
  );

  testWidgets(
    'ignores the initial empty container before SmartCaptcha renders',
    (tester) async {
      _installReadySmartCaptcha();
      final controller = _createController();
      addTearDown(controller.dispose);

      controller.attachContainer(_createContainer());
      await _settleFrames(tester);

      expect(controller.isReady.value, isTrue);
      expect(controller.contentHeight.value, equals(118));
    },
  );

  testWidgets(
    'stops following the container height after disposal',
    (tester) async {
      _installReadySmartCaptcha(
        onRender: (containerId) => _setHeight(containerId, 150),
      );
      final controller = _createController();
      addTearDown(controller.dispose);
      final host = _createContainer();

      controller.attachContainer(host);
      await _waitFor(tester, () => controller.contentHeight.value == 150);
      expect(controller.contentHeight.value, equals(150));

      controller.dispose();
      _setHeight(host.firstElementChild!.id, 80);
      await _settleFrames(tester);

      expect(controller.contentHeight.value, equals(150));
    },
  );
}

void _setHeight(String containerId, double height) {
  (document.getElementById(containerId)! as HTMLElement).style.height =
      '${height}px';
}

// ResizeObserver callbacks are delivered by real browser frames, which only
// advance outside the fake-async zone of testWidgets. The wait is bounded by
// a frame budget rather than a timeout, so it never depends on wall-clock time.
Future<void> _waitFor(WidgetTester tester, bool Function() condition) {
  return tester.runAsync(() async {
    for (var i = 0; i < _frameBudget && !condition(); i++) {
      await _nextFrame();
    }
  });
}

// Observers run right after the animation frame callbacks of the same frame,
// so two frames guarantee that earlier DOM changes have been reported.
Future<void> _settleFrames(WidgetTester tester) {
  return tester.runAsync(() async {
    await _nextFrame();
    await _nextFrame();
  });
}

Future<void> _nextFrame() {
  final frame = Completer<void>();
  window.requestAnimationFrame(((JSNumber _) => frame.complete()).toJS);
  return frame.future;
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

void _removeSmartCaptchaScript() {
  document.querySelector(_captchaScriptSelector)?.remove();
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
  void Function()? onSubscribe,
  void Function()? onExecute,
  void Function()? onReset,
  void Function(int? widgetId)? onDestroy,
}) {
  var nextWidgetId = 0;
  final smartCaptcha = _FakeSmartCaptcha._(JSObject());
  smartCaptcha.render = ((String containerId, JSObject _) {
    onRender?.call(containerId);
    return (++nextWidgetId).toJS;
  }).toJS;
  smartCaptcha.subscribe = ((JSNumber _, String __, JSFunction ___) {
    onSubscribe?.call();
  }).toJS;
  smartCaptcha.execute = (([JSNumber? _]) {
    onExecute?.call();
  }).toJS;
  smartCaptcha.reset = (([JSNumber? _]) {
    onReset?.call();
  }).toJS;
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
