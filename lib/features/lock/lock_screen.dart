import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/app_lock.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_widgets.dart';
import '../auth/sign_out.dart';
import 'widgets/pin_entry.dart';

/// Covers the app while [AppLock.locked]. Sits above the navigator (see
/// [AppLockGate]), so it cannot be popped and uses no dialogs or routes.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  PinNotice? _notice;
  bool _confirmForgot = false;
  bool _signingOut = false;

  /// Below this height the logo is hidden so the keypad fits.
  static const double _brandMinHeight = 700;

  AppLock get _lock => AppLock.instance;

  @override
  void initState() {
    super.initState();
    if (_lock.blockedFor != null) _notice = PinNotice.blocked;
    // Offer the fingerprint straight away.
    if (_lock.biometricEnabled && _lock.biometricAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  Future<void> _onPin(String pin) async {
    final result = await _lock.checkPin(pin);
    if (!mounted) return;
    switch (result) {
      case PinCheck.ok:
        break;
      case PinCheck.wrong:
        setState(() => _notice = PinNotice.wrong);
      case PinCheck.blocked:
        setState(() => _notice = PinNotice.blocked);
      case PinCheck.signOut:
        await _signOut();
    }
  }

  Future<void> _biometric() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final result = await _lock.authenticate(
      reason: l10n.biometricPromptReason,
      title: l10n.biometricPromptTitle,
      cancel: l10n.cancel,
    );
    if (!mounted) return;
    final notice = switch (result) {
      BiometricResult.success || BiometricResult.cancelled => null,
      BiometricResult.lockedOut => PinNotice.biometricLockedOut,
      BiometricResult.notAvailable => PinNotice.biometricNotAvailable,
      BiometricResult.failed => PinNotice.biometricFailed,
    };
    if (notice != null) setState(() => _notice = notice);
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await signOutToLogin();
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final showBiometric = _lock.biometricEnabled && _lock.biometricAvailable;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Short screens (landscape, split screen): keypad first.
                  if (constraints.maxHeight >= _brandMinHeight) ...[
                    const BrandMark(),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appName,
                      style: text.titleLarge?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_confirmForgot)
                    _ForgotPin(
                      busy: _signingOut,
                      onCancel: () => setState(() => _confirmForgot = false),
                      onLogout: _signOut,
                    )
                  else ...[
                    PinEntry(
                      title: l10n.unlockTitle,
                      notice: _notice,
                      busy: _signingOut,
                      onCompleted: _onPin,
                      onBiometric: showBiometric ? _biometric : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _signingOut
                          ? null
                          : () => setState(() => _confirmForgot = true),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, AppTheme.controlHeight),
                      ),
                      child: Text(l10n.forgotPin),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline confirmation (no dialog: there is no navigator above the lock).
class _ForgotPin extends StatelessWidget {
  const _ForgotPin({
    required this.busy,
    required this.onCancel,
    required this.onLogout,
  });

  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.forgotPin,
            style: text.titleMedium?.copyWith(color: AppTheme.textStrong),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.forgotPinBody,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppTheme.controlHeight),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onLogout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    minimumSize: const Size.fromHeight(AppTheme.controlHeight),
                  ),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.logout),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
