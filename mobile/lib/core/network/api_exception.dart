import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.originalError,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'An error occurred';
    int? statusCode = error.response?.statusCode;
    String? code;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        code = 'CONNECTION_TIMEOUT';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Request timeout. Please try again.';
        code = 'RECEIVE_TIMEOUT';
        break;
      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        if (responseData is Map && responseData.containsKey('detail')) {
          message = responseData['detail'];
        } else if (statusCode == 401) {
          message = 'Unauthorized. Please login again.';
          code = 'UNAUTHORIZED';
        } else if (statusCode == 403) {
          message = 'Access denied.';
          code = 'FORBIDDEN';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
          code = 'NOT_FOUND';
        } else if (statusCode == 409) {
          message = 'Conflict. Resource already exists.';
          code = 'CONFLICT';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
          code = 'SERVER_ERROR';
        } else {
          message = 'Request failed with status code: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        code = 'CANCELLED';
        break;
      case DioExceptionType.unknown:
        message = error.message ?? 'Unknown error occurred';
        code = 'UNKNOWN_ERROR';
        break;
      default:
        message = 'An unexpected error occurred';
        code = 'UNEXPECTED_ERROR';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      originalError: error,
    );
  }

  @override
  String toString() => message;

  bool get isNetworkError =>
      code == 'CONNECTION_TIMEOUT' || code == 'RECEIVE_TIMEOUT';

  bool get isAuthenticationError => statusCode == 401;

  bool get isAuthorizationError => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isConflict => statusCode == 409;

  bool get isServerError => statusCode == null || statusCode! >= 500;
}
