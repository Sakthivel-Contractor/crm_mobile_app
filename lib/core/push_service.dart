// Classic FCM registration tokens are used on purpose: the server sends with
// them (firebase-admin / FCM HTTP v1 `token`). firebase_messaging 17
// deprecates them in favour of Firebase Installation IDs (register() /
// onRegistered) for FCM "direct send"; switch here and on the server together.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'api_client.dart';
import 'app_error.dart';
import 'log.dart';

/// Runs in its own isolate when a message arrives while the app is in the
/// background or closed. Notification messages are shown by the system on
/// the "new_leads" channel (AndroidManifest meta-data), so nothing else is
/// needed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logDebug('[push] background message ${message.messageId}');
}

/// Firebase Cloud Messaging for Android (no-op on web and other platforms):
/// permission, device registration with the Frappe server, foreground
/// notifications and opening the tapped lead.
class PushService extends ChangeNotifier {
  PushService._();

  static final PushService instance = PushService._();

  static const String channelId = 'new_leads';
  static const String _registerPath =
      '/api/method/hitech.api.register_device';
  static const String _unregisterPath =
      '/api/method/hitech.api.unregister_device';
  static const String _cardDismissedKey = 'notifications_card_dismissed';
  static const MethodChannel _device = MethodChannel('com.hitech.crm/device');

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool? _enabled;
  bool _cardDismissed = false;
  String? _token;
  StreamSubscription<String>? _tokenRefresh;

  /// The registration in progress, shared by overlapping callers.
  Future<void>? _registering;

  /// Bumped on unregister; a registration started before it is dropped.
  int _session = 0;

  /// The last registration attempt failed; retried once on next resume.
  bool _retryOnResume = false;

  /// Seeded from the clock so ids don't repeat across app starts (a repeated
  /// id replaces the older notification in the tray). Android ids are int32.
  int _notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
    0x7FFFFFFF,
  );
  String _channelName = 'New leads';

  final _newLeads = StreamController<String>.broadcast();

  /// A lead to open because a notification was tapped. The app shell opens
  /// it once the user is signed in, then clears it.
  final ValueNotifier<String?> leadToOpen = ValueNotifier<String?>(null);

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Notifications allowed by the user; null until known.
  bool? get enabled => _enabled;

  /// Show the "Notifications are off" card on Today (once, until dismissed).
  bool get showPermissionCard => _enabled == false && !_cardDismissed;

  /// Fires with the lead name when a "new_lead" message arrives while the
  /// app is open, so lists can refresh.
  Stream<String> get newLeads => _newLeads.stream;

  /// The lead name from a message's data, if it is a new-lead message.
  static String? leadFromData(Map<String, dynamic> data) {
    if (data['type'] != 'new_lead') return null;
    final lead = data['lead'];
    if (lead is! String) return null;
    final name = lead.trim();
    // Frappe document names: no control characters, sane length.
    if (name.isEmpty ||
        name.length > 140 ||
        name.contains(RegExp(r'[\x00-\x1F]'))) {
      return null;
    }
    return name;
  }

  /// Call once in main() before runApp, after the language is loaded.
  Future<void> init(Locale locale) async {
    if (!isSupported || _ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotifications(locale);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _openFromData(m.data));

      // App launched by tapping a notification while it was closed.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _openFromData(initial.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _openFromPayload(launch!.notificationResponse?.payload);
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        _cardDismissed = prefs.getBool(_cardDismissedKey) ?? false;
      } catch (e) {
        logDebug('[push] reading card setting failed: $e');
      }
      _ready = true;
      await refreshPermissionStatus();
    } catch (e) {
      logDebug('[push] init failed: $e');
    }
  }

  Future<void> _initLocalNotifications(Locale locale) async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notify'),
      ),
      onDidReceiveNotificationResponse: (r) => _openFromPayload(r.payload),
    );
    await _createChannel(locale);
  }

  /// Creates the channel, or renames it in [locale] (Android keeps the
  /// user's sound/importance choices when a channel is re-created).
  Future<void> _createChannel(Locale locale) async {
    final l10n = lookupAppLocalizations(locale);
    _channelName = l10n.channelNewLeads;
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            l10n.channelNewLeads,
            description: l10n.channelNewLeadsDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

  /// The app language changed: show the channel name in it.
  Future<void> updateLanguage(Locale locale) async {
    if (!_ready) return;
    try {
      await _createChannel(locale);
    } catch (e) {
      logDebug('[push] renaming channel failed: $e');
    }
  }

  /// Asks for permission (Android 13+ shows the system prompt) only if the
  /// user has never answered; after a denial the Today card and Profile row
  /// lead to the system settings instead of prompting again.
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      var status =
          (await messaging.getNotificationSettings()).authorizationStatus;
      if (shouldPrompt(status)) {
        status = (await messaging.requestPermission()).authorizationStatus;
      }
      _setEnabled(status);
    } catch (e) {
      logDebug('[push] permission request failed: $e');
    }
  }

  /// Only a user who was never asked gets the system prompt.
  static bool shouldPrompt(AuthorizationStatus status) =>
      status == AuthorizationStatus.notDetermined;

  /// Re-reads the permission (e.g. after returning from system settings).
  Future<void> refreshPermissionStatus() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      _setEnabled(settings.authorizationStatus);
    } catch (e) {
      logDebug('[push] reading permission failed: $e');
    }
  }

  void _setEnabled(AuthorizationStatus status) {
    final enabled =
        status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    if (enabled != _enabled) {
      _enabled = enabled;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    if (!_ready) return;
    try {
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } catch (e) {
      logDebug('[push] opening settings failed: $e');
    }
  }

  Future<void> dismissPermissionCard() async {
    _cardDismissed = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cardDismissedKey, true);
    } catch (e) {
      logDebug('[push] saving card setting failed: $e');
    }
  }

  /// After login and on every start while signed in: ask for permission,
  /// then send this device's FCM token to the Frappe server. Overlapping
  /// calls share one registration.
  Future<void> registerDevice() {
    if (!_ready) return Future.value();
    return _registering ??= _registerDevice().whenComplete(
      () => _registering = null,
    );
  }

  /// Called when the signed-in app returns to the foreground: repeats a
  /// failed registration once (no loop â€” a new failure waits for the next
  /// resume).
  Future<void> retryRegistrationIfNeeded() {
    if (!_retryOnResume) return Future.value();
    _retryOnResume = false;
    return registerDevice();
  }

  Future<void> _registerDevice() async {
    final session = _session;
    await requestPermission();
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || session != _session) return;
      await _register(token, session);
      if (session != _session) return;
      _tokenRefresh ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => _register(token, _session),
      );
    } catch (e) {
      logDebug('[push] getting token failed: $e');
    }
  }

  Future<void> _register(String token, int session) async {
    String? deviceName;
    try {
      deviceName = await _device.invokeMethod<String>('deviceModel');
    } catch (_) {}
    // Signed out meanwhile: don't register for the old session.
    if (session != _session) return;
    _token = token;
    try {
      await ApiClient.instance.postJson(_registerPath, {
        'token': token,
        'platform': 'android',
        'device_name': deviceName ?? 'Android',
      });
      logDebug('[push] device registered');
      _retryOnResume = false;
    } on AppException catch (e) {
      // e.g. offline or the server app is not installed yet: try again when
      // the app next comes to the foreground (or on next start).
      _retryOnResume = e.error != AppError.unauthorized;
      logDebug('[push] register_device failed: ${e.error}');
    }
  }


  /// Returns a human-readable diagnostic string showing the FCM token and
  /// the result of calling register_device on the server. Used by the
  /// Profile page debug button to diagnose why token count stays at 0.
  Future<String> runDiagnostic() async {
    if (!isSupported) {
      return 'Push notifications: not supported on this platform.';
    }
    if (!_ready) {
      return 'PushService not ready.\nFirebase may have failed to initialise.\nCheck google-services.json and internet connection.';
    }

    // 1. Get FCM token from Firebase
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return 'ERROR: getToken() threw: $e';
    }
    if (token == null) {
      return 'ERROR: FirebaseMessaging.getToken() returned null.\n\nCauses:\n  - No internet connection at launch\n  - google-services.json package_name mismatch\n  - Google Play Services unavailable on device';
    }
    final shortToken = '${token.substring(0, 20)}...${token.substring(token.length - 8)}';

    // 2. Get device name via MethodChannel
    String? deviceName;
    try {
      deviceName = await _device.invokeMethod<String>('deviceModel');
    } catch (_) {}

    // 3. POST register_device to Frappe server
    try {
      final result = await ApiClient.instance.postJson(_registerPath, {
        'token': token,
        'platform': 'android',
        'device_name': deviceName ?? 'Android',
      });
      return 'Token: $shortToken\nDevice: ${deviceName ?? "Android"}\n\nRegistration: SUCCESS\nServer: $result';
    } on AppException catch (e) {
      final hint = switch (e.error) {
        AppError.unauthorized => 'Session expired - log out and back in.',
        AppError.network => 'Cannot reach server - check internet / ngrok.',
        AppError.server => 'Frappe server error - is hitech app installed?',
        _ => '',
      };
      return 'Token: $shortToken\nDevice: ${deviceName ?? "Android"}\n\nRegistration: FAILED\nError: ${e.error}\n\n$hint';
    } catch (e) {
      return 'Token: $shortToken\n\nUnexpected error: $e';
    }
  }
  /// On logout, before the session is cleared: remove this device from the
  /// server, delete the FCM token and clear this user's notifications.
  Future<void> unregisterDevice() async {
    if (!_ready) return;
    _session++;
    _retryOnResume = false;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    // Let a registration already sent finish first, so the server sees
    // register â†’ unregister in that order.
    await _registering;
    try {
      final token = _token ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiClient.instance.postJson(_unregisterPath, {'token': token});
      }
    } on AppException catch (e) {
      logDebug('[push] unregister_device failed: ${e.error}');
    } catch (e) {
      logDebug('[push] unregister failed: $e');
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      logDebug('[push] deleteToken failed: $e');
    }
    // Lead names must not stay in the tray for the next user.
    try {
      await _local.cancelAll();
    } catch (e) {
      logDebug('[push] clearing notifications failed: $e');
    }
    _token = null;
    leadToOpen.value = null;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] as String?;
    final body = message.notification?.body ?? data['body'] as String?;
    if (title != null || body != null) {
      try {
        await _local.show(
          id: _notificationId = (_notificationId + 1) & 0x7FFFFFFF,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
              icon: 'ic_stat_notify',
            ),
          ),
          payload: jsonEncode(data),
        );
      } catch (e) {
        logDebug('[push] showing notification failed: $e');
      }
    }
    final lead = leadFromData(data);
    if (lead != null) _newLeads.add(lead);
  }

  /// The lead name in a local notification's payload (JSON message data).
  static String? leadFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload);
      return data is Map<String, dynamic> ? leadFromData(data) : null;
    } on FormatException {
      return null;
    }
  }

  void _openFromPayload(String? payload) {
    final lead = leadFromPayload(payload);
    if (lead != null) leadToOpen.value = lead;
  }

  void _openFromData(Map<String, dynamic> data) {
    final lead = leadFromData(data);
    if (lead != null) leadToOpen.value = lead;
  }
}
