@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_smart_captcha/src/native/utils.dart';

void main() {
  group('isValidBaseUrl', () {
    test('accepts absolute HTTP(S) URLs with a host', () {
      for (final baseUrl in [
        'http://captcha.example',
        'https://captcha.example',
        'HTTPS://Captcha.Example',
        'https://captcha.example:8443/path?query=1',
      ]) {
        expect(isValidBaseUrl(baseUrl), isTrue, reason: baseUrl);
      }
    });

    test('rejects URLs that cannot serve as an HTTP(S) origin', () {
      for (final baseUrl in [
        '',
        'captcha.example',
        'https://',
        'file:///captcha',
        'ftp://captcha.example',
        'http://[::1',
      ]) {
        expect(isValidBaseUrl(baseUrl), isFalse, reason: baseUrl);
      }
    });
  });

  group('isInitialDocument', () {
    test('treats about: URLs as the initial document', () {
      expect(isInitialDocument('about:blank', null), isTrue);
      expect(
        isInitialDocument('about:blank', Uri.parse('https://captcha.example')),
        isTrue,
      );
    });

    test('rejects other URLs when there is no base URL', () {
      expect(isInitialDocument('https://captcha.example', null), isFalse);
    });

    test('matches the base URL ignoring a trailing slash', () {
      final baseUrl = Uri.parse('https://captcha.example');

      expect(isInitialDocument('https://captcha.example', baseUrl), isTrue);
      expect(isInitialDocument('https://captcha.example/', baseUrl), isTrue);
      expect(
        isInitialDocument(
          'https://captcha.example',
          Uri.parse('https://captcha.example/'),
        ),
        isTrue,
      );
    });

    test('matches the base URL regardless of scheme and host casing', () {
      expect(
        isInitialDocument(
          'https://captcha.example/',
          Uri.parse('HTTPS://Captcha.EXAMPLE'),
        ),
        isTrue,
      );
    });

    test('rejects URLs that differ from the base URL', () {
      final baseUrl = Uri.parse('https://captcha.example/form');

      expect(isInitialDocument('https://captcha.example', baseUrl), isFalse);
      expect(
        isInitialDocument('https://captcha.example/form/next', baseUrl),
        isFalse,
      );
      expect(isInitialDocument('https://other.example/form', baseUrl), isFalse);
    });
  });

  group('removeTrailingSlash', () {
    test('removes a single trailing slash', () {
      expect(removeTrailingSlash('https://captcha.example/'),
          'https://captcha.example');
      expect(removeTrailingSlash('https://captcha.example//'),
          'https://captcha.example/');
    });

    test('keeps URLs without a trailing slash unchanged', () {
      expect(removeTrailingSlash('https://captcha.example'),
          'https://captcha.example');
      expect(removeTrailingSlash(''), '');
    });
  });
}
