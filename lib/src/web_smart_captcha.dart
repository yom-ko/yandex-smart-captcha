import 'dart:convert';

import 'captcha_event.dart';

const widgetIdProp = 'wscWidgetId';

final class WebSmartCaptcha {
  final String _clientKey;
  final String _language;
  final bool _alwaysShowChallenge;
  final bool _useInvisibleMode;
  final String _badgePosition;
  final bool _hideBadge;
  final double _initialScale;
  final String _allowUserScaling;
  final double _maximumScale;
  final bool _useWebViewMode;

  late final String html;

  WebSmartCaptcha({
    required String clientKey,
    required String language,
    required bool alwaysShowChallenge,
    required bool useInvisibleMode,
    required String badgePosition,
    required bool hideBadge,
    required double initialScale,
    required String allowUserScaling,
    required double maximumScale,
    required bool useWebViewMode,
  })  : _clientKey = clientKey,
        _language = language,
        _alwaysShowChallenge = alwaysShowChallenge,
        _useInvisibleMode = useInvisibleMode,
        _badgePosition = badgePosition,
        _hideBadge = hideBadge,
        _initialScale = initialScale,
        _allowUserScaling = allowUserScaling,
        _maximumScale = maximumScale,
        _useWebViewMode = useWebViewMode {
    const containerId = 'smart-captcha-container';
    final eventsJson = jsonEncode(
      CaptchaEvent.values
          .where((e) => e.subscribable)
          .map((e) => {
                'id': e.id,
                'name': e.name,
              })
          .toList(),
    );

    html = '''
<!doctype html>
<html lang="$_language">
  <head>
    <meta charset="utf-8" />
    <meta
      name="viewport"
      content="
  width=device-width,
  initial-scale=$_initialScale,
  user-scalable=$_allowUserScaling,
  maximum-scale=$_maximumScale"
    />
    <title></title>
    <script>
      function onLoadFunction() {
        if (!window.smartCaptcha) {
          window.flutter_inappwebview.callHandler(
            "${CaptchaEvent.networkError.name}",
          );
          return;
        }

        function resultCallback(token) {
          window.flutter_inappwebview.callHandler(
            "${CaptchaEvent.challengeSolved.name}",
            token,
          );
        }

        const widgetId = window.smartCaptcha.render("$containerId", {
          sitekey: "$_clientKey",
          hl: "$_language",
          test: $_alwaysShowChallenge,
          invisible: $_useInvisibleMode,
          shieldPosition: "$_badgePosition",
          hideShield: $_hideBadge,
          webview: $_useWebViewMode,
          callback: resultCallback,
        });

        window.$widgetIdProp = widgetId;
        const events = $eventsJson;
        events.forEach(function (e) {
          window.smartCaptcha.subscribe(widgetId, e.id, function () {
            window.flutter_inappwebview.callHandler(e.name);
          });
        });

        window.flutter_inappwebview.callHandler(
          "${CaptchaEvent.captchaReady.name}",
        );
      }
    </script>
    <script
      src="https://smartcaptcha.cloud.yandex.ru/captcha.js?render=onload&onload=onLoadFunction"
      defer
    ></script>
  </head>
  <body>
    <div id="$containerId" style="height:100px"></div>
  </body>
</html>
''';
  }
}
