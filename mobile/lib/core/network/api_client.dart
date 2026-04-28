import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  late SharedPreferences _prefs;
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);

  ApiClient._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: AppConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FixMate-Mobile/1.0.0',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    // Add interceptors for request/response handling
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            _prefs = await SharedPreferences.getInstance();
            final token = _prefs.getString(AppConstants.tokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Error adding auth token - continue without token
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode == 401) {
            clearAuthToken();
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  /// Execute request with retry logic and exponential backoff
  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() request,
  ) async {
    int retries = 0;
    Duration delay = _initialDelay;

    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        final apiException = ApiException.fromDioError(e);

        // Don't retry on client errors (4xx)
        if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 400 &&
            e.response!.statusCode! < 500) {
          throw apiException;
        }

        // Retry on network errors or server errors (5xx)
        if (retries < _maxRetries &&
            (apiException.isNetworkError || apiException.isServerError)) {
          retries++;
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }

        throw apiException;
      }
    }
  }

  // Authentication endpoints
  Future<Response> register(Map<String, dynamic> data) async {
    try {
      return await _executeWithRetry(
        () => dio.post(AppConstants.authRegister, data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> login(Map<String, dynamic> data) async {
    try {
      return await _executeWithRetry(
        () => dio.post(AppConstants.authLogin, data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  // Categories endpoints
  Future<Response> getCategories() async {
    try {
      return await _executeWithRetry(
        () => dio.get(AppConstants.categoriesEndpoint),
      );
    } on ApiException {
      rethrow;
    }
  }

  // Services endpoints
  Future<Response> getServices({String? categoryId}) async {
    try {
      return await _executeWithRetry(
        () => dio.get(
          AppConstants.servicesEndpoint,
          queryParameters: {
            if (categoryId != null) 'category_id': categoryId,
          },
        ),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> getService(String serviceId) async {
    try {
      return await _executeWithRetry(
        () => dio.get('${AppConstants.servicesEndpoint}/$serviceId'),
      );
    } on ApiException {
      rethrow;
    }
  }

  // Bookings endpoints
  Future<Response> createBooking(Map<String, dynamic> data) async {
    try {
      return await _executeWithRetry(
        () => dio.post(AppConstants.bookingsEndpoint, data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> getBookings({String? status}) async {
    try {
      return await _executeWithRetry(
        () => dio.get(
          AppConstants.bookingsEndpoint,
          queryParameters: {
            if (status != null) 'status': status,
          },
        ),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> getBooking(String id) async {
    try {
      return await _executeWithRetry(
        () => dio.get('${AppConstants.bookingsEndpoint}/$id'),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> updateBooking(String id, Map<String, dynamic> data) async {
    try {
      return await _executeWithRetry(
        () => dio.put('${AppConstants.bookingsEndpoint}/$id', data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> cancelBooking(String id) async {
    try {
      return await _executeWithRetry(
        () => dio.delete('${AppConstants.bookingsEndpoint}/$id'),
      );
    } on ApiException {
      rethrow;
    }
  }

  // Profile endpoints
  Future<Response> getProfile() async {
    try {
      return await _executeWithRetry(
        () => dio.get(AppConstants.profileEndpoint),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      return await _executeWithRetry(
        () => dio.put(AppConstants.profileEndpoint, data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  // Booking action endpoints
  Future<Response> acceptBooking(String bookingId) async {
    try {
      return await _executeWithRetry(
        () => dio.post('${AppConstants.bookingsEndpoint}/$bookingId/accept'),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> startBooking(String bookingId) async {
    try {
      return await _executeWithRetry(
        () => dio.post('${AppConstants.bookingsEndpoint}/$bookingId/start'),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> completeBooking(String bookingId) async {
    try {
      return await _executeWithRetry(
        () => dio.post('${AppConstants.bookingsEndpoint}/$bookingId/complete'),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> getAvailableBookings() async {
    try {
      return await _executeWithRetry(
        () => dio.get('${AppConstants.bookingsEndpoint}/available'),
      );
    } on ApiException {
      rethrow;
    }
  }

  // Payment endpoints
  Future<Response> createPayment(Map<String, dynamic> data) async {
    try {
      return await _executeWithRetry(
        () => dio.post('/api/payments', data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> getPayment(String bookingId) async {
    return await dio.get('/api/payments/$bookingId');
  }

  Future<Response> updatePaymentStatus(
    String paymentId,
    String status, {
    String? transactionId,
  }) async {
    return await dio.put(
      '/api/payments/$paymentId',
      queryParameters: {
        'status': status,
        if (transactionId != null) 'transaction_id': transactionId,
      },
    );
  }

  Future<Response> getMyPayments() async {
    return await dio.get('/api/payments/bookings/my-payments');
  }

  // Utility methods
  Future<void> setAuthToken(String token) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.userKey);
  }

  Future<String?> getAuthToken() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString(AppConstants.tokenKey);
  }

  // Generic HTTP methods for flexible endpoint access
  Future<Response> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _executeWithRetry(
        () => dio.get(endpoint, queryParameters: queryParameters),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> post(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        () => dio.post(endpoint, data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> put(String endpoint, dynamic data) async {
    try {
      return await _executeWithRetry(
        () => dio.put(endpoint, data: data),
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      return await _executeWithRetry(
        () => dio.delete(endpoint),
      );
    } on ApiException {
      rethrow;
    }
  }
}
