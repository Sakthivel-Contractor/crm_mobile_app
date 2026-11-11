import '../leads/lead_activity_model.dart';
import '../leads/lead_model.dart';

enum TodayItemType { overdue, dueToday, newLead }

/// One row of the daily call list.
class TodayItem {
  const TodayItem({required this.lead, required this.type, this.task});

  final CrmLead lead;

  /// The open follow-up; null for [TodayItemType.newLead].
  final CrmTask? task;
  final TodayItemType type;

  /// Whole calendar days past the due date (overdue items only).
  int daysLate(DateTime now) {
    final due = task?.dueDate;
    if (due == null) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return today.difference(dueDay).inDays;
  }
}

/// Merges open tasks and new leads into the ordered daily list:
/// overdue (oldest first) → due today (by time) → new leads (newest first).
///
/// One row per lead: a lead with several open tasks shows its earliest one,
/// and a lead with a task is not repeated as a new lead.
List<TodayItem> buildTodayItems({
  required List<CrmTask> tasks,
  required Map<String, CrmLead> leadsByName,
  required List<CrmLead> newLeads,
  required DateTime now,
}) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  final sorted = tasks.where((t) => t.isOpen && t.dueDate != null).toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  final seen = <String>{};
  final overdue = <TodayItem>[];
  final dueToday = <TodayItem>[];
  for (final task in sorted) {
    final leadName = task.referenceDocname;
    if (leadName == null || !seen.add(leadName)) continue;
    final item = TodayItem(
      lead: leadsByName[leadName] ?? CrmLead(name: leadName),
      task: task,
      type: task.dueDate!.isBefore(startOfToday)
          ? TodayItemType.overdue
          : TodayItemType.dueToday,
    );
    (item.type == TodayItemType.overdue ? overdue : dueToday).add(item);
  }

  final fresh =
      newLeads
          .where((lead) => lead.name.isNotEmpty && seen.add(lead.name))
          .toList()
        ..sort((a, b) {
          final ac = a.creation, bc = b.creation;
          if (ac == null && bc == null) return 0;
          if (ac == null || bc == null) return ac == null ? 1 : -1;
          return bc.compareTo(ac);
        });

  return [
    ...overdue,
    ...dueToday,
    for (final lead in fresh)
      TodayItem(lead: lead, type: TodayItemType.newLead),
  ];
}
