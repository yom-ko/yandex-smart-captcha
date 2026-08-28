import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';
import 'package:yandex_smart_captcha/src/web_smart_captcha.dart';

void main() {
  WebSmartCaptcha createCaptcha({
    String clientKey = 'client-key',
    String language = 'en',
    bool alwaysShowChallenge = false,
    bool useInvisibleMode = false,
    String badgePosition = 'bottom-right',
    bool hideBadge = false,
    double initialScale = 1,
    String allowUserScaling = 'no',
    double maximumScale = 3,
    bool useWebViewMode = true,
  }) {
    return WebSmartCaptcha(
      clientKey: clientKey,
      language: language,
      alwaysShowChallenge: alwaysShowChallenge,
      useInvisibleMode: useInvisibleMode,
      badgePosition: badgePosition,
      hideBadge: hideBadge,
      initialScale: initialScale,
      allowUserScaling: allowUserScaling,
      maximumScale: maximumScale,
      useWebViewMode: useWebViewMode,
    );
  }

  group('$WebSmartCaptcha', () {
    group('HTML structure', () {
      test('contains the document structure and captcha container', () {
        final html = createCaptcha().html;

        expect(html, contains('<!doctype html>'));
        expect(html, contains('<html lang="en">'));
        expect(html, contains('<head>'));
        expect(html, contains('</head>'));
        expect(html, contains('<body>'));
        expect(html, contains('</body>'));
        expect(
          html,
          contains(
              '<div id="smart-captcha-container" style="height:100px"></div>'),
        );
      });

      test('contains charset, viewport, and SmartCaptcha script tags', () {
        final html = createCaptcha().html;

        expect(html, contains('<meta charset="utf-8" />'));
        expect(html, contains('width=device-width'));
        expect(html, contains('initial-scale=1.0'));
        expect(html, contains('user-scalable=no'));
        expect(html, contains('maximum-scale=3.0'));
        expect(
          html,
          contains(
            'src="https://smartcaptcha.cloud.yandex.ru/captcha.js?render=onload&onload=onLoadFunction"',
          ),
        );
        expect(html, contains('defer'));
      });
    });

    group('configuration', () {
      test('serializes all widget options', () {
        final html = createCaptcha(
          clientKey: 'test-key',
          language: 'ru',
          alwaysShowChallenge: true,
          useInvisibleMode: true,
          badgePosition: 'top-left',
          hideBadge: true,
          initialScale: 1.5,
          allowUserScaling: 'yes',
          maximumScale: 4,
          useWebViewMode: false,
        ).html;

        expect(html, contains('<html lang="ru">'));
        expect(html, contains('sitekey: "test-key"'));
        expect(html, contains('hl: "ru"'));
        expect(html, contains('test: true'));
        expect(html, contains('invisible: true'));
        expect(html, contains('shieldPosition: "top-left"'));
        expect(html, contains('hideShield: true'));
        expect(html, contains('initial-scale=1.5'));
        expect(html, contains('user-scalable=yes'));
        expect(html, contains('maximum-scale=4.0'));
        expect(html, contains('webview: false'));
      });
    });

    group('event wiring', () {
      test('contains exactly 4 callHandler calls', () {
        final html = createCaptcha().html;

        expect(
          'window.flutter_inappwebview.callHandler('.allMatches(html),
          hasLength(4),
        );
      });

      test('contains networkError event handler', () {
        final html = createCaptcha().html;

        expect(html, contains('if (!window.smartCaptcha)'));
        expect(html, contains('"${CaptchaEvent.networkError.name}"'));
        expect(html, contains('return;'));
      });

      test('contains challengeSolved event handler', () {
        final html = createCaptcha().html;

        expect(html, contains('function resultCallback(token)'));
        expect(html, contains('"${CaptchaEvent.challengeSolved.name}"'));
        expect(html, contains('token,'));
      });

      test('contains captchaLoaded event handler', () {
        final html = createCaptcha().html;

        expect(html, contains('window.flutter_inappwebview.callHandler('));
        expect(html, contains('"${CaptchaEvent.captchaLoaded.name}"'));
      });

      test('contains every subscribable event in JSON string', () {
        final html = createCaptcha().html;

        for (final event in CaptchaEvent.values.where((e) => e.subscribable)) {
          expect(html, contains('"id":"${event.id}","name":"${event.name}"'));
        }
      });

      test('does not contain callback-only events in JSON string', () {
        final html = createCaptcha().html;

        for (final event in CaptchaEvent.values.where((e) => !e.subscribable)) {
          expect(
            html,
            isNot(contains('"id":"${event.id}","name":"${event.name}"')),
          );
        }
      });

      test('renders and subscribes widget using configured container', () {
        final html = createCaptcha().html;

        expect(
          html,
          contains(
            'const widgetId = window.smartCaptcha.render("smart-captcha-container"',
          ),
        );
        expect(html, contains('window.$widgetIdProp = widgetId;'));

        expect(
          html,
          contains('window.flutter_inappwebview.callHandler(e.name)'),
        );
        expect(html, contains('window.smartCaptcha.subscribe(widgetId, e.id'));
      });
    });
  });
}
