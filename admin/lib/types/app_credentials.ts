// FixMate App Credentials Types
// Types for app authentication with the backend

export interface AppCredential {
  id: string;
  app_name: string;
  app_type: string;
  api_key_preview: string;
  oauth_client_id?: string;
  basic_username?: string;
  is_active: boolean;
  last_used_at?: string;
  expires_at?: string;
  created_at: string;
  updated_at: string;
  description?: string;
}

export interface AppCredentialCreateResponse {
  credential: AppCredential;
  api_key: string;
  oauth_client_secret?: string;
  basic_password?: string;
  warning: string;
}

export interface AppAuthRequest {
  app_name: string;
  api_key: string;
}

export interface AppAuthResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  app_name: string;
  app_type: string;
}

// ============ API Client Functions ============

export const appCredentialsApi = {
  // Authenticate app and get access token
  authenticate: (data: AppAuthRequest) =>
    api.post<AppAuthResponse>('/api/auth/apps/authenticate', data),

  // List all app credentials (admin only)
  listCredentials: () =>
    api.get<AppCredential[]>('/api/auth/apps'),

  // Get a specific app credential (admin only)
  getCredential: (appName: string) =>
    api.get<AppCredential>(`/api/auth/apps/${appName}`),

  // Regenerate API key (admin only)
  regenerateCredential: (appName: string) =>
    api.post(`/api/auth/apps/${appName}/regenerate`),

  // Toggle active status (admin only)
  toggleCredential: (appName: string) =>
    api.put(`/api/auth/apps/${appName}/toggle`),
};
