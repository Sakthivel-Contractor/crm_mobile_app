import 'app_error.dart';

/// Rows from a Frappe list response.
///
/// Frappe's REST API returns rows in two shapes depending on the query:
///   - Standard list: `{"data": [...]}`
///   - Aggregated / grouped queries may return: `{"message": [...]}`
///
/// Both are accepted here. Anything else is treated as a server error.
Iterable<Map<String, dynamic>> frappeRows(Object? body) {
  if (body is Map) {
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map>().map(
        (row) => Map<String, dynamic>.from(row),
      );
    }
    // Frappe aggregation / grouped queries wrap rows under "message".
    final message = body['message'];
    if (message is List) {
      return message.whereType<Map>().map(
        (row) => Map<String, dynamic>.from(row),
      );
    }
  }
  throw const AppException(AppError.server);
}

/// The document from a Frappe single-doc response `{"data": {...}}`.
Map<String, dynamic> frappeDoc(Object? body) {
  if (body is Map && body['data'] is Map) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  throw const AppException(AppError.server);
}
