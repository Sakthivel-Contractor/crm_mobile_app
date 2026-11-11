import 'dart:async';

import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'core/api_client.dart';
import 'core/app_lock.dart';
import 'core/locale_controller.dart';
import 'core/push_service.dart';
import 'core/screen_security.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/sign_out.dart';
import 'features/lock/app_lock_gate.dart';
import 'features/shell/app_shell.dart';
import 'l10n/app_localizations.dart';
import 'core/log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start-up work must never block the first frame: each step is
  // time-limited and failures fall back to defaults.
  await Future.wait([
    _guarded('language', LocaleController.instance.load),
    _guarded('screen security', ScreenSecurity.instance.load),
    // A saved PIN means the app starts locked.
    _guarded('app lock', AppLock.instance.load),
    // Cookie jar + saved base URL ready before the session check.
    _guarded('api client', ApiClient.instance.init),
  ]);
  // Needs the language for the notification channel name.
  await _guarded(
    'push notifications',
    () => PushService.instance.init(LocaleController.instance.locale),
  );
  runApp(const HiTechCrmApp());
}

Future<void> _guarded(String what, Future<void> Function() step) async {
  try {
    await step().timeout(const Duration(seconds: 5));
  } catch (e) {
    logDebug('Start-up step "$what" failed: $e');
  }
}

class HiTechCrmApp extends StatefulWidget {
  const HiTechCrmApp({super.key});

  @override
  State<HiTechCrmApp> createState() => _HiTechCrmAppState();
}

class _HiTechCrmAppState extends State<HiTechCrmApp> {
  /// Server confirmed the session is gone → same path as Logout.
  late final StreamSubscription<void> _expiry = ApiClient
      .instance
      .sessionExpired
      .listen((_) => signOutToLogin());

  @override
  void initState() {
    super.initState();
    _expiry; // start listening
    LocaleController.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _expiry.cancel();
    LocaleController.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  /// Keeps the notification channel name in the chosen language.
  void _onLocaleChanged() =>
      PushService.instance.updateLanguage(LocaleController.instance.locale);

  @override
  Widget build(BuildContext context) {
    final localeController = LocaleController.instance;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => MaterialApp(
        navigatorKey: appNavigatorKey,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => AppTheme.clampTextScale(
          context,
          AppLockGate(child: child ?? const SizedBox.shrink()),
        ),
        locale: localeController.locale,
        supportedLocales: LocaleController.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const _StartupGate(),
      ),
    );
  }
}

/// Splash: opens AppShell if a saved session is valid (or the server is just
/// unreachable), otherwise LoginScreen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<SessionRestore> _session = _restore();

  static Future<SessionRestore> _restore() async {
    try {
      // Dio's own timeouts end this sooner; this is only a safety net.
      final result = await ApiClient.instance.restoreSession().timeout(
        const Duration(seconds: 40),
      );
      // Server says signed out: the next user sets their own PIN.
      if (result.state == SessionState.loggedOut) {
        // preserved app lock
      }
      return result;
    } catch (e) {
      logDebug('Restoring session failed: $e');
      return const SessionRestore(SessionState.loggedOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionRestore>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data;
        final user = result?.user;
        if (result == null ||
            result.state == SessionState.loggedOut ||
            user == null) {
          return const LoginScreen();
        }
        return AppShell(
          fullName: user.fullName,
          startOffline: result.state == SessionState.offline,
        );
      },
    );
  }
}
