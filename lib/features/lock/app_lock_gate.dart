import 'package:flutter/material.dart';

import '../../core/app_lock.dart';
import 'lock_screen.dart';

/// Wraps the whole navigator (MaterialApp.builder). While locked, the app
/// underneath keeps its state but is not painted, focusable, animated or
/// read by screen readers; the [LockScreen] is shown on top.
class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLock.instance,
      builder: (context, _) {
        final locked = AppLock.instance.locked;
        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              excluding: locked,
              child: TickerMode(
                enabled: !locked,
                child: Offstage(offstage: locked, child: child),
              ),
            ),
            if (locked) const LockScreen(),
          ],
        );
      },
    );
  }
}
