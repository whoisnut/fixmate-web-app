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

  Future<Map<String, dynamic>> registerTechnician({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bio,
    required List<String> specialties,
    required List<String> documents,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register/technician', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'bio': bio,
        'specialties': specialties,
        'documents': documents,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] ?? '';
        await _apiClient.setAuthToken(token);
        // Save technician status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'tech_status', data['technician_status'] ?? 'pending');
        return data;
      } else {
        throw Exception(response.data?['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Technician registration error: ${e.toString()}');
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

  Future<Map<String, dynamic>> loginTechnician({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/auth/login/technician', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] ?? '';
        await _apiClient.setAuthToken(token);

        // Save technician status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'tech_status', data['technician_status'] ?? 'pending');
        await prefs.setBool('is_verified', data['is_verified'] ?? false);
        await prefs.setBool(
            'can_accept_jobs', data['can_accept_jobs'] ?? false);

        return data;
      } else {
        throw Exception(response.data?['detail'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Technician login error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getTechnicianVerificationStatus() async {
    try {
      final response =
          await _apiClient.get('/auth/technician/verification-status');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get verification status');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> uploadTechnicianDocuments(
      List<String> documents) async {
    try {
      final response = await _apiClient.post(
        '/auth/technician/upload-documents',
        {'documents': documents},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to upload documents');
      }
    } catch (e) {
      throw Exception('Document upload error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _apiClient.clearAuthToken();
      await prefs.remove('user_data');
      await prefs.remove('tech_status');
      await prefs.remove('is_verified');
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

  Future<bool> isTechnicianVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_verified') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getTechnicianStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('tech_status');
    } catch (e) {
      return null;
    }
  }
}
