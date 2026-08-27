import 'package:flutter/material.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

// Find your key in the Yandex Cloud admin panel.
const clientKey = String.fromEnvironment('CLIENT_KEY');

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yandex SmartCaptcha',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(title: 'Example'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({required this.title, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CaptchaConfig _config;
  late final CaptchaController _controller;

  @override
  void initState() {
    super.initState();

    _config = const CaptchaConfig(
      clientKey: clientKey,
      language: CaptchaLanguage.en,
      alwaysShowChallenge: true,
      // useInvisibleMode: false,
      // badgePosition: DPNBadgePosition.bottomRight,
      // hideBadge: false,
      // initialScale: 1.0,
      // allowUserScaling: false,
      // maximumScale: 3.0,
      backgroundColor: Colors.lightBlue,
      // useWebViewMode: true,
    );
    _controller = CaptchaController()
      ..setReadyCallback(() {
        debugPrint('called: readyCallback – SmartCaptcha controller is ready');
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: YandexSmartCaptcha(
                config: _config,
                controller: _controller,
                loadingIndicator: const Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
                onNavigationRequest: (url) {
                  debugPrint('called: onNavigationRequest $url');
                  if (url.contains('cloud.yandex')) {
                    // Block the navigation request when the user
                    // clicks on the 'SmartCaptcha by Yandex Cloud' link.
                    return false;
                  }
                  return true;
                },
                onCaptchaLoaded: () {
                  debugPrint('called: onCaptchaLoaded');
                },
                onChallengeShown: () {
                  debugPrint('called: onChallengeShown');
                },
                onChallengeHidden: () {
                  debugPrint('called: onChallengeHidden');
                },
                onNetworkError: () {
                  debugPrint('called: onNetworkError');
                },
                onJavaScriptError: () {
                  debugPrint('called: onJavaScriptError');
                },
                onChallengeSolved: (token) {
                  debugPrint('called: onChallengeSolved with token: $token');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.isReady) {
                        _controller.execute();
                      }
                    },
                    child: const Text('Execute'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.isReady) {
                        _controller.destroy();
                      }
                    },
                    child: const Text('Destroy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
