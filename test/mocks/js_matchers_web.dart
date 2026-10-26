import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';

/// Matches a JavaScript value that is strictly equal (`===`) to [expected].
///
/// Use instead of `same()` for JavaScript values: dart2wasm wraps them in
/// fresh Dart objects, so Dart's `identical` fails for the same JS reference.
Matcher jsIdentical(JSAny? expected) => _JSIdentical(expected);

class _JSIdentical extends Matcher {
  const _JSIdentical(this._expected);

  final JSAny? _expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item == null || _expected == null) return item == _expected;
    return (item as JSAny).strictEquals(_expected).toDart;
  }

  @override
  Description describe(Description description) => description
      .add('JavaScript value strictly equal (===) to ')
      .addDescriptionOf(_expected);
}
