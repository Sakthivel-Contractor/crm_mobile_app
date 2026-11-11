import 'package:flutter/material.dart';

import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../lead_model.dart';
import '../lead_status_style.dart';

/// Horizontal "All" + status chips. [selected] null means All.
class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.statuses,
    required this.selected,
    required this.onSelected,
    required this.padding,
    this.leading = const [],
  });

  /// Extra chips before "All", e.g. removable source/district filters.
  final List<Widget> leading;

  final List<LeadStatus> statuses;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding.copyWith(top: 4, bottom: 4),
        itemCount: leading.length + statuses.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < leading.length) return leading[index];
          index -= leading.length;
          if (index == 0) {
            return _Chip(
              label: l10n.filterAll,
              selected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final status = statuses[index - 1];
          return _Chip(
            label: localizedStatus(l10n, status.name),
            dot: StatusStyle.of(status).foreground,
            selected: selected == status.name,
            onTap: () => onSelected(status.name),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) =>
      AppChip(label: label, selected: selected, onTap: onTap, dot: dot);
}
