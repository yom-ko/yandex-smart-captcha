import 'package:flutter/material.dart';
import 'package:yandex_smart_captcha/yandex_smart_captcha.dart';

// Find your key in the Yandex Cloud admin panel.
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
  final _isReady = ValueNotifier<bool>(false);
  final _isSolved = ValueNotifier<bool>(false);

  final _controller = CaptchaController();
  final _config = const CaptchaConfig(
    clientKey: clientKey,
    language: CaptchaLanguage.en,
    alwaysShowChallenge: true,
  );

  @override
  void dispose() {
    _isSolved.dispose();
    _isReady.dispose();

    super.dispose();
  }

  Future<void> _onExecutePressed() async {
    await _controller.execute();
  }

  Future<void> _onResetPressed() async {
    await _controller.reset();
    _isSolved.value = false;
  }

  Future<void> _onDestroyPressed() async {
    await _controller.destroy();
    _isSolved.value = false;
    _isReady.value = false;
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
                  // Block navigation when clicking external links (e.g. Terms/Privacy).
                  if (url.contains('cloud.yandex')) {
                    return false;
                  }
                  return true;
                },
                onCaptchaReady: () {
                  debugPrint('called: onCaptchaReady');
                  _isReady.value = true;
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
                  _isSolved.value = token != null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isReady,
                builder: (_, isReady, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isReady ? _onExecutePressed : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Execute'),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isSolved,
                      builder: (_, isSolved, _) => ElevatedButton.icon(
                        onPressed: isSolved ? _onResetPressed : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: isReady ? _onDestroyPressed : null,
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
