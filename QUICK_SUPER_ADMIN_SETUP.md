# Quick Super Admin Setup - Phone: 9773609077

## 🚀 FASTEST METHOD: Firebase Console

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database**

### Step 2: Create Collection
1. Click **Start collection** (if `super_admins` doesn't exist)
2. Collection ID: `super_admins`
3. Click **Next**

### Step 3: Add Document
**Document ID**: `super_admin_9773609077`

> **Note**: You can use any unique ID for initial setup. After first login, update the document ID to your Firebase Auth UID for better security (see below).

**Add these fields:**

| Field Name | Type | Value |
|------------|------|-------|
| `id` | string | `super_admin_9773609077` |
| `mobileNumber` | string | `+919773609077` |
| `name` | string | `Super Admin` |
| `isActive` | boolean | `true` |
| `createdAt` | timestamp | (Click "Set" → Current time) |
| `updatedAt` | timestamp | (Click "Set" → Current time) |

### Step 4: Save
Click **Save**

---

## ✅ Done!

Now you can:
1. Open the app
2. Login with phone number: `9773609077`
3. Verify OTP
4. You'll be redirected to **Super Admin Dashboard**

---

## 📋 JSON Format (Copy-Paste Ready)

If you prefer JSON format, here's the complete document:

```json
{
  "id": "super_admin_9773609077",
  "mobileNumber": "+919773609077",
  "name": "Super Admin",
  "isActive": true,
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

---

## ⚠️ Important Notes

1. **Phone Number Format**: Must be `+919773609077` (with +91 prefix)
2. **isActive**: Must be `true`
3. **After First Login**: Update document ID to your Firebase Auth UID for better security

---

## 🔄 Update Document ID After First Login (Optional but Recommended)

**Why?** Firestore security rules work best when document ID = Firebase Auth UID.

**Steps:**
1. Login with `9773609077` in the app
2. Go to Firebase Console → **Authentication** → **Users**
3. Find your user → **Copy the UID** (e.g., `abc123xyz789...`)
4. Go to Firestore → `super_admins` collection
5. **Create new document**:
   - **Document ID**: Your Firebase Auth UID (paste the UID you copied)
   - **Copy all fields** from old document (`super_admin_9773609077`)
   - Update the `id` field to match the new document ID
6. **Delete old document** (`super_admin_9773609077`)

**Result**: Document ID = Your Firebase Auth UID ✅

---

**Your Super Admin Phone Number**: `+919773609077` ✅

