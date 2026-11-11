import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/app_lock.dart';
import '../../l10n/app_localizations.dart';
import '../auth/sign_out.dart';
import 'widgets/pin_entry.dart';

enum PinSetupMode {
  /// Set a new PIN (turns the lock on).
  create,

  /// Check the current PIN, then set a new one.
  change,

  /// Check the current PIN only (before turning the lock off).
  verify,
}

enum _Step { current, create, confirm }

/// Pops `true` when the PIN was set / changed / verified.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.mode});

  final PinSetupMode mode;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  late _Step _step = widget.mode == PinSetupMode.create
      ? _Step.create
      : _Step.current;
  String? _firstPin;
  PinNotice? _notice;
  bool _busy = false;

  Future<void> _onPin(String pin) async {
    switch (_step) {
      case _Step.current:
        await _checkCurrent(pin);
      case _Step.create:
        setState(() {
          _firstPin = pin;
          _notice = null;
          _step = _Step.confirm;
        });
      case _Step.confirm:
        if (pin != _firstPin) {
          setState(() {
            _firstPin = null;
            _notice = PinNotice.mismatch;
            _step = _Step.create;
          });
          return;
        }
        setState(() => _busy = true);
        await AppLock.instance.setPin(pin);
        if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _checkCurrent(String pin) async {
    final result = await AppLock.instance.checkPin(pin);
    if (!mounted) return;
    switch (result) {
      case PinCheck.ok:
        if (widget.mode == PinSetupMode.verify) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _notice = null;
            _step = _Step.create;
          });
        }
      case PinCheck.wrong:
        setState(() => _notice = PinNotice.wrong);
      case PinCheck.blocked:
        setState(() => _notice = PinNotice.blocked);
      case PinCheck.signOut:
        setState(() => _busy = true);
        await signOutToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (_step) {
      _Step.current => l10n.enterCurrentPin,
      _Step.create => l10n.createPinTitle(AppLock.pinLength),
      _Step.confirm => l10n.confirmPinTitle,
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.mode == PinSetupMode.change ? l10n.changePin : l10n.appLock,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: PinEntry(
              // New key per step so the dots reset between steps.
              key: ValueKey(_step),
              title: title,
              notice: _notice,
              busy: _busy,
              onCompleted: _onPin,
            ),
          ),
        ),
      ),
    );
  }
}
