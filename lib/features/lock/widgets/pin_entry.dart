import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/app_lock.dart';
import '../../../l10n/app_localizations.dart';

/// What to show under the PIN dots. Kept as an enum so it re-translates.
enum PinNotice {
  wrong,
  blocked,
  mismatch,
  biometricLockedOut,
  biometricNotAvailable,
  biometricFailed,
}

/// Localized text for [notice]; null when there is nothing to show
/// (e.g. a wait that has already ended).
String? pinNoticeText(AppLocalizations l10n, PinNotice? notice) {
  final lock = AppLock.instance;
  return switch (notice) {
    null => null,
    PinNotice.wrong => l10n.wrongPin(lock.attemptsBeforeWait),
    PinNotice.blocked => switch (lock.blockedFor) {
      null => null,
      final left => l10n.pinBlocked((left.inMilliseconds / 1000).ceil()),
    },
    PinNotice.mismatch => l10n.pinMismatch,
    PinNotice.biometricLockedOut => l10n.biometricLockedOut,
    PinNotice.biometricNotAvailable => l10n.biometricNotAvailable,
    PinNotice.biometricFailed => l10n.biometricFailed,
  };
}

/// Title, PIN dots, notice and a number keypad.
///
/// Calls [onCompleted] once [AppLock.pinLength] digits are entered, then
/// clears the dots. The keypad is disabled while [busy] or while a
/// wrong-PIN wait is running.
class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.title,
    required this.onCompleted,
    this.notice,
    this.busy = false,
    this.onBiometric,
  });

  final String title;
  final Future<void> Function(String pin) onCompleted;
  final PinNotice? notice;
  final bool busy;

  /// Shows a fingerprint key in the bottom-left corner.
  final VoidCallback? onBiometric;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  String _pin = '';
  bool _submitting = false;
  Timer? _ticker;

  bool get _blocked => AppLock.instance.blockedFor != null;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(PinEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Rebuilds every second while a wait runs, so the countdown moves and
  /// the keypad comes back when it ends.
  void _syncTicker() {
    if (!_blocked || _ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_blocked) {
        _ticker?.cancel();
        _ticker = null;
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _add(String digit) async {
    if (_pin.length >= AppLock.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length < AppLock.pinLength) return;
    setState(() => _submitting = true);
    try {
      await widget.onCompleted(_pin);
    } finally {
      if (mounted) {
        setState(() {
          _pin = '';
          _submitting = false;
        });
        _syncTicker();
      }
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final notice = pinNoticeText(l10n, widget.notice);
    final enabled = !widget.busy && !_submitting && !_blocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: text.titleMedium?.copyWith(color: AppTheme.textStrong),
        ),
        const SizedBox(height: 20),
        _PinDots(filled: _pin.length),
        const SizedBox(height: 12),
        // Fixed height so the keypad does not jump when a notice appears.
        SizedBox(
          height: 40,
          child: notice == null
              ? null
              : Text(
                  notice,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: AppTheme.error),
                ),
        ),
        const SizedBox(height: 8),
        _Keypad(
          enabled: enabled,
          onDigit: _add,
          onDelete: _pin.isEmpty ? null : _delete,
          onBiometric: widget.busy ? null : widget.onBiometric,
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.pinDigitsEntered(filled, AppLock.pinLength),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < AppLock.pinLength; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < filled ? AppTheme.primary : Colors.transparent,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    required this.onBiometric,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback? onDelete;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget digit(String d) => _Key(
      onTap: enabled ? () => onDigit(d) : null,
      semanticLabel: d,
      child: Text(d),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map(digit).toList(),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            onBiometric == null
                ? const SizedBox(width: _Key.size + 2 * _Key.gap)
                : _Key(
                    key: const ValueKey('pin-biometric'),
                    onTap: onBiometric,
                    semanticLabel: l10n.biometricButton,
                    child: const Icon(Icons.fingerprint, size: 32),
                  ),
            digit('0'),
            _Key(
              key: const ValueKey('pin-delete'),
              onTap: enabled ? onDelete : null,
              semanticLabel: l10n.deleteDigit,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  static const double size = 72;
  static const double gap = 10;

  final VoidCallback? onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = onTap == null ? AppTheme.border : AppTheme.textStrong;
    return Padding(
      padding: const EdgeInsets.all(gap),
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: AppTheme.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: color),
                  child: DefaultTextStyle.merge(
                    style: text.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
