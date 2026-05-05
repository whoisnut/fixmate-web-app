# Backend Migration Guide

This guide helps you migrate from the old backend structure to the new template-based structure.

## Overview

The new backend structure follows a clean architecture pattern with:
- **API Versioning** (`/api/v1.0.0`)
- **Service Layer** for business logic
- **Standardized Response Format** with trace IDs
- **Comprehensive Middleware** for logging and error handling
- **Better Separation of Concerns**

## Directory Structure Comparison

### Old Structure
```
backend/
├── app/
│   ├── core/
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── deps.py
│   │   └── security.py
│   ├── models/
│   │   ├── user.py
│   │   ├── service.py
│   │   ├── booking.py
│   │   └── payout.py
│   ├── routers/
│   │   ├── auth.py
│   │   ├── bookings.py
│   │   └── ...
│   ├── schemas/
│   │   ├── user.py
│   │   └── ...
│   └── main.py
```

### New Structure
```
backend_new/
├── app/
│   ├── api/
│   │   └── v1_0_0/
│   │       ├── deps/
│   │       ├── handler/
│   │       └── router.py
│   ├── core/
│   │   ├── config/
│   │   ├── enum/
│   │   ├── system/
│   │   └── util/
│   ├── middleware/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   └── __init__.py
├── logs/
├── main.py
└── seed_data.py
```

## Key Changes

### 1. Configuration

**Old:**
```python
# app/core/config.py
class Settings(BaseSettings):
    SECRET_KEY: str
    DATABASE_URL: str
    # ...
```

**New:**
```python
# app/core/config/config.py
class Settings(BaseSettings):
    PROJECT_NAME: str = 'FixMate API'
    API_V1_0_0_STR: str = '/api/v1.0.0'
    ENV: str = 'development'
    # ...
```

### 2. Database

**Old:**
```python
# app/core/database.py
from sqlalchemy import create_engine
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
```

**New:**
```python
# app/core/system/db.py
from app.core.config import settings
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def getSession():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### 3. Response Format

**Old:**
```python
# Direct return
return {"access_token": token, "user": user_data}
```

**New:**
```python
# Standardized response
return IResponseBase(TokenResponse)(
    data=TokenResponse(...),
    response_status=RESPONSE_STATUS_ENUM.SUCCESS,
    response_code=int(RES_CUSTOM_CODE_ENUM.TRANSACTION_SUCCESS),
    response_msg="Success message"
)
```

### 4. Service Layer

**Old:**
```python
# Business logic in routers
@router.post("/register")
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Business logic here
    user = User(...)
    db.add(user)
    db.commit()
    return user
```

**New:**
```python
# Business logic in services
@router.post("/register")
async def register(user_data: UserCreate, session: Session = Depends(getSession)):
    user, token = await AuthService.register_user(session, user_data)
    return IResponseBase(TokenResponse)(...)
```

### 5. Models

**Old:**
```python
# app/models/user.py
class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=gen_uuid)
    # ...
```

**New:**
```python
# app/models/user_model.py
class UserModel(Base):
    __tablename__ = 'users'
    id: Mapped[UUID] = Column(sqlalchemyUUID, primary_key=True, default=uuid4)
    # ...
```

## Migration Steps

### Step 1: Install New Dependencies

```bash
cd backend_new
pip install -r requirements.txt
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your configuration
nano .env
```

### Step 3: Seed Initial Data

```bash
# Run seed script
python seed_data.py
```

This will create:
- Default admin user (admin@fixmate.dev / Admin1234)
- Demo services (Car and Motorbike categories)
- App credentials for admin and mobile

### Step 4: Start the Server

```bash
# Development
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Step 5: Update Frontend API Calls

**Old API URL:**
```typescript
const API_URL = 'http://localhost:8000/api/auth/login'
```

**New API URL:**
```typescript
const API_URL = 'http://localhost:8000/api/v1.0.0/auth/login'
```

**Old Response:**
```json
{
  "access_token": "...",
  "user": {...}
}
```

**New Response:**
```json
{
  "trace_id": "...",
  "data": {
    "access_token": "...",
    "user": {...}
  },
  "response_status": 1,
  "response_code": 200,
  "response_msg": "Login successful"
}
```

## API Endpoint Mapping

| Old Endpoint | New Endpoint |
|--------------|--------------|
| `POST /api/auth/register` | `POST /api/v1.0.0/auth/register` |
| `POST /api/auth/login` | `POST /api/v1.0.0/auth/login` |
| `GET /api/categories` | `GET /api/v1.0.0/services/categories` |
| `GET /api/services` | `GET /api/v1.0.0/services/services` |
| `POST /api/auth/apps/authenticate` | `POST /api/v1.0.0/apps/authenticate` |

## Response Format Changes

### Authentication Endpoints

**Old:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "name": "...",
    "email": "...",
    "role": "customer"
  },
  "expires_in": 86400
}
```

**New:**
```json
{
  "trace_id": "01H...",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "...",
      "name": "...",
      "email": "...",
      "role": "customer"
    },
    "expires_in": 3600
  },
  "response_status": 1,
  "response_code": 200,
  "response_msg": "Login successful"
}
```

### Error Responses

**Old:**
```json
{
  "detail": "Invalid credentials"
}
```

**New:**
```json
{
  "trace_id": "01H...",
  "data": null,
  "response_status": 0,
  "response_code": 401,
  "response_msg": "Invalid credentials"
}
```

## Frontend Updates Required

### Admin App (TypeScript)

**Update API base URL:**
```typescript
// lib/api.ts
const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1.0.0',
});
```

**Update response handling:**
```typescript
// Old
const response = await api.post('/auth/login', credentials);
const { access_token, user } = response.data;

// New
const response = await api.post('/auth/login', credentials);
const { access_token, user } = response.data.data;
```

### Mobile App (Dart)

**Update API base URL:**
```dart
// lib/core/network/api_client.dart
class ApiClient {
  final String baseUrl = 'http://localhost:8000/api/v1.0.0';
}
```

**Update response handling:**
```dart
// Old
final response = await _apiClient.post('/auth/login', data);
final token = response.data['access_token'];

// New
final response = await _apiClient.post('/auth/login', data);
final token = response.data['data']['access_token'];
```

## Testing the Migration

### 1. Test Authentication

```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1.0.0/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+1234567890",
    "password": "Test1234",
    "role": "customer"
  }'
```

### 2. Test App Authentication

```bash
# Authenticate admin app
curl -X POST http://localhost:8000/api/v1.0.0/apps/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "app_name": "admin",
    "api_key": "fm_..."  # Use the key from seed_data.py output
  }'
```

### 3. Test Services

```bash
# Get categories
curl http://localhost:8000/api/v1.0.0/services/categories

# Get services
curl http://localhost:8000/api/v1.0.0/services/services
```

## Rollback Plan

If you need to rollback to the old structure:

1. Stop the new server
2. Start the old server:
   ```bash
   cd backend
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
3. Revert frontend API URL changes

## Troubleshooting

### Import Errors

If you get import errors, make sure you're running from the `backend_new` directory:
```bash
cd backend_new
python main.py
```

### Database Errors

If you get database errors, run the seed script:
```bash
python seed_data.py
```

### CORS Errors

Update the `.env` file with your frontend URLs:
```env
WHITE_LIST_CORS=http://localhost:3000,http://localhost:3001
```

## Next Steps

1. **Complete API Endpoints**: Add remaining endpoints (bookings, payments, payouts, etc.)
2. **Add Tests**: Write unit and integration tests
3. **Add Documentation**: Update API documentation
4. **Deploy**: Deploy to production environment

## Support

For issues or questions, refer to:
- [README.md](README.md) - General documentation
- [CLAUDE.md](../backend/CLAUDE.md) - Codebase documentation
- [APP_CREDENTIALS.md](../backend/APP_CREDENTIALS.md) - App credentials guide
