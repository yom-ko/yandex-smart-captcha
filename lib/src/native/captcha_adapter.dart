import 'dart:convert';

import '../captcha_event.dart';

const widgetIdProp = 'yscWidgetId';

final class SmartCaptcha {
  late final String htmlData;

  SmartCaptcha({
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
  }) {
    const containerId = 'smart-captcha-container';

    final safeLang =
        const HtmlEscape(HtmlEscapeMode.attribute).convert(language);
    final safeAllowUserScaling =
        const HtmlEscape(HtmlEscapeMode.attribute).convert(allowUserScaling);

    final safeLanguage = _encodeJsStringLiteral(language);
    final safeClientKey = _encodeJsStringLiteral(clientKey);
    final safeBadgePosition = _encodeJsStringLiteral(badgePosition);
    final eventsJson = jsonEncode(
      CaptchaEvent.values
          .where((e) => e.subscribable)
          .map((e) => {
                'id': e.id,
                'name': e.name,
              })
          .toList(),
    );

    htmlData = '''
<!doctype html>
<html lang="$safeLang">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=$initialScale, user-scalable=$safeAllowUserScaling, maximum-scale=$maximumScale" />
    <title></title>
    <script>
      let isNetworkErrorReported = false;

      function isHandlerReady() {
        return (
          typeof window.flutter_inappwebview !== "undefined" &&
          typeof window.flutter_inappwebview.callHandler === "function"
        );
      }

      function reportNetworkError() {
        if (isNetworkErrorReported) return;

        if (isHandlerReady()) {
          isNetworkErrorReported = true;
          window.flutter_inappwebview.callHandler("${CaptchaEvent.networkError.name}");
        } else {
          window.addEventListener("flutterInAppWebViewPlatformReady", reportNetworkError, { once: true });
        }
      }

      function initializeCaptcha() {
        if (!window.smartCaptcha) {
          reportNetworkError();
          return;
        }

        function resultCallback(token) {
          window.flutter_inappwebview.callHandler("${CaptchaEvent.challengeSolved.name}", token);
        }

        try {
          const widgetId = window.smartCaptcha.render("$containerId", {
            sitekey: $safeClientKey,
            hl: $safeLanguage,
            test: $alwaysShowChallenge,
            invisible: $useInvisibleMode,
            shieldPosition: $safeBadgePosition,
            hideShield: $hideBadge,
            webview: $useWebViewMode,
            callback: resultCallback,
          });

          window.$widgetIdProp = widgetId;
          const events = $eventsJson;
          events.forEach(function (e) {
            window.smartCaptcha.subscribe(widgetId, e.id, function () {
              window.flutter_inappwebview.callHandler(e.name);
            });
          });

          window.flutter_inappwebview.callHandler("${CaptchaEvent.captchaReady.name}");
        } catch (e) {
          window.flutter_inappwebview.callHandler("${CaptchaEvent.javaScriptError.name}");
          return;
        }
      }

      function onLoadFunction() {
        if (isHandlerReady()) {
          initializeCaptcha();
        } else {
          window.addEventListener("flutterInAppWebViewPlatformReady", initializeCaptcha, { once: true });
        }
      }
    </script>
    <script
      src="https://smartcaptcha.cloud.yandex.ru/captcha.js?render=onload&onload=onLoadFunction"
      onerror="reportNetworkError()"
      defer
    ></script>
  </head>
  <body>
    <div id="$containerId" style="height:100px"></div>
  </body>
</html>
''';
  }

  static String _encodeJsStringLiteral(String value) => jsonEncode(value)
      .replaceAll('<', r'\u003C')
      .replaceAll('>', r'\u003E')
      .replaceAll('&', r'\u0026')
      .replaceAll('\u2028', r'\u2028')
      .replaceAll('\u2029', r'\u2029');
}
