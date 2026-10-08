import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../captcha_event.dart';
import 'captcha_adapter_controller.dart';

final class CaptchaAdapterWidget extends StatelessWidget {
  final CaptchaAdapterController controller;
  final Color? backgroundColor;
  final Widget? loadingIndicator;

  const CaptchaAdapterWidget({
    required this.controller,
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
          shouldOverrideUrlLoading: (_, action) async =>
              controller.decideNavigation(action),
          onConsoleMessage: (_, message) {
            debugPrint('YandexSmartCaptcha JS console message: $message');
          },
          onWebViewCreated: (webViewController) {
            controller.isReady.value = false;
            controller.isLoaded.value = false;
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
            valueListenable: controller.isLoaded,
            child: loadingIndicator,
            builder: (_, isLoaded, child) =>
                isLoaded ? const SizedBox.shrink() : child!,
          ),
      ],
    );
  }
}
