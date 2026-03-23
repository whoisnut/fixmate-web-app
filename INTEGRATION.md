# Backend & Mobile Integration Guide

## Overview

This document describes the complete integration between the FixMate backend API and mobile Flutter application. The integration includes authentication, service management, booking operations, and real-time updates through WebSockets.

---

## Architecture

### Backend (FastAPI - Python)
- **Framework**: FastAPI with SQLAlchemy ORM
- **Database**: SQLite (development), PostgreSQL (production)
- **Authentication**: JWT tokens with 60-minute expiration
- **CORS**: Configured for mobile clients on multiple origins

### Mobile (Flutter)
- **State Management**: Riverpod for reactive state
- **HTTP Client**: Dio with interceptors for auth and error handling
- **Real-time**: WebSocket for live booking updates
- **Storage**: SharedPreferences for token and user data persistence

---

## API Endpoints

### Authentication (`/api/auth`)

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "securePassword123",
  "role": "customer" | "technician"
}

Response (201):
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "role": "customer",
    "created_at": "2024-02-22T10:00:00Z"
  }
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}

Response (200):
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": { ... }
}
```

### Services (`/api`)

#### Get Categories
```http
GET /api/categories
Authorization: Bearer {token}

Response (200):
[
  {
    "id": "uuid",
    "name": "Plumbing",
    "icon": "plumbing_icon",
    "is_active": true
  },
  ...
]
```

#### Get Services
```http
GET /api/services?category_id=uuid
Authorization: Bearer {token}

Response (200):
[
  {
    "id": "uuid",
    "name": "Pipe Repair",
    "description": "Repair broken pipes",
    "category_id": "uuid",
    "price": 50.00,
    "duration_minutes": 60,
    "is_active": true
  },
  ...
]
```

#### Get Service Details
```http
GET /api/services/{service_id}
Authorization: Bearer {token}

Response (200):
{
  "id": "uuid",
  "name": "Pipe Repair",
  "description": "Repair broken pipes",
  "category_id": "uuid",
  "price": 50.00,
  "duration_minutes": 60,
  "rating": 4.8,
  "reviews_count": 45,
  "is_active": true
}
```

### Bookings (`/api/bookings`)

#### Create Booking
```http
POST /api/bookings
Authorization: Bearer {token}
Content-Type: application/json

{
  "service_id": "uuid",
  "address": "123 Main St, City, State",
  "lat": 40.7128,
  "lng": -74.0060,
  "scheduled_at": "2024-02-25T14:00:00Z",
  "notes": "Please call before arriving"
}

Response (201):
{
  "id": "uuid",
  "customer_id": "uuid",
  "service_id": "uuid",
  "technician_id": null,
  "address": "123 Main St, City, State",
  "lat": 40.7128,
  "lng": -74.0060,
  "scheduled_at": "2024-02-25T14:00:00Z",
  "status": "pending",
  "notes": "Please call before arriving",
  "created_at": "2024-02-22T10:00:00Z"
}
```

#### Get Bookings
```http
GET /api/bookings?status=active
Authorization: Bearer {token}

Response (200):
[
  {
    "id": "uuid",
    "customer_id": "uuid",
    "service_id": "uuid",
    "technician_id": "uuid",
    "address": "123 Main St, City, State",
    "status": "active",
    "scheduled_at": "2024-02-25T14:00:00Z",
    ...
  },
  ...
]
```

#### Get Booking Details
```http
GET /api/bookings/{booking_id}
Authorization: Bearer {token}

Response (200):
{
  "id": "uuid",
  ...
}
```

#### Update Booking
```http
PUT /api/bookings/{booking_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "completed",
  "rating": 5,
  "review": "Excellent service!"
}

Response (200):
{
  "id": "uuid",
  ...
}
```

#### Cancel Booking
```http
DELETE /api/bookings/{booking_id}
Authorization: Bearer {token}

Response (204): No content
```

---

## Mobile Implementation

### 1. Setup Network Configuration

The mobile app automatically detects the platform and sets the correct API base URL:

**Android Emulator**: `http://10.0.2.2:8000`
**iOS Simulator**: `http://localhost:8000`
**Physical Device**: Update `app_constants.dart` with your machine IP

```dart
// lib/core/constants/app_constants.dart
import 'dart:io' show Platform;

static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000'; // Android emulator
  } else if (Platform.isIOS) {
    return 'http://localhost:8000'; // iOS simulator
  } else {
    return 'http://localhost:8000'; // Web/desktop fallback
  }
}
```

### 2. Authentication Flow

```dart
// lib/features/auth/screens/login_screen.dart
ConsumerWidget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);
  
  return Center(
    child: ElevatedButton(
      onPressed: () {
        ref.read(authStateProvider.notifier).login(
          email: 'user@example.com',
          password: 'password123',
        );
      },
      child: Text('Login'),
    ),
  );
}
```

### 3. Using Repositories

```dart
// Using the service repository
final services = await ServiceRepository().getServices(categoryId: 'category-123');

// Using the booking repository
final booking = await BookingRepository().createBooking(
  serviceId: 'service-456',
  address: '123 Main St',
  lat: 40.7128,
  lng: -74.0060,
  scheduledAt: DateTime.now().add(Duration(days: 3)),
  notes: 'Please call before arriving',
);
```

### 4. Riverpod Providers

```dart
// lib/features/services/providers/service_provider.dart
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getCategories();
});

// Usage in widgets
final categories = ref.watch(categoriesProvider);
categories.when(
  data: (data) => ListView(children: []),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### 5. Real-time Updates (WebSocket)

```dart
// Connect to WebSocket when user logs in
final wsService = WebSocketService();
await wsService.connect(userId: 'user-123', token: token);

// Listen for updates
wsService.events.listen((event) {
  if (event['type'] == 'booking_update') {
    // Handle booking update
  }
});

// Disconnect when logging out
await wsService.disconnect();
```

### 6. Error Handling

```dart
// Using the error handler
try {
  final booking = await BookingRepository().createBooking(...);
} catch (error) {
  final errorMsg = ErrorHandler.getErrorMessage(error);
  
  if (ErrorHandler.isNetworkError(error)) {
    // Show network error dialog
  } else if (ErrorHandler.isAuthError(error)) {
    // Redirect to login
  } else if (ErrorHandler.isServerError(error)) {
    // Show server error dialog
  }
}
```

---

## Environment Configuration

### Backend `.env` File

Update the `ALLOWED_ORIGINS` to include your mobile client:

```env
ALLOWED_ORIGINS=http://localhost:8000,http://localhost:3000,http://10.0.2.2:8000,http://127.0.0.1:8000,http://YOUR_MACHINE_IP:8000
```

### Mobile Configuration

For physical device testing, update the IP address in `app_constants.dart`:

```dart
static const String apiBaseUrl = 'http://192.168.1.100:8000'; // Your machine IP
```

---

## Running the Integration

### 1. Start Backend Server

```bash
cd /Users/user/fixmate/backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Get Dependencies

```bash
cd /Users/user/fixmate/mobile
flutter pub get
```

### 3. Run Mobile App

```bash
# Android Emulator
flutter run -d emulator-5554

# iOS Simulator
flutter run -d iPhone

# Web
flutter run -d chrome
```

---

## API Response Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request succeeded |
| 201 | Created - Resource created |
| 204 | No Content - Delete successful |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid/missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Resource already exists |
| 500 | Internal Server Error - Server error |
| 503 | Service Unavailable - Server down |

---

## Common Issues & Solutions

### 1. Connection Refused

**Issue**: `Connection refused` when mobile app tries to connect to backend.

**Solution**:
- Verify backend is running: `curl http://localhost:8000/health`
- Check correct IP address for your environment
- Ensure firewall allows port 8000

### 2. CORS Error

**Issue**: `CORS policy: No 'Access-Control-Allow-Origin' header`

**Solution**:
- Verify `ALLOWED_ORIGINS` includes your mobile client's origin
- Restart backend server after `.env` changes
- Check that origin includes correct protocol and port

### 3. Token Expiration

**Issue**: `401 Unauthorized` after some time

**Solution**:
- Token expires after 60 minutes (configurable in backend)
- Implement token refresh logic (to be added)
- Users should log in again

### 4. WebSocket Connection Failed

**Issue**: WebSocket fails to connect for real-time updates

**Solution**:
- Ensure backend WebSocket route is implemented
- Check WebSocket URL uses `ws://` instead of `http://`
- Verify token is passed correctly

---

## Testing

### Using Postman

1. **Register User**: POST to `/api/auth/register`
2. **Copy access_token** from response
3. **Set Authorization**: Add header `Authorization: Bearer {token}`
4. **Test Endpoints**: GET `/api/categories`, GET `/api/services`, etc.

### Using Mobile App

1. **Register**: New user account via registration screen
2. **Browse**: Browse categories and services
3. **Create Booking**: Select service and create booking
4. **View History**: Check booking history

---

## Next Steps

- Implement token refresh mechanism
- Add payment integration with Stripe
- Implement chat system for bookings
- Add push notifications
- Implement technician tracking
- Add rating and review system

---

## Support & Resources

- **Backend**: FastAPI Documentation - https://fastapi.tiangolo.com
- **Mobile**: Flutter Documentation - https://flutter.dev
- **State Management**: Riverpod - https://riverpod.dev
- **HTTP Client**: Dio - https://pub.dev/packages/dio
