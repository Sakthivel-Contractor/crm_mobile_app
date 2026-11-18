import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hitech_crm_app/core/api_client.dart';
import 'package:hitech_crm_app/core/app_error.dart';
import 'package:hitech_crm_app/core/session_io.dart' as session;
import 'package:hitech_crm_app/core/storage.dart';
import 'package:hitech_crm_app/features/leads/lead_repository.dart';

/// Answers requests from [handler] instead of the network.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  Future<ResponseBody> Function(RequestOptions options) handler;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    paths.add(options.uri.path);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Future<ResponseBody> Function(RequestOptions) _loggedUser(Object answer) =>
    (o) async => answer is int ? _json(answer, {}) : _json(200, answer);

Future<ResponseBody> _networkError(RequestOptions o) async =>
    throw DioException(
      requestOptions: o,
      type: DioExceptionType.connectionError,
    );

void main() {
  final api = ApiClient.instance;
  late FakeAdapter adapter;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'site_url': 'https://crm.example.com/app/',
    });
    await api.init(); // no path_provider in tests → in-memory cookie jar
    adapter = FakeAdapter(_loggedUser({'message': 'ravi@example.com'}));
    api.dio.httpClientAdapter = adapter;
  });

  setUp(() async {
    await AppStorage.saveUser(username: 'ravi@example.com', fullName: 'Ravi');
  });

  group('restoreSession', () {
    test('server confirms user → logged in, base URL normalised', () async {
      adapter.handler = _loggedUser({'message': 'ravi@example.com'});
      final r = await api.restoreSession();
      expect(r.state, SessionState.loggedIn);
      expect(r.user?.fullName, 'Ravi');
      expect(api.siteUrl, 'https://crm.example.com');
    });

    test('"Guest" → logged out', () async {
      adapter.handler = _loggedUser({'message': 'Guest'});
      expect((await api.restoreSession()).state, SessionState.loggedOut);
    });

    test('401 and 403 → logged out', () async {
      for (final status in [401, 403]) {
        adapter.handler = _loggedUser(status);
        expect((await api.restoreSession()).state, SessionState.loggedOut);
      }
    });

    test('network error, timeout, 5xx → stays signed in (offline)', () async {
      for (final handler in [
        _networkError,
        (RequestOptions o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        ),
        _loggedUser(502),
        _loggedUser(404), // e.g. ngrok tunnel offline
      ]) {
        adapter.handler = handler;
        final r = await api.restoreSession();
        expect(r.state, SessionState.offline);
        expect(r.user?.fullName, 'Ravi');
      }
    });

    test('offline without a saved user → login', () async {
      await AppStorage.clearUser();
      adapter.handler = _networkError;
      expect((await api.restoreSession()).state, SessionState.loggedOut);
    });
  });

  group('login, password and logout', () {
    const password = 'S3cret-Pa55!';

    Future<ResponseBody> server(RequestOptions o) async {
      final path = o.uri.path;
      if (path.endsWith('/api/method/ping')) {
        return _json(200, {'message': 'pong'});
      }
      if (path.endsWith('/api/method/login')) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Logged In', 'full_name': 'Ravi Kumar'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'set-cookie': ['sid=abc123; Path=/; HttpOnly'],
          },
        );
      }
      return _json(200, {'message': 'ok'});
    }

    test('password is never stored; logout clears cookies and user', () async {
      adapter.handler = server;
      final name = await api.signIn(
        siteUrl: 'https://crm.example.com',
        username: 'ravi@example.com',
        password: password,
      );
      expect(name, 'Ravi Kumar');

      final site = Uri.parse('https://crm.example.com');
      expect(await session.cookieNamesFor(site), contains('sid'));

      // Nothing persisted anywhere contains the password.
      final secure = await const FlutterSecureStorage().readAll();
      final prefs = await SharedPreferences.getInstance();
      final stored = [
        ...secure.values,
        for (final k in prefs.getKeys()) '${prefs.get(k)}',
      ];
      expect(stored.any((v) => v.contains(password)), isFalse);
      expect(secure['username'], 'ravi@example.com');

      await api.signOut();
      expect(await session.cookieNamesFor(site), isEmpty);
      final after = await const FlutterSecureStorage().readAll();
      expect(after.containsKey('username'), isFalse);
      expect(after.containsKey('full_name'), isFalse);
      expect(await AppStorage.loadUsername(), isNull);
      expect(await AppStorage.loadFullName(), isNull);
      // Server URL is kept to prefill the login form.
      expect(api.siteUrl, 'https://crm.example.com');
    });

    test('plain http server URL is refused before any request', () async {
      adapter.paths.clear();
      await expectLater(
        api.signIn(
          siteUrl: 'http://crm.example.com',
          username: 'u',
          password: password,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.type,
            'type',
            AuthErrorType.insecureUrl,
          ),
        ),
      );
      expect(adapter.paths, isEmpty);
    });

    test(
      'server URL with embedded credentials is refused before any request',
      () async {
        adapter.paths.clear();
        await expectLater(
          api.signIn(
            siteUrl: 'https://user:secret@crm.example.com/path',
            username: 'u',
            password: password,
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'type',
              AuthErrorType.insecureUrl,
            ),
          ),
        );
        expect(adapter.paths, isEmpty);
      },
    );
  });

  test(
    'createLead posts the CRM Lead fields and parses the created document',
    () async {
      RequestOptions? sent;
      adapter.handler = (options) async {
        sent = options;
        return _json(200, {
          'data': {
            'name': 'CRM-LEAD-NEW',
            'first_name': 'Ravi',
            'status': 'New',
          },
        });
      };
      final lead = await LeadRepository(client: api).createLead(
        firstName: 'Ravi',
        status: 'New',
        mobileNo: '9840012345',
        district: 'Madurai',
        workType: 'New Well',
        whenStart: 'Next month',
      );
      expect(sent?.method, 'POST');
      expect(sent?.uri.toString(), contains('/api/resource/CRM%20Lead'));
      expect(sent?.data, containsPair('first_name', 'Ravi'));
      expect(sent?.data, containsPair('mobile_no', '9840012345'));
      expect(sent?.data, containsPair('custom_district', 'Madurai'));
      expect(sent?.data, containsPair('custom_work_type', 'New Well'));
      expect(sent?.data, containsPair('custom_when_start', 'Next month'));
      expect(lead.name, 'CRM-LEAD-NEW');
    },
  );

  group('error mapping (no raw server text reaches the UI)', () {
    Future<AppError> errorFor(
      Future<ResponseBody> Function(RequestOptions) handler,
    ) async {
      adapter.handler = handler;
      try {
        await api.getJson('/api/resource/CRM%20Lead');
      } on AppException catch (e) {
        return e.error;
      }
      fail('expected AppException');
    }

    test('500 → server, timeout → network, 401/403 → unauthorized', () async {
      expect(
        await errorFor(
          (o) async => _json(500, {'exception': 'Traceback (most recent ...'}),
        ),
        AppError.server,
      );
      expect(
        await errorFor(
          (o) async => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        AppError.network,
      );
      for (final status in [401, 403]) {
        expect(
          await errorFor(
            (o) async => o.uri.path.contains('get_logged_user')
                ? _json(200, {'message': 'ravi@example.com'})
                : _json(status, {}),
          ),
          AppError.unauthorized,
        );
      }
    });

    test('AppException text never contains server output', () {
      const e = AppException(AppError.server);
      expect(e.toString(), 'AppException(AppError.server)');
    });
  });

  group('session-expiry interceptor', () {
    Future<bool> expiresAfter(
      Future<ResponseBody> Function(RequestOptions) whoAmI,
      int resourceStatus,
    ) async {
      adapter.handler = (o) async =>
          o.uri.path.endsWith('frappe.auth.get_logged_user')
          ? await whoAmI(o)
          : _json(resourceStatus, {'exc_type': 'PermissionError'});
      var fired = false;
      final sub = api.sessionExpired.listen((_) => fired = true);
      await expectLater(
        api.getJson('/api/resource/CRM%20Lead'),
        throwsA(isA<AppException>()),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      return fired;
    }

    test('401 and the server says Guest → session expired', () async {
      expect(
        await expiresAfter(_loggedUser({'message': 'Guest'}), 401),
        isTrue,
      );
    });

    test('500 → never checks or expires the session', () async {
      expect(
        await expiresAfter(_loggedUser({'message': 'Guest'}), 500),
        isFalse,
      );
    });

    test('403 and the server says Guest → session expired', () async {
      expect(
        await expiresAfter(_loggedUser({'message': 'Guest'}), 403),
        isTrue,
      );
    });

    test('403 but still logged in (no permission) → not expired', () async {
      expect(
        await expiresAfter(_loggedUser({'message': 'ravi@example.com'}), 403),
        isFalse,
      );
    });

    test('network error during the check → not expired', () async {
      expect(await expiresAfter(_networkError, 401), isFalse);
    });

    test('network error on a request → never checks the session', () async {
      adapter.paths.clear();
      adapter.handler = _networkError;
      var fired = false;
      final sub = api.sessionExpired.listen((_) => fired = true);
      await expectLater(
        api.getJson('/api/resource/CRM%20Lead'),
        throwsA(
          isA<AppException>().having((e) => e.error, 'error', AppError.network),
        ),
      );
      await sub.cancel();
      expect(fired, isFalse);
      expect(
        adapter.paths.where((p) => p.contains('get_logged_user')),
        isEmpty,
      );
    });
  });

  test('normalizeUrl keeps only scheme + host', () {
    expect(
      ApiClient.normalizeUrl('crm.example.com'),
      'https://crm.example.com',
    );
    expect(
      ApiClient.normalizeUrl(' HTTP://CRM.example.com:8000/app/leads?x=1 '),
      'http://crm.example.com:8000',
    );
    expect(
      ApiClient.normalizeUrl('https://scribble-vitalize-sugar.ngrok-free.dev/'),
      'https://scribble-vitalize-sugar.ngrok-free.dev',
    );
  });
}
