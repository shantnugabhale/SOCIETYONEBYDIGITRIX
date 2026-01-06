# SocietyOne Enterprise Architecture
## Multi-Tenant Apartment Society Management Platform

---

## 📋 TABLE OF CONTENTS

1. [System Overview](#system-overview)
2. [Core Non-Negotiable Rules](#core-non-negotiable-rules)
3. [Authentication & Authorization Flow](#authentication--authorization-flow)
4. [Multi-Tenancy Architecture](#multi-tenancy-architecture)
5. [Feature-Based Billing System](#feature-based-billing-system)
6. [Authority Verification System](#authority-verification-system)
7. [Super Admin Panel](#super-admin-panel)
8. [Committee Management](#committee-management)
9. [Database Schema](#database-schema)
10. [Security Rules](#security-rules)
11. [Navigation Guards](#navigation-guards)
12. [API Access Control](#api-access-control)

---

## 🎯 SYSTEM OVERVIEW

**SocietyOne** is an enterprise-grade, multi-tenant apartment society management platform designed to:
- Support thousands of independent societies
- Enforce strict authority verification before data access
- Provide feature-based billing per society
- Enable committee-based user approval workflow
- Maintain complete data isolation between societies

---

## 🔒 CORE NON-NEGOTIABLE RULES

### 1. Multi-Tenancy (MANDATORY)
- **Every society is fully isolated** using `societyId`
- **ALL database queries MUST be filtered by `societyId`**
- No cross-society data access allowed
- All collections must include `societyId` field

### 2. Authority-Verified Access (STRICT PENDING MODE)
- User authentication is allowed
- **User MUST NOT access ANY society data until:**
  - ✅ Mobile OTP verified
  - ✅ Address proof uploaded
  - ✅ Address proof approved by Chairman/Secretary/Treasurer
- **Until approval:**
  - User remains logged in
  - **ONLY** "Address Proof Verification Pending" screen accessible
  - **ONLY** Logout button enabled
  - **ALL other routes, APIs, and features are BLOCKED**

### 3. Feature-Based Billing
- Each society has different enabled features
- Feature access depends on society configuration
- Features can be enabled/disabled per society by Super Admin

---

## 🔐 AUTHENTICATION & AUTHORIZATION FLOW

### App Entry Screen
On app launch, show **THREE options**:
1. **Login with Mobile Number** → OTP verification
2. **Login with Email** → Password authentication
3. **New Sign Up** → Complete registration flow

### Login Flow (Mobile/Email)
```
1. Authenticate user (OTP/Password)
2. Check approvalStatus:
   - IF 'pending' OR 'rejected' → Redirect to Pending Verification Screen
   - IF 'approved' → Redirect to Society Home Dashboard
```

### New Sign Up Flow (STRICT ORDER)
```
STEP 1: Society Search
  - Search by Society Name / City / PIN
  - User selects society

STEP 2: Registration Form
  - Full Name
  - User Type (Owner / Tenant)
  - Block / Wing
  - Flat / Room Number
  - Mobile Number
  - Email (optional)

STEP 3: Mobile OTP Verification
  - OTP sent and verified

STEP 4: Address Proof Upload (MANDATORY)
  - Aadhaar / Electricity Bill / Rent Agreement

STEP 5: Submission to Committee
  - Create user with approvalStatus = 'pending'
  - Send verification request to:
    - Chairman
    - Secretary
    - Treasurer of selected society
```

---

## 🏢 MULTI-TENANCY ARCHITECTURE

### Society Model
```dart
class SocietyModel {
  final String id;
  final String name;
  final String buildingId; // Parent building
  final Map<String, bool> enabledFeatures; // Feature-based billing
  final Map<String, String> committeeMembers; // {role: userId}
  // ... other fields
}
```

### Query Pattern (MANDATORY)
```dart
// ALL queries must filter by societyId
.where('societyId', isEqualTo: currentUser.societyId)
```

### Data Isolation
- Users can only see data from their own society
- No cross-society queries allowed
- Firestore rules enforce society-level access

---

## 💰 FEATURE-BASED BILLING SYSTEM

### Master Feature List
```dart
const MASTER_FEATURES = {
  'notice_board': 'Notice Board',
  'visitor_management': 'Visitor Management',
  'maintenance_complaints': 'Maintenance Complaints',
  'billing_payments': 'Billing & Payments',
  'resident_directory': 'Resident Directory',
  'community_chat': 'Community Chat',
  'parking_management': 'Parking Management',
  'document_repository': 'Document Repository',
  'emergency_alerts': 'Emergency Alerts',
  'gatekeeper_app': 'Gatekeeper App',
  'facility_booking': 'Facility Booking',
  'forum_discussions': 'Forum Discussions',
  'polls_surveys': 'Polls & Surveys',
  'events_calendar': 'Events & Calendar',
  'package_tracking': 'Package Tracking',
};
```

### Per Society Configuration
```dart
enabledFeatures: {
  'notice_board': true,
  'visitor_management': true,
  'maintenance_complaints': false,
  // ... other features
}
```

### Feature Gating Logic
```dart
// Check if feature is enabled for society
if (!FeatureGatingService.isFeatureEnabled('visitor_management')) {
  // Hide UI or block backend access
  return;
}
```

---

## ✅ AUTHORITY VERIFICATION SYSTEM

### Pending Verification Screen (LOCKED MODE)
**Shown when:** `approvalStatus == 'pending'`

**UI Content:**
- Message: "Your address proof is under verification by society committee members. You will get access after approval."
- Buttons: Refresh Status, Logout

**Restrictions:**
- ❌ No back navigation
- ❌ No bottom tabs
- ❌ No drawer
- ❌ No deep linking
- ❌ No API access to society data

### Committee Verification Flow
**Committee Roles:**
- Chairman
- Secretary
- Treasurer

**Committee Dashboard:**
- View pending users
- View address proof
- Approve / Reject

**On APPROVE:**
```dart
approvalStatus = 'approved'
approvedByRole = 'chairman' // or 'secretary' or 'treasurer'
approvedAt = DateTime.now()
```

**On REJECT:**
```dart
approvalStatus = 'rejected'
rejectionReason = 'Reason provided by committee'
```

---

## 👑 SUPER ADMIN PANEL

### Super Admin Authentication
- Predefined mobile number
- OTP-based authentication
- Separate collection: `super_admins/{adminId}`

### Super Admin Capabilities
1. **Buildings Management**
   - Add Buildings
   - Edit Building details
   - View all buildings

2. **Societies Management**
   - Add Societies under Buildings
   - Edit Society details
   - View all societies

3. **Committee Assignment**
   - Assign Chairman per society
   - Assign Secretary per society
   - Assign Treasurer per society

4. **Feature Management**
   - Enable/Disable features per society
   - Manage feature-based billing
   - View feature usage statistics

---

## 👥 COMMITTEE MANAGEMENT

### Committee Roles
- **Chairman**: Highest authority, can approve/reject users
- **Secretary**: Can approve/reject users
- **Treasurer**: Can approve/reject users

### Committee Dashboard
- View pending user registrations
- View address proof documents
- Approve/Reject with reason
- View approval history

---

## 🗄️ DATABASE SCHEMA

### Members Collection
```dart
members/{userId}
{
  userId: string,
  societyId: string, // MANDATORY
  name: string,
  userType: 'owner' | 'tenant',
  block: string,
  flatNumber: string,
  committeeRole: 'chairman' | 'secretary' | 'treasurer' | null,
  approvalStatus: 'pending' | 'approved' | 'rejected',
  addressProofUrl: string,
  approvedByRole: string | null,
  approvedAt: timestamp | null,
  // ... other fields
}
```

### Societies Collection
```dart
societies/{societyId}
{
  id: string,
  name: string,
  buildingId: string,
  enabledFeatures: {
    'notice_board': bool,
    'visitor_management': bool,
    // ... other features
  },
  committeeMembers: {
    'chairman': userId | null,
    'secretary': userId | null,
    'treasurer': userId | null,
  },
  // ... other fields
}
```

### Buildings Collection
```dart
buildings/{buildingId}
{
  id: string,
  name: string,
  address: string,
  // ... other fields
}
```

### Super Admins Collection
```dart
super_admins/{adminId}
{
  id: string,
  mobileNumber: string,
  name: string,
  // ... other fields
}
```

---

## 🔐 SECURITY RULES

### Firestore Rules (CRITICAL)

```javascript
// Helper: Check if user is approved
function isApproved() {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/members/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/members/$(request.auth.uid)).data.approvalStatus == 'approved';
}

// Helper: Get user's societyId
function getUserSocietyId() {
  return get(/databases/$(database)/documents/members/$(request.auth.uid)).data.societyId;
}

// STRICT RULE: Pending users CANNOT access society data
match /{collection}/{documentId} {
  allow read: if isApproved() && 
                 resource.data.societyId == getUserSocietyId();
  allow write: if isApproved() && 
                  resource.data.societyId == getUserSocietyId();
}
```

### Access Control Matrix

| User Status | Authentication | Society Data Access | Pending Screen |
|------------|---------------|---------------------|----------------|
| Not Authenticated | ❌ | ❌ | ❌ |
| Authenticated (Pending) | ✅ | ❌ | ✅ |
| Authenticated (Rejected) | ✅ | ❌ | ✅ |
| Authenticated (Approved) | ✅ | ✅ | ❌ |
| Committee Member | ✅ | ✅ (Own Society) | ❌ |
| Super Admin | ✅ | ✅ (All Societies) | ❌ |

---

## 🛡️ NAVIGATION GUARDS

### Route Guard Middleware
```dart
class RouteGuardMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = Get.find<AuthService>().currentUser;
    if (user == null) return RouteSettings(name: '/login');
    
    final profile = Get.find<FirestoreService>().getCurrentUserProfile();
    if (profile == null) return RouteSettings(name: '/society-selection');
    
    // STRICT: Block pending/rejected users
    if (profile.approvalStatus != 'approved') {
      return RouteSettings(name: '/pending-approval');
    }
    
    return null; // Allow navigation
  }
}
```

### Protected Routes
All society data routes must use `RouteGuardMiddleware`:
- `/dashboard`
- `/notices`
- `/visitors`
- `/maintenance`
- `/payments`
- ... (all feature routes)

---

## 🚫 API ACCESS CONTROL

### Service Layer Protection
```dart
class FirestoreService {
  Future<List<NoticeModel>> getNotices() async {
    final user = await getCurrentUserProfile();
    
    // STRICT: Block pending users
    if (user?.approvalStatus != 'approved') {
      throw Exception('Access denied. Approval pending.');
    }
    
    // Multi-tenancy: Filter by societyId
    return _noticesCollection
        .where('societyId', isEqualTo: user!.societyId)
        .get();
  }
}
```

---

## 📱 IMPLEMENTATION CHECKLIST

- [x] System architecture document
- [ ] App entry screen with 3 options
- [ ] Navigation guard middleware
- [ ] Pending approval screen (locked mode)
- [ ] Society model with enabledFeatures
- [ ] Super Admin model and authentication
- [ ] Super Admin panel screens
- [ ] Committee dashboard
- [ ] Feature gating service
- [ ] Updated Firestore security rules
- [ ] Email login flow
- [ ] Address proof upload in signup
- [ ] All API endpoints protected

---

## 🎓 FINAL-YEAR PROJECT EXPLANATION

**SocietyOne** is a comprehensive, enterprise-grade apartment society management platform that demonstrates:

1. **Multi-Tenancy Architecture**: Complete data isolation using `societyId`
2. **Strict Access Control**: Authority-verified access with pending mode
3. **Feature-Based Billing**: Per-society feature configuration
4. **Role-Based Access Control**: Super Admin, Committee, and Resident roles
5. **Security Best Practices**: Firestore rules, navigation guards, API protection
6. **Scalability**: Designed to support thousands of societies
7. **Modern Architecture**: Flutter frontend, Firebase backend, clean code structure

**Key Technologies:**
- Flutter (Cross-platform mobile app)
- Firebase (Authentication, Firestore, Storage)
- GetX (State management, routing)
- Multi-tenancy pattern
- Role-based access control (RBAC)

---

**Built with ❤️ for SocietyOne by Digitrix**

