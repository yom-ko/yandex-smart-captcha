import 'package:flutter/material.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

// Find your key in the Yandex Cloud console.
const clientKey = String.fromEnvironment(
  'CLIENT_KEY',
  defaultValue: 'your-yandex-smartcaptcha-client-key',
);

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yandex SmartCaptcha Example',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(title: 'Yandex SmartCaptcha'),
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
  final _isSolved = ValueNotifier<bool>(false);

  final _controller = CaptchaController();
  final _config = const CaptchaConfig(
    clientKey: clientKey,
    language: CaptchaLanguage.en,
    alwaysShowChallenge: true,
    // Enable to test the execute() method.
    // useInvisibleMode: true,
  );

  @override
  void dispose() {
    _isSolved.dispose();
    _controller.dispose();

    super.dispose();
  }

  Future<void> _onExecute() async {
    await _controller.execute();
  }

  Future<void> _onReset() async {
    await _controller.reset();
    _isSolved.value = false;
  }

  Future<void> _onDestroy() async {
    await _controller.destroy();
    _isSolved.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: YandexSmartCaptcha(
                config: _config,
                controller: _controller,
                // Optionally, specify a base URL for the WebView.
                // baseUrl: 'https://example.com',
                backgroundColor: Colors.lightBlue,
                loadingIndicator:
                    // You fully control the loading indicator layout.
                    const Center(
                      child: SizedBox.square(
                        dimension: 50,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                onNavigationRequest: (url) {
                  debugPrint('called: onNavigationRequest: $url');
                  // Block navigation when clicking Yandex Cloud links,
                  return !url.contains('yandex.cloud');
                  // ...or simply block any web navigation.
                  // return false;
                },
                onCaptchaReady: () {
                  debugPrint('called: onCaptchaReady');
                },
                onChallengeShown: () {
                  debugPrint('called: onChallengeShown');
                },
                onChallengeHidden: () {
                  debugPrint('called: onChallengeHidden');
                },
                onChallengeSolved: (token) {
                  debugPrint('called: onChallengeSolved with token: $token');
                  _isSolved.value = token != null;
                },
                onTokenExpired: () {
                  debugPrint('called: onTokenExpired');
                },
                onNetworkError: () {
                  debugPrint('called: onNetworkError');
                },
                onJavaScriptError: () {
                  debugPrint('called: onJavaScriptError');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isReady,
                builder: (_, ready, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _isSolved,
                      builder: (_, solved, _) => ElevatedButton.icon(
                        onPressed: ready && !solved ? _onExecute : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Execute'),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isSolved,
                      builder: (_, solved, _) => ElevatedButton.icon(
                        onPressed: ready && solved ? _onReset : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: ready ? _onDestroy : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Destroy'),
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
