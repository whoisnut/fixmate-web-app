// FixMate API Credentials Models
// Shared models for API credential management

enum AuthType {
  basic,
  bearer,
  oauth2,
  apiKey,
}

enum AppType {
  admin,
  mobile,
  web,
  external,
}

// ============ Request Models ============

class ApiCredentialCreate {
  final String name;
  final String? description;
  final AuthType authType;
  final AppType appType;
  final String? appVersion;

  // For Basic Auth
  final String? basicUsername;
  final String? basicPassword;

  // For OAuth 2.0
  final List<String>? oauthRedirectUris;
  final List<String>? oauthScopes;

  // Rate limiting
  final int? rateLimitPerMinute;
  final int? rateLimitPerHour;

  // Optional expiration
  final int? expiresInDays;

  // IP whitelist
  final List<String>? ipWhitelist;

  // Additional metadata
  final Map<String, dynamic>? metadata;

  ApiCredentialCreate({
    required this.name,
    this.description,
    required this.authType,
    required this.appType,
    this.appVersion,
    this.basicUsername,
    this.basicPassword,
    this.oauthRedirectUris,
    this.oauthScopes,
    this.rateLimitPerMinute,
    this.rateLimitPerHour,
    this.expiresInDays,
    this.ipWhitelist,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'auth_type': authType.name,
      'app_type': appType.name,
      'app_version': appVersion,
      'basic_username': basicUsername,
      'basic_password': basicPassword,
      'oauth_redirect_uris': oauthRedirectUris,
      'oauth_scopes': oauthScopes,
      'rate_limit_per_minute': rateLimitPerMinute,
      'rate_limit_per_hour': rateLimitPerHour,
      'expires_in_days': expiresInDays,
      'ip_whitelist': ipWhitelist,
      'metadata': metadata,
    };
  }
}

class ApiCredentialUpdate {
  final String? name;
  final String? description;
  final bool? isActive;
  final int? rateLimitPerMinute;
  final int? rateLimitPerHour;
  final List<String>? ipWhitelist;
  final Map<String, dynamic>? metadata;

  ApiCredentialUpdate({
    this.name,
    this.description,
    this.isActive,
    this.rateLimitPerMinute,
    this.rateLimitPerHour,
    this.ipWhitelist,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
      'rate_limit_per_minute': rateLimitPerMinute,
      'rate_limit_per_hour': rateLimitPerHour,
      'ip_whitelist': ipWhitelist,
      'metadata': metadata,
    };
  }
}

// ============ Response Models ============

class ApiCredential {
  final String id;
  final String name;
  final String? description;
  final String authType;
  final String appType;
  final String? appVersion;

  // For Basic Auth (username only, no password)
  final String? basicUsername;

  // For Bearer/API Key (masked)
  final String? apiKeyPreview;

  // For OAuth 2.0
  final String? oauthClientId;
  final List<String>? oauthRedirectUris;
  final List<String>? oauthScopes;

  // Rate limiting
  final int rateLimitPerMinute;
  final int rateLimitPerHour;

  // Status
  final bool isActive;
  final bool isRevoked;
  final String? lastUsedAt;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;
  final String? revokedAt;

  // Metadata
  final List<String>? ipWhitelist;
  final Map<String, dynamic>? metadata;

  ApiCredential({
    required this.id,
    required this.name,
    this.description,
    required this.authType,
    required this.appType,
    this.appVersion,
    this.basicUsername,
    this.apiKeyPreview,
    this.oauthClientId,
    this.oauthRedirectUris,
    this.oauthScopes,
    required this.rateLimitPerMinute,
    required this.rateLimitPerHour,
    required this.isActive,
    required this.isRevoked,
    this.lastUsedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.revokedAt,
    this.ipWhitelist,
    this.metadata,
  });

  factory ApiCredential.fromJson(Map<String, dynamic> json) {
    return ApiCredential(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      authType: json['auth_type'] as String,
      appType: json['app_type'] as String,
      appVersion: json['app_version'] as String?,
      basicUsername: json['basic_username'] as String?,
      apiKeyPreview: json['api_key_preview'] as String?,
      oauthClientId: json['oauth_client_id'] as String?,
      oauthRedirectUris: (json['oauth_redirect_uris'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      oauthScopes: (json['oauth_scopes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rateLimitPerMinute: json['rate_limit_per_minute'] as int,
      rateLimitPerHour: json['rate_limit_per_hour'] as int,
      isActive: json['is_active'] as bool,
      isRevoked: json['is_revoked'] as bool,
      lastUsedAt: json['last_used_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      revokedAt: json['revoked_at'] as String?,
      ipWhitelist: (json['ip_whitelist'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'auth_type': authType,
      'app_type': appType,
      'app_version': appVersion,
      'basic_username': basicUsername,
      'api_key_preview': apiKeyPreview,
      'oauth_client_id': oauthClientId,
      'oauth_redirect_uris': oauthRedirectUris,
      'oauth_scopes': oauthScopes,
      'rate_limit_per_minute': rateLimitPerMinute,
      'rate_limit_per_hour': rateLimitPerHour,
      'is_active': isActive,
      'is_revoked': isRevoked,
      'last_used_at': lastUsedAt,
      'expires_at': expiresAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'revoked_at': revokedAt,
      'ip_whitelist': ipWhitelist,
      'metadata': metadata,
    };
  }
}

class ApiCredentialCreateResponse {
  final ApiCredential credential;

  // Only shown on creation
  final String? apiKey;
  final String? basicPassword;
  final String? oauthClientSecret;

  final String warning;

  ApiCredentialCreateResponse({
    required this.credential,
    this.apiKey,
    this.basicPassword,
    this.oauthClientSecret,
    required this.warning,
  });

  factory ApiCredentialCreateResponse.fromJson(Map<String, dynamic> json) {
    return ApiCredentialCreateResponse(
      credential: ApiCredential.fromJson(json['credential'] as Map<String, dynamic>),
      apiKey: json['api_key'] as String?,
      basicPassword: json['basic_password'] as String?,
      oauthClientSecret: json['oauth_client_secret'] as String?,
      warning: json['warning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'credential': credential.toJson(),
      'api_key': apiKey,
      'basic_password': basicPassword,
      'oauth_client_secret': oauthClientSecret,
      'warning': warning,
    };
  }
}

class ApiCredentialsListResponse {
  final int total;
  final int active;
  final List<ApiCredential> credentials;

  ApiCredentialsListResponse({
    required this.total,
    required this.active,
    required this.credentials,
  });

  factory ApiCredentialsListResponse.fromJson(Map<String, dynamic> json) {
    return ApiCredentialsListResponse(
      total: json['total'] as int,
      active: json['active'] as int,
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => ApiCredential.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'credentials': credentials.map((e) => e.toJson()).toList(),
    };
  }
}

// ============ OAuth 2.0 Models ============

class OAuthTokenRequest {
  final String grantType;
  final String clientId;
  final String clientSecret;
  final String? code;
  final String? redirectUri;
  final String? refreshToken;
  final String? scope;

  OAuthTokenRequest({
    required this.grantType,
    required this.clientId,
    required this.clientSecret,
    this.code,
    this.redirectUri,
    this.refreshToken,
    this.scope,
  });

  Map<String, dynamic> toJson() {
    return {
      'grant_type': grantType,
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': code,
      'redirect_uri': redirectUri,
      'refresh_token': refreshToken,
      'scope': scope,
    };
  }
}

class OAuthTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final String? scope;

  OAuthTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.scope,
  });

  factory OAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return OAuthTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      refreshToken: json['refresh_token'] as String?,
      scope: json['scope'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
      'scope': scope,
    };
  }
}

// ============ Usage Log Models ============

class ApiUsageLog {
  final String id;
  final String? credentialId;
  final String? userId;
  final String method;
  final String endpoint;
  final String? path;
  final int statusCode;
  final int? responseTimeMs;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceType;
  final String createdAt;

  ApiUsageLog({
    required this.id,
    this.credentialId,
    this.userId,
    required this.method,
    required this.endpoint,
    this.path,
    required this.statusCode,
    this.responseTimeMs,
    this.ipAddress,
    this.userAgent,
    this.deviceType,
    required this.createdAt,
  });

  factory ApiUsageLog.fromJson(Map<String, dynamic> json) {
    return ApiUsageLog(
      id: json['id'] as String,
      credentialId: json['credential_id'] as String?,
      userId: json['user_id'] as String?,
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      path: json['path'] as String?,
      statusCode: json['status_code'] as int,
      responseTimeMs: json['response_time_ms'] as int?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      deviceType: json['device_type'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credential_id': credentialId,
      'user_id': userId,
      'method': method,
      'endpoint': endpoint,
      'path': path,
      'status_code': statusCode,
      'response_time_ms': responseTimeMs,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_type': deviceType,
      'created_at': createdAt,
    };
  }
}

class ApiUsageStatsResponse {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTimeMs;
  final Map<String, int> requestsByMethod;
  final Map<String, int> requestsByStatus;
  final List<Map<String, dynamic>> topEndpoints;
  final int periodDays;

  ApiUsageStatsResponse({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTimeMs,
    required this.requestsByMethod,
    required this.requestsByStatus,
    required this.topEndpoints,
    required this.periodDays,
  });

  factory ApiUsageStatsResponse.fromJson(Map<String, dynamic> json) {
    return ApiUsageStatsResponse(
      totalRequests: json['total_requests'] as int,
      successfulRequests: json['successful_requests'] as int,
      failedRequests: json['failed_requests'] as int,
      averageResponseTimeMs: (json['average_response_time_ms'] as num).toDouble(),
      requestsByMethod: Map<String, int>.from(
          json['requests_by_method'] as Map<String, dynamic>),
      requestsByStatus: Map<String, int>.from(
          json['requests_by_status'] as Map<String, dynamic>),
      topEndpoints: (json['top_endpoints'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      periodDays: json['period_days'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'successful_requests': successfulRequests,
      'failed_requests': failedRequests,
      'average_response_time_ms': averageResponseTimeMs,
      'requests_by_method': requestsByMethod,
      'requests_by_status': requestsByStatus,
      'top_endpoints': topEndpoints,
      'period_days': periodDays,
    };
  }
}
