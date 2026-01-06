# Firestore "members" Database Setup Guide

## ✅ What's Been Implemented

1. **Cloud Firestore Dependency**: Added `cloud_firestore: ^6.0.3` to `pubspec.yaml`

2. **FirestoreService** (`lib/services/firestore_service.dart`):
   - `saveMemberProfile()` - Saves member profile to Firestore
   - `getMemberProfile()` - Retrieves member profile by user ID
   - `getCurrentUserProfile()` - Gets current user's profile
   - `updateMemberProfile()` - Updates member profile
   - `getAllMembers()` - Gets all active members
   - `deleteMemberProfile()` - Soft deletes a member profile

3. **Profile Setup Integration**:
   - When user completes profile setup, data is automatically saved to Firestore
   - Data is stored in the `members` collection with the Firebase Auth UID as document ID

## 🔥 Firebase Console Setup

### Step 1: Create Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **society-management**
3. Click on **Firestore Database** in the left sidebar
4. Click **"Add database"** button
5. Choose **"Start in test mode"** (for development) or **"Start in production mode"** (for production)
6. Select a **location** for your database (choose closest to your users)
7. Click **"Enable"**

### Step 2: Configure Security Rules (Important!)

1. Go to **Firestore Database** → **Rules** tab
2. Update the rules to allow authenticated users to read/write their own data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Members collection - users can read/write their own profile
    match /members/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading all members for listing
    }
  }
}
```

3. Click **"Publish"** to save the rules

### Step 3: Verify Collection Structure

The app will automatically create the `members` collection with documents structured like:

```
members/
  {userId}/
    id: string
    email: string
    name: string
    mobileNumber: string
    role: string (default: "member")
    apartmentNumber: string
    buildingName: string
    profileImageUrl: string
    isEmailVerified: boolean
    isMobileVerified: boolean (always true for phone auth users)
    createdAt: string (ISO 8601)
    updatedAt: string (ISO 8601)
    isActive: boolean
```

## 📝 Data Flow

1. **User Registration Flow**:
   - User enters phone number → OTP sent → OTP verified → Profile setup screen
   - User fills profile form → Data saved to `members/{userId}` in Firestore
   - User navigates to dashboard

2. **Data Storage**:
   - Document ID = Firebase Auth User UID (unique per user)
   - Full name is constructed from: `firstName + (middleName?) + surname`
   - Phone number is verified via Firebase Auth (isMobileVerified = true)
   - Timestamps are automatically set (createdAt, updatedAt)

## 🔍 Example Document

```json
{
  "id": "abc123xyz...",
  "email": "john.doe@example.com",
  "name": "John Michael Doe",
  "mobileNumber": "+919876543210",
  "role": "member",
  "apartmentNumber": "201",
  "buildingName": "Block A",
  "profileImageUrl": "",
  "isEmailVerified": false,
  "isMobileVerified": true,
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z",
  "isActive": true
}
```

## 🛡️ Security Best Practices

1. **Always use Security Rules**: Don't rely on client-side validation alone
2. **Validate Input**: The app validates inputs before saving
3. **Use Authentication**: Only authenticated users can save profiles
4. **Limit Access**: Users can only modify their own profile
5. **Soft Delete**: Use `isActive` flag instead of hard deleting records

## 🧪 Testing

1. **Test Profile Creation**:
   - Register a new user with phone number
   - Complete profile setup
   - Check Firestore Console → `members` collection
   - Verify document was created with correct data

2. **Test Profile Retrieval**:
   - Use `FirestoreService().getCurrentUserProfile()` to retrieve profile
   - Verify all fields are correctly saved and retrieved

## 📚 Additional Resources

- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [FlutterFire Firestore](https://firebase.flutter.dev/docs/firestore/usage)

## ⚠️ Important Notes

1. **Billing**: Firestore has a free tier, but monitor usage for production apps
2. **Indexes**: If you add queries with multiple conditions, you may need to create composite indexes
3. **Offline Support**: Firestore provides offline persistence automatically
4. **Data Migration**: Consider migration strategies if you need to change data structure later

## 🚀 Next Steps

1. Set up Firestore in Firebase Console (follow Step 1 above)
2. Configure security rules (follow Step 2 above)
3. Test the profile creation flow
4. Monitor Firestore usage in Firebase Console

