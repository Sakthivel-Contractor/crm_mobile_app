import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_lock.dart';
import '../../core/push_service.dart';
import 'login_screen.dart';

/// Root navigator, so a session expiry detected anywhere can return to login.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _signingOut = false;

/// Logout: clears cookies and the saved user (via [ApiClient.signOut]),
/// replaces the whole navigation stack with the login screen and turns the
/// app lock off (the next user sets their own PIN).
Future<void> signOutToLogin([BuildContext? context]) async {
  if (_signingOut) return;
  _signingOut = true;
  try {
    final navigator = context != null && context.mounted
        ? Navigator.of(context, rootNavigator: true)
        : appNavigatorKey.currentState;
    // Remove this device from the server while the session still works.
    await PushService.instance.unregisterDevice().timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
    await ApiClient.instance.signOut();
    // From the lock screen: swap to login without an animation, so the
    // screens behind the lock are never shown.
    final fromLock = AppLock.instance.locked;
    navigator?.pushAndRemoveUntil(
      fromLock
          ? PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => const LoginScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            )
          : MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    if (fromLock) await WidgetsBinding.instance.endOfFrame;
    // preserved app lock across logouts
  } finally {
    _signingOut = false;
  }
}
