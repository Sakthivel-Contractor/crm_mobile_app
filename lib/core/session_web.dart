import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Web: the browser owns the cookies; just send them with every request.
Future<void> configureSession(Dio dio) async {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}

/// The browser's cookies are not readable from Dart (sid is HttpOnly).
Future<List<String>> cookieNamesFor(Uri uri) async => const [];

/// The "sid" cookie is HttpOnly, so it can only be cleared by the server
/// (the logout call does that).
Future<void> clearSessionCookies() async {}
