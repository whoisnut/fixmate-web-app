// FixMate App Credentials Models
// Models for app authentication with the backend

class AppCredential {
  final String id;
  final String appName;
  final String appType;
  final String apiKeyPreview;
  final String? oauthClientId;
  final String? basicUsername;
  final bool isActive;
  final String? lastUsedAt;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;
  final String? description;

  AppCredential({
    required this.id,
    required this.appName,
    required this.appType,
    required this.apiKeyPreview,
    this.oauthClientId,
    this.basicUsername,
    required this.isActive,
    this.lastUsedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  factory AppCredential.fromJson(Map<String, dynamic> json) {
    return AppCredential(
      id: json['id'] as String,
      appName: json['app_name'] as String,
      appType: json['app_type'] as String,
      apiKeyPreview: json['api_key_preview'] as String,
      oauthClientId: json['oauth_client_id'] as String?,
      basicUsername: json['basic_username'] as String?,
      isActive: json['is_active'] as bool,
      lastUsedAt: json['last_used_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'app_name': appName,
      'app_type': appType,
      'api_key_preview': apiKeyPreview,
      'oauth_client_id': oauthClientId,
      'basic_username': basicUsername,
      'is_active': isActive,
      'last_used_at': lastUsedAt,
      'expires_at': expiresAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'description': description,
    };
  }
}

class AppCredentialCreateResponse {
  final AppCredential credential;
  final String apiKey;
  final String? oauthClientSecret;
  final String? basicPassword;
  final String warning;

  AppCredentialCreateResponse({
    required this.credential,
    required this.apiKey,
    this.oauthClientSecret,
    this.basicPassword,
    required this.warning,
  });

  factory AppCredentialCreateResponse.fromJson(Map<String, dynamic> json) {
    return AppCredentialCreateResponse(
      credential: AppCredential.fromJson(json['credential'] as Map<String, dynamic>),
      apiKey: json['api_key'] as String,
      oauthClientSecret: json['oauth_client_secret'] as String?,
      basicPassword: json['basic_password'] as String?,
      warning: json['warning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'credential': credential.toJson(),
      'api_key': apiKey,
      'oauth_client_secret': oauthClientSecret,
      'basic_password': basicPassword,
      'warning': warning,
    };
  }
}

class AppAuthRequest {
  final String appName;
  final String apiKey;

  AppAuthRequest({
    required this.appName,
    required this.apiKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'api_key': apiKey,
    };
  }
}

class AppAuthResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String appName;
  final String appType;

  AppAuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.appName,
    required this.appType,
  });

  factory AppAuthResponse.fromJson(Map<String, dynamic> json) {
    return AppAuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      appName: json['app_name'] as String,
      appType: json['app_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'app_name': appName,
      'app_type': appType,
    };
  }
}
