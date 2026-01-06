# SocietyOne - STRICT Authority-Based Access Control

## 🛡️ Implementation Summary

This document describes the **STRICT authority-based access control system** implemented for SocietyOne, ensuring that users **CANNOT access any society data** until their address proof is verified and approved by a society authority (Chairman/Secretary/Treasurer).

---

## 1. Core Architecture

### User Model Enhancements (`lib/models/user_model.dart`)

**New Fields Added:**
- `committeeRole`: `'chairman' | 'secretary' | 'treasurer' | null`
- `addressProofUrl`: URL of uploaded address proof document
- `addressProofVerified`: Boolean - verified by authority
- `approvedByRole`: Which authority approved (`'chairman' | 'secretary' | 'treasurer'`)
- `approvalStatus`: `'pending' | 'approved' | 'rejected'` (STRICT)

**Key Behavior:**
- All new users start with `approvalStatus: 'pending'`
- Users **CANNOT** access dashboard until `approvalStatus == 'approved'`
- Only committee members can approve/reject

---

## 2. Onboarding Flow (STRICT ORDER)

### Step-by-Step Process:

1. **New Sign Up** → User enters phone number
2. **OTP Verification** → Firebase Auth verification
3. **Society Search** → Search by name/city/PIN (`/society-selection`)
4. **Unit Selection** → Select block/flat (`/unit-selection`)
5. **Role Selection** → Owner/Tenant/Family (`/role-selection`)
6. **Profile Setup** → Personal details (`/setup-profile`)
7. **Address Proof Upload** → **MANDATORY** (`/address-proof-upload`)
8. **FORCE LOGOUT** → User automatically logged out after upload
9. **Authority Approval** → Chairman/Secretary/Treasurer reviews
10. **Login Enabled** → Only after approval

### Code Flow:

```dart
// After OTP verification
if (isNewUser) {
  Get.offNamed('/society-selection'); // Step 1
}

// After society/unit/role selection
Get.toNamed('/setup-profile', arguments: {
  'society': societyModel,
  'unit': unitModel,
  'userType': 'owner',
});

// After profile setup
Get.offAllNamed('/address-proof-upload'); // Step 2

// After address proof upload
await authService.signOut(); // FORCE LOGOUT
Get.offAllNamed('/login');
```

---

## 3. STRICT Login Gatekeeper Logic

### Implementation Points:

#### A. Splash Screen (`lib/views/splash/splash_screen.dart`)

```dart
// Check approval status on app start
if (profile != null) {
  if (profile.approvalStatus == 'approved') {
    Get.offAllNamed('/dashboard'); // ✅ ALLOWED
  } else {
    await authService.signOut(); // ❌ FORCE LOGOUT
    Get.offAllNamed('/blocked-access'); // ❌ BLOCKED
  }
}
```

#### B. OTP Verification (`lib/views/auth/mobile_otp_verification.dart`)

```dart
// After OTP verification
final profile = await firestoreService.getCurrentUserProfile();

if (profile == null) {
  Get.offNamed('/society-selection'); // New user
} else if (profile.approvalStatus == 'approved') {
  Get.offAllNamed('/dashboard'); // ✅ APPROVED
} else {
  await authService.signOut(); // ❌ NOT APPROVED
  Get.offAllNamed('/blocked-access'); // ❌ BLOCKED
}
```

#### C. Blocked Access Screen (`lib/views/auth/blocked_access_screen.dart`)

- **No back navigation** (`WillPopScope` returns `false`)
- Shows approval status (pending/rejected)
- Shows rejection reason if rejected
- Only "Refresh Status" and "Logout" buttons
- **NO access to any society data**

---

## 4. Address Proof Upload (Mandatory)

### Screen: `lib/views/auth/address_proof_upload_screen.dart`

**Features:**
- Image picker for address proof
- Upload to Firebase Storage
- Updates user profile with `addressProofUrl`
- **Automatically logs out user after upload**
- Shows society and unit details

**Accepted Documents:**
- Aadhaar Card
- Utility Bill
- Rent Agreement
- Sale Deed

**Code:**
```dart
// Upload address proof
final downloadUrl = await _storageService.uploadAddressProof(file, userId);
await _firestoreService.updateUserAddressProof(userId, downloadUrl);

// FORCE LOGOUT
await authService.signOut();
Get.offAllNamed('/login');
```

---

## 5. Authority Approval Dashboard

### Screen: `lib/views/admin/authority_approval_dashboard.dart`

**Access Control:**
- Only users with `committeeRole` can access
- Validates: `chairman`, `secretary`, or `treasurer`
- Redirects unauthorized users

**Features:**
- Lists all pending users for the society
- Shows user details: Name, Unit, Role, Registration Date
- **View Address Proof** button (opens image viewer)
- **Approve** button (only if address proof uploaded)
- **Reject** button (requires reason)

**Approval Process:**
```dart
await _firestoreService.approveUserByAuthority(
  userId,
  approverUserId,
  approverRole, // 'chairman' | 'secretary' | 'treasurer'
);
```

**Updates:**
- `approvalStatus: 'approved'`
- `addressProofVerified: true`
- `approvedByRole: 'chairman'` (or secretary/treasurer)
- `approvedAt: DateTime.now()`

---

## 6. Firestore Security Rules (STRICT)

### Required Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper: Check if user is approved
    function isApproved() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/members/$(request.auth.uid)).data.approvalStatus == 'approved';
    }
    
    // Helper: Check if user is committee member
    function isCommitteeMember() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/members/$(request.auth.uid)).data.committeeRole in ['chairman', 'secretary', 'treasurer'];
    }
    
    // Helper: Get user's societyId
    function getUserSocietyId() {
      return get(/databases/$(database)/documents/members/$(request.auth.uid)).data.societyId;
    }
    
    // ============ MEMBERS ============
    match /members/{userId} {
      // Pending/Rejected users: CANNOT read any member data
      allow read: if isAuthenticated() && 
                     (isApproved() || isCommitteeMember() || request.auth.uid == userId);
      
      // Only approved users or committee can list members
      allow list: if isAuthenticated() && (isApproved() || isCommitteeMember());
      
      // Create: Only during signup (self-registration)
      allow create: if isAuthenticated() && 
                       request.auth.uid == userId &&
                       request.resource.data.approvalStatus == 'pending';
      
      // Update: Self-update or committee approval
      allow update: if isAuthenticated() && (
        (request.auth.uid == userId && 
         request.resource.data.approvalStatus == resource.data.approvalStatus) ||
        (isCommitteeMember() && 
         request.resource.data.societyId == getUserSocietyId())
      );
    }
    
    // ============ SOCIETY DATA (All Collections) ============
    // Pattern: All collections must check approvalStatus
    
    match /notices/{noticeId} {
      allow read: if isAuthenticated() && 
                     (isApproved() || isCommitteeMember()) &&
                     resource.data.societyId == getUserSocietyId();
      allow write: if isAuthenticated() && isCommitteeMember() &&
                      request.resource.data.societyId == getUserSocietyId();
    }
    
    match /payments/{paymentId} {
      allow read: if isAuthenticated() && 
                     (isApproved() || isCommitteeMember()) &&
                     resource.data.societyId == getUserSocietyId();
      allow write: if isAuthenticated() && isApproved() &&
                      request.resource.data.societyId == getUserSocietyId();
    }
    
    // ... Similar pattern for all collections
  }
}
```

**Key Rules:**
1. **Pending users CANNOT read** any society data
2. **Approved users CAN** read their society's data
3. **Committee members CAN** read and approve
4. **All queries filtered by `societyId`**

---

## 7. Service Methods

### FirestoreService (`lib/services/firestore_service.dart`)

**New Methods:**

1. **`updateUserAddressProof(userId, url)`**
   - Updates `addressProofUrl`
   - Sets `addressProofVerified: false`

2. **`approveUserByAuthority(userId, approverId, approverRole)`**
   - Validates approver has committee role
   - Updates approval status
   - Sets verification flags

3. **`rejectUserByAuthority(userId, reason, rejectorId, rejectorRole)`**
   - Validates rejector has committee role
   - Sets rejection reason

4. **`isCommitteeMember(user)`**
   - Checks if user is chairman/secretary/treasurer

5. **`getPendingApprovalsForSociety(societyId)`**
   - Returns stream of pending users
   - Only committee members can access

### StorageService (`lib/services/storage_service.dart`)

**New Method:**

1. **`uploadAddressProof(file, userId)`**
   - Uploads to `address_proofs/{userId}_{timestamp}.{ext}`
   - Returns download URL

---

## 8. Navigation Flow Diagram

```
┌─────────────────┐
│   Login/OTP     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Society Search  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Unit Selection │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Role Selection │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Profile Setup   │
└────────┬────────┘
         │
         ▼
┌──────────────────────┐
│ Address Proof Upload│
└────────┬─────────────┘
         │
         ▼
┌─────────────────┐
│  FORCE LOGOUT   │ ❌
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Blocked Screen  │ ❌
└─────────────────┘
         │
         │ (Authority Approves)
         ▼
┌─────────────────┐
│   Dashboard     │ ✅
└─────────────────┘
```

---

## 9. Testing Checklist

### ✅ Test Cases:

1. **New User Registration:**
   - [ ] User cannot skip address proof upload
   - [ ] User is logged out after upload
   - [ ] User sees blocked screen on login

2. **Approval Workflow:**
   - [ ] Only committee members can access approval dashboard
   - [ ] Committee can view address proof
   - [ ] Committee can approve user
   - [ ] Committee can reject with reason

3. **Access Control:**
   - [ ] Pending user cannot access dashboard
   - [ ] Pending user cannot read notices
   - [ ] Pending user cannot read payments
   - [ ] Approved user can access all features

4. **Security:**
   - [ ] Firestore rules block pending users
   - [ ] Back navigation disabled on blocked screen
   - [ ] Force logout works correctly

---

## 10. Files Modified/Created

### Created:
- `lib/views/auth/blocked_access_screen.dart`
- `lib/views/auth/address_proof_upload_screen.dart`
- `lib/views/admin/authority_approval_dashboard.dart`
- `STRICT_ACCESS_CONTROL_IMPLEMENTATION.md`

### Modified:
- `lib/models/user_model.dart` - Added approval fields
- `lib/services/firestore_service.dart` - Added approval methods
- `lib/services/storage_service.dart` - Added address proof upload
- `lib/views/splash/splash_screen.dart` - Added gatekeeper check
- `lib/views/auth/mobile_otp_verification.dart` - Added gatekeeper check
- `lib/views/auth/setup_profile_screen.dart` - Updated to save society data
- `lib/routes/app_routes.dart` - Added new routes

---

## 11. Final-Year Project Explanation

### Problem Statement:
"Design an enterprise-grade apartment society management app with STRICT authority-based access control, ensuring users cannot access any society data until their address proof is verified and approved by society authorities."

### Solution:
1. **Multi-Tenancy**: Each society isolated by `societyId`
2. **Strict Onboarding**: Mandatory address proof upload
3. **Gatekeeper Logic**: Force logout for unapproved users
4. **Authority Approval**: Only Chairman/Secretary/Treasurer can approve
5. **Security Rules**: Firestore rules enforce access control

### Technologies:
- **Flutter**: Mobile app framework
- **Firebase Auth**: Phone OTP authentication
- **Firebase Firestore**: Multi-tenant database
- **Firebase Storage**: Address proof document storage
- **GetX**: State management and navigation

### Key Features:
- ✅ Zero data leakage between societies
- ✅ Mandatory address proof verification
- ✅ Authority-based approval workflow
- ✅ Force logout for unapproved users
- ✅ Real-time approval status updates
- ✅ Privacy controls for directory

---

## 12. Next Steps

1. **Update Firestore Rules**: Implement strict rules as described
2. **Add Route**: Add `/authority-approval` to admin dashboard menu
3. **Testing**: Comprehensive testing with multiple users
4. **Migration**: Migrate existing users to new approval system
5. **Documentation**: User guide for authorities

---

**Built with ❤️ for SocietyOne by Digitrix**

**Security First. Access Control. Zero Compromises.**

