import '../network/api_client.dart';
import '../models/api_credential.dart';

class ApiCredentialRepository {
  final ApiClient _apiClient = ApiClient();

  /// Create a new API credential
  Future<ApiCredentialCreateResponse> createCredential(
      ApiCredentialCreate data) async {
    try {
      final response = await _apiClient.post('/auth/credentials', data.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiCredentialCreateResponse.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to create credential');
      }
    } catch (e) {
      throw Exception('Create credential error: ${e.toString()}');
    }
  }

  /// List all credentials for current user
  Future<ApiCredentialsListResponse> listCredentials() async {
    try {
      final response = await _apiClient.get('/auth/credentials');

      if (response.statusCode == 200) {
        return ApiCredentialsListResponse.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to list credentials');
      }
    } catch (e) {
      throw Exception('List credentials error: ${e.toString()}');
    }
  }

  /// Get a specific credential
  Future<ApiCredential> getCredential(String credentialId) async {
    try {
      final response =
          await _apiClient.get('/auth/credentials/$credentialId');

      if (response.statusCode == 200) {
        return ApiCredential.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to get credential');
      }
    } catch (e) {
      throw Exception('Get credential error: ${e.toString()}');
    }
  }

  /// Update a credential
  Future<ApiCredential> updateCredential(
      String credentialId, ApiCredentialUpdate data) async {
    try {
      final response =
          await _apiClient.put('/auth/credentials/$credentialId', data.toJson());

      if (response.statusCode == 200) {
        return ApiCredential.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to update credential');
      }
    } catch (e) {
      throw Exception('Update credential error: ${e.toString()}');
    }
  }

  /// Revoke a credential
  Future<void> revokeCredential(String credentialId,
      {String? reason}) async {
    try {
      final response = await _apiClient
          .post('/auth/credentials/$credentialId/revoke', {'reason': reason});

      if (response.statusCode != 200) {
        throw Exception(response.data?['detail'] ?? 'Failed to revoke credential');
      }
    } catch (e) {
      throw Exception('Revoke credential error: ${e.toString()}');
    }
  }

  /// Delete a credential
  Future<void> deleteCredential(String credentialId) async {
    try {
      final response =
          await _apiClient.delete('/auth/credentials/$credentialId');

      if (response.statusCode != 200) {
        throw Exception(response.data?['detail'] ?? 'Failed to delete credential');
      }
    } catch (e) {
      throw Exception('Delete credential error: ${e.toString()}');
    }
  }

  /// OAuth 2.0 token endpoint
  Future<OAuthTokenResponse> oauthToken(OAuthTokenRequest data) async {
    try {
      final response =
          await _apiClient.post('/auth/credentials/oauth/token', data.toJson());

      if (response.statusCode == 200) {
        return OAuthTokenResponse.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to get OAuth token');
      }
    } catch (e) {
      throw Exception('OAuth token error: ${e.toString()}');
    }
  }

  /// Get usage statistics
  Future<ApiUsageStatsResponse> getUsageStats({int days = 30}) async {
    try {
      final response = await _apiClient
          .get('/auth/credentials/usage/stats?days=$days');

      if (response.statusCode == 200) {
        return ApiUsageStatsResponse.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.data?['detail'] ?? 'Failed to get usage stats');
      }
    } catch (e) {
      throw Exception('Get usage stats error: ${e.toString()}');
    }
  }
}
