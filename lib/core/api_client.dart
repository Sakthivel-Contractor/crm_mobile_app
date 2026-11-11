import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'session_io.dart'
    if (dart.library.js_interop) 'session_web.dart'
    as session;
import 'app_error.dart';
import 'storage.dart';
import 'log.dart';

enum AuthErrorType {
  serverUnreachable,
  invalidCredentials,
  network,

  /// The server URL is not https:// (http is allowed only for localhost in
  /// debug builds).
  insecureUrl,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.type);

  final AuthErrorType type;

  @override
  String toString() => 'AuthException($type)';
}

/// The signed-in user restored from storage.
class SessionUser {
  const SessionUser({required this.username, required this.fullName});

  final String username;
  final String fullName;
}

enum SessionState {
  /// The server confirmed the session.
  loggedIn,

  /// No saved session, or the server said 401/403/"Guest".
  loggedOut,

  /// A saved session exists but the server could not be reached; the user
  /// stays signed in.
  offline,
}

class SessionRestore {
  const SessionRestore(this.state, [this.user]);

  final SessionState state;

  /// Set for [SessionState.loggedIn] and [SessionState.offline].
  final SessionUser? user;
}

/// Single Dio instance shared by the whole app, talking to a Frappe server.
class ApiClient {
  ApiClient._() {
    _dio.interceptors.add(
      InterceptorsWrapper(onError: _checkSessionOnAuthError),
    );
  }

  static final ApiClient instance = ApiClient._();

  final Dio _dio =
      Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            responseType: ResponseType.json,
            headers: {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // ngrok's free plan answers browser requests with an HTML
              // warning page unless this header is present. Same-origin web
              // requests go through the dev proxy (web_dev_config.yaml),
              // which may forward to ngrok; the header costs nothing there.
              if (_isNgrokHost(options.uri.host) ||
                  _isSameOriginWeb(options.uri)) {
                options.headers['ngrok-skip-browser-warning'] = 'true';
              }
              handler.next(options);
            },
          ),
        );

  static bool _isSameOriginWeb(Uri uri) =>
      kIsWeb && uri.hasScheme && uri.origin == Uri.base.origin;

  static bool _isNgrokHost(String host) =>
      host.endsWith('.ngrok-free.dev') ||
      host.endsWith('.ngrok-free.app') ||
      host.endsWith('.ngrok.app') ||
      host.endsWith('.ngrok.dev') ||
      host.endsWith('.ngrok.io');

  Future<void>? _initFuture;
  String? _siteUrl;

  final _sessionExpired = StreamController<void>.broadcast();
  bool _checkingSession = false;

  /// Marks requests that must not trigger the session check (avoids loops).
  static const _skipSessionCheck = 'skipSessionCheck';

  Dio get dio => _dio;

  /// The normalised base URL (scheme + host[:port]) used for every request.
  String? get siteUrl => _siteUrl;

  /// Fires when the server confirms the session is gone (real 401/403).
  /// Never fires for network errors or timeouts.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  /// Sets up the single cookie jar (browser cookies on web) and loads the
  /// saved base URL. Awaited in main() before runApp.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    await session.configureSession(_dio);
    _siteUrl = _allowedOrNull(await AppStorage.loadSiteUrl());
    if (kDebugMode) await _logCookies('startup');
  }

  Future<void> _logCookies(String when) async {
    final url = _siteUrl;
    if (url == null) {
      logDebug('[session] $when: no saved site URL');
      return;
    }
    final names = await session.cookieNamesFor(Uri.parse(url));
    final sid = names.contains('sid') ? 'present' : 'MISSING';
    logDebug('[session] $when: cookies for $url = $names (sid $sid)');
  }

  /// Hosts that may use plain http:// — debug builds only (dev proxy,
  /// Android emulator → host machine).
  static const Set<String> _debugHttpHosts = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  /// Only https:// sites are allowed. In debug builds http:// is accepted
  /// for localhost / emulator addresses only. [release] is for tests.
  static bool isAllowedSiteUrl(String url, {bool release = kReleaseMode}) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        !release &&
        _debugHttpHosts.contains(uri.host.toLowerCase());
  }

  /// The normalised [saved] URL if it is allowed, otherwise null.
  static String? _allowedOrNull(String? saved) {
    if (saved == null || saved.trim().isEmpty) return null;
    final url = normalizeUrl(saved);
    if (isAllowedSiteUrl(url)) return url;
    logDebug('[session] ignoring saved URL that is not https');
    return null;
  }

  /// Base URL as scheme + host[:port]: adds https:// when no scheme is given
  /// and drops any path, query or trailing slash. Cookies are stored per host,
  /// so every request must use exactly this form.
  static String normalizeUrl(String input) {
    var url = input.trim();
    if (!url.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      while (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }
    return uri.origin;
  }

  /// Full sign-in flow: ping the server, log in, persist the session.
  /// Returns the user's full name.
  Future<String> signIn({
    required String siteUrl,
    required String username,
    required String password,
  }) async {
    await init();
    final url = normalizeUrl(siteUrl);
    if (!isAllowedSiteUrl(url)) {
      throw const AuthException(AuthErrorType.insecureUrl);
    }

    await _ping(url);

    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '$url/api/method/login',
        data: {'usr': username, 'pwd': password},
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthException(AuthErrorType.invalidCredentials);
      }
      throw AuthException(
        _isNetworkError(e) ? AuthErrorType.network : AuthErrorType.unknown,
      );
    }

    final data = response.data;
    final fullName = data is Map ? data['full_name'] : null;
    if (fullName is! String || fullName.isEmpty) {
      throw const AuthException(AuthErrorType.unknown);
    }

    _siteUrl = url;
    await AppStorage.saveSiteUrl(url);
    await AppStorage.saveUser(username: username, fullName: fullName);
    if (kDebugMode) await _logCookies('after login');
    return fullName;
  }

  /// Startup check. Only a 401/403 or "Guest" from the server means logged
  /// out; network errors, timeouts and server errors keep a saved user
  /// signed in ([SessionState.offline]).
  Future<SessionRestore> restoreSession() async {
    await init();
    _siteUrl = _allowedOrNull(await AppStorage.loadSiteUrl()) ?? _siteUrl;
    final url = _siteUrl;
    if (url == null) return const SessionRestore(SessionState.loggedOut);

    final username = await AppStorage.loadUsername();
    final fullName = await AppStorage.loadFullName();
    SessionUser? savedUser(String? fallback) {
      final name = username ?? fallback;
      if (name == null || name.isEmpty) return null;
      return SessionUser(
        username: name,
        fullName: (fullName == null || fullName.isEmpty) ? name : fullName,
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        '$url/api/method/frappe.auth.get_logged_user',
        options: Options(extra: {_skipSessionCheck: true}),
      );
      final data = response.data;
      final user = data is Map ? data['message'] : null;
      if (user == 'Guest') return const SessionRestore(SessionState.loggedOut);
      if (user is String && user.isNotEmpty) {
        return SessionRestore(SessionState.loggedIn, savedUser(user));
      }
      // 200 but not Frappe JSON (e.g. a proxy page): treat as unreachable.
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      logDebug('[session] restore: ${e.type} $status');
      if (status == 401 || status == 403) {
        return const SessionRestore(SessionState.loggedOut);
      }
    }
    final user = savedUser(null);
    return user == null
        ? const SessionRestore(SessionState.loggedOut)
        : SessionRestore(SessionState.offline, user);
  }

  /// On a 401/403 from a normal request, asks Frappe who is logged in. Only
  /// if that also says 401/403/"Guest" is [sessionExpired] fired; a real
  /// permission error on one document type does not log the user out, and
  /// network failures never do.
  Future<void> _checkSessionOnAuthError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final url = _siteUrl;
    final skip = err.requestOptions.extra[_skipSessionCheck] == true;
    final path = err.requestOptions.uri.path;
    final isAuthCall =
        path.endsWith('/api/method/login') ||
        path.endsWith('/api/method/logout');

    if ((status == 401 || status == 403) &&
        !skip &&
        !isAuthCall &&
        url != null &&
        !_checkingSession) {
      _checkingSession = true;
      try {
        final response = await _dio.get<dynamic>(
          '$url/api/method/frappe.auth.get_logged_user',
          options: Options(extra: {_skipSessionCheck: true}),
        );
        final data = response.data;
        if (data is Map && data['message'] == 'Guest') {
          _sessionExpired.add(null);
        }
      } on DioException catch (e) {
        final s = e.response?.statusCode;
        if (s == 401 || s == 403) _sessionExpired.add(null);
      } finally {
        _checkingSession = false;
      }
    }
    handler.next(err);
  }

  /// Logout — the ONLY place that clears cookies and the saved user.
  /// Logs out on the server (best effort). The site URL is kept so the login
  /// form stays prefilled.
  Future<void> signOut() async {
    await init();
    final url = _siteUrl;
    if (url != null) {
      try {
        await _dio.post<dynamic>(
          '$url/api/method/logout',
          options: Options(extra: {_skipSessionCheck: true}),
        );
      } on DioException catch (e) {
        logDebug('Logout request failed: ${e.type}');
      }
    }
    await session.clearSessionCookies();
    await AppStorage.clearUser();
  }

  /// GET [path] (e.g. `/api/resource/...`) on the signed-in site and return
  /// the decoded JSON. Throws [AppException] on failure.
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);

  /// POST a JSON body. Throws [AppException] on failure.
  Future<dynamic> postJson(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  /// PUT a JSON body. Throws [AppException] on failure.
  Future<dynamic> putJson(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    await init();
    final url = _siteUrl;
    if (url == null || url.isEmpty || !isAllowedSiteUrl(url)) {
      throw const AppException(AppError.unauthorized);
    }
    try {
      final response = await _dio.request<dynamic>(
        '$url$path',
        queryParameters: query,
        data: body,
        options: Options(
          method: method,
          contentType: body == null ? null : Headers.jsonContentType,
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> _ping(String url) async {
    try {
      logDebug('[ping] trying $url/api/method/ping');
      final response = await _dio.get<dynamic>('$url/api/method/ping');
      final data = response.data;
      logDebug('[ping] response type=${data.runtimeType} data=$data');
      if (data is Map && data['message'] == 'pong') return;
      if (data is String && data.contains('pong')) return;
    } on DioException catch (e) {
      logDebug('[ping] DioException type=${e.type} status=${e.response?.statusCode} msg=${e.message}');
      if (_isNetworkError(e)) {
        throw const AuthException(AuthErrorType.network);
      }
    } catch (e) {
      logDebug('[ping] unexpected error: $e');
    }
    // Wrong URL, not a Frappe server, unreachable host or CORS failure.
    throw const AuthException(AuthErrorType.serverUnreachable);
  }

  static bool _isTimeout(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;

  static bool _isNetworkError(DioException e) =>
      _isTimeout(e) || e.type == DioExceptionType.connectionError;
}
