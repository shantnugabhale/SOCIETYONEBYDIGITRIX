# SocietyOne by Digitrix - Enterprise Architecture

## 🏗️ System Architecture Overview

This document outlines the comprehensive architecture of SocietyOne, designed to match and exceed ADDA's functionality with enterprise-grade multi-tenancy support.

---

## 1. Multi-Tenancy Architecture

### Society Model (`lib/models/society_model.dart`)
- **Society-level isolation**: Each society has its own data namespace
- **Scalable design**: Supports thousands of independent societies
- **Location-based search**: Search by name, city, or PIN code
- **Metadata**: GSTIN, coordinates, amenities, contact info

### Unit Model (`lib/models/society_model.dart`)
- **Block/Wing structure**: Organized unit hierarchy
- **Status tracking**: Occupied/Vacant/Under Construction
- **Owner/Tenant linking**: Links units to users
- **Property details**: Area, bedrooms, possession date

### User Model Enhancements (`lib/models/user_model.dart`)
- **`societyId`**: Multi-tenancy key - all queries filtered by society
- **`societyName`**: Quick access without joins
- **`userType`**: Owner/Tenant/Family Member
- **`approvalStatus`**: Pending/Approved/Rejected (Gatekeeper logic)
- **`hideContactInDirectory`**: Privacy toggle
- **`isKycVerified`**: KYC status tracking

---

## 2. Onboarding & Authentication Flow

### Two-Tier Search System

**Phase 1: Society Selection** (`lib/views/auth/society_selection_screen.dart`)
- Global search by:
  - Society Name (fuzzy search)
  - City
  - PIN Code
- Results show: Name, Address, Unit count, Block count

**Phase 2: Unit Selection** (`lib/views/auth/unit_selection_screen.dart`)
- Block/Wing selection (dropdown if available)
- Flat/Unit selection (list or manual entry)
- Unit details: Floor, Status, Area

**Phase 3: Role Selection** (`lib/views/auth/role_selection_screen.dart`)
- Owner
- Tenant
- Family Member

**Phase 4: Profile Setup** (`lib/views/auth/setup_profile_screen.dart`)
- Personal details
- Contact information
- Saves with `approvalStatus: 'pending'`

### Gatekeeper Logic

**Pending Approval State** (`lib/views/auth/pending_approval_screen.dart`)
- Users cannot access society data until approved
- Shows pending status with refresh option
- Admin dashboard shows pending requests

**Approval Workflow** (`lib/services/firestore_service.dart`)
- `getPendingApprovalsStream()`: Real-time pending requests
- `approveUserRegistration()`: Admin approves user
- `rejectUserRegistration()`: Admin rejects with reason
- Auto-updates `approvalStatus`, `approvedAt`, `approvedBy`

---

## 3. Database Architecture

### Collections Structure

All collections now support multi-tenancy with `societyId`:

```
societies/
  {societyId}/
    - name, address, city, pinCode
    - latitude, longitude
    - gstin, totalUnits
    - blocks: [string]
    - amenities: [string]

units/
  {unitId}/
    - societyId (foreign key)
    - block, unitNumber, floorNumber
    - status: 'occupied' | 'vacant' | 'under_construction'
    - ownerId, tenantId
    - area, bedrooms

members/
  {userId}/
    - societyId (multi-tenancy key)
    - societyName
    - userType: 'owner' | 'tenant' | 'family_member'
    - approvalStatus: 'pending' | 'approved' | 'rejected'
    - hideContactInDirectory: boolean
    - isKycVerified: boolean
    - approvedAt, approvedBy
```

### Query Patterns

All queries filtered by `societyId`:
```dart
.where('societyId', isEqualTo: currentUser.societyId)
```

This ensures:
- **Data isolation**: Users only see their society's data
- **Performance**: Indexed queries, fast results
- **Security**: Firestore rules enforce society-level access

---

## 4. Privacy Controls

### Resident Directory (`lib/services/firestore_service.dart`)

**`getResidentDirectory()`**:
- Returns only approved users
- Respects `hideContactInDirectory` flag
- Admin can always see all contacts

**Privacy Toggle**:
- Users can hide contact from directory
- Admin still has access
- Emergency contacts always visible

---

## 5. Core Modules (All Multi-Tenant)

### Communication
- **Notice Board**: Admin → All (filtered by societyId)
- **Community Forum**: Resident → Resident (society-scoped)

### Helpdesk
- **Maintenance Requests**: Society-scoped tickets
- **Status Tracking**: Open → In-Progress → Closed
- **Assignment**: Staff assigned per society

### Accounts & Billing
- **Maintenance Bills**: Generated per society
- **Payment Integration**: Razorpay/Cashfree ready
- **Digital Receipts**: Instant generation

### Visitor Management
- **Gatekeeper Module**: Security guards log visitors
- **Real-time Notifications**: Approve/Deny push notifications
- **Offline Support**: Queue syncs when online

---

## 6. UI/UX Requirements (ADDA-Inspired)

### Home Screen Layout
- **Card-based design**: Priority cards for quick access
- **Priority Cards**:
  1. My Bills (with due amount)
  2. Visitor Entry (pending count)
  3. Notice Board (new notices)
  4. Emergency Contacts

### Color Palette
- **Deep Navy & White**: Professional, trustworthy
- **Gradients**: Only on splash/login/dashboard header
- **High Contrast**: Accessibility-first

### Offline Mode
- **Security Guards**: Can log visitors offline
- **Queue System**: Syncs when connection restored
- **Local Storage**: Hive/SQLite for offline data

---

## 7. Security & Access Control

### Firestore Rules (Multi-Tenant)

```javascript
// Members - Society-scoped
match /members/{userId} {
  allow read: if isAuthenticated() && 
                 (resource.data.societyId == getSocietyId() || isAdmin());
  allow write: if isAuthenticated() && 
                  request.auth.uid == userId &&
                  request.resource.data.societyId == getSocietyId();
}

// All other collections follow same pattern
```

### Role-Based Access
- **Admin**: Full access to their society
- **Committee**: Read/write for their society
- **Resident**: Read own data, write own requests
- **Security**: Visitor management only

---

## 8. Scalability Considerations

### India-Scale Design
- **Millions of users**: Optimized queries with indexes
- **Thousands of societies**: Logical isolation, no cross-contamination
- **Geographic distribution**: Location-based search optimized

### Performance
- **Indexed queries**: All societyId queries indexed
- **Pagination**: Large lists paginated
- **Caching**: Frequently accessed data cached
- **Lazy loading**: Images and heavy content lazy-loaded

---

## 9. Implementation Status

✅ **Completed**:
- Society & Unit models
- Multi-tenancy architecture
- Two-tier search (Society → Unit)
- Role selection (Owner/Tenant/Family)
- Approval workflow (Gatekeeper)
- Privacy controls
- Society management services

🔄 **In Progress**:
- Update all collections for societyId
- Admin approval dashboard
- Resident directory UI
- Offline mode for security

📋 **Pending**:
- Payment gateway integration
- Push notification system
- Advanced analytics
- Document management

---

## 10. Next Steps

1. **Update Existing Collections**: Add `societyId` to all existing models
2. **Admin Dashboard**: Build approval interface
3. **Migration Script**: Migrate existing data to multi-tenant structure
4. **Testing**: Comprehensive testing with multiple societies
5. **Performance Tuning**: Optimize queries for scale

---

## 📚 Related Files

- `lib/models/society_model.dart` - Society & Unit models
- `lib/models/user_model.dart` - Enhanced user model
- `lib/services/firestore_service.dart` - Society management methods
- `lib/views/auth/society_selection_screen.dart` - Society search
- `lib/views/auth/unit_selection_screen.dart` - Unit selection
- `lib/views/auth/role_selection_screen.dart` - Role selection
- `lib/views/auth/pending_approval_screen.dart` - Approval pending state

---

**Built with ❤️ for SocietyOne by Digitrix**

