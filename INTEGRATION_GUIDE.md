# FixMate Platform - New Features Integration Guide

## 📱 Mobile Platform - New Screens

### 1. Review Screen
**Location:** `lib/features/review/screens/review_screen.dart`

**Navigate to it:**
```dart
Navigator.pushNamed(
  context,
  '/review',
  arguments: {
    'bookingId': 'booking-123',
    'technicianName': 'John Doe',
    'technicianId': 'tech-456',
  },
);
```

**How it works:**
- User selects 1-5 stars
- Writes feedback comment
- Submits to API endpoint: `POST /api/reviews/{bookingId}`
- Review provider handles state

**Required Provider:**
```dart
ref.read(reviewProvider.notifier).createReview(
  bookingId: 'booking-123',
  rating: 5,
  comment: 'Great service!',
);
```

---

### 2. Chat Screen
**Location:** `lib/features/chat/screens/chat_screen.dart`

**Navigate to it:**
```dart
Navigator.pushNamed(
  context,
  '/chat',
  arguments: {
    'bookingId': 'booking-123',
    'otherUserName': 'John Doe',
    'otherUserId': 'user-456',
  },
);
```

**How it works:**
- Displays message history with auto-scroll
- Type message and send
- Own messages appear on right (blue)
- Other user messages on left (gray)
- Timestamps on each message

**Required Provider:**
```dart
// Fetch messages
final messages = ref.watch(messageProvider);

// Send message
await ref.read(messageProvider.notifier).sendMessage(
  bookingId: 'booking-123',
  message: 'When will you arrive?',
);
```

---

### 3. Technician Profile Setup
**Location:** `lib/features/technician/screens/technician_profile_setup_screen.dart`

**Navigate to it:**
```dart
Navigator.pushNamed(context, '/technician-profile-setup');
```

**How it works:**
- Technician completes professional bio
- Selects specialties (AC Repair, Plumbing, etc.)
- Sets service area radius (1-50km)
- Toggles availability status
- Saves profile with validation

**Available Specialties:**
```
AC Repair, Plumbing, Electrical, Automotive,
Carpentry, Painting, Installation, Maintenance, Inspection
```

---

### 4. Real-time Job Tracking
**Location:** `lib/features/booking/screens/job_tracking_screen.dart`

**Navigate to it:**
```dart
Navigator.pushNamed(
  context,
  '/job-tracking',
  arguments: {
    'bookingId': 'booking-123',
    'technicianName': 'John Doe',
  },
);
```

**How it works:**
- Shows map with technician location (placeholder)
- Real-time ETA countdown
- Visual timeline of job status:
  - 🟡 On the way
  - 🟠 Arrived
  - 🔵 In Progress
  - 🟢 Completed
- Contact button to open chat

**Status Flow:**
```
pending → on_the_way → arrived → in_progress → completed
```

---

## 🖥️ Admin Platform - New Pages

### 1. User Management
**URL:** `/admin/users`

**Features:**
- Search users by name/email
- Filter by role (Customer, Technician, Admin)
- Filter by status (Active, Suspended)
- Suspend/Activate accounts
- View user details

**API Endpoints (to implement):**
```
GET    /api/admin/users
GET    /api/admin/users/:id
POST   /api/admin/users/:id/suspend
POST   /api/admin/users/:id/unsuspend
```

---

### 2. Technician Verification
**URL:** `/admin/technicians`

**Features:**
- List pending technician requests
- View detailed profile and documents
- Approve technician registration
- Reject with reason
- Filter by verification status

**API Endpoints (to implement):**
```
GET    /api/admin/technicians
GET    /api/admin/technicians/:id
POST   /api/admin/technicians/:id/verify
POST   /api/admin/technicians/:id/reject
```

---

### 3. Payout Management
**URL:** `/admin/payouts`

**Features:**
- View payout requests from technicians
- Filter by status (Pending, Approved, Rejected, Completed)
- View payment method (ABA Pay / Wing)
- Approve/Reject payouts
- Track processing fees
- View statistics by status

**API Endpoints (to implement):**
```
GET    /api/admin/payouts
GET    /api/admin/payouts/:id
POST   /api/admin/payouts/:id/approve
POST   /api/admin/payouts/:id/reject
GET    /api/admin/payouts/analytics
```

---

### 4. Analytics Dashboard
**URL:** `/admin/analytics`

**Features:**
- Overview statistics (users, technicians, bookings, revenue)
- Period selector (Day, Week, Month, Year)
- Bookings breakdown by status
- Revenue trend chart
- Top 3 technicians by earnings
- Low-rated technicians flagging (< 3.0 stars)

**API Endpoints (to implement):**
```
GET    /api/admin/analytics?period=month
GET    /api/admin/analytics/bookings?period=month
GET    /api/admin/analytics/revenue?period=month
GET    /api/admin/analytics/technicians/top
GET    /api/admin/analytics/technicians/low-rated
```

---

## 🔧 Backend Implementation Checklist

### For Review Feature:
```python
# app/routers/reviews.py
POST /api/reviews/{booking_id}
  - Input: { rating: int, comment: str }
  - Output: { id, booking_id, rating, comment, created_at }
  - Validates: rating 1-5, non-empty comment
  - Auto-calculates technician average rating
```

### For Chat Feature:
```python
# app/routers/messages.py
GET /api/messages/{booking_id}
  - Returns: [{ id, sender_id, message, created_at }]
POST /api/messages/{booking_id}
  - Input: { message: str }
  - Output: { id, sender_id, message, created_at }
```

### For Admin Users:
```python
# app/routers/admin.py
GET /api/admin/users
  - Query params: ?role=customer&status=active&search=john
  - Returns: [{ id, name, email, role, is_active, created_at }]
POST /api/admin/users/{user_id}/suspend
  - No input needed
  - Returns: { success: bool, message: str }
```

### For Admin Technicians:
```python
# app/routers/admin.py
GET /api/admin/technicians
  - Query params: ?status=pending
  - Returns: [{ id, name, email, bio, specialties, documents, status }]
POST /api/admin/technicians/{tech_id}/verify
  - No input needed
  - Returns: { success: bool }
```

### For Admin Payouts:
```python
# app/routers/admin.py
GET /api/admin/payouts
  - Query params: ?status=pending
  - Returns: [{ id, technician_id, amount, status, request_date }]
POST /api/admin/payouts/{payout_id}/approve
  - No input needed
  - Returns: { success: bool }
```

### For Analytics:
```python
# app/routers/admin.py
GET /api/admin/analytics?period=month
  - Returns: {
      overview: { total_users, total_technicians, total_bookings, total_revenue },
      bookings_by_status: { completed, in_progress, pending, cancelled },
      revenue_by_period: [{ period, amount }],
      top_technicians: [{ id, name, rating, jobs_completed, earnings }],
      low_rated_technicians: [{ id, name, rating, total_jobs }]
    }
```

---

## 📱 Mobile Route Constants

Add to `lib/core/constants/app_constants.dart`:

```dart
class AppRoutes {
  // Existing routes...
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String technicianHome = '/technician-home';
  static const String services = '/services';
  static const String booking = '/booking';
  static const String bookingHistory = '/booking-history';
  static const String profile = '/profile';
  
  // New routes
  static const String technicianProfileSetup = '/technician-profile-setup';
  static const String jobTracking = '/job-tracking';
  static const String review = '/review';
  static const String chat = '/chat';
}
```

---

## 🎨 UI/UX Implementation Notes

### Colors Used
- Primary: `AppTheme.primary` (#2563EB - Blue)
- Secondary: `AppTheme.secondary` (#8B5CF6 - Purple)
- Success: `Colors.green`
- Warning: `Colors.orange`
- Error: `AppTheme.error` (Red)

### Typography
- Headings: `TextStyle(fontSize: 24, fontWeight: FontWeight.w700)`
- Subheadings: `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)`
- Body: `TextStyle(fontSize: 14, fontWeight: FontWeight.w500)`
- Captions: `TextStyle(fontSize: 12, fontWeight: FontWeight.w400)`

### Spacing Standard
- Large gaps: 32px
- Medium gaps: 24px, 16px
- Small gaps: 12px, 8px

---

## 🧪 Testing Guide

### Manual Testing (Mobile)

1. **Review Screen Test:**
   - Rate a booking 1-5 stars
   - Add comment
   - Submit and verify API call
   - Check review appears in history

2. **Chat Test:**
   - Open chat from booking
   - Send message
   - Receive real-time updates
   - Verify message format

3. **Technician Profile Test:**
   - Complete bio (required)
   - Select specialties (required, min 1)
   - Set service radius
   - Toggle availability
   - Save and verify

4. **Job Tracking Test:**
   - Open from booking
   - Verify timeline displays
   - Check ETA countdown
   - Test contact technician button

### Manual Testing (Admin)

1. **User Management:**
   - Search and filter users
   - Suspend an account
   - Verify suspension worked
   - Reactivate account

2. **Technician Verification:**
   - View pending requests
   - Review documents
   - Approve technician
   - Verify status changed

3. **Payout Management:**
   - View pending payouts
   - Approve payment
   - Check fee calculation
   - Reject with reason

4. **Analytics:**
   - Switch time periods
   - Verify stat updates
   - Check top technicians list
   - Flag low-rated technicians

---

## 🚀 Deployment Checklist

- [ ] All TODO comments replaced with actual API calls
- [ ] Error handling implemented
- [ ] Loading states visible
- [ ] Validation messages clear
- [ ] No hardcoded values
- [ ] Environment variables configured
- [ ] API base URLs correct
- [ ] Database migrations run
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Documentation updated

---

## 📞 Support & Questions

For implementation questions or issues:
1. Check this guide first
2. Review code comments in each file
3. Check existing similar features
4. Test with mock data

All new screens follow the same patterns as existing screens for consistency.
