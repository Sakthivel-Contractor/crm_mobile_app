import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'log.dart';
import 'storage.dart';

/// Result of checking an entered PIN.
enum PinCheck {
  ok,
  wrong,

  /// Too many wrong PINs; wait [AppLock.blockedFor] before trying again.
  blocked,

  /// [AppLock.maxFailures] wrong PINs in a row: the caller must sign out.
  signOut,
}

/// Result of a fingerprint / face prompt. Display text is chosen by widgets.
enum BiometricResult { success, cancelled, notAvailable, lockedOut, failed }

/// Optional app lock (default off): a 4-digit PIN, plus fingerprint / face
/// unlock if the user turns it on.
///
/// - The PIN is stored only as a salted PBKDF2-HMAC-SHA256 hash, in
///   flutter_secure_storage (Keystore AES-GCM). It is never logged.
/// - Locks on app start and when the app returns after [relockAfter] in the
///   background.
/// - After [failuresBeforeWait] wrong PINs the user must wait (30 s, doubling
///   each time); after [maxFailures] the app signs out. The count survives
///   restarts.
/// - Cleared on sign-out and session expiry (the next user sets their own).
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  AppLock._();

  static final AppLock instance = AppLock._();

  static const int pinLength = 4;
  static const Duration relockAfter = Duration(minutes: 1);
  static const int failuresBeforeWait = 5;
  static const int maxFailures = 10;
  static const Duration _firstWait = Duration(seconds: 30);

  static const _pinKey = 'app_lock_pin';
  static const _biometricKey = 'app_lock_biometric';
  static const _failuresKey = 'app_lock_failures';
  static const _blockedUntilKey = 'app_lock_blocked_until';

  /// PBKDF2 rounds for new PINs (stored with the hash, so it can change).
  @visibleForTesting
  static int iterations = 60000;

  /// Clock, replaceable in tests.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// Android only (the app ships for Android; web has no lock).
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final LocalAuthentication _auth = LocalAuthentication();

  String? _pinRecord;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _locked = false;
  int _failures = 0;
  DateTime? _blockedUntil;
  DateTime? _backgroundedAt;
  bool _promptOpen = false;
  bool _observing = false;

  /// A PIN is set, so the lock is on.
  bool get enabled => _pinRecord != null;
  bool get biometricEnabled => enabled && _biometricEnabled;

  /// The device has fingerprint / face unlock set up.
  bool get biometricAvailable => _biometricAvailable;
  bool get locked => enabled && _locked;

  /// Time left before another PIN may be tried, or null.
  Duration? get blockedFor {
    final until = _blockedUntil;
    if (until == null) return null;
    final left = until.difference(now());
    return left > Duration.zero ? left : null;
  }

  /// Wrong PINs allowed before the next wait starts.
  int get attemptsBeforeWait =>
      max(0, failuresBeforeWait - _failures % failuresBeforeWait);

  /// Call once before runApp. A saved PIN means the app starts locked.
  Future<void> load() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (!isSupported) return;
    _pinRecord = await _read(_pinKey);
    _biometricEnabled = await _read(_biometricKey) == '1';
    _failures = int.tryParse(await _read(_failuresKey) ?? '') ?? 0;
    final until = int.tryParse(await _read(_blockedUntilKey) ?? '');
    _blockedUntil = until == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(until);
    _locked = enabled;
    await refreshBiometricAvailability();
    notifyListeners();
  }

  // ---- PIN ----

  /// Sets (or changes) the PIN and turns the lock on.
  Future<void> setPin(String pin) async {
    assert(isValidPin(pin));
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final rounds = iterations;
    final hash = await _hash(pin, salt, rounds);
    _pinRecord = 'v1:$rounds:${base64Encode(salt)}:${base64Encode(hash)}';
    _locked = false;
    await _write(_pinKey, _pinRecord);
    await _resetFailures();
    notifyListeners();
  }

  static bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  /// Checks [pin]; unlocks the app when it is right.
  Future<PinCheck> checkPin(String pin) async {
    if (blockedFor != null) return PinCheck.blocked;
    if (await _matches(pin)) {
      await _resetFailures();
      _unlock();
      return PinCheck.ok;
    }
    _failures++;
    await _write(_failuresKey, '$_failures');
    if (_failures >= maxFailures) return PinCheck.signOut;
    if (_failures % failuresBeforeWait == 0) {
      final rounds = _failures ~/ failuresBeforeWait;
      _blockedUntil = now().add(_firstWait * (1 << (rounds - 1)));
      await _write(
        _blockedUntilKey,
        '${_blockedUntil!.millisecondsSinceEpoch}',
      );
      notifyListeners();
      return PinCheck.blocked;
    }
    notifyListeners();
    return PinCheck.wrong;
  }

  Future<bool> _matches(String pin) async {
    final parts = _pinRecord?.split(':');
    if (parts == null || parts.length != 4 || parts[0] != 'v1') return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return false;
    try {
      final hash = await _hash(pin, base64Decode(parts[2]), rounds);
      return _constantTimeEquals(hash, base64Decode(parts[3]));
    } on FormatException {
      return false;
    }
  }

  /// Turns the lock off and forgets the PIN and fingerprint choice.
  /// Also used on sign-out.
  Future<void> disable() async {
    _pinRecord = null;
    _biometricEnabled = false;
    _locked = false;
    _backgroundedAt = null;
    for (final key in [_pinKey, _biometricKey]) {
      await _write(key, null);
    }
    await _resetFailures();
    notifyListeners();
  }

  // ---- Fingerprint / face ----

  Future<void> refreshBiometricAvailability() async {
    if (!isSupported) return;
    try {
      final available =
          await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
      if (available != _biometricAvailable) {
        _biometricAvailable = available;
        notifyListeners();
      }
    } catch (e) {
      logDebug('Biometric check failed: $e');
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    notifyListeners();
    await _write(_biometricKey, value ? '1' : null);
  }

  /// Shows the system fingerprint / face prompt; unlocks on success.
  Future<BiometricResult> authenticate({
    required String reason,
    required String title,
    required String cancel,
  }) async {
    if (!_biometricAvailable) return BiometricResult.notAvailable;
    if (_promptOpen) return BiometricResult.cancelled;
    _promptOpen = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: [
          AndroidAuthMessages(signInTitle: title, cancelButton: cancel),
        ],
      );
      if (!ok) return BiometricResult.failed;
      _unlock();
      return BiometricResult.success;
    } on LocalAuthException catch (e) {
      logDebug('Biometric prompt ended: ${e.code.name}');
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress => BiometricResult.cancelled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable => BiometricResult.notAvailable,
        _ => BiometricResult.failed,
      };
    } catch (e) {
      logDebug('Biometric prompt failed: $e');
      return BiometricResult.failed;
    } finally {
      _promptOpen = false;
    }
  }

  // ---- Lifecycle ----

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!enabled) return;
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // The fingerprint prompt itself can pause the app; ignore that.
        if (!_promptOpen) _backgroundedAt ??= now();
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            !_locked &&
            now().difference(since) >= relockAfter) {
          _locked = true;
          notifyListeners();
        }
        refreshBiometricAvailability();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// System back on the lock screen leaves the app instead of reaching the
  /// hidden screens. (Registered before the app's navigator, so runs first.)
  @override
  Future<bool> didPopRoute() async {
    if (!locked) return false;
    await SystemNavigator.pop();
    return true;
  }

  /// Locks immediately (tests and future "lock now" action).
  @visibleForTesting
  void lockNow() {
    if (!enabled) return;
    _locked = true;
    notifyListeners();
  }

  // ---- Helpers ----

  void _unlock() {
    _backgroundedAt = null;
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }

  Future<void> _resetFailures() async {
    _failures = 0;
    _blockedUntil = null;
    await _write(_failuresKey, null);
    await _write(_blockedUntilKey, null);
  }

  static Future<String?> _read(String key) async {
    try {
      return await AppStorage.secure
          .read(key: key)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      logDebug('AppLock read $key failed: $e');
      return null;
    }
  }

  static Future<void> _write(String key, String? value) async {
    try {
      final secure = AppStorage.secure;
      await (value == null
              ? secure.delete(key: key)
              : secure.write(key: key, value: value))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      logDebug('AppLock write $key failed: $e');
    }
  }

  /// Hashing takes ~0.1 s on a phone, so it runs off the UI thread.
  static Future<List<int>> _hash(String pin, List<int> salt, int rounds) =>
      rounds < 1000
      ? Future.value(_pbkdf2([pin, salt, rounds]))
      : compute(_pbkdf2, [pin, salt, rounds]);
}

/// PBKDF2-HMAC-SHA256, one 32-byte block. Args: [pin, salt, rounds].
List<int> _pbkdf2(List<Object> args) {
  final pin = args[0] as String;
  final salt = args[1] as List<int>;
  final rounds = args[2] as int;
  final hmac = Hmac(sha256, utf8.encode(pin));
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = List<int>.of(u);
  for (var i = 1; i < rounds; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
