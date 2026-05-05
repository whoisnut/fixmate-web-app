# FixMate App Credentials

This module provides API credentials for the admin and mobile apps to authenticate with the backend.

## Overview

The `AppCredential` model stores credentials that allow apps (admin, mobile) to access the backend API. Each app has a unique API key that can be used to authenticate and obtain access tokens.

## Authentication Flow

1. **App Registration**: Admin creates app credentials via the API
2. **API Key Storage**: API key is stored securely (hashed) in the database
3. **Authentication**: App sends `app_name` and `api_key` to `/api/auth/apps/authenticate`
4. **Access Token**: Backend returns a JWT access token valid for 1 hour
5. **API Access**: App uses the access token in `Authorization: Bearer <token>` header

## API Endpoints

### Public Endpoints

#### Authenticate App
```http
POST /api/auth/apps/authenticate
Content-Type: application/json

{
  "app_name": "admin",
  "api_key": "fm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "app_name": "admin",
  "app_type": "admin"
}
```

### Admin Endpoints (Requires Admin Role)

#### List All App Credentials
```http
GET /api/auth/apps
Authorization: Bearer <admin_token>
```

#### Get Specific App Credential
```http
GET /api/auth/apps/{app_name}
Authorization: Bearer <admin_token>
```

#### Regenerate API Key
```http
POST /api/auth/apps/{app_name}/regenerate
Authorization: Bearer <admin_token>
```

Response:
```json
{
  "message": "API key regenerated successfully",
  "api_key": "fm_new_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "warning": "Store this new API key securely. It will not be shown again."
}
```

#### Toggle Active Status
```http
PUT /api/auth/apps/{app_name}/toggle
Authorization: Bearer <admin_token>
```

## Usage Examples

### Admin App (TypeScript)

```typescript
import { appCredentialsApi } from './lib/types/app_credentials';

// Authenticate and get access token
const auth = await appCredentialsApi.authenticate({
  app_name: 'admin',
  api_key: 'fm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
});

// Store token for API calls
localStorage.setItem('app_token', auth.access_token);
```

### Mobile App (Dart)

```dart
import 'package:fixmate/models/app_credential.dart';
import 'package:fixmate/core/repositories/app_credential_repository.dart';

final repo = AppCredentialRepository();

// Authenticate and get access token
final auth = await repo.authenticate(AppAuthRequest(
  appName: 'mobile',
  apiKey: 'fm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
));

// Store token for API calls
await storage.write(key: 'app_token', value: auth.accessToken);
```

## Security Notes

1. **API Keys**: Generated using `secrets.token_urlsafe(32)` for cryptographic security
2. **Hashing**: API keys are hashed using SHA-256 before storage
3. **Expiration**: Access tokens expire after 1 hour
4. **Rotation**: Admin can regenerate API keys at any time
5. **Revocation**: Admin can deactivate credentials without deleting them

## Environment Variables

The following environment variables can be set in `.env`:

```env
# App Credentials (for admin and mobile apps)
ADMIN_APP_API_KEY=fm_admin_dev_key_change_in_production
MOBILE_APP_API_KEY=fm_mobile_dev_key_change_in_production
```

Note: These are for reference only. Actual credentials are stored in the database.

## Database Schema

```sql
CREATE TABLE app_credentials (
    id VARCHAR PRIMARY KEY,
    app_name VARCHAR(50) UNIQUE NOT NULL,
    app_type VARCHAR(20) NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    api_key_hash VARCHAR(255) UNIQUE NOT NULL,
    oauth_client_id VARCHAR(255) UNIQUE,
    oauth_client_secret VARCHAR(255),
    basic_username VARCHAR(100),
    basic_password VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);
```

## Default Credentials

On first startup, the following credentials are automatically created:

| App Name | App Type | Description |
|----------|----------|-------------|
| admin | admin | Admin web panel credentials |
| mobile | mobile | Mobile app credentials |

The actual API keys are generated randomly and printed to the console on first run.

## Troubleshooting

### "Invalid or expired app credentials"
- Check that the API key is correct
- Verify the credential is active (not revoked)
- Check if the credential has expired

### "App credentials have expired"
- Contact admin to regenerate the API key
- Or use the admin endpoint to regenerate it

### "Only admins can create app credentials"
- Log in as an admin user
- Use the admin endpoints to manage credentials
