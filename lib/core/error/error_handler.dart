import 'package:dio/dio.dart';
import 'failures.dart';
import '../services/logger_service.dart';

Failure handleError(dynamic error) {
  if (error is DioException) {
    LoggerService.error('DioError: ${error.message}', error);
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message = (data is Map ? data['message'] as String? : null) ?? 'Server error';
        if (statusCode == 401 || statusCode == 403) {
          return AuthFailure(message: message, statusCode: statusCode);
        }
        if (statusCode == 404) {
          return NotFoundFailure(message: message);
        }
        return ServerFailure(message: message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return const ServerFailure(message: 'Request cancelled');
      default:
        return const ServerFailure();
    }
  }

  LoggerService.error('Unexpected error: ${error.toString()}', error);
  return UnexpectedFailure(message: error.toString());
}
