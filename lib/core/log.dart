import 'package:flutter/foundation.dart';

/// The app's only logger. Prints in debug builds only — release builds write
/// nothing to the device log.
///
/// Never pass passwords, cookie values, tokens or request/response bodies.
/// (Enforced by test/security_test.dart: no other print/debugPrint in lib/.)
void logDebug(String message) {
  if (kDebugMode) debugPrint(message);
}
