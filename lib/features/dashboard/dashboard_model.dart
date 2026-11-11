import '../leads/lead_model.dart';

enum DashboardPeriod { today, week, month, custom }

/// Inclusive local date range: [start] 00:00:00 to [end] 23:59:59.
class PeriodRange {
  PeriodRange(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day, 23, 59, 59);

  final DateTime start;
  final DateTime end;

  /// Week starts on Monday.
  factory PeriodRange.of(DashboardPeriod period, DateTime now) =>
      switch (period) {
        DashboardPeriod.today => PeriodRange(now, now),
        DashboardPeriod.week => PeriodRange(
          now.subtract(Duration(days: now.weekday - DateTime.monday)),
          now,
        ),
        DashboardPeriod.month || DashboardPeriod.custom => PeriodRange(
          DateTime(now.year, now.month),
          now,
        ),
      };

  @override
  bool operator ==(Object other) =>
      other is PeriodRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// One bar: a field value (null = not set) and how many leads have it.
class GroupCount {
  const GroupCount(this.value, this.count, {this.isOther = false});

  final String? value;
  final int count;

  /// The "Other" bar that sums the values beyond the top N.
  final bool isOther;
}

/// Everything the dashboard shows. Optional parts are null when the server
/// does not have that data (e.g. no Site Visit doctype, no district field).
class DashboardData {
  const DashboardData({
    required this.totalLeads,
    required this.byStatus,
    required this.statuses,
    this.siteVisits,
    this.callsLogged,
    this.overdueFollowUps,
    this.bySource,
    this.byDistrict,
  });

  final int totalLeads;
  final int? siteVisits;
  final int? callsLogged;
  final int? overdueFollowUps;
  final List<GroupCount> byStatus;
  final List<GroupCount>? bySource;
  final List<GroupCount>? byDistrict;
  final List<LeadStatus> statuses;
}

/// Largest first; ties keep the server order.
List<GroupCount> sortByCount(List<GroupCount> groups) {
  final indexed = groups.asMap().entries.toList()
    ..sort((a, b) {
      final byCount = b.value.count.compareTo(a.value.count);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// The [limit] largest groups, plus one "Other" bar summing the rest.
List<GroupCount> topWithOther(List<GroupCount> groups, int limit) {
  final sorted = sortByCount(groups.where((g) => g.count > 0).toList());
  if (sorted.length <= limit) return sorted;
  final rest = sorted.skip(limit).fold<int>(0, (sum, g) => sum + g.count);
  return [...sorted.take(limit), GroupCount(null, rest, isOther: true)];
}

/// Statuses in board (position) order, including those with no leads;
/// values the status list doesn't know (and "not set") follow at the end.
List<GroupCount> funnelOrder(
  List<GroupCount> byStatus,
  List<LeadStatus> statuses,
) {
  final counts = {for (final g in byStatus) g.value: g.count};
  final known = {for (final s in statuses) s.name};
  return [
    for (final s in statuses) GroupCount(s.name, counts[s.name] ?? 0),
    for (final g in sortByCount(byStatus))
      if (!known.contains(g.value) && g.count > 0) g,
  ];
}
