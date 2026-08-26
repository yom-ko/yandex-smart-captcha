import 'dart:convert';

import 'captcha_event.dart';

final class WebSmartCaptcha {
  final String _clientKey;
  final bool _alwaysShowChallenge;
  final String _language;
  final bool _invisibleMode;
  final bool _hideDPNBadge;
  final String _dpnBadgePosition;
  final bool _webViewMode;
  final double _initialContentScale;
  final String _userScalableContent;
  final double _maximumContentScale;

  late final String html;

  WebSmartCaptcha({
    required String clientKey,
    required bool alwaysShowChallenge,
    required String language,
    required bool invisibleMode,
    required bool hideDPNBadge,
    required String dpnBadgePosition,
    required bool webViewMode,
    required double initialContentScale,
    required String userScalableContent,
    required double maximumContentScale,
  })  : _clientKey = clientKey,
        _alwaysShowChallenge = alwaysShowChallenge,
        _language = language,
        _invisibleMode = invisibleMode,
        _hideDPNBadge = hideDPNBadge,
        _dpnBadgePosition = dpnBadgePosition,
        _webViewMode = webViewMode,
        _initialContentScale = initialContentScale,
        _userScalableContent = userScalableContent,
        _maximumContentScale = maximumContentScale {
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
  initial-scale=$_initialContentScale,
  user-scalable=$_userScalableContent,
  maximum-scale=$_maximumContentScale"
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

        const widgetId = window.smartCaptcha.render("captcha-container", {
          sitekey: "$_clientKey",
          test: $_alwaysShowChallenge,
          hl: "$_language",
          invisible: $_invisibleMode,
          hideShield: $_hideDPNBadge,
          shieldPosition: "$_dpnBadgePosition",
          webview: $_webViewMode,
          callback: resultCallback,
        });

        const events = $eventsJson;
        events.forEach(function (e) {
          window.smartCaptcha.subscribe(widgetId, e.id, function () {
            window.flutter_inappwebview.callHandler(e.name);
          });
        });

        window.flutter_inappwebview.callHandler(
          "${CaptchaEvent.captchaLoaded.name}",
        );
      }
    </script>
    <script
      src="https://smartcaptcha.cloud.yandex.ru/captcha.js?render=onload&onload=onLoadFunction"
      defer
    ></script>
  </head>
  <body>
    <div id="captcha-container" style="height: 100px"></div>
  </body>
</html>
''';
  }
}
