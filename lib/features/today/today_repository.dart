import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/app_error.dart';
import '../../core/frappe_json.dart';
import '../leads/lead_activity_model.dart';
import '../leads/lead_model.dart';

/// Reads the data behind the Today tab.
class TodayRepository {
  TodayRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static final String _taskPath =
      '/api/resource/${Uri.encodeComponent('CRM Task')}';
  static final String _leadPath =
      '/api/resource/${Uri.encodeComponent('CRM Lead')}';

  /// Keeps the `name in [...]` query string well under URL length limits.
  static const int _namesPerRequest = 100;

  /// Open lead tasks due on or before the end of [now]'s day.
  /// Throws [AppException].
  Future<List<CrmTask>> fetchDueTasks(DateTime now) async {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final data = await _client.getJson(
      _taskPath,
      query: {
        'filters': jsonEncode([
          ['reference_doctype', '=', 'CRM Lead'],
          [
            'status',
            'not in',
            ['Done', 'Canceled'],
          ],
          ['due_date', '<=', frappeDateTimeFormat.format(endOfToday)],
        ]),
        'fields': jsonEncode([
          'name',
          'title',
          'description',
          'due_date',
          'status',
          'reference_docname',
        ]),
        'order_by': 'due_date asc',
        'limit_page_length': 200,
      },
    );
    return frappeRows(data).map(CrmTask.fromJson).toList();
  }

  /// Leads still in "New", newest first. Throws [AppException].
  Future<List<CrmLead>> fetchNewLeads() async {
    final data = await _client.getJson(
      _leadPath,
      query: {
        'filters': jsonEncode([
          ['status', '=', 'New'],
        ]),
        'fields': jsonEncode([
          'name',
          'lead_name',
          'mobile_no',
          'source',
          'creation',
        ]),
        'order_by': 'creation desc',
        'limit_page_length': 50,
      },
    );
    return frappeRows(data).map(CrmLead.fromJson).toList();
  }

  /// The given leads keyed by name — one request (per 100 names).
  /// Throws [AppException].
  Future<Map<String, CrmLead>> fetchLeadsByName(Iterable<String> names) async {
    final unique = names.toSet().toList();
    final result = <String, CrmLead>{};
    for (var i = 0; i < unique.length; i += _namesPerRequest) {
      final chunk = unique.sublist(
        i,
        (i + _namesPerRequest).clamp(0, unique.length),
      );
      final data = await _client.getJson(
        _leadPath,
        query: {
          'filters': jsonEncode([
            ['name', 'in', chunk],
          ]),
          'fields': jsonEncode([
            'name',
            'lead_name',
            'mobile_no',
            'source',
            'status',
          ]),
          'limit_page_length': chunk.length,
        },
      );
      for (final lead in frappeRows(data).map(CrmLead.fromJson)) {
        result[lead.name] = lead;
      }
    }
    return result;
  }
}
