/// Whether [baseUrl] is an absolute HTTP(S) URL with a host.
bool isValidBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  return uri != null &&
      uri.host.isNotEmpty &&
      (uri.isScheme('http') || uri.isScheme('https'));
}

/// Whether [url] points to the initial WebView document loaded from [baseUrl].
///
/// `about:` URLs are always treated as the initial document.
bool isInitialDocument(String url, Uri? baseUrl) {
  if (url.startsWith('about:')) return true;
  if (baseUrl == null) return false;
  return removeTrailingSlash(url) == removeTrailingSlash(baseUrl.toString());
}

String removeTrailingSlash(String url) =>
    url.endsWith('/') ? url.substring(0, url.length - 1) : url;
