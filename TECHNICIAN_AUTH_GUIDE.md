# Technician Authentication & Verification System

## 🎯 Overview

Complete end-to-end technician authentication, registration, and verification flow with:
- **Backend**: Enhanced FastAPI with technician-specific endpoints
- **Mobile**: Technician sign-in/signup screens with document upload
- **Admin**: Dashboard for verifying technicians and managing applications

---

## 🔧 Backend Enhancements

### New Endpoints

#### 1. Technician Registration
```
POST /api/auth/register/technician

Request Body:
{
  "name": "John Smith",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "SecurePass123!",
  "bio": "Professional AC repair specialist with 5 years experience",
  "specialties": ["AC Repair", "Plumbing"],
  "documents": ["base64_encoded_doc1", "base64_encoded_doc2"]
}

Response:
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "user": { ... },
  "technician_status": "pending",
  "is_verified": false,
  "can_accept_jobs": false,
  "expires_in": 86400
}
```

#### 2. Technician Login
```
POST /api/auth/login/technician

Request Body:
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}

Response:
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "user": { ... },
  "technician_status": "pending|verified|rejected",
  "is_verified": false,
  "can_accept_jobs": false,
  "expires_in": 86400
}
```

#### 3. Get Verification Status
```
GET /api/auth/technician/verification-status

Response:
{
  "user_id": "user-123",
  "is_verified": false,
  "status": "pending",
  "rejection_reason": null,
  "submitted_at": "2026-04-27T10:00:00Z",
  "verified_at": null
}
```

#### 4. Upload Documents
```
POST /api/auth/technician/upload-documents

Request Body:
{
  "documents": ["base64_doc1", "base64_doc2", "base64_doc3"]
}

Response:
{
  "message": "Documents uploaded successfully",
  "verification_status": "pending",
  "documents_count": 3
}
```

### Updated Models

#### Technician Model Fields
```python
- verification_status: str  # pending, verified, rejected
- rejection_reason: Optional[str]
- submitted_at: DateTime
- verified_at: DateTime
- verified_by: str  # Admin user ID
- documents: List[dict]  # [{"name": "...", "url": "...", "type": "id|license|insurance"}]
```

#### User Response Schema
```python
class TechnicianInfo(BaseModel):
    id: str
    user_id: str
    bio: str
    specialties: List[str]
    rating: float
    total_jobs: int
    is_verified: bool
    is_available: bool
    documents: List[dict]

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    phone: Optional[str]
    role: str
    avatar_url: Optional[str]
    is_active: bool
    created_at: datetime
    technician: Optional[TechnicianInfo] = None
```

---

## 📱 Mobile Implementation

### New Files Created

#### 1. `technician_signin_screen.dart`
- Tab-based interface (Sign In | Register)
- Full technician registration form
- Specialties selection
- Document upload preparation

#### 2. `technician_verification_screen.dart`
- Shows verification status
- Document upload interface
- Timeline of verification process
- Required documents checklist

### Features

**Sign In Tab:**
- Email/password authentication
- Forgot password link
- Technician-specific login endpoint
- Auto-redirect based on verification status

**Register Tab:**
- Full name, email, phone, password
- Professional bio
- Specialties multi-select
- Document upload
- Verification requirements information

**Verification Screen:**
- Real-time status checking
- Document upload progress
- Timeline visualization
- Support contact link

### Usage

```dart
// Navigate to technician sign-in
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TechnicianSigninScreen(),
  ),
);

// After registration, navigate to verification
Navigator.pushReplacementNamed(context, '/technician-verification');
```

---

## 🖥️ Admin Dashboard

### New Component: `TechnicianVerification.tsx`

**Features:**
1. **Verification Stats**
   - Total technicians
   - Pending applications
   - Verified count
   - Rejected count

2. **Filter Options**
   - All technicians
   - Pending (only)
   - Verified
   - Rejected

3. **Technician Cards**
   - Quick overview of each technician
   - Status badge
   - Rating and jobs
   - Click to view details

4. **Detail Panel**
   - Full contact information
   - Professional details (rating, jobs, specialties)
   - Bio display
   - Document viewer
   - Action buttons for pending technicians

5. **Verification Actions**
   - **Approve**: Mark as verified (can accept jobs)
   - **Reject**: Provide rejection reason (resubmit option)

### Integration

```typescript
// In your admin dashboard or navigation
import TechnicianVerification from '@/components/TechnicianVerification';

// Add to your dashboard routes
<Route path="/admin/technicians" component={TechnicianVerification} />
```

---

## 🔄 Complete User Journey

### Technician Sign-Up Flow

```
1. Mobile App
   ↓
2. Technician Sign-In Screen (Register Tab)
   - Enter: Name, Email, Phone, Password
   - Enter: Bio
   - Select: Specialties
   - Upload: Documents (ID, License, Insurance)
   ↓
3. Backend: POST /api/auth/register/technician
   - Create User account
   - Create Technician profile
   - Set status = "pending"
   ↓
4. Mobile: Redirect to Verification Screen
   - Show "Pending Verification"
   - Allow document re-upload
   - Show timeline
   ↓
5. Admin Dashboard
   - Admin sees pending application
   - Reviews documents
   - Clicks "Approve" or "Reject"
   ↓
6. Backend: Update technician status
   - If approved: is_verified = true
   - If rejected: store rejection_reason
   ↓
7. Technician Mobile
   - Polling for verification status
   - Show result (approved/rejected)
   - If approved: can now accept jobs
```

### Technician Login Flow

```
1. Mobile App
   ↓
2. Technician Sign-In Screen (Sign In Tab)
   - Enter: Email, Password
   ↓
3. Backend: POST /api/auth/login/technician
   - Authenticate user
   - Get technician status
   ↓
4. Response includes:
   - access_token
   - technician_status (pending/verified/rejected)
   - is_verified (boolean)
   - can_accept_jobs (boolean)
   ↓
5. Mobile Logic:
   if (is_verified) {
     // Navigate to /technician-home
   } else if (status == "pending") {
     // Navigate to /technician-verification
   } else if (status == "rejected") {
     // Show rejection reason with resubmit option
   }
```

---

## 🔐 Security Considerations

1. **Document Storage**
   - Store documents in secure cloud storage (AWS S3, Google Cloud Storage)
   - Don't expose document URLs to unauthorized users
   - Implement file size limits
   - Validate file types

2. **Verification Process**
   - Only admins can approve/reject (RBAC)
   - Audit trail of who verified and when
   - Rejection reasons are stored
   - Technicians can resubmit after rejection

3. **Token Management**
   - 24-hour JWT expiration
   - Refresh token mechanism
   - Token blacklist on logout
   - Verified status checked on each request

---

## 📊 Database Schema

### Technician Table Updates

```sql
-- New/Updated columns in technicians table
ALTER TABLE technicians ADD COLUMN (
    verification_status VARCHAR(20) DEFAULT 'pending',
    rejection_reason TEXT NULL,
    submitted_at TIMESTAMP NULL,
    verified_at TIMESTAMP NULL,
    verified_by VARCHAR(255) NULL,
    documents JSON DEFAULT '[]'
);

-- Index for fast filtering
CREATE INDEX idx_verification_status ON technicians(verification_status);
```

---

## 🚀 Deployment Checklist

### Backend
- [ ] Update requirements.txt (done ✓)
- [ ] Update models.py with new Technician fields
- [ ] Update schemas.py with new request/response models
- [ ] Add technician endpoints to auth.py
- [ ] Test all authentication endpoints
- [ ] Deploy to production

### Mobile
- [ ] Create technician sign-in screen
- [ ] Create technician verification screen
- [ ] Update auth provider with technician methods
- [ ] Update auth repository with technician methods
- [ ] Test on Android emulator/device
- [ ] Test on iOS simulator/device
- [ ] Build APK/IPA for release

### Admin
- [ ] Create TechnicianVerification component
- [ ] Integrate into admin dashboard routes
- [ ] Connect to backend verification endpoints
- [ ] Test approval/rejection flow
- [ ] Deploy Next.js app

---

## 📝 Testing

### Technician Registration
```bash
# Test endpoint
curl -X POST http://localhost:8000/api/auth/register/technician \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Technician",
    "email": "tech@example.com",
    "phone": "1234567890",
    "password": "Test123!",
    "bio": "Experienced technician",
    "specialties": ["AC Repair"],
    "documents": ["doc1", "doc2"]
  }'
```

### Technician Login
```bash
curl -X POST http://localhost:8000/api/auth/login/technician \
  -H "Content-Type: application/json" \
  -d '{
    "email": "tech@example.com",
    "password": "Test123!"
  }'
```

### Check Verification Status
```bash
curl http://localhost:8000/api/auth/technician/verification-status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Admin Approve
```bash
curl -X POST http://localhost:8000/api/admin/technicians/TECH_ID/verify \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

## 🎯 Next Steps

1. **Real Document Upload**
   - Integrate with cloud storage (S3, Google Cloud)
   - Add file size/type validation
   - Generate secure download URLs

2. **Email Notifications**
   - Send confirmation email on registration
   - Notify when verification status changes
   - Send rejection reason email

3. **SMS Notifications**
   - SMS on verification approval
   - Technician alert when job available

4. **Enhanced Verification**
   - Background check integration
   - Automated document validation (OCR)
   - Manual review workflow

5. **Technician Dashboard**
   - View verification status
   - Re-submit documents if rejected
   - View job opportunities
   - Manage availability

---

## 📞 Support

- **Backend Issues**: Check auth router implementation
- **Mobile Issues**: Check screen navigation and provider setup
- **Admin Issues**: Check component API calls and state management

