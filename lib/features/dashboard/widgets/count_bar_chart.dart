import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';

/// One horizontal bar.
class CountBar {
  const CountBar({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;

  /// Opens the Leads tab filtered by this value; null = not tappable.
  final VoidCallback? onTap;
}

/// Horizontal bars on one scale (the largest bar is full width). Every bar
/// carries its label and "count (percent%)" in text colours; the bar colour
/// only marks identity.
class CountBarChart extends StatelessWidget {
  const CountBarChart({
    super.key,
    required this.title,
    required this.bars,
    required this.total,
    this.unavailable = false,
  });

  final String title;
  final List<CountBar> bars;

  /// Denominator for the percentages (total leads in the period).
  final int total;

  /// The server has no data for this chart (missing field/doctype).
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final max = bars.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    final Widget body;
    if (unavailable) {
      body = Text(l10n.chartUnavailable, style: text.bodySmall);
    } else if (max == 0) {
      body = Text(l10n.chartNoData, style: text.bodySmall);
    } else {
      body = Column(
        children: [
          for (final bar in bars)
            _BarRow(
              bar: bar,
              fraction: bar.count / max,
              value: l10n.barValue(
                bar.count,
                total == 0 ? 0 : (bar.count * 100 / total).round(),
              ),
            ),
        ],
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: text.titleSmall?.copyWith(color: AppTheme.textStrong),
            ),
          ),
          const SizedBox(height: 8),
          body,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.bar,
    required this.fraction,
    required this.value,
  });

  final CountBar bar;
  final double fraction;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Keep a visible stub for small non-zero counts.
    final width = bar.count == 0 ? 0.0 : fraction.clamp(0.02, 1.0);

    return Semantics(
      button: bar.onTap != null,
      label: '${bar.label}, $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: bar.onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bar.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: AppTheme.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: text.labelMedium?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                    // Same width with or without the chevron, so values align.
                    SizedBox(
                      width: AppTheme.smallIconSize,
                      child: bar.onTap == null
                          ? null
                          : const Icon(
                              Icons.chevron_right,
                              size: AppTheme.smallIconSize,
                              color: AppTheme.textMuted,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: width,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bar.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact KPI: icon, number, label. [value] null = not available.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppTheme.textStrong,
  });

  final IconData icon;
  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value == null ? l10n.kpiUnavailable : '$value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: value == null
                  ? text.bodyMedium?.copyWith(color: AppTheme.textMuted)
                  : text.titleLarge?.copyWith(color: color),
            ),
            // Always two lines tall, so tiles in a row match without
            // IntrinsicHeight (whose Tamil measurement is short on web).
            Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: Text(' \n ', maxLines: 2, style: text.bodySmall),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
