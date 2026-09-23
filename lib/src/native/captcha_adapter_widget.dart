import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../captcha_event.dart';
import '../captcha_platform_controller.dart';
import 'captcha_adapter_controller.dart';

final class CaptchaAdapterWidget extends StatelessWidget {
  final CaptchaAdapterController controller;
  final CaptchaAdapterCallbacks callbacks;
  final Color? backgroundColor;
  final Widget? loadingIndicator;

  const CaptchaAdapterWidget({
    required this.controller,
    required this.callbacks,
    this.backgroundColor,
    this.loadingIndicator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (backgroundColor != null) ColoredBox(color: backgroundColor!),
        InAppWebView(
          initialData: controller.initialData,
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          onPermissionRequest: (_, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          shouldOverrideUrlLoading: (_, navigationAction) async {
            final url = navigationAction.request.url.toString();
            final result = callbacks.onNavigationRequest?.call(url) ?? true;
            return result
                ? NavigationActionPolicy.ALLOW
                : NavigationActionPolicy.CANCEL;
          },
          onConsoleMessage: (_, message) {
            debugPrint('YandexSmartCaptcha JS console message: $message');
          },
          onWebViewCreated: (webViewController) {
            controller.isReady.value = false;
            controller.attachWebViewController(webViewController);

            for (final event in CaptchaEvent.values) {
              webViewController.addJavaScriptHandler(
                handlerName: event.name,
                callback: (args) {
                  controller.handleEvent(event, args);
                },
              );
            }
          },
        ),
        if (loadingIndicator != null)
          ValueListenableBuilder<bool>(
            valueListenable: controller.isReady,
            child: loadingIndicator,
            builder: (_, ready, child) =>
                ready ? const SizedBox.shrink() : child!,
          ),
      ],
    );
  }
}
