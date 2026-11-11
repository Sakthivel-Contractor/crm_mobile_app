import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/skeleton.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../l10n/app_localizations.dart';
import '../auth/sign_out.dart';
import '../leads/lead_status_style.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';
import 'widgets/count_bar_chart.dart';

/// Opens the Leads tab filtered by one value.
typedef OpenLeads = void Function({
  String? status,
  String? source,
  String? district,
});

const Color _overdueRed = Color(0xFFB42318);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onOpenLeads,
  });

  final DashboardController controller;
  final OpenLeads onOpenLeads;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardController get _c => widget.controller;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  String get _locale => Localizations.localeOf(context).toLanguageTag();

  Future<void> _refresh() async {
    final error = await _c.refresh();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(appErrorMessage(_l10n, error))));
    }
  }

  Future<void> _pickCustomRange() async {
    final now = _c.now;
    final current = _c.customRange ?? _c.range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: current.start,
        end: current.end.isAfter(now) ? now : current.end,
      ),
    );
    if (picked != null) {
      _c.setCustomRange(PeriodRange(picked.start, picked.end));
    }
  }

  String _customLabel() {
    final range = _c.customRange;
    if (_c.period != DashboardPeriod.custom || range == null) {
      return _l10n.periodCustom;
    }
    final f = DateFormat('d MMM', _locale);
    return _l10n.dateRange(f.format(range.start), f.format(range.end));
  }

  String _label(GroupCount g, {bool isStatus = false}) {
    if (g.isOther) return _l10n.chartOther;
    final value = g.value;
    if (value == null) return _l10n.chartNotSet;
    return isStatus ? localizedStatus(_l10n, value) : value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabDashboard)),
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
    final periodRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (period, label) in [
            (DashboardPeriod.today, l10n.periodToday),
            (DashboardPeriod.week, l10n.periodWeek),
            (DashboardPeriod.month, l10n.periodMonth),
          ]) ...[
            AppChip(
              label: label,
              selected: _c.period == period,
              onTap: () => _c.setPeriod(period),
            ),
            const SizedBox(width: 8),
          ],
          AppChip(
            label: _customLabel(),
            selected: _c.period == DashboardPeriod.custom,
            trailingIcon: Icons.date_range_outlined,
            onTap: _pickCustomRange,
          ),
        ],
      ),
    );

    // Skeleton while loading, and before the first load has started.
    if (_c.isLoading || (_c.data == null && _c.error == null)) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [periodRow, const SizedBox(height: 8), const _Skeleton()],
      );
    }

    final data = _c.data;
    if (data == null) {
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

    final total = data.totalLeads;
    final source = _c.bySource;
    final district = _c.byDistrict;
    final updatedAt = _c.updatedAt;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          periodRow,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  icon: Icons.people_alt_outlined,
                  label: l10n.kpiTotalLeads,
                  value: total,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KpiTile(
                  icon: Icons.place_outlined,
                  label: l10n.kpiSiteVisits,
                  value: data.siteVisits,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  icon: Icons.call_outlined,
                  label: l10n.kpiCallsLogged,
                  value: data.callsLogged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KpiTile(
                  icon: Icons.alarm,
                  label: l10n.kpiOverdue,
                  value: data.overdueFollowUps,
                  color: _overdueRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CountBarChart(
            title: l10n.chartFunnel,
            total: total,
            bars: [
              for (final g in _c.funnel)
                CountBar(
                  label: _label(g, isStatus: true),
                  count: g.count,
                  color: StatusStyle.of(_c.statusNamed(g.value)).foreground,
                  onTap: g.value == null || g.count == 0
                      ? null
                      : () => widget.onOpenLeads(status: g.value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CountBarChart(
            title: l10n.chartSource,
            total: total,
            unavailable: source == null,
            bars: [
              for (final g in source ?? const <GroupCount>[])
                CountBar(
                  label: _label(g),
                  count: g.count,
                  color: g.value == null
                      ? AppTheme.textMuted
                      : AppTheme.primary,
                  onTap: g.value == null
                      ? null
                      : () => widget.onOpenLeads(source: g.value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CountBarChart(
            title: l10n.chartDistrict,
            total: total,
            unavailable: district == null,
            bars: [
              for (final g in district ?? const <GroupCount>[])
                CountBar(
                  label: _label(g),
                  count: g.count,
                  color: g.isOther || g.value == null
                      ? AppTheme.textMuted
                      : AppTheme.secondary,
                  onTap: g.isOther || g.value == null
                      ? null
                      : () => widget.onOpenLeads(district: g.value),
                ),
            ],
          ),
          if (updatedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.updatedAt(DateFormat.Hm(_locale).format(updatedAt)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget tile() => const Expanded(
      child: SurfaceCard(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 20, height: 20, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(width: 48, height: 20),
            SizedBox(height: 6),
            SkeletonBox(width: 90, height: 12),
          ],
        ),
      ),
    );
    Widget chart() => SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 120, height: 14),
          for (final w in const [1.0, 0.7, 0.45, 0.25]) ...[
            const SizedBox(height: 16),
            const SkeletonBox(width: 140, height: 12),
            const SizedBox(height: 6),
            FractionallySizedBox(
              widthFactor: w,
              child: const SkeletonBox(height: 8),
            ),
          ],
        ],
      ),
    );

    return SkeletonPulse(
      child: Column(
        children: [
          Row(children: [tile(), const SizedBox(width: 8), tile()]),
          const SizedBox(height: 8),
          Row(children: [tile(), const SizedBox(width: 8), tile()]),
          const SizedBox(height: 16),
          chart(),
        ],
      ),
    );
  }
}
