# FixMate Backend - Codebase Documentation

## Overview

FixMate is an on-demand technician booking platform built with FastAPI. The backend provides REST APIs for customers, technicians, and admins to manage service bookings, payments, reviews, and real-time messaging.

## Tech Stack

- **Framework**: FastAPI 0.104+
- **Database**: SQLite (development), PostgreSQL (production recommended)
- **ORM**: SQLAlchemy 2.0+
- **Authentication**: JWT (access + refresh tokens)
- **Password Hashing**: bcrypt
- **Payment Gateway**: Stripe (configured, partial implementation)
- **Storage**: Firebase Storage
- **Maps**: Google Maps API
- **Real-time**: WebSocket (FastAPI native)
- **Testing**: pytest

## Project Structure

```
backend/
├── app/
│   ├── core/              # Core configuration and utilities
│   │   ├── config.py      # Settings and environment variables
│   │   ├── database.py    # Database session and engine
│   │   ├── deps.py        # Dependency injection (auth, roles)
│   │   └── security.py    # Password hashing, JWT tokens
│   ├── models/            # SQLAlchemy ORM models
│   │   ├── user.py        # User, Technician, TokenBlacklist
│   │   ├── service.py     # Category, Service
│   │   ├── booking.py     # Booking, Payment, PaymentMethod, Review, Message
│   │   ├── payout.py      # Payout
│   │   ├── auth_session.py  # AuthSession for session tracking
│   │   ├── api_credential.py  # ApiCredential, ApiUsageLog for user API keys
│   │   └── app_credential.py  # AppCredential for app authentication
│   ├── routers/           # API endpoints
│   │   ├── auth.py        # Registration, login, logout, technician verification
│   │   ├── bookings.py    # Booking CRUD, status transitions
│   │   ├── payments.py    # Payment processing, webhooks
│   │   ├── payment_methods.py  # Saved payment methods
│   │   ├── payouts.py     # Technician payout requests
│   │   ├── reviews.py     # Reviews and ratings
│   │   ├── messages.py    # In-app messaging
│   │   ├── profile.py     # User profile management
│   │   ├── services.py    # Service catalog
│   │   ├── admin.py       # Admin dashboard endpoints
│   │   ├── websocket.py   # WebSocket connection
│   │   ├── api_credentials.py  # User API key management
│   │   └── app_credentials.py  # App authentication (admin, mobile)
│   ├── schemas/           # Pydantic request/response models
│   │   ├── user.py
│   │   ├── booking.py
│   │   ├── payment.py
│   │   ├── payment_method.py
│   │   ├── payout.py
│   │   ├── auth_session.py
│   │   ├── api_credential.py
│   │   └── app_credential.py
│   ├── websockets/        # WebSocket connection manager
│   │   └── manager.py
│   └── main.py            # Application entry point
├── tests/                 # Test files
├── requirements.txt       # Python dependencies
├── create_demo_users.py   # Demo data seeding script
├── seed_app_credentials.py  # App credentials seeding script
└── APP_CREDENTIALS.md     # App credentials documentation
```

## Core Concepts

### User Roles

1. **Customer**: Can create bookings, make payments, leave reviews
2. **Technician**: Can accept/reject bookings, update status, request payouts
3. **Admin**: Can verify technicians, manage users, view analytics

### Booking Status Flow

```
pending → accepted → in_progress → completed
    ↓         ↓           ↓
  cancelled  cancelled   cancelled
```

Valid transitions are enforced in `bookings.py` via `VALID_TRANSITIONS` dict.

### Authentication Flow

1. User registers/logs in → receives access token (60 min) + refresh token (30 days)
2. Access token sent in `Authorization: Bearer <token>` header
3. Token blacklisted on logout
4. Refresh token can generate new access tokens

### App Authentication

Admin and mobile apps use API keys to authenticate with the backend:
- Apps are registered with unique API keys stored in `app_credentials` table
- Authenticate via `POST /api/auth/apps/authenticate` with `app_name` and `api_key`
- Returns JWT access token valid for 1 hour
- See [APP_CREDENTIALS.md](APP_CREDENTIALS.md) for details

### Technician Verification

Technicians must submit documents for admin approval before accepting jobs:
- `pending` → `verified` (by admin) or `rejected` (with reason)

## Key Endpoints

### Authentication (`/api/auth`)
- `POST /register` - User registration
- `POST /register/technician` - Technician registration with documents
- `POST /login` - User login
- `POST /login/technician` - Technician login with verification status
- `POST /refresh` - Refresh access token
- `POST /logout` - Blacklist current token

### Bookings (`/api/bookings`)
- `POST /` - Create booking
- `GET /` - List user's bookings
- `GET /available` - Available bookings for technicians (with distance filter)
- `POST /{id}/accept` - Technician accepts booking
- `POST /{id}/start` - Start job
- `POST /{id}/complete` - Complete job
- `DELETE /{id}` - Cancel booking

### Payments (`/api/payments`)
- `POST /` - Create payment
- `GET /{booking_id}` - Get payment status
- `POST /webhook/stripe` - Stripe webhook handler

### Payouts (`/api/payouts`)
- `POST /` - Request payout (technician)
- `GET /my-requests` - List my payouts
- `POST /{id}/approve` - Admin approves payout
- `POST /{id}/reject` - Admin rejects payout

### Admin (`/api/admin`)
- `GET /users` - List all users
- `POST /users/{id}/suspend` - Suspend user
- `GET /technicians` - List technicians with verification status
- `POST /technicians/{id}/verify` - Verify technician
- `GET /analytics/overview` - Platform analytics

### App Credentials (`/api/auth/apps`)
- `POST /authenticate` - Authenticate app and get access token
- `GET /` - List all app credentials (admin only)
- `GET /{app_name}` - Get specific app credential (admin only)
- `POST /{app_name}/regenerate` - Regenerate API key (admin only)
- `PUT /{app_name}/toggle` - Toggle active status (admin only)

## Database Models

### User
- `id`, `name`, `email`, `phone`, `password` (hashed)
- `role`: customer | technician | admin
- `is_active`, `created_at`

### Technician (extends User)
- `user_id`, `bio`, `specialties`, `documents`
- `verification_status`, `is_verified`, `is_available`
- `rating`, `total_jobs`, `current_lat`, `current_lng`

### Booking
- `customer_id`, `technician_id`, `service_id`
- `address`, `lat`, `lng`, `scheduled_at`
- `status`, `total_price`, `notes`

### Payment
- `booking_id`, `amount`, `method`, `status`
- `transaction_id`, `paid_at`

### Payout
- `user_id`, `amount`, `method`, `status`
- `payment_account`, `requested_at`, `processed_at`

### AppCredential
- `app_name`, `app_type`, `api_key` (hashed)
- `oauth_client_id`, `oauth_client_secret`
- `is_active`, `last_used_at`, `expires_at`

## Configuration

Environment variables (`.env`):

```env
SECRET_KEY=your-secret-key
DATABASE_URL=sqlite:///./fixmate.db
REDIS_URL=redis://localhost:6379
FIREBASE_CREDENTIALS_PATH=path/to/credentials.json
FIREBASE_STORAGE_BUCKET=fixmate-storage
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
GOOGLE_MAPS_API_KEY=AIza_...

# App Credentials (for reference only)
ADMIN_APP_API_KEY=fm_admin_dev_key_change_in_production
MOBILE_APP_API_KEY=fm_mobile_dev_key_change_in_production
```

## Running the Application

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run tests
pytest tests/
```

## Known Issues & TODOs

1. **Security**: Card numbers stored (should tokenize with Stripe)
2. **No rate limiting** on public endpoints
3. **No database migrations** (add Alembic)
4. **Redis configured but unused** (implement caching)
5. **No background tasks** (use Celery or FastAPI BackgroundTasks)
6. **Limited test coverage**
7. **No pagination** on list endpoints
8. **No proper logging** framework
9. **No API versioning**
10. **Firebase integration incomplete**

## Development Notes

- All datetime fields use UTC
- UUIDs are strings for JSON compatibility
- Email addresses are normalized to lowercase
- Phone numbers are stored as-is (no validation)
- Distance calculations use Haversine formula
- WebSocket connections managed via `ConnectionManager`
