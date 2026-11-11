import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';

/// Optional "block screenshots on lead details" setting (default off).
///
/// On Android it sets FLAG_SECURE on the window while a lead detail screen
/// is open: screenshots, screen recording and the recent-apps thumbnail
/// show a blank screen. Other platforms ignore it. Native side:
/// android/app/src/main/kotlin/.../MainActivity.kt.
class ScreenSecurity extends ChangeNotifier {
  ScreenSecurity._();

  static final ScreenSecurity instance = ScreenSecurity._();

  static const _prefsKey = 'block_screenshots_lead_detail';
  static const MethodChannel _channel = MethodChannel(
    'com.hitech.crm/screen_security',
  );

  bool _blockOnLeadDetail = false;

  bool get blockOnLeadDetail => _blockOnLeadDetail;

  /// Whether this platform supports the setting.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      _blockOnLeadDetail = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      logDebug('Loading screenshot setting failed: $e');
    }
  }

  Future<void> setBlockOnLeadDetail(bool value) async {
    if (value == _blockOnLeadDetail) return;
    _blockOnLeadDetail = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      logDebug('Saving screenshot setting failed: $e');
    }
  }

  /// Turns FLAG_SECURE on/off for the current window (Android only).
  static Future<void> setSecure(bool secure) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } catch (e) {
      logDebug('FLAG_SECURE change failed: $e');
    }
  }
}
