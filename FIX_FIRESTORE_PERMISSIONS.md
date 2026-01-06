# Fix Firestore Permission Denied Error

## 🔴 Error Message
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## ✅ Quick Fix (5 Steps)

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project: **society-management-56e43**

### Step 2: Navigate to Firestore Rules
1. In the left sidebar, click **Firestore Database**
2. Click on the **Rules** tab (next to Data, Indexes, etc.)

### Step 3: Check Current Rules
You'll likely see default rules like:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

These rules **block all access**, which is why you're getting permission denied.

### Step 4: Replace with Correct Rules

**Delete all existing rules** and paste this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Members collection - users can create/read/update their own profile
    match /members/{userId} {
      // Allow authenticated users to create their own profile
      allow create: if request.auth != null && request.auth.uid == userId;
      // Allow authenticated users to read their own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      // Allow authenticated users to update their own profile
      allow update: if request.auth != null && request.auth.uid == userId;
      // Allow authenticated users to read all members (for directory/search)
      allow list: if request.auth != null;
    }
    
    // Deny all other collections by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 5: Publish Rules
1. Click **"Publish"** button (top right)
2. Wait for confirmation: "Rules published successfully"

## 🧪 Test the Fix

1. Go back to your app
2. Try completing the profile setup again
3. The error should be resolved!

## 📋 What These Rules Do

1. **`match /members/{userId}`**: Applies rules to the `members` collection
2. **`allow create`**: Users can only create documents with their own UID as the document ID
3. **`allow read`**: Users can only read their own profile document
4. **`allow update`**: Users can only update their own profile
5. **`allow list`**: Authenticated users can query/list all members (for directory features)
6. **`allow read, write: if false`**: Blocks all other collections by default

## 🔒 Security Notes

- ✅ Only authenticated users can access the collection
- ✅ Users can only modify their own profile (UID must match document ID)
- ✅ Other collections are protected by default
- ⚠️ Users can read all members (for directory/search). If you want to restrict this:
  - Change `allow list: if request.auth != null;` to `allow list: if false;`

## 🆘 Still Having Issues?

### Check 1: Is Firestore Database Created?
1. Go to Firestore Database → Data tab
2. If you see "Create database" button, click it and create the database first
3. Choose "Start in test mode" or "Start in production mode"

### Check 2: Is User Authenticated?
- The rules require `request.auth != null`
- Make sure the user has completed phone authentication before profile setup

### Check 3: Check Firebase Console Logs
1. Go to Firebase Console → Firestore Database → Usage tab
2. Check for any error logs

### Check 4: Verify User ID Matches
- Document ID in Firestore must match the authenticated user's UID
- Our code uses `user.uid` as document ID automatically

## 📸 Visual Guide

### Step 2 Screenshot Location:
```
Firebase Console
├── Project Overview
├── Authentication ✓
└── Firestore Database ← Click here
    ├── Data tab
    ├── Rules tab ← Click here (THIS IS WHERE YOU NEED TO BE)
    ├── Indexes tab
    └── ...
```

## ✅ After Fixing

Once rules are published:
- Profile setup should work
- Data will be saved to `members/{userId}` collection
- You can verify in Firestore Database → Data tab

---

**Need More Help?**
- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Rules Reference](https://firebase.google.com/docs/reference/rules/rules)

