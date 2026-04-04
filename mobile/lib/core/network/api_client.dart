import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  late SharedPreferences _prefs;

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
            print('Error adding auth token: $e');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode == 401) {
            clearAuthToken();
          }
          print(
              'API Response: ${response.statusCode} - ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('API Error: ${error.type} - ${error.message}');
          print('Error Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  // Authentication endpoints
  Future<Response> register(Map<String, dynamic> data) async {
    return await dio.post(AppConstants.authRegister, data: data);
  }

  Future<Response> login(Map<String, dynamic> data) async {
    return await dio.post(AppConstants.authLogin, data: data);
  }

  // Categories endpoints
  Future<Response> getCategories() async {
    return await dio.get(AppConstants.categoriesEndpoint);
  }

  // Services endpoints
  Future<Response> getServices({String? categoryId}) async {
    return await dio.get(
      AppConstants.servicesEndpoint,
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
      },
    );
  }

  Future<Response> getService(String serviceId) async {
    return await dio.get('${AppConstants.servicesEndpoint}/$serviceId');
  }

  // Bookings endpoints
  Future<Response> createBooking(Map<String, dynamic> data) async {
    return await dio.post(AppConstants.bookingsEndpoint, data: data);
  }

  Future<Response> getBookings({String? status}) async {
    return await dio.get(
      AppConstants.bookingsEndpoint,
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
  }

  Future<Response> getBooking(String id) async {
    return await dio.get('${AppConstants.bookingsEndpoint}/$id');
  }

  Future<Response> updateBooking(String id, Map<String, dynamic> data) async {
    return await dio.put('${AppConstants.bookingsEndpoint}/$id', data: data);
  }

  Future<Response> cancelBooking(String id) async {
    return await dio.delete('${AppConstants.bookingsEndpoint}/$id');
  }

  // Profile endpoints
  Future<Response> getProfile() async {
    return await dio.get(AppConstants.profileEndpoint);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await dio.put(AppConstants.profileEndpoint, data: data);
  }

  // Booking action endpoints
  Future<Response> acceptBooking(String bookingId) async {
    return await dio.post('${AppConstants.bookingsEndpoint}/$bookingId/accept');
  }

  Future<Response> startBooking(String bookingId) async {
    return await dio.post('${AppConstants.bookingsEndpoint}/$bookingId/start');
  }

  Future<Response> completeBooking(String bookingId) async {
    return await dio
        .post('${AppConstants.bookingsEndpoint}/$bookingId/complete');
  }

  Future<Response> getAvailableBookings() async {
    return await dio.get('${AppConstants.bookingsEndpoint}/available');
  }

  // Payment endpoints
  Future<Response> createPayment(Map<String, dynamic> data) async {
    return await dio.post('/api/payments', data: data);
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
}
