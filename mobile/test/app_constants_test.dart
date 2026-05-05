import 'package:flutter_test/flutter_test.dart';
import 'package:fixmate_mobile/core/constants/app_constants.dart';

void main() {
  group('AppConstants Tests', () {
    test('apiBaseUrl should be http://localhost:8000', () {
      expect(AppConstants.apiBaseUrl, 'http://localhost:8000');
    });

    test('apiVersion should be /api/v1.0.0', () {
      expect(AppConstants.apiVersion, '/api/v1.0.0');
    });

    test('authLogin endpoint should be auth/login', () {
      expect(AppConstants.authLogin, 'auth/login');
    });
  });
}
