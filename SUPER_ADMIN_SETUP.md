# Super Admin Setup Guide

## 📋 Overview

This guide explains how to set up a Super Admin user in the SocietyOne system.

---

## 🔐 Super Admin Phone Number

**Your Super Admin Phone Number:** `+919773609077`

---

## 📝 Method 1: Manual Setup in Firebase Console

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**

### Step 2: Create Super Admin Document
1. Go to **Firestore Database** → **Data** tab
2. Click on **Start collection** (if `super_admins` doesn't exist)
3. Collection ID: `super_admins`
4. Click **Next**

### Step 3: Add Document
1. **Document ID**: Use your Firebase Auth UID (after you login with this number)
   - OR use a temporary ID like `super_admin_1`
   - You can update this later with your actual Firebase Auth UID

2. **Add Fields**:
   ```
   Field Name          Type        Value
   ──────────────────────────────────────────────
   id                  string      (same as Document ID)
   mobileNumber        string      +919773609077
   name                string      Super Admin
   email               string      (optional - your email)
   isActive            boolean     true
   createdAt           timestamp   (current date/time)
   updatedAt           timestamp   (current date/time)
   ```

3. Click **Save**

### Step 4: Example Document Structure
```json
{
  "id": "super_admin_1",
  "mobileNumber": "+919773609077",
  "name": "Super Admin",
  "email": "admin@societyone.com",
  "isActive": true,
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

---

## 📝 Method 2: Using Flutter Code (Development)

### Option A: Create a Setup Screen
Create a temporary setup screen to add Super Admin:

```dart
// Temporary setup screen (remove after setup)
Future<void> setupSuperAdmin() async {
  final firestoreService = FirestoreService();
  try {
    await firestoreService.createSuperAdmin(
      mobileNumber: '9773609077',
      name: 'Super Admin',
      email: 'admin@societyone.com', // Optional
    );
    print('Super Admin created successfully');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Option B: Use Firebase Console (Recommended)
Use Method 1 above for production setup.

---

## 🔄 Method 3: Update After Authentication

### Recommended Approach:
1. **First**: Login with phone number `9773609077` using the app
2. **Then**: Create Super Admin document with your Firebase Auth UID

**Steps:**
1. Login with `9773609077` in the app
2. Get your Firebase Auth UID from Firebase Console → Authentication
3. Create document in `super_admins` collection:
   - **Document ID**: Your Firebase Auth UID
   - **Fields**: As shown in Method 1

---

## ✅ Verification

### Test Super Admin Login:
1. Open the app
2. Click "Login with Mobile Number"
3. Enter: `9773609077`
4. Verify OTP
5. You should be redirected to **Super Admin Dashboard**

### If Not Working:
1. Check Firestore Console → `super_admins` collection
2. Verify `mobileNumber` field matches exactly: `+919773609077`
3. Verify `isActive` is `true`
4. Check Firebase Auth → Authentication → Users
5. Ensure phone number is verified in Firebase Auth

---

## 🔐 Security Notes

1. **Document ID**: Should ideally be the Firebase Auth UID
2. **Mobile Number**: Must match exactly (with country code `+91`)
3. **isActive**: Must be `true` for login to work
4. **Firestore Rules**: Super Admin can read/write `super_admins` collection

---

## 📱 Phone Number Format

The system accepts multiple formats:
- `+919773609077` ✅ (Recommended)
- `9773609077` ✅ (Will be normalized)
- `919773609077` ✅ (Will be normalized)

**Note**: The system normalizes to `+919773609077` format internally.

---

## 🚀 Quick Setup Script

### For Firebase Console:
1. Collection: `super_admins`
2. Document ID: `super_admin_1` (or your Firebase Auth UID)
3. Fields:
   ```json
   {
     "id": "super_admin_1",
     "mobileNumber": "+919773609077",
     "name": "Super Admin",
     "isActive": true,
     "createdAt": "2024-01-15T10:00:00.000Z",
     "updatedAt": "2024-01-15T10:00:00.000Z"
   }
   ```

---

## ✅ After Setup

Once Super Admin is set up:
1. Login with `9773609077`
2. You'll be redirected to Super Admin Dashboard
3. You can now:
   - Create Buildings
   - Create Societies
   - Assign Committee Members
   - Manage Features

---

**Status**: Ready for setup. Follow Method 1 (Firebase Console) for production.

