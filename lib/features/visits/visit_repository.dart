import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/frappe_json.dart';
import 'visit_model.dart';

class VisitRepository {
  VisitRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static final String _visitPath =
      '/api/resource/${Uri.encodeComponent('Site Visit')}';

  static const List<String> _fields = [
    'name',
    'lead',
    'lead_name',
    'mobile_no',
    'village',
    'district',
    'visit_date',
    'visited_by',
    'status',
    'diameter_ft',
    'expected_depth_ft',
    'rock_from_ft',
    'soil_type',
    'latitude',
    'longitude',
    'map_link',
    'notes',
    'modified',
  ];

  Future<List<SiteVisit>> fetchVisits({
    String? status,
    String? search,
    int limit = 50,
  }) async {
    final filters = <List<Object>>[];
    if (status != null && status.isNotEmpty && status != 'All') {
      filters.add(['status', '=', status]);
    }
    if (search != null && search.trim().isNotEmpty) {
      filters.add(['lead_name', 'like', '%${search.trim()}%']);
    }

    final query = <String, dynamic>{
      'fields': jsonEncode(_fields),
      'order_by': 'visit_date desc',
      'limit_page_length': limit,
    };
    if (filters.isNotEmpty) {
      query['filters'] = jsonEncode(filters);
    }

    final data = await _client.getJson(_visitPath, query: query);
    return frappeRows(data).map(SiteVisit.fromJson).toList();
  }

  Future<SiteVisit> createVisit(SiteVisit visit) async {
    final data = await _client.postJson(_visitPath, visit.toJson());
    return SiteVisit.fromJson(frappeDoc(data));
  }

  Future<void> updateStatus(String name, String status) async {
    final path = '$_visitPath/${Uri.encodeComponent(name)}';
    await _client.putJson(path, {'status': status});
  }

  Future<SiteVisit> getVisit(String name) async {
    final path = '$_visitPath/${Uri.encodeComponent(name)}';
    final data = await _client.getJson(path);
    return SiteVisit.fromJson(frappeDoc(data));
  }
}
