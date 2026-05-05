import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'FixMate';

  // API Configuration - Adapts to platform and environment
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000'; // Flutter web in browser
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android emulator
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8000'; // iOS simulator
    } else {
      return 'http://localhost:8000'; // Web/desktop fallback
    }
  }

  // For physical devices, change this to your machine's IP
  // Example: 'http://192.168.1.100:8000'
  static const String deviceIpAddress = 'http://localhost:8000';

  // Default API base URL for development
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1.0.0';

  // API Endpoints
  static const String authRegister = 'auth/register';
  static const String authLogin = 'auth/login';
  static const String categoriesEndpoint = 'services/categories';
  static const String servicesEndpoint = 'services';
  static const String bookingsEndpoint = 'bookings';
  static const String profileEndpoint = 'profile';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';

  // Timeouts
  static const int connectionTimeout = 30000; // milliseconds
  static const int receiveTimeout = 30000; // milliseconds
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String technicianHome = '/technician-home';
  static const String services = '/services';
  static const String technicianMap = '/technician-map';
  static const String booking = '/booking';
  static const String tracking = '/tracking';
  static const String chat = '/chat';
  static const String payment = '/payment';
  static const String profile = '/profile';
  static const String bookingHistory = '/booking-history';
  static const String favorites = '/favorites';
  static const String technicianPayout = '/technician-payout';
}

// HTTP Status codes
class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;
}

// Error messages
class ErrorMessages {
  static const String networkError = 'Network connection failed';
  static const String unauthorized = 'Unauthorized access';
  static const String invalidCredentials = 'Invalid email or password';
  static const String emailAlreadyExists = 'Email already registered';
  static const String serverError = 'Server error occurred';
  static const String unexpectedError = 'An unexpected error occurred';
  static const String noInternetConnection = 'No internet connection';
}
