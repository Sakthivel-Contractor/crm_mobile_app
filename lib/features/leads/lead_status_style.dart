import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'lead_model.dart';

/// Text/dot colour and soft background for a status pill.
class StatusStyle {
  const StatusStyle(this.foreground, this.background);

  final Color foreground;
  final Color background;

  static const StatusStyle neutral = StatusStyle(
    Color(0xFF4B5563),
    Color(0xFFF1F3F5),
  );

  /// Frappe CRM stores colour names; foregrounds are dark enough for 4.5:1
  /// on their background.
  static const Map<String, StatusStyle> _named = {
    'gray': neutral,
    'black': StatusStyle(Color(0xFF111827), Color(0xFFE5E7EB)),
    'blue': StatusStyle(Color(0xFF1D4ED8), Color(0xFFE0EAFF)),
    'green': StatusStyle(Color(0xFF15803D), Color(0xFFDCFCE7)),
    'red': StatusStyle(Color(0xFFB42318), Color(0xFFFDECEA)),
    'orange': StatusStyle(Color(0xFFC2410C), Color(0xFFFFEDD5)),
    'amber': StatusStyle(Color(0xFFB45309), Color(0xFFFEF3C7)),
    'yellow': StatusStyle(Color(0xFF946200), Color(0xFFFEF9C3)),
    'cyan': StatusStyle(Color(0xFF0E7490), Color(0xFFCFFAFE)),
    'teal': StatusStyle(Color(0xFF0F766E), Color(0xFFCCFBF1)),
    'violet': StatusStyle(Color(0xFF6D28D9), Color(0xFFEDE9FE)),
    'purple': StatusStyle(Color(0xFF7E22CE), Color(0xFFF3E8FF)),
    'pink': StatusStyle(Color(0xFFBE185D), Color(0xFFFCE7F3)),
  };

  factory StatusStyle.of(LeadStatus? status) {
    final raw = status?.color?.toLowerCase();
    if (raw == null) return neutral;
    final named = _named[raw];
    if (named != null) return named;

    final hex = raw.startsWith('#') ? raw.substring(1) : raw;
    final value = int.tryParse(hex, radix: 16);
    if (hex.length == 6 && value != null) {
      final color = Color(0xFF000000 | value);
      return StatusStyle(color, color.withValues(alpha: 0.12));
    }
    return neutral;
  }
}

/// Tamil/English label for Frappe CRM's default statuses; custom statuses
/// are shown as entered on the server.
String localizedStatus(AppLocalizations l10n, String status) =>
    switch (status.toLowerCase()) {
      'new' => l10n.statusNew,
      'contacted' => l10n.statusContacted,
      'nurture' => l10n.statusNurture,
      'qualified' => l10n.statusQualified,
      'unqualified' => l10n.statusUnqualified,
      'junk' => l10n.statusJunk,
      _ => status,
    };

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.style});

  final String label;
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: style.foreground),
      ),
    );
  }
}

/// Localized label for work types.
String localizedWorkType(AppLocalizations l10n, String workType) {
  if (l10n.localeName == 'ta') {
    switch (workType) {
      case 'New Well':
        return 'புதிய கிணறு';
      case 'Well Deepening':
        return 'ஆழப்படுத்துதல்';
      case 'Wall Construction':
        return 'சுற்றுச்சுவர்';
      case 'Desilting':
        return 'தூர்வாருதல்';
      case 'Water Survey':
        return 'நீர் ஆய்வு';
    }
  }
  return workType;
}
