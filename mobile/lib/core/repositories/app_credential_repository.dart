import '../network/api_client.dart';
import '../models/app_credential.dart';

class AppCredentialRepository {
  final ApiClient _apiClient = ApiClient();

  /// Authenticate app and get access token
  Future<AppAuthResponse> authenticate(AppAuthRequest data) async {
    try {
      final response = await _apiClient.post('/auth/apps/authenticate', data.toJson());

      if (response.statusCode == 200) {
        return AppAuthResponse.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to authenticate app');
      }
    } catch (e) {
      throw Exception('App authentication error: ${e.toString()}');
    }
  }

  /// List all app credentials (admin only)
  Future<List<AppCredential>> listCredentials() async {
    try {
      final response = await _apiClient.get('/auth/apps');

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((e) => AppCredential.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to list credentials');
      }
    } catch (e) {
      throw Exception('List credentials error: ${e.toString()}');
    }
  }

  /// Get a specific app credential (admin only)
  Future<AppCredential> getCredential(String appName) async {
    try {
      final response = await _apiClient.get('/auth/apps/$appName');

      if (response.statusCode == 200) {
        return AppCredential.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to get credential');
      }
    } catch (e) {
      throw Exception('Get credential error: ${e.toString()}');
    }
  }

  /// Regenerate API key (admin only)
  Future<Map<String, dynamic>> regenerateCredential(String appName) async {
    try {
      final response = await _apiClient.post('/auth/apps/$appName/regenerate', {});

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to regenerate credential');
      }
    } catch (e) {
      throw Exception('Regenerate credential error: ${e.toString()}');
    }
  }

  /// Toggle active status (admin only)
  Future<Map<String, dynamic>> toggleCredential(String appName) async {
    try {
      final response = await _apiClient.put('/auth/apps/$appName/toggle', {});

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to toggle credential');
      }
    } catch (e) {
      throw Exception('Toggle credential error: ${e.toString()}');
    }
  }
}
