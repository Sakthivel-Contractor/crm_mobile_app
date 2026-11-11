import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';

/// Persists the site URL (shared_preferences) and the signed-in user
/// (flutter_secure_storage).
///
/// Storage must never block or break the app: every call is time-limited,
/// failures are logged, and values are also kept in memory so the current
/// run keeps working even if the device storage does not.
class AppStorage {
  AppStorage._();

  static const _siteUrlKey = 'site_url';
  static const _usernameKey = 'username';
  static const _fullNameKey = 'full_name';

  static const Duration _timeout = Duration(seconds: 3);

  /// Android: Keystore-backed encryption (AES-GCM data, RSA-OAEP wrapped
  /// key). flutter_secure_storage v11 removed the old
  /// `encryptedSharedPreferences` option (Jetpack Security is deprecated);
  /// this is its replacement.
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  /// The same Keystore-backed store, for other secure settings (app lock).
  static FlutterSecureStorage get secure => _secure;

  /// Last known values, used when the device storage fails.
  static final Map<String, String?> _memory = {};

  /// Runs [action]; on timeout or any error logs it and returns [fallback].
  static Future<T> _guard<T>(
    String what,
    Future<T> Function() action,
    T fallback,
  ) async {
    try {
      return await action().timeout(_timeout);
    } catch (e) {
      logDebug('AppStorage $what failed: $e');
      return fallback;
    }
  }

  /// Saved in shared_preferences and, as a backup, in secure storage — the
  /// session is useless without it, and some phones' preferences are flaky.
  static Future<void> saveSiteUrl(String url) async {
    _memory[_siteUrlKey] = url;
    await _guard('saveSiteUrl', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_siteUrlKey, url);
    }, null);
    await _guard(
      'saveSiteUrl backup',
      () => _secure.write(key: _siteUrlKey, value: url),
      null,
    );
  }

  static Future<String?> loadSiteUrl() async {
    final fromPrefs = await _guard('loadSiteUrl', () async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_siteUrlKey);
    }, null);
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;
    return _readSecure(_siteUrlKey);
  }

  static Future<void> saveUser({
    required String username,
    required String fullName,
  }) async {
    _memory[_usernameKey] = username;
    _memory[_fullNameKey] = fullName;
    await _guard('saveUser', () async {
      await _secure.write(key: _usernameKey, value: username);
      await _secure.write(key: _fullNameKey, value: fullName);
    }, null);
  }

  static Future<String?> loadUsername() => _readSecure(_usernameKey);

  static Future<String?> loadFullName() => _readSecure(_fullNameKey);

  static Future<String?> _readSecure(String key) => _guard(
    'read $key',
    () async => await _secure.read(key: key) ?? _memory[key],
    _memory[key],
  );

  static Future<void> clearUser() async {
    _memory
      ..remove(_usernameKey)
      ..remove(_fullNameKey);
    await _guard('clearUser', () async {
      await _secure.delete(key: _usernameKey);
      await _secure.delete(key: _fullNameKey);
    }, null);
  }
}
