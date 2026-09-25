import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/captcha_event.dart';
import 'package:yandex_smart_captcha/src/native/captcha_adapter.dart';

void main() {
  SmartCaptcha createCaptcha({
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
    return SmartCaptcha(
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

  List<Map<String, dynamic>> subscribedEventsFrom(String html) {
    final match = RegExp(r'const events = (\[[\s\S]*?\]);').firstMatch(html);

    expect(match, isNotNull);
    return (jsonDecode(match!.group(1)!) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  group('$SmartCaptcha', () {
    group('HTML structure', () {
      test('contains the document structure and captcha container', () {
        final html = createCaptcha().data;

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
        final html = createCaptcha().data;

        expect(html, contains('<meta charset="utf-8" />'));
        expect(html, contains('width=device-width'));
        expect(html, contains(RegExp(r'initial-scale=1(?:\.0)?')));
        expect(html, contains('user-scalable=no'));
        expect(html, contains(RegExp(r'maximum-scale=3(?:\.0)?')));
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
      test('serializes all widget configuration', () {
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
        ).data;

        expect(html, contains('<html lang="ru">'));
        expect(html, contains('sitekey: "test-key"'));
        expect(html, contains('hl: "ru"'));
        expect(html, contains('test: true'));
        expect(html, contains('invisible: true'));
        expect(html, contains('shieldPosition: "top-left"'));
        expect(html, contains('hideShield: true'));
        expect(html, contains('initial-scale=1.5'));
        expect(html, contains('user-scalable=yes'));
        expect(html, contains(RegExp(r'maximum-scale=4(?:\.0)?')));
        expect(html, contains('webview: false'));
      });

      test('escapes JavaScript string configuration values', () {
        final html = createCaptcha(
          clientKey: 'key"\\</script><script>\u2028\u2029',
        ).data;

        expect(
          html,
          contains(
            r'sitekey: "key\"\\\u003C/script\u003E\u003Cscript\u003E\u2028\u2029"',
          ),
        );
        expect(html, isNot(contains(r'sitekey: "key"\')));
        expect(html, contains(r'hl: "en"'));
        expect(html, contains(r'shieldPosition: "bottom-right"'));
      });
    });

    group('event wiring', () {
      test('reports a missing SmartCaptcha script before rendering', () {
        final html = createCaptcha().data;

        expect(html, contains('if (!window.smartCaptcha)'));
        expect(html, contains('"${CaptchaEvent.networkError.name}"'));
        expect(html, contains('return;'));
        expect(
          html.indexOf('return;'),
          lessThan(
            html.indexOf('const widgetId = window.smartCaptcha.render('),
          ),
        );
      });

      test('contains challengeSolved event handler', () {
        final html = createCaptcha().data;

        expect(html, contains('function resultCallback(token)'));
        expect(html, contains('"${CaptchaEvent.challengeSolved.name}"'));
        expect(html, contains('token,'));
      });

      test('contains captchaReady event handler', () {
        final html = createCaptcha().data;

        expect(html, contains('window.flutter_inappwebview.callHandler('));
        expect(html, contains('"${CaptchaEvent.captchaReady.name}"'));
      });

      test('subscribes to exactly the native SmartCaptcha events', () {
        final html = createCaptcha().data;

        expect(
          subscribedEventsFrom(html),
          equals(
            CaptchaEvent.values
                .where((event) => event.subscribable)
                .map((event) => {'id': event.id, 'name': event.name})
                .toList(),
          ),
        );
      });

      test('renders and subscribes widget using configured container', () {
        final html = createCaptcha().data;

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
