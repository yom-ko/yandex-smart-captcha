import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// A fake [PlatformInAppWebViewController] that records JavaScript handler
/// registrations and evaluated JavaScript sources, allowing tests to
/// simulate WebView events without a native `flutter_inappwebview`
/// platform implementation.
class PlatformInAppWebViewControllerFake
    extends PlatformInAppWebViewController {
  PlatformInAppWebViewControllerFake()
      : super.implementation(
          const PlatformInAppWebViewControllerCreationParams(id: 'fake'),
        );

  final Map<String, JavaScriptHandlerCallback> _handlers = {};

  /// The JavaScript sources passed to [evaluateJavascript], in call order.
  final List<String> evaluatedJavascriptSources = [];

  /// Simulates the WebView invoking the handler previously registered for
  /// [handlerName] (as if `window.flutter_inappwebview.callHandler` was
  /// called from JavaScript) with the given [args].
  dynamic emit(String handlerName, [List<dynamic> args = const []]) {
    return _handlers[handlerName]?.call(args);
  }

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    _handlers[handlerName] = callback;
  }

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    evaluatedJavascriptSources.add(source);
    return null;
  }
}

/// A fake [PlatformInAppWebViewWidget] that immediately invokes
/// [PlatformInAppWebViewWidgetCreationParams.onWebViewCreated] with a
/// [PlatformInAppWebViewControllerFake], then renders an empty placeholder
/// in place of the real native WebView.
class PlatformInAppWebViewWidgetFake extends PlatformInAppWebViewWidget {
  /// The fake platform controller created for this widget instance.
  final controller = PlatformInAppWebViewControllerFake();

  PlatformInAppWebViewWidgetFake(super.params) : super.implementation() {
    Future.microtask(() {
      params.onWebViewCreated?.call(
        InAppWebViewController.fromPlatform(platform: controller),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    return InAppWebViewController.fromPlatform(platform: controller) as T;
  }

  @override
  void dispose() {}
}

/// A fake [InAppWebViewPlatform] that returns [PlatformInAppWebViewWidgetFake]
/// instances, allowing widgets that embed [InAppWebView] to be exercised in
/// widget tests without registering a native platform implementation.
class InAppWebViewPlatformFake extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    return PlatformInAppWebViewWidgetFake(params);
  }
}
