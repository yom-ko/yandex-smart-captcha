@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/native_hit_testing.dart';

void main() {
  final dispatcher = ui.PlatformDispatcher.instance;

  setUp(() {
    final original = dispatcher.onHitTest;
    dispatcher.onHitTest = null;
    addTearDown(() => dispatcher.onHitTest = original);
  });

  testWidgets(
    'native hit testing respects platform views and Flutter overlays',
    (tester) async {
      setUpNativeHitTesting();
      final callback = dispatcher.onHitTest!;
      final request = ui.HitTestRequest(
        view: tester.view,
        offset: const Offset(10, 10),
      );

      await tester.pumpWidget(const SizedBox.expand());
      expect(callback(request).hasPlatformView, isFalse);

      await tester.pumpWidget(const _NativeView());
      expect(callback(request).hasPlatformView, isTrue);

      await tester.pumpWidget(
        const Stack(
          fit: StackFit.expand,
          textDirection: TextDirection.ltr,
          children: [
            _NativeView(),
            AbsorbPointer(child: SizedBox.expand()),
          ],
        ),
      );
      expect(callback(request).hasPlatformView, isFalse);
    },
  );

  test('preserves an existing native hit-test callback', () {
    ui.HitTestResponse callback(ui.HitTestRequest request) =>
        const ui.HitTestResponse(hasPlatformView: false);
    dispatcher.onHitTest = callback;

    setUpNativeHitTesting();

    expect(dispatcher.onHitTest, same(callback));
  });
}

class _NativeView extends LeafRenderObjectWidget {
  const _NativeView();

  @override
  RenderBox createRenderObject(BuildContext context) => _NativeRenderBox();
}

class _NativeRenderBox extends RenderBox with NativeHitTestTarget {
  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) => true;
}
