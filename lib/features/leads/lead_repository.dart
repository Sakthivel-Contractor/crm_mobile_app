import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/app_error.dart';
import '../../core/frappe_json.dart';
import 'lead_activity_model.dart';
import 'lead_model.dart';

/// Reads leads and lead statuses from Frappe's REST API.
class LeadRepository {
  LeadRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const int defaultPageLength = 20;

  static const List<String> _leadFields = [
    'name',
    'first_name',
    'last_name',
    'lead_name',
    'mobile_no',
    'status',
    'source',
    'custom_district',
    'custom_work_type',
    'lead_owner',
    'modified',
  ];

  static final String _leadPath =
      '/api/resource/${Uri.encodeComponent('CRM Lead')}';
  static final String _statusPath =
      '/api/resource/${Uri.encodeComponent('CRM Lead Status')}';
  static final String _notePath =
      '/api/resource/${Uri.encodeComponent('FCRM Note')}';
  static final String _taskPath =
      '/api/resource/${Uri.encodeComponent('CRM Task')}';

  static String _leadDoc(String name) =>
      '$_leadPath/${Uri.encodeComponent(name)}';

  /// One page of leads, newest-modified first. Throws [AppException].
  /// Field used for the lead's district (a custom field on CRM Lead).
  static const String districtField = 'custom_district';

  Future<List<CrmLead>> fetchLeads({
    String? search,
    String? status,
    String? source,
    String? district,
    int start = 0,
    int pageLength = defaultPageLength,
  }) async {
    final query = buildLeadListQuery(
      search: search,
      status: status,
      source: source,
      district: district,
      start: start,
      pageLength: pageLength,
    );
    final data = await _client.getJson(_leadPath, query: query);
    return frappeRows(data).map(CrmLead.fromJson).toList();
  }

  /// Longest search text sent to the server.
  static const int maxSearchLength = 100;

  /// Query for the lead list. User text only ever becomes a filter *value*
  /// inside a JSON-encoded list — never part of the filter structure — so
  /// quotes, brackets or markup in it cannot change the query.
  static Map<String, dynamic> buildLeadListQuery({
    String? search,
    String? status,
    String? source,
    String? district,
    int start = 0,
    int pageLength = defaultPageLength,
  }) {
    final query = <String, dynamic>{
      'fields': jsonEncode(_leadFields),
      'order_by': 'modified desc',
      'limit_start': start < 0 ? 0 : start,
      'limit_page_length': pageLength.clamp(1, 100),
    };
    final filters = [
      if (status != null && status.isNotEmpty) ['status', '=', status],
      if (source != null && source.isNotEmpty) ['source', '=', source],
      if (district != null && district.isNotEmpty)
        [districtField, '=', district],
    ];
    if (filters.isNotEmpty) query['filters'] = jsonEncode(filters);
    var term = search?.trim() ?? '';
    if (term.length > maxSearchLength) {
      term = term.substring(0, maxSearchLength);
    }
    if (term.isNotEmpty) {
      query['or_filters'] = jsonEncode([
        ['lead_name', 'like', '%$term%'],
        ['mobile_no', 'like', '%$term%'],
      ]);
    }
    return query;
  }

  /// All lead statuses in board order. Throws [AppException].
  Future<List<LeadStatus>> fetchStatuses() async {
    final data = await _client.getJson(
      _statusPath,
      query: {
        'fields': jsonEncode(['name', 'color', 'position', 'type']),
        'order_by': 'position asc',
        'limit_page_length': 0, // all
      },
    );
    return frappeRows(data)
        .map(LeadStatus.fromJson)
        .where((s) => s.name.isNotEmpty)
        .toList();
  }

  /// The full lead document. Throws [AppException].
  Future<CrmLead> getLead(String name) async {
    final data = await _client.getJson(_leadDoc(name));
    return CrmLead.fromJson(frappeDoc(data));
  }

  /// Creates a lead with fields supported by the CRM Lead DocType.
  /// The server validates permissions, links and business rules.
  Future<CrmLead> createLead({
    required String firstName,
    required String status,
    String? lastName,
    String? mobileNo,
    String? email,
    String? village,
    String? district,
    String? workType,
  }) async {
    final data = await _client.postJson(_leadPath, {
      'first_name': firstName,
      'status': status,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      if (mobileNo != null && mobileNo.isNotEmpty) 'mobile_no': mobileNo,
      if (email != null && email.isNotEmpty) 'email': email,
      if (village != null && village.isNotEmpty) 'custom_village': village,
      if (district != null && district.isNotEmpty) districtField: district,
      if (workType != null && workType.isNotEmpty) 'custom_work_type': workType,
    });
    final lead = CrmLead.fromJson(frappeDoc(data));
    if (lead.name.isEmpty) throw const AppException(AppError.server);
    return lead;
  }

  /// Throws [AppException].
  Future<void> updateStatus(String name, String status) async {
    await _client.putJson(_leadDoc(name), {'status': status});
  }

  /// Notes on a lead, newest first. Throws [AppException].
  Future<List<CrmNote>> getNotes(String name) async {
    final data = await _client.getJson(
      _notePath,
      query: {
        'filters': jsonEncode(_referenceFilter(name)),
        'fields': jsonEncode(['name', 'title', 'content', 'owner', 'creation']),
        'order_by': 'creation desc',
        'limit_page_length': 0, // all
      },
    );
    return frappeRows(data).map(CrmNote.fromJson).toList();
  }

  /// [content] is plain text; it is stored as HTML for Frappe's editor.
  /// Throws [AppException].
  Future<void> addNote(String name, String title, String content) async {
    await _client.postJson(_notePath, {
      'reference_doctype': 'CRM Lead',
      'reference_docname': name,
      'title': title,
      'content': plainTextToHtml(content),
    });
  }

  /// Tasks on a lead, earliest due first. Throws [AppException].
  Future<List<CrmTask>> getTasks(String name) async {
    final data = await _client.getJson(
      _taskPath,
      query: {
        'filters': jsonEncode(_referenceFilter(name)),
        'fields': jsonEncode([
          'name',
          'title',
          'status',
          'due_date',
          'priority',
        ]),
        'order_by': 'due_date asc',
        'limit_page_length': 0, // all
      },
    );
    return frappeRows(data).map(CrmTask.fromJson).toList();
  }

  /// Creates a "Follow-up call" task due at [dueDate] (device time).
  /// Throws [AppException].
  Future<void> addFollowUp(String name, DateTime dueDate, String note) async {
    await _client.postJson(_taskPath, {
      'reference_doctype': 'CRM Lead',
      'reference_docname': name,
      'title': CrmTask.followUpTitle,
      'description': plainTextToHtml(note),
      'due_date': frappeDateTimeFormat.format(dueDate),
      'status': 'Todo',
      'priority': 'Medium',
    });
  }

  /// Throws [AppException].
  Future<void> completeTask(String taskName) async {
    await _client.putJson('$_taskPath/${Uri.encodeComponent(taskName)}', {
      'status': 'Done',
    });
  }

  static List<List<String>> _referenceFilter(String name) => [
    ['reference_doctype', '=', 'CRM Lead'],
    ['reference_docname', '=', name],
  ];
}
