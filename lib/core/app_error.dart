import 'package:dio/dio.dart';

/// Error categories for data requests. The UI maps these to localized text.
enum AppError { network, unauthorized, server, unknown }

class AppException implements Exception {
  const AppException(this.error);

  final AppError error;

  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const AppException(AppError.network);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        // Frappe answers 403 (PermissionError) when the session has expired.
        if (status == 401 || status == 403) {
          return const AppException(AppError.unauthorized);
        }
        return const AppException(AppError.server);
      case DioExceptionType.badCertificate:
        return const AppException(AppError.server);
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const AppException(AppError.unknown);
    }
  }

  @override
  String toString() => 'AppException($error)';
}
