import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/language_toggle.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api_client.dart';
import '../../core/app_lock.dart';
import '../../core/push_service.dart';
import '../../core/screen_security.dart';
import '../../l10n/app_localizations.dart';
import '../auth/sign_out.dart';
import '../lock/pin_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.fullName});

  final String fullName;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await signOutToLogin(context);
  }

  Future<bool> _openPinSetup(PinSetupMode mode) async {
    final done = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => PinSetupScreen(mode: mode)));
    return done == true && mounted;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setAppLock(bool on) async {
    final l10n = AppLocalizations.of(context)!;
    if (on) {
      if (await _openPinSetup(PinSetupMode.create)) _showSnack(l10n.appLockOn);
    } else if (await _openPinSetup(PinSetupMode.verify)) {
      await AppLock.instance.disable();
    }
  }

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context)!;
    if (await _openPinSetup(PinSetupMode.change)) _showSnack(l10n.pinChanged);
  }

  /// Turning fingerprint on needs one successful scan first.
  Future<void> _setBiometric(bool on) async {
    final lock = AppLock.instance;
    if (!on) return lock.setBiometricEnabled(false);
    final l10n = AppLocalizations.of(context)!;
    final result = await lock.authenticate(
      reason: l10n.biometricPromptReason,
      title: l10n.biometricPromptTitle,
      cancel: l10n.cancel,
    );
    if (!mounted) return;
    switch (result) {
      case BiometricResult.success:
        await lock.setBiometricEnabled(true);
      case BiometricResult.cancelled:
        break;
      case BiometricResult.lockedOut:
        _showSnack(l10n.biometricLockedOut);
      case BiometricResult.notAvailable:
        _showSnack(l10n.biometricNotAvailable);
      case BiometricResult.failed:
        _showSnack(l10n.biometricFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final name = widget.fullName;
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    const errorColor = AppTheme.error;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: centeredContentPadding(constraints.maxWidth, vertical: 16),
          children: [
            SurfaceCard(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: text.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.dns_outlined,
                    label: l10n.profileServer,
                    value: ApiClient.instance.siteUrl ?? '',
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  _InfoRow(
                    icon: Icons.translate,
                    label: l10n.profileLanguage,
                    trailing: const LanguageToggle(),
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  if (AppLock.isSupported)
                    ListenableBuilder(
                      listenable: AppLock.instance,
                      builder: (context, _) => _AppLockRows(
                        lock: AppLock.instance,
                        onLockChanged: _setAppLock,
                        onChangePin: _changePin,
                        onBiometricChanged: _setBiometric,
                      ),
                    ),
                  if (ScreenSecurity.isSupported) ...[
                    ListenableBuilder(
                      listenable: ScreenSecurity.instance,
                      builder: (context, _) => MergeSemantics(
                        child: _InfoRow(
                          icon: Icons.screenshot_monitor_outlined,
                          label: l10n.blockScreenshots,
                          value: l10n.blockScreenshotsHint,
                          trailing: Switch(
                            value: ScreenSecurity.instance.blockOnLeadDetail,
                            onChanged:
                                ScreenSecurity.instance.setBlockOnLeadDetail,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                  ],
                  if (PushService.isSupported) ...[
                    ListenableBuilder(
                      listenable: PushService.instance,
                      builder: (context, _) {
                        final enabled = PushService.instance.enabled;
                        return _InfoRow(
                          icon: enabled == false
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_outlined,
                          label: l10n.notifications,
                          value: enabled == null
                              ? null
                              : (enabled
                                    ? l10n.notificationsOn
                                    : l10n.notificationsOff),
                          trailing: TextButton(
                            onPressed: PushService.instance.openSettings,
                            child: Text(l10n.openSettings),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                  ],
                  FutureBuilder<PackageInfo>(
                    future: _packageInfo,
                    builder: (context, snapshot) => _InfoRow(
                      icon: Icons.info_outline,
                      label: l10n.profileVersion,
                      value: snapshot.data?.version ?? '',
                    ),
                  ),
                ],
              ),
            ),
            if (PushService.isSupported)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final msg = await PushService.instance.runDiagnostic();
                    if (!mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Push Notification Diagnostic'),
                        content: SingleChildScrollView(
                          child: SelectableText(msg, style: const TextStyle(fontSize: 13)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Test Push Registration'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppTheme.controlHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: const BorderSide(color: errorColor),
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(AppTheme.controlHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// App lock switch, then (when on) Change PIN and the fingerprint switch.
class _AppLockRows extends StatelessWidget {
  const _AppLockRows({
    required this.lock,
    required this.onLockChanged,
    required this.onChangePin,
    required this.onBiometricChanged,
  });

  final AppLock lock;
  final ValueChanged<bool> onLockChanged;
  final VoidCallback onChangePin;
  final ValueChanged<bool> onBiometricChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const divider = Divider(height: 1, color: AppTheme.border);
    return Column(
      children: [
        MergeSemantics(
          child: _InfoRow(
            icon: Icons.lock_outline,
            label: l10n.appLock,
            value: l10n.appLockHint,
            trailing: Switch(value: lock.enabled, onChanged: onLockChanged),
          ),
        ),
        divider,
        if (lock.enabled) ...[
          _InfoRow(
            icon: Icons.password,
            label: l10n.changePin,
            trailing: TextButton(
              onPressed: onChangePin,
              child: Text(l10n.change),
            ),
          ),
          divider,
          if (lock.biometricAvailable) ...[
            MergeSemantics(
              child: _InfoRow(
                icon: Icons.fingerprint,
                label: l10n.useBiometric,
                value: l10n.useBiometricHint,
                trailing: Switch(
                  value: lock.biometricEnabled,
                  onChanged: onBiometricChanged,
                ),
              ),
            ),
            divider,
          ],
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.labelMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (value != null && value!.isNotEmpty)
                    SelectableText(
                      value!,
                      style: text.bodyLarge?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
