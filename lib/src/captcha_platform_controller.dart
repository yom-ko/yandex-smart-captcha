import 'package:flutter/foundation.dart';

typedef ChallengeSolvedCallback = void Function(String? token);
typedef NavigationRequestCallback = bool Function(String url);

abstract interface class CaptchaPlatformController {
  ValueNotifier<bool> get isReady;

  Future<void> execute();

  Future<void> reset();

  Future<void> destroy();

  void dispose();
}

final class CaptchaAdapterCallbacks {
  ChallengeSolvedCallback onChallengeSolved;
  VoidCallback? onCaptchaReady;
  VoidCallback? onChallengeShown;
  VoidCallback? onChallengeHidden;
  VoidCallback? onTokenExpired;
  VoidCallback? onNetworkError;
  VoidCallback? onJavaScriptError;
  NavigationRequestCallback? onNavigationRequest;

  CaptchaAdapterCallbacks({
    required this.onChallengeSolved,
    this.onCaptchaReady,
    this.onChallengeShown,
    this.onChallengeHidden,
    this.onTokenExpired,
    this.onNetworkError,
    this.onJavaScriptError,
    this.onNavigationRequest,
  });

  void update({
    required ChallengeSolvedCallback onChallengeSolved,
    VoidCallback? onCaptchaReady,
    VoidCallback? onChallengeShown,
    VoidCallback? onChallengeHidden,
    VoidCallback? onTokenExpired,
    VoidCallback? onNetworkError,
    VoidCallback? onJavaScriptError,
    NavigationRequestCallback? onNavigationRequest,
  }) {
    this.onChallengeSolved = onChallengeSolved;
    this.onCaptchaReady = onCaptchaReady;
    this.onChallengeShown = onChallengeShown;
    this.onChallengeHidden = onChallengeHidden;
    this.onTokenExpired = onTokenExpired;
    this.onNetworkError = onNetworkError;
    this.onJavaScriptError = onJavaScriptError;
    this.onNavigationRequest = onNavigationRequest;
  }
}
