import 'dart:convert';

import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/app_error.dart';
import '../../core/frappe_json.dart';
import '../leads/lead_activity_model.dart';
import '../leads/lead_repository.dart';
import 'dashboard_model.dart';

/// Count-only queries for the dashboard. No amounts are ever requested.
class DashboardRepository {
  DashboardRepository({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const String _countPath = '/api/method/frappe.client.get_count';
  static final String _leadPath =
      '/api/resource/${Uri.encodeComponent('CRM Lead')}';
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static List<List<Object>> createdIn(PeriodRange range) => [
    ['creation', '>=', frappeDateTimeFormat.format(range.start)],
    ['creation', '<=', frappeDateTimeFormat.format(range.end)],
  ];

  /// Number of [doctype] documents matching [filters]. Throws [AppException].
  Future<int> count(String doctype, List<List<Object>> filters) async {
    final data = await _client.getJson(
      _countPath,
      query: {'doctype': doctype, 'filters': jsonEncode(filters)},
    );
    final message = data is Map ? data['message'] : null;
    if (message is num) return message.toInt();
    throw const AppException(AppError.server);
  }

  /// Leads per distinct [field] value. Throws [AppException].
  Future<List<GroupCount>> leadsGroupedBy(
    String field,
    List<List<Object>> filters,
  ) async {
    final data = await _client.getJson(
      _leadPath,
      query: {
        'fields': jsonEncode([field, 'count(name) as count']),
        'group_by': field,
        'filters': jsonEncode(filters),
        'limit_page_length': 0, // all groups
      },
    );
    return [
      for (final row in frappeRows(data))
        GroupCount(_value(row[field]), _int(row['count'])),
    ];
  }

  Future<int> totalLeads(PeriodRange range) =>
      count('CRM Lead', createdIn(range));

  Future<List<GroupCount>> leadsByStatus(PeriodRange range) =>
      leadsGroupedBy('status', createdIn(range));

  Future<List<GroupCount>> leadsBySource(PeriodRange range) =>
      leadsGroupedBy('source', createdIn(range));

  Future<List<GroupCount>> leadsByDistrict(PeriodRange range) =>
      leadsGroupedBy(LeadRepository.districtField, createdIn(range));

  Future<int> siteVisits(PeriodRange range) => count('Site Visit', [
    ['visit_date', '>=', _dateFormat.format(range.start)],
    ['visit_date', '<=', _dateFormat.format(range.end)],
  ]);

  /// Not limited to the period: everything still open and due before today.
  Future<int> overdueFollowUps(DateTime now) => count('CRM Task', [
    ['reference_doctype', '=', 'CRM Lead'],
    [
      'status',
      'not in',
      ['Done', 'Canceled'],
    ],
    [
      'due_date',
      '<',
      frappeDateTimeFormat.format(DateTime(now.year, now.month, now.day)),
    ],
  ]);

  /// Notes written by "Log a call" (titles start with "Call:").
  Future<int> callsLogged(PeriodRange range) => count('FCRM Note', [
    ['reference_doctype', '=', 'CRM Lead'],
    ['title', 'like', '${CallOutcome.notePrefix.trim()}%'],
    ...createdIn(range),
  ]);

  static String? _value(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int _int(Object? v) => switch (v) {
    num n => n.toInt(),
    String s => int.tryParse(s) ?? 0,
    _ => 0,
  };
}
