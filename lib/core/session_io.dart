import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'log.dart';

CookieJar? _cookieJar;

/// Android / desktop: ONE persistent cookie jar for the whole app, so
/// Frappe's "sid" survives the app being closed and reopened.
///
/// If the support folder is unavailable the app still works with in-memory
/// cookies (the login then lasts until the app is closed).
Future<void> configureSession(Dio dio) async {
  CookieJar jar;
  try {
    final dir = await getApplicationSupportDirectory().timeout(
      const Duration(seconds: 3),
    );
    jar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
      ignoreExpires: false,
      persistSession: true,
    );
  } catch (e) {
    logDebug('Persistent cookies unavailable, using memory: $e');
    jar = CookieJar();
  }
  _cookieJar = jar;
  dio.interceptors.add(CookieManager(jar));
}

/// Names of the cookies that will be sent to [uri] (for debug logging).
Future<List<String>> cookieNamesFor(Uri uri) async {
  try {
    final cookies = await _cookieJar?.loadForRequest(uri) ?? const [];
    return [for (final c in cookies) c.name];
  } catch (e) {
    return ['<error: $e>'];
  }
}

/// Only called by [ApiClient.signOut].
Future<void> clearSessionCookies() async {
  try {
    await _cookieJar?.deleteAll();
  } catch (e) {
    logDebug('Clearing cookies failed: $e');
  }
}
