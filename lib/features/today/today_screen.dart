import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../core/contact_links.dart';
import '../../core/push_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/sign_out.dart';
import '../leads/lead_detail_screen.dart';
import '../leads/widgets/lead_card.dart';
import 'today_controller.dart';
import 'today_model.dart';
import 'widgets/today_card.dart';

/// The salesperson's daily call list. The controller is owned by the app
/// shell so the bottom-nav badge and auto-refresh share it.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.controller});

  final TodayController controller;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodayController get _c => widget.controller;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    final error = await _c.refresh();
    if (error != null && mounted) _snack(appErrorMessage(_l10n, error));
  }

  Future<void> _open(Uri? uri) async {
    if (uri == null || !await openExternal(uri)) {
      if (mounted) _snack(_l10n.couldNotOpenApp);
    }
  }

  /// Tap handler for a validated phone link, or null (button disabled).
  VoidCallback? _linkAction(String? phone, Uri? Function(String) build) {
    final uri = phone == null ? null : build(phone);
    return uri == null ? null : () => _open(uri);
  }

  Future<void> _openLead(TodayItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeadDetailScreen(lead: item.lead),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.tabToday),
              Text(
                DateFormat('EEE, d MMM', locale).format(_c.now),
                style: text.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListenableBuilder(
          listenable: _c,
          builder: (context, _) => _buildBody(
            l10n,
            centeredContentPadding(constraints.maxWidth, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, EdgeInsets padding) {
    if (_c.isLoading) return LeadSkeletonList(padding: padding);

    if (!_c.hasLoaded) {
      final error = _c.error ?? AppError.unknown;
      final unauthorized = error == AppError.unauthorized;
      return Center(
        child: SingleChildScrollView(
          child: StateMessage(
            icon: error == AppError.network
                ? Icons.wifi_off_rounded
                : Icons.cloud_off_outlined,
            title: appErrorMessage(l10n, error),
            actionLabel: unauthorized ? l10n.loginAgain : l10n.retry,
            onAction: unauthorized ? () => signOutToLogin(context) : _c.load,
          ),
        ),
      );
    }

    final items = _c.visibleItems;
    final now = _c.now;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          ListenableBuilder(
            listenable: PushService.instance,
            builder: (context, _) => PushService.instance.showPermissionCard
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationsOffCard(l10n: l10n),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            children: [
              Expanded(
                child: TodayStatTile(
                  label: l10n.statTotal,
                  value: _c.total,
                  color: AppTheme.textStrong,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TodayStatTile(
                  label: l10n.overdue,
                  value: _c.count(TodayItemType.overdue),
                  color: todayOverdueColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TodayStatTile(
                  label: l10n.statNew,
                  value: _c.count(TodayItemType.newLead),
                  color: todayNewColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (filter, label, count) in [
                  (null, l10n.filterAll, _c.total),
                  (
                    TodayItemType.overdue,
                    l10n.overdue,
                    _c.count(TodayItemType.overdue),
                  ),
                  (
                    TodayItemType.dueToday,
                    l10n.filterDueToday,
                    _c.count(TodayItemType.dueToday),
                  ),
                  (
                    TodayItemType.newLead,
                    l10n.statNew,
                    _c.count(TodayItemType.newLead),
                  ),
                ]) ...[
                  AppChip(
                    label: l10n.chipWithCount(label, count),
                    selected: _c.filter == filter,
                    onTap: () => _c.setFilter(filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: StateMessage(
                icon: Icons.check_circle_outline,
                title: l10n.noCallsToday,
                message: l10n.noCallsTodayHint,
              ),
            ),
          for (final item in items) ...[
            TodayCard(
              item: item,
              now: now,
              onTap: () => _openLead(item),
              onCall: _linkAction(item.lead.mobileNo, telUri),
              onWhatsApp: _linkAction(item.lead.mobileNo, whatsappUri),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// One-time hint when notification permission was denied.
class _NotificationsOffCard extends StatelessWidget {
  const _NotificationsOffCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notificationsOffTitle,
                      style: text.titleSmall?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.notificationsOffBody,
                      style: text.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: PushService.instance.dismissPermissionCard,
                child: Text(l10n.dismiss),
              ),
              TextButton(
                onPressed: PushService.instance.openSettings,
                child: Text(l10n.enableNotifications),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
