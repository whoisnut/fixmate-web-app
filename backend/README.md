# FixMate Backend API

A modern FastAPI backend for the FixMate on-demand technician booking platform.

## Features

- **RESTful API** with versioning support (`/api/v1.0.0`)
- **Service Layer Architecture** for clean separation of concerns
- **Comprehensive Logging** with file-based logging
- **Middleware System** for request/response processing
- **Standardized Response Format** with trace IDs
- **App Authentication** for admin and mobile apps
- **User Authentication** with JWT tokens
- **Service & Category Management**
- **Booking System** with status transitions
- **Technician Verification** workflow

## Project Structure

```
backend_new/
├── app/
│   ├── api/
│   │   └── v1_0_0/
│   │       ├── deps/           # API dependencies
│   │       ├── handler/        # API route handlers
│   │       └── router.py       # API router
│   ├── core/
│   │   ├── config/             # Configuration settings
│   │   ├── enum/               # Enumerations
│   │   ├── system/             # System utilities (db, log)
│   │   └── util/               # Utility functions
│   ├── middleware/              # Custom middleware
│   ├── models/                  # SQLAlchemy models
│   ├── schemas/                 # Pydantic schemas
│   ├── services/                # Business logic layer
│   └── __init__.py
├── logs/                        # Application logs
├── main.py                      # Application entry point
├── requirements.txt             # Python dependencies
├── .env                         # Environment variables
└── .env.example                # Environment template
```

## Quick Start

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### Running the Application

```bash
# Development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production server
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### API Documentation

Once running, access the API documentation at:
- Swagger UI: http://localhost:8000/api/v1.0.0/docs
- ReDoc: http://localhost:8000/api/v1.0.0/redoc

## API Endpoints

### Authentication (`/api/v1.0.0/auth`)

- `POST /register` - Register a new user
- `POST /register/technician` - Register a new technician
- `POST /login` - User login
- `POST /login/technician` - Technician login
- `POST /refresh` - Refresh access token
- `POST /logout` - Logout user
- `GET /technician/verification-status` - Get technician verification status

### Services (`/api/v1.0.0/services`)

- `GET /categories` - Get all categories
- `POST /categories` - Create a new category
- `PUT /categories/{id}` - Update a category
- `DELETE /categories/{id}` - Delete a category
- `GET /services` - Get all services
- `POST /services` - Create a new service
- `PUT /services/{id}` - Update a service
- `DELETE /services/{id}` - Delete a service

### App Credentials (`/api/v1.0.0/apps`)

- `POST /authenticate` - Authenticate app
- `GET /credentials` - List all app credentials (admin only)
- `GET /credentials/{app_name}` - Get app credential (admin only)
- `POST /credentials/{app_name}/regenerate` - Regenerate API key (admin only)
- `PUT /credentials/{app_name}/toggle` - Toggle active status (admin only)

## Response Format

All API responses follow a standard format:

```json
{
  "trace_id": "01H...",
  "data": { ... },
  "response_status": 1,
  "response_code": 200,
  "response_msg": "Success message"
}
```

- `trace_id`: Unique identifier for request tracing
- `data`: Response payload
- `response_status`: 1 for success, 0 for failure
- `response_code`: HTTP status code
- `response_msg`: Human-readable message

## Configuration

Key environment variables:

```env
# Application
APP_NAME=FixMate
ENV=development
PORT=8000

# Security
SECRET_KEY=your-secret-key-min-32-chars
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

# Database
DATABASE_URL=sqlite:///./fixmate.db

# Redis
REDIS_URL=redis://localhost:6379/0

# Firebase
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
FIREBASE_STORAGE_BUCKET=fixmate-storage.appspot.com

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Google Maps
GOOGLE_MAPS_API_KEY=AIza_...
```

## Development

### Code Style

```bash
# Format code
black app/

# Lint code
ruff check app/
```

### Testing

```bash
# Run tests
pytest tests/

# Run tests with coverage
pytest tests/ --cov=app
```

## Architecture

### Service Layer Pattern

Business logic is separated into service classes:
- `AuthService` - Authentication operations
- `ServiceService` - Service and category management
- `BookingService` - Booking operations
- `AppCredentialService` - App credential management

### Middleware

- `BaseMiddleware` - Request/response caching
- `LogMiddleware` - Request/response logging and error handling

### Database Models

- `UserModel` - User accounts
- `TechnicianModel` - Technician profiles
- `CategoryModel` - Service categories
- `ServiceModel` - Services
- `BookingModel` - Bookings
- `PaymentModel` - Payments
- `AppCredentialModel` - App credentials

## License

MIT
