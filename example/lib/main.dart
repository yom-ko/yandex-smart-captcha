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
  final _isLoaded = ValueNotifier<bool>(false);

  final _config = const CaptchaConfig(
    clientKey: clientKey,
    language: CaptchaLanguage.en,
    alwaysShowChallenge: true,
    backgroundColor: Colors.lightBlue,
  );
  final _controller = CaptchaController();

  @override
  void dispose() {
    _isLoaded.dispose();

    super.dispose();
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
                loadingIndicator:
                    // You fully control the loading indicator layout.
                    const Center(
                      child: SizedBox.square(
                        dimension: 50,
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
                  _isLoaded.value = true;
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
              child: ValueListenableBuilder<bool>(
                valueListenable: _isLoaded,
                builder: (_, isLoaded, child) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: isLoaded ? _controller.execute : null,
                      child: const Text('Execute'),
                    ),
                    ElevatedButton(
                      onPressed: isLoaded ? _controller.destroy : null,
                      child: const Text('Destroy'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
