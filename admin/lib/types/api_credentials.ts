// FixMate API Credentials Types
// Shared types for API credential management

export enum AuthType {
  BASIC = 'basic',
  BEARER = 'bearer',
  OAUTH2 = 'oauth2',
  API_KEY = 'api_key',
}

export enum AppType {
  ADMIN = 'admin',
  MOBILE = 'mobile',
  WEB = 'web',
  EXTERNAL = 'external',
}

// ============ Request Types ============

export interface ApiCredentialCreate {
  name: string;
  description?: string;
  authType: AuthType;
  appType: AppType;
  appVersion?: string;

  // For Basic Auth
  basicUsername?: string;
  basicPassword?: string;

  // For OAuth 2.0
  oauthRedirectUris?: string[];
  oauthScopes?: string[];

  // Rate limiting
  rateLimitPerMinute?: number;
  rateLimitPerHour?: number;

  // Optional expiration
  expiresInDays?: number;

  // IP whitelist
  ipWhitelist?: string[];

  // Additional metadata
  metadata?: Record<string, any>;
}

export interface ApiCredentialUpdate {
  name?: string;
  description?: string;
  isActive?: boolean;
  rateLimitPerMinute?: number;
  rateLimitPerHour?: number;
  ipWhitelist?: string[];
  metadata?: Record<string, any>;
}

export interface ApiCredentialRevoke {
  reason?: string;
}

// ============ Response Types ============

export interface ApiCredential {
  id: string;
  name: string;
  description?: string;
  authType: string;
  appType: string;
  appVersion?: string;

  // For Basic Auth (username only, no password)
  basicUsername?: string;

  // For Bearer/API Key (masked)
  apiKeyPreview?: string;

  // For OAuth 2.0
  oauthClientId?: string;
  oauthRedirectUris?: string[];
  oauthScopes?: string[];

  // Rate limiting
  rateLimitPerMinute: number;
  rateLimitPerHour: number;

  // Status
  isActive: boolean;
  isRevoked: boolean;
  lastUsedAt?: string;
  expiresAt?: string;
  createdAt: string;
  updatedAt: string;
  revokedAt?: string;

  // Metadata
  ipWhitelist?: string[];
  metadata?: Record<string, any>;
}

export interface ApiCredentialCreateResponse {
  credential: ApiCredential;

  // Only shown on creation
  apiKey?: string;
  basicPassword?: string;
  oauthClientSecret?: string;

  warning: string;
}

export interface ApiCredentialsListResponse {
  total: number;
  active: number;
  credentials: ApiCredential[];
}

// ============ OAuth 2.0 Types ============

export interface OAuthTokenRequest {
  grantType: 'client_credentials' | 'authorization_code' | 'refresh_token';
  clientId: string;
  clientSecret: string;
  code?: string;
  redirectUri?: string;
  refreshToken?: string;
  scope?: string;
}

export interface OAuthTokenResponse {
  accessToken: string;
  tokenType: string;
  expiresIn: number;
  refreshToken?: string;
  scope?: string;
}

// ============ Usage Log Types ============

export interface ApiUsageLog {
  id: string;
  credentialId?: string;
  userId?: string;
  method: string;
  endpoint: string;
  path?: string;
  statusCode: number;
  responseTimeMs?: number;
  ipAddress?: string;
  userAgent?: string;
  deviceType?: string;
  createdAt: string;
}

export interface ApiUsageStatsResponse {
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  averageResponseTimeMs: number;
  requestsByMethod: Record<string, number>;
  requestsByStatus: Record<string, number>;
  topEndpoints: Array<{ endpoint: string; count: number }>;
  periodDays: number;
}

// ============ API Client Functions ============

export const apiCredentialsApi = {
  // Create a new API credential
  createCredential: (data: ApiCredentialCreate) =>
    api.post<ApiCredentialCreateResponse>('/api/auth/credentials', data),

  // List all credentials for current user
  listCredentials: () =>
    api.get<ApiCredentialsListResponse>('/api/auth/credentials'),

  // Get a specific credential
  getCredential: (credentialId: string) =>
    api.get<ApiCredential>(`/api/auth/credentials/${credentialId}`),

  // Update a credential
  updateCredential: (credentialId: string, data: ApiCredentialUpdate) =>
    api.put<ApiCredential>(`/api/auth/credentials/${credentialId}`, data),

  // Revoke a credential
  revokeCredential: (credentialId: string, data?: ApiCredentialRevoke) =>
    api.post(`/api/auth/credentials/${credentialId}/revoke`, data || {}),

  // Delete a credential
  deleteCredential: (credentialId: string) =>
    api.delete(`/api/auth/credentials/${credentialId}`),

  // OAuth 2.0 token endpoint
  oauthToken: (data: OAuthTokenRequest) =>
    api.post<OAuthTokenResponse>('/api/auth/credentials/oauth/token', data),

  // Get usage statistics
  getUsageStats: (days = 30) =>
    api.get<ApiUsageStatsResponse>(`/api/auth/credentials/usage/stats?days=${days}`),
};
