import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// "2 மணி நேரம் முன்" / "2h ago" for the last week, then a short date
/// ("12 மே" / "May 12") formatted with intl in the current locale.
String formatRelativeTime(
  BuildContext context,
  DateTime time, {
  DateTime? now,
}) {
  final l10n = AppLocalizations.of(context)!;
  final current = now ?? DateTime.now();
  final diff = current.difference(time);

  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);

  final locale = Localizations.localeOf(context).toLanguageTag();
  final format = time.year == current.year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return format.format(time);
}
