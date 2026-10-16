import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' show HTMLDivElement;

import 'captcha_adapter_controller_web.dart';

final class CaptchaAdapterWidget extends StatelessWidget {
  final CaptchaAdapterController controller;

  const CaptchaAdapterWidget({
    required this.controller,
    Color? backgroundColor,
    Widget? loadingIndicator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.contentHeight,
      child: HtmlElementView.fromTagName(
        tagName: 'div',
        onElementCreated: (element) {
          if (element case final JSObject host
              when host.isA<HTMLDivElement>()) {
            controller.attachContainer(host as HTMLDivElement);
          }
        },
      ),
      builder: (_, height, child) => SizedBox(height: height, child: child),
    );
  }
}
