import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  factory ApiException.fromDioException(DioException error) {
    String message = ErrorMessages.unexpectedError;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = ErrorMessages.networkError;
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response timeout';
        break;
      case DioExceptionType.badResponse:
        message = _parseErrorMessage(
          error.response?.data,
          statusCode,
        );
        break;
      case DioExceptionType.unknown:
        message = error.message ?? ErrorMessages.unexpectedError;
        break;
      default:
        message = ErrorMessages.unexpectedError;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      originalError: error,
    );
  }

  static String _parseErrorMessage(dynamic data, int? statusCode) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }

    switch (statusCode) {
      case HttpStatus.badRequest:
        return 'Invalid request';
      case HttpStatus.unauthorized:
        return ErrorMessages.unauthorized;
      case HttpStatus.forbidden:
        return 'Access denied';
      case HttpStatus.notFound:
        return 'Resource not found';
      case HttpStatus.conflict:
        return 'Conflict occurred';
      case HttpStatus.internalServerError:
        return ErrorMessages.serverError;
      case HttpStatus.serviceUnavailable:
        return 'Service unavailable';
      default:
        return ErrorMessages.unexpectedError;
    }
  }

  bool get isNetworkError => statusCode == null || statusCode == 0;
  bool get isUnauthorized => statusCode == HttpStatus.unauthorized;
  bool get isForbidden => statusCode == HttpStatus.forbidden;
  bool get isNotFound => statusCode == HttpStatus.notFound;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  ValidationException({
    required this.message,
    this.errors,
  });

  @override
  String toString() => message;
}
