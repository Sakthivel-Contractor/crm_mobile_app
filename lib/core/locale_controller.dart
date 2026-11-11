import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';

/// Holds the app language. Tamil is the default; the choice is persisted.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale';
  static const Locale tamil = Locale('ta');
  static const Locale english = Locale('en');
  static const List<Locale> supportedLocales = [tamil, english];

  Locale _locale = tamil;

  Locale get locale => _locale;

  /// Call once before runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = supportedLocales.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => tamil,
    );
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (e) {
      // The switch still applies for this run.
      logDebug('Saving language failed: $e');
    }
  }
}
