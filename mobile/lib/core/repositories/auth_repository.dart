import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiClient.register({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] ?? '';
        await _apiClient.setAuthToken(token);
        return data;
      } else {
        throw Exception(response.data?['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.login({
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] ?? '';
        await _apiClient.setAuthToken(token);
        return data;
      } else {
        throw Exception(response.data?['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _apiClient.clearAuthToken();
      await prefs.remove('user_data');
    } catch (e) {
      throw Exception('Logout error: ${e.toString()}');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await _apiClient.getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
