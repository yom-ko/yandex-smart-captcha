import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_platform_controller.dart';

void main() {
  group('$CaptchaAdapterCallbacks', () {
    test('updates every callback while preserving the callback contract', () {
      final initialCalls = <String>[];
      final updatedCalls = <String>[];
      final callbacks = CaptchaAdapterCallbacks(
        onChallengeSolved: (_) => initialCalls.add('solved'),
        onCaptchaReady: () => initialCalls.add('ready'),
        onChallengeShown: () => initialCalls.add('shown'),
        onChallengeHidden: () => initialCalls.add('hidden'),
        onTokenExpired: () => initialCalls.add('expired'),
        onNetworkError: () => initialCalls.add('network'),
        onJavaScriptError: () => initialCalls.add('javascript'),
        onNavigationRequest: (_) {
          initialCalls.add('navigation');
          return true;
        },
      );

      callbacks.update(
        onChallengeSolved: (_) => updatedCalls.add('solved'),
        onCaptchaReady: () => updatedCalls.add('ready'),
        onChallengeShown: () => updatedCalls.add('shown'),
        onChallengeHidden: () => updatedCalls.add('hidden'),
        onTokenExpired: () => updatedCalls.add('expired'),
        onNetworkError: () => updatedCalls.add('network'),
        onJavaScriptError: () => updatedCalls.add('javascript'),
        onNavigationRequest: (_) {
          updatedCalls.add('navigation');
          return false;
        },
      );

      callbacks.onChallengeSolved('token');
      callbacks.onCaptchaReady?.call();
      callbacks.onChallengeShown?.call();
      callbacks.onChallengeHidden?.call();
      callbacks.onTokenExpired?.call();
      callbacks.onNetworkError?.call();
      callbacks.onJavaScriptError?.call();

      final navigationAllowed = callbacks.onNavigationRequest?.call('url');

      expect(initialCalls, isEmpty);
      expect(
        updatedCalls,
        equals([
          'solved',
          'ready',
          'shown',
          'hidden',
          'expired',
          'network',
          'javascript',
          'navigation',
        ]),
      );
      expect(navigationAllowed, isFalse);
    });

    test('allows optional callbacks to remain unset', () {
      final callbacks = CaptchaAdapterCallbacks(
        onChallengeSolved: (_) {},
      );

      expect(callbacks.onCaptchaReady, isNull);
      expect(callbacks.onChallengeShown, isNull);
      expect(callbacks.onChallengeHidden, isNull);
      expect(callbacks.onTokenExpired, isNull);
      expect(callbacks.onNetworkError, isNull);
      expect(callbacks.onJavaScriptError, isNull);
      expect(callbacks.onNavigationRequest, isNull);
    });
  });
}
