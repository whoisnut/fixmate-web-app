import 'package:dio/dio.dart';
import '../exceptions/api_exception.dart';

class ErrorHandler {
  static ApiException handleError(dynamic error) {
    if (error is DioException) {
      return ApiException.fromDioException(error);
    }

    if (error is ApiException) {
      return error;
    }

    if (error is Exception) {
      return ApiException(message: error.toString());
    }

    return ApiException(message: 'An unknown error occurred');
  }

  static String getErrorMessage(dynamic error) {
    return handleError(error).message;
  }

  static bool isNetworkError(dynamic error) {
    if (error is ApiException) {
      return error.isNetworkError;
    }
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  static bool isAuthError(dynamic error) {
    if (error is ApiException) {
      return error.isUnauthorized;
    }
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }

  static bool isServerError(dynamic error) {
    if (error is ApiException) {
      return error.isServerError;
    }
    if (error is DioException) {
      return error.response?.statusCode != null &&
          error.response!.statusCode! >= 500;
    }
    return false;
  }

  static Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    void Function(ApiException)? onError,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final apiException = handleError(e);
      onError?.call(apiException);
      rethrow;
    }
  }
}
