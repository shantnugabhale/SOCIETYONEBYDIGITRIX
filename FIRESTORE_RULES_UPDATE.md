# Firestore Security Rules Update Guide

## 📋 Overview

This document explains the updated Firestore security rules that include all new features (Adda features + additional features).

---

## ✅ Collections with Security Rules

### **Existing Collections**
1. ✅ `members` - Member profiles
2. ✅ `admins` / `admin` - Admin users
3. ✅ `utility_bills` - Utility bills
4. ✅ `payments` - Payment records
5. ✅ `maintenance_requests` - Maintenance requests
6. ✅ `notices` - Society notices
7. ✅ `balance_sheets` - Balance sheets
8. ✅ `notifications` / `user_notifications` - Notifications
9. ✅ `audit_logs` - Audit logs

### **New Collections (Adda Features)**
10. ✅ `forum_posts` - Discussion forum posts
11. ✅ `forum_comments` - Forum post comments
12. ✅ `polls` - Polls and surveys
13. ✅ `facilities` - Facility definitions
14. ✅ `facility_bookings` - Facility bookings
15. ✅ `visitors` - Visitor management
16. ✅ `staff` - Staff management
17. ✅ `staff_attendance` - Staff attendance records
18. ✅ `emergency_alerts` - Emergency alerts
19. ✅ `emergency_contacts` - Emergency contacts
20. ✅ `chat_rooms` - Chat rooms
21. ✅ `chat_messages` - Chat messages
22. ✅ `documents` - Document storage
23. ✅ `document_folders` - Document folders

### **Additional Collections (Beyond Adda)**
24. ✅ `events` - Society events
25. ✅ `packages` - Package/delivery tracking
26. ✅ `votings` - Voting system
27. ✅ `meetings` - Meeting management
28. ✅ `expenses` - Expense tracking

---

## 🔐 Security Rules Summary

### **General Rules**
- All collections require authentication (`isAuthenticated()`)
- Admin users have elevated privileges
- Users can only modify their own data (unless admin)
- Input validation on critical fields

### **Read Permissions**
- **Public Collections**: All authenticated users can read
  - `notices`, `events`, `facilities`, `polls`, `forum_posts`, `staff`, `emergency_contacts`
- **User-Specific Collections**: Users can only read their own data
  - `members`, `payments`, `visitors`, `packages`, `facility_bookings`
- **Member Collections**: All members can read, but limited access
  - `documents` (based on access level)
  - `chat_rooms` (only members of the room)
  - `meetings` (all members can see)

### **Write Permissions**
- **Admin-Only Collections**: Only admins can create/update/delete
  - `facilities`, `staff`, `emergency_contacts`, `admins`
- **User Collections**: Users can create, admins can update/delete
  - `payments`, `visitors`, `forum_posts`, `polls`, `events`
- **Owner Collections**: Users can create and modify their own, admins can modify any
  - `maintenance_requests`, `facility_bookings`, `expenses`

### **Delete Permissions**
- Most collections allow soft deletes via `isActive` flag
- Some collections prevent hard deletes (`payments`, `audit_logs`)
- Users can delete their own content (posts, comments, bookings in pending status)
- Admins can delete any content

---

## 🚀 Deployment Steps

### **Step 1: Backup Current Rules**
1. Go to Firebase Console
2. Navigate to Firestore Database → Rules
3. Copy existing rules to a backup file

### **Step 2: Update Rules**
1. Copy the entire content from `firestore.rules`
2. Paste into Firebase Console Rules editor
3. Click "Publish" to deploy

### **Step 3: Verify Rules**
1. Test with different user roles (admin, member)
2. Verify read/write permissions work correctly
3. Check error logs for any permission issues

### **Step 4: Monitor**
- Monitor Firestore usage
- Check for permission denied errors
- Adjust rules if needed based on usage patterns

---

## 🔍 Security Features

### **Helper Functions**
- `isAuthenticated()` - Checks if user is logged in
- `isAdmin()` - Checks if user is admin (checks both `admins` and `admin` collections)
- `isOwner(userId)` - Checks if user owns the document
- `isValidEmail(email)` - Validates email format
- `isValidPhone(phone)` - Validates phone number format

### **Security Principles**
1. **Least Privilege**: Users only get minimum required permissions
2. **Input Validation**: Critical fields are validated
3. **Owner Verification**: Users can only modify their own data
4. **Admin Override**: Admins have elevated permissions for management
5. **Immutable Logs**: Audit logs cannot be modified or deleted
6. **Soft Deletes**: Prefer `isActive` flag over hard deletes

---

## 📝 Collection-Specific Rules

### **Forum Posts**
- ✅ All users can read
- ✅ Users can create their own posts
- ✅ Users can update/delete their own posts
- ✅ Admins can modify any post

### **Polls**
- ✅ All users can read
- ✅ Users can create polls
- ✅ Only creator/admin can update/delete
- ✅ Voting is handled in update operation

### **Facility Bookings**
- ✅ Users can read their own bookings
- ✅ Users can create bookings
- ✅ Users can cancel pending bookings
- ✅ Admins can approve/reject any booking

### **Visitors**
- ✅ Users can read their own visitor entries
- ✅ Users can create visitor entries
- ✅ Users can update their own entries
- ✅ Admins can manage all entries

### **Chat Messages**
- ✅ All authenticated users can read (within their rooms)
- ✅ Users can create messages in rooms they're members of
- ✅ Users can edit/delete their own messages
- ✅ Admins can moderate all messages

### **Documents**
- ✅ Access based on `accessLevel` field
- ✅ Public documents: all members
- ✅ Private documents: only shared users
- ✅ Uploader and admins can manage

### **Expenses**
- ✅ All users can read (for transparency)
- ✅ Users can create expenses
- ✅ Only creator/admin can update/delete
- ✅ Admin approval workflow

---

## ⚠️ Important Notes

1. **Index Requirements**: Some queries may require composite indexes. Firebase will prompt you to create them.

2. **Admin Collection**: Rules check both `admins` and `admin` collections for backward compatibility.

3. **Soft Deletes**: Most collections use `isActive` flag. Rules allow deletes but recommend soft deletes.

4. **Testing**: Always test rules in Firebase Console Rules Playground before deploying.

5. **Performance**: Complex rules can impact query performance. Monitor and optimize as needed.

---

## 🔄 Migration Checklist

- [ ] Backup current rules
- [ ] Review new rules
- [ ] Test in Rules Playground
- [ ] Deploy to staging (if available)
- [ ] Deploy to production
- [ ] Monitor for errors
- [ ] Create required indexes
- [ ] Update documentation

---

## 📚 Additional Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Security Rules Testing](https://firebase.google.com/docs/firestore/security/test-rules)
- [Index Creation](https://firebase.google.com/docs/firestore/query-data/indexing)

---

## ✅ Summary

**28 collections** now have comprehensive security rules covering:
- ✅ All Adda features
- ✅ All additional premium features
- ✅ Role-based access control
- ✅ Input validation
- ✅ Owner verification
- ✅ Admin privileges

Your Firestore database is now secure and ready for all features! 🎉

