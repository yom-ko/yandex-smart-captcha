import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Restores native hit testing dropped by Flutter 3.47's TestPlatformDispatcher.
void setUpNativeHitTesting() {
  final dispatcher = ui.PlatformDispatcher.instance;
  final original = dispatcher.onHitTest;
  if (original != null) return;

  dispatcher.onHitTest = (request) {
    final result = HitTestResult();
    GestureBinding.instance.hitTestInView(
      result,
      request.offset,
      request.view.viewId,
    );
    return ui.HitTestResponse(
      hasPlatformView: result.path.any(
        (entry) => entry.target is NativeHitTestTarget,
      ),
    );
  };
  addTearDown(() => dispatcher.onHitTest = original);
}
