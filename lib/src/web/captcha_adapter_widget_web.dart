import 'package:flutter/widgets.dart';
import 'package:web/web.dart';

import '../captcha_platform_controller.dart';
import 'captcha_adapter_controller_web.dart';

final class CaptchaAdapterWidget extends StatelessWidget {
  final CaptchaAdapterController controller;
  final CaptchaAdapterCallbacks callbacks;

  const CaptchaAdapterWidget({
    required this.controller,
    required this.callbacks,
    Color? backgroundColor,
    Widget? loadingIndicator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (element) {
        if (element case final HTMLDivElement container) {
          controller.attachContainer(container);
        }
      },
    );
  }
}
