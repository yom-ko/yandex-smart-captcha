import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject? _originalSrcDescriptor;

/// Turns every script element given a `src` into an inert data block, so
/// browser tests never fetch or execute the real SmartCaptcha script.
///
/// The element still fires events dispatched manually by a test.
void blockScriptNetwork() {
  if (_originalSrcDescriptor != null) return;

  _originalSrcDescriptor = globalContext.callMethod<JSObject>(
    'eval'.toJS,
    '''
(() => {
  const proto = HTMLScriptElement.prototype;
  const descriptor = Object.getOwnPropertyDescriptor(proto, 'src');
  Object.defineProperty(proto, 'src', {
    configurable: true,
    enumerable: descriptor.enumerable,
    get() { return descriptor.get.call(this); },
    set(value) {
      this.type = 'application/json';
      descriptor.set.call(this, value);
    },
  });
  return descriptor;
})()
'''
        .toJS,
  );
}

void restoreScriptNetwork() {
  final descriptor = _originalSrcDescriptor;
  if (descriptor == null) return;

  _originalSrcDescriptor = null;
  globalContext.getProperty<JSObject>('Object'.toJS).callMethod(
        'defineProperty'.toJS,
        globalContext
            .getProperty<JSObject>('HTMLScriptElement'.toJS)
            .getProperty<JSObject>('prototype'.toJS),
        'src'.toJS,
        descriptor,
      );
}
