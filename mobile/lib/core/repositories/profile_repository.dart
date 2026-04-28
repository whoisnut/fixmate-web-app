import '../network/api_client.dart';
import '../network/api_exception.dart';

class ProfileRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.getProfile();

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'Failed to fetch profile: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error fetching profile: $e',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await _apiClient.updateProfile(data);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'Failed to update profile: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error updating profile: $e',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getTechnicianStats() async {
    try {
      final response =
          await _apiClient.dio.get('/api/profile/technician/stats');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'Failed to fetch technician stats: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error fetching technician stats: $e',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateTechnicianAvailability(
      bool isAvailable) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/profile/technician/availability',
        queryParameters: {'is_available': isAvailable},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'Failed to update availability: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error updating availability: $e',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateTechnicianLocation(
      double lat, double lng) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/profile/technician/location',
        queryParameters: {'lat': lat, 'lng': lng},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      throw Exception('Error updating location: ${e.toString()}');
    }
  }
}
