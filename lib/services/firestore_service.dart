import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../models/user_model.dart';
import '../models/utility_model.dart';
import '../models/payment_model.dart';
import '../models/maintenance_request_model.dart';
import '../models/notice_model.dart';
import '../models/balance_sheet_model.dart';
import '../models/notification_model.dart';
import '../models/forum_model.dart';
import '../models/poll_model.dart';
import '../models/facility_model.dart';
import '../models/visitor_model.dart';
import '../models/event_model.dart';
import '../models/document_model.dart';
import '../models/package_model.dart';
import '../models/emergency_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _membersCollection => _firestore.collection('members');
  CollectionReference get _utilityBillsCollection => _firestore.collection('utility_bills');
  CollectionReference get _paymentsCollection => _firestore.collection('payments');
  CollectionReference get _maintenanceRequestsCollection => _firestore.collection('maintenance_requests');
  CollectionReference get _noticesCollection => _firestore.collection('notices');
  CollectionReference get _balanceSheetsCollection => _firestore.collection('balance_sheets');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _forumPostsCollection => _firestore.collection('forum_posts');
  CollectionReference get _forumCommentsCollection => _firestore.collection('forum_comments');
  CollectionReference get _pollsCollection => _firestore.collection('polls');
  CollectionReference get _facilitiesCollection => _firestore.collection('facilities');
  CollectionReference get _facilityBookingsCollection => _firestore.collection('facility_bookings');
  CollectionReference get _visitorsCollection => _firestore.collection('visitors');
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _documentsCollection => _firestore.collection('documents');
  CollectionReference get _packagesCollection => _firestore.collection('packages');
  CollectionReference get _emergencyAlertsCollection => _firestore.collection('emergency_alerts');

  /// Save member profile to Firestore
  Future<void> saveMemberProfile({
    required String firstName,
    required String? middleName,
    required String surname,
    required String email,
    required String phoneNumber,
    required String flatNumber,
    required String building,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Build full name
      final fullName = middleName != null && middleName.isNotEmpty
          ? '$firstName $middleName $surname'
          : '$firstName $surname';

      // Create user model
      final userModel = UserModel(
        id: user.uid,
        email: email,
        name: fullName,
        mobileNumber: phoneNumber,
        role: 'member', // Default role
        apartmentNumber: flatNumber,
        buildingName: building,
        isEmailVerified: user.emailVerified,
        isMobileVerified: true, // Phone is verified via Firebase Auth
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Save to Firestore
      await _membersCollection.doc(user.uid).set(
        userModel.toMap(),
        SetOptions(merge: true), // Merge if document already exists
      );
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Please check Firestore security rules in Firebase Console. '
          'Ensure authenticated users can write to members/{userId} collection.'
        );
      }
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Get member profile by user ID
  Future<UserModel?> getMemberProfile(String userId) async {
    try {
      final doc = await _membersCollection.doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Get current user's profile
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getMemberProfile(user.uid);
  }

  /// Update member profile
  Future<void> updateMemberProfile({
    String? firstName,
    String? middleName,
    String? surname,
    String? email,
    String? flatNumber,
    String? building,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Build name if any name field is provided
      if (firstName != null || middleName != null || surname != null) {
        // Get current profile to merge names
        final currentProfile = await getMemberProfile(user.uid);
        final finalFirstName = firstName ?? currentProfile?.name.split(' ').first ?? '';
        final finalMiddleName = middleName ?? '';
        final finalSurname = surname ?? currentProfile?.name.split(' ').last ?? '';

        final fullName = finalMiddleName.isNotEmpty
            ? '$finalFirstName $finalMiddleName $finalSurname'
            : '$finalFirstName $finalSurname';
        
        updateData['name'] = fullName;
      }

      if (email != null) updateData['email'] = email;
      if (flatNumber != null) updateData['apartmentNumber'] = flatNumber;
      if (building != null) updateData['buildingName'] = building;

      await _membersCollection.doc(user.uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Check if member profile exists
  Future<bool> memberProfileExists(String userId) async {
    try {
      final doc = await _membersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all members
  Future<List<UserModel>> getAllMembers() async {
    try {
      final snapshot = await _membersCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get members: $e');
    }
  }

  /// Delete member profile (soft delete)
  Future<void> deleteMemberProfile(String userId) async {
    try {
      await _membersCollection.doc(userId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  /// Check if a phone number belongs to an admin
  Future<bool> isAdmin(String phoneNumber) async {
    try {
      // Clean phone number (remove spaces, +, etc.)
      final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Get last 10 digits (for Indian numbers without country code)
      final last10Digits = cleanedPhone.length >= 10
          ? cleanedPhone.substring(cleanedPhone.length - 10)
          : cleanedPhone;
      
      // Try multiple matching strategies
      // 1. Try exact match with full cleaned number
      var adminSnapshot = await _firestore
          .collection('admin')
          .where('phoneNumber', isEqualTo: cleanedPhone)
          .limit(1)
          .get();
      
      if (adminSnapshot.docs.isNotEmpty) {
        return true;
      }
      
      // 2. Try match with last 10 digits (for numbers stored without country code)
      adminSnapshot = await _firestore
          .collection('admin')
          .where('phoneNumber', isEqualTo: last10Digits)
          .limit(1)
          .get();
      
      if (adminSnapshot.docs.isNotEmpty) {
        return true;
      }
      
      // 3. Try match without country code (if stored as 917021868352, match 7021868352)
      if (cleanedPhone.length > 10 && cleanedPhone.startsWith('91')) {
        final withoutCountryCode = cleanedPhone.substring(2);
        adminSnapshot = await _firestore
            .collection('admin')
            .where('phoneNumber', isEqualTo: withoutCountryCode)
            .limit(1)
            .get();
        
        if (adminSnapshot.docs.isNotEmpty) {
          return true;
        }
      }
      
      // 4. Try match with string comparison (handles string vs number in DB)
      // Get all admins and check manually
      final allAdmins = await _firestore.collection('admin').get();
      for (var doc in allAdmins.docs) {
        final data = doc.data();
        final dbPhone = data['phoneNumber']?.toString() ?? '';
        final dbCleaned = dbPhone.replaceAll(RegExp(r'[^\d]'), '');
        
        // Compare cleaned versions
        if (dbCleaned == cleanedPhone || 
            dbCleaned == last10Digits ||
            (cleanedPhone.length > 10 && dbCleaned == cleanedPhone.substring(cleanedPhone.length - 10))) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // If error, assume not admin
      if (kDebugMode) {
        debugPrint('Error checking admin status: $e');
      }
      return false;
    }
  }

  /// Get admin document by phone number
  Future<Map<String, dynamic>?> getAdminByPhoneNumber(String phoneNumber) async {
    try {
      // Clean phone number (remove spaces, +, etc.)
      final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Query admin collection for matching phone number
      final adminSnapshot = await _firestore
          .collection('admin')
          .where('phoneNumber', isEqualTo: cleanedPhone)
          .limit(1)
          .get();
      
      if (adminSnapshot.docs.isNotEmpty) {
        return adminSnapshot.docs.first.data();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============ Utility Bills Management ============

  /// Create a utility bill
  Future<String> createUtilityBill(UtilityModel utilityBill) async {
    try {
      // Use auto-generated document ID for multiple bills per type
      final docRef = await _utilityBillsCollection.add(utilityBill.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error creating utility bill: $e');
      }
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check Firestore security rules.');
      }
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating utility bill: $e');
      }
      throw Exception('Failed to create utility bill: $e');
    }
  }

  /// Get all utility bills
  Future<List<UtilityModel>> getAllUtilityBills() async {
    try {
      final snapshot = await _utilityBillsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = UtilityModel.fromMap(data);
            return model.copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting utility bills: $e');
      }
      throw Exception('Failed to get utility bills: $e');
    }
  }

  /// Get utility bills by type
  Future<List<UtilityModel>> getUtilityBillsByType(String utilityType) async {
    try {
      final snapshot = await _utilityBillsCollection
          .where('utilityType', isEqualTo: utilityType.toLowerCase())
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = UtilityModel.fromMap(data);
            return model.copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting utility bills by type: $e');
      }
      throw Exception('Failed to get utility bills by type: $e');
    }
  }

  /// Get utility bill by document ID
  Future<UtilityModel?> getUtilityBillById(String billId) async {
    try {
      final doc = await _utilityBillsCollection.doc(billId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final model = UtilityModel.fromMap(data);
      return model.copyWith(id: doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting utility bill: $e');
      }
      throw Exception('Failed to get utility bill: $e');
    }
  }

  /// Update utility bill
  Future<void> updateUtilityBill(String billId, UtilityModel utilityBill) async {
    try {
      await _utilityBillsCollection.doc(billId).update(utilityBill.toMap());
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error updating utility bill: $e');
      }
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check Firestore security rules.');
      }
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating utility bill: $e');
      }
      throw Exception('Failed to update utility bill: $e');
    }
  }

  /// Delete utility bill (soft delete)
  Future<void> deleteUtilityBill(String billId) async {
    try {
      await _utilityBillsCollection.doc(billId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting utility bill: $e');
      }
      throw Exception('Failed to delete utility bill: $e');
    }
  }


  /// Stream utility bills for real-time updates
  Stream<List<UtilityModel>> streamUtilityBills() {
    return _utilityBillsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final model = UtilityModel.fromMap(data);
              return model.copyWith(id: doc.id);
            })
            .toList());
  }

  // ==================== PAYMENT METHODS ====================

  /// Create a new payment record
  Future<String> createPayment(PaymentModel payment) async {
    try {
      final docRef = await _paymentsCollection.add(payment.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error creating payment: $e');
      }
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check Firestore security rules.');
      }
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating payment: $e');
      }
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Get all payments for the current user
  Future<List<PaymentModel>> getUserPayments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _paymentsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('paidDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = PaymentModel.fromMap(data);
            return model.copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user payments: $e');
      }
      throw Exception('Failed to get payments: $e');
    }
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _paymentsCollection.doc(paymentId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final model = PaymentModel.fromMap(data);
      return model.copyWith(id: doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting payment: $e');
      }
      throw Exception('Failed to get payment: $e');
    }
  }

  // ============ Maintenance Requests Management ============

  /// Create a maintenance request
  Future<String> createMaintenanceRequest(MaintenanceRequestModel request) async {
    try {
      final docRef = await _maintenanceRequestsCollection.add(request.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating maintenance request: $e');
      }
      throw Exception('Failed to create maintenance request: $e');
    }
  }

  /// Get all maintenance requests for the current user (includes user's personal requests + all public requests)
  Future<List<MaintenanceRequestModel>> getUserMaintenanceRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user's personal requests (where userId matches)
      final userRequestsSnapshot = await _maintenanceRequestsCollection
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Get all public requests (where isPublic is true)
      // Note: Index order must match query order (isPublic, isActive, createdAt)
      List<MaintenanceRequestModel> publicRequests = [];
      try {
        final publicRequestsSnapshot = await _maintenanceRequestsCollection
            .where('isPublic', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        for (var doc in publicRequestsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final model = MaintenanceRequestModel.fromMap(data);
          publicRequests.add(model.copyWith(id: doc.id));
        }
      } catch (e) {
        // If index is not ready, try without orderBy and sort in memory
        if (e.toString().contains('index')) {
          try {
            final publicRequestsSnapshot = await _maintenanceRequestsCollection
                .where('isPublic', isEqualTo: true)
                .where('isActive', isEqualTo: true)
                .get();
            
            for (var doc in publicRequestsSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final model = MaintenanceRequestModel.fromMap(data);
              publicRequests.add(model.copyWith(id: doc.id));
            }
            
            // Sort by createdAt descending in memory
            publicRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } catch (e2) {
            // If that also fails, just skip public requests
            if (kDebugMode) {
              debugPrint('Error getting public requests: $e2');
            }
          }
        } else {
          rethrow;
        }
      }

      // Combine both lists and remove duplicates
      final allRequests = <String, MaintenanceRequestModel>{};
      
      for (var doc in userRequestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final model = MaintenanceRequestModel.fromMap(data);
        allRequests[doc.id] = model.copyWith(id: doc.id);
      }
      
      // Add public requests
      for (var request in publicRequests) {
        allRequests[request.id] = request;
      }

      // Sort by createdAt descending
      final sortedRequests = allRequests.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sortedRequests;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user maintenance requests: $e');
      }
      throw Exception('Failed to get maintenance requests: $e');
    }
  }

  /// Get all maintenance requests (for admin)
  Future<List<MaintenanceRequestModel>> getAllMaintenanceRequests() async {
    try {
      final snapshot = await _maintenanceRequestsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = MaintenanceRequestModel.fromMap(data);
            return model.copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all maintenance requests: $e');
      }
      throw Exception('Failed to get maintenance requests: $e');
    }
  }

  /// Get maintenance requests by status (for admin)
  Future<List<MaintenanceRequestModel>> getMaintenanceRequestsByStatus(String status) async {
    try {
      final snapshot = await _maintenanceRequestsCollection
          .where('status', isEqualTo: status)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = MaintenanceRequestModel.fromMap(data);
            return model.copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting maintenance requests by status: $e');
      }
      throw Exception('Failed to get maintenance requests: $e');
    }
  }

  /// Update maintenance request
  Future<void> updateMaintenanceRequest(String requestId, MaintenanceRequestModel request) async {
    try {
      await _maintenanceRequestsCollection.doc(requestId).update(request.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating maintenance request: $e');
      }
      throw Exception('Failed to update maintenance request: $e');
    }
  }

  /// Get maintenance request by ID
  Future<MaintenanceRequestModel?> getMaintenanceRequestById(String requestId) async {
    try {
      final doc = await _maintenanceRequestsCollection.doc(requestId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final model = MaintenanceRequestModel.fromMap(data);
      return model.copyWith(id: doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting maintenance request: $e');
      }
      throw Exception('Failed to get maintenance request: $e');
    }
  }

  /// Delete maintenance request (soft delete)
  Future<void> deleteMaintenanceRequest(String requestId) async {
    try {
      await _maintenanceRequestsCollection.doc(requestId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting maintenance request: $e');
      }
      throw Exception('Failed to delete maintenance request: $e');
    }
  }

  // ============ Notices Management ============

  /// Create a notice (admin only)
  Future<String> createNotice(NoticeModel notice) async {
    try {
      final docRef = await _noticesCollection.add(notice.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating notice: $e');
      }
      throw Exception('Failed to create notice: $e');
    }
  }

  /// Get all active notices (for all members)
  Future<List<NoticeModel>> getAllNotices() async {
    try {
      final snapshot = await _noticesCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = NoticeModel.fromMap(data);
            return model.copyWithId(doc.id);
          })
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting notices: $e');
      }
      throw Exception('Failed to get notices: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting notices: $e');
      }
      throw Exception('Failed to get notices: $e');
    }
  }

  /// Get new notices (not read by current user)
  Future<List<NoticeModel>> getNewNotices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _noticesCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = NoticeModel.fromMap(data);
            return model.copyWithId(doc.id);
          })
          .where((notice) => !notice.readBy.contains(user.uid))
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting new notices: $e');
      }
      // Re-throw with original message for better error handling
      throw Exception('Failed to get new notices: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting new notices: $e');
      }
      throw Exception('Failed to get new notices: $e');
    }
  }

  /// Get archived notices
  Future<List<NoticeModel>> getArchivedNotices() async {
    try {
      final snapshot = await _noticesCollection
          .where('status', isEqualTo: 'archived')
          .where('isActive', isEqualTo: true)
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = NoticeModel.fromMap(data);
            return model.copyWithId(doc.id);
          })
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting archived notices: $e');
      }
      throw Exception('Failed to get archived notices: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting archived notices: $e');
      }
      throw Exception('Failed to get archived notices: $e');
    }
  }

  /// Get all notices (for admin)
  Future<List<NoticeModel>> getAllNoticesForAdmin() async {
    try {
      final snapshot = await _noticesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final model = NoticeModel.fromMap(data);
            return model.copyWithId(doc.id);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all notices: $e');
      }
      throw Exception('Failed to get notices: $e');
    }
  }

  /// Update notice
  Future<void> updateNotice(String noticeId, NoticeModel notice) async {
    try {
      await _noticesCollection.doc(noticeId).update(notice.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating notice: $e');
      }
      throw Exception('Failed to update notice: $e');
    }
  }

  /// Delete notice (soft delete)
  Future<void> deleteNotice(String noticeId) async {
    try {
      await _noticesCollection.doc(noticeId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notice: $e');
      }
      throw Exception('Failed to delete notice: $e');
    }
  }

  /// Mark notice as read by user
  Future<void> markNoticeAsRead(String noticeId, String userId) async {
    try {
      final noticeRef = _noticesCollection.doc(noticeId);
      final noticeDoc = await noticeRef.get();
      
      if (!noticeDoc.exists) {
        throw Exception('Notice not found');
      }

      final data = noticeDoc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);
      
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        await noticeRef.update({
          'readBy': readBy,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notice as read: $e');
      }
      throw Exception('Failed to mark notice as read: $e');
    }
  }

  /// Get notice by ID
  Future<NoticeModel?> getNoticeById(String noticeId) async {
    try {
      final doc = await _noticesCollection.doc(noticeId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final model = NoticeModel.fromMap(data);
      return model.copyWithId(doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting notice: $e');
      }
      throw Exception('Failed to get notice: $e');
    }
  }

  /// Save FCM Token for Notifications
  Future<void> saveUserToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _membersCollection.doc(user.uid).update({
          'fcmToken': token, // This token will be saved
          'updatedAt': DateTime.now().toIso8601String(),
        });
        if (kDebugMode) {
          debugPrint('FCM Token Saved: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  // ============ Balance Sheet Management ============

  /// Create a balance sheet
  Future<String> createBalanceSheet(BalanceSheetModel balanceSheet) async {
    try {
      final docRef = await _balanceSheetsCollection.add(balanceSheet.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating balance sheet: $e');
      }
      throw Exception('Failed to create balance sheet: $e');
    }
  }

  /// Get balance sheet by year
  Future<BalanceSheetModel?> getBalanceSheetByYear(int year) async {
    try {
      // Try with index first
      try {
        final snapshot = await _balanceSheetsCollection
            .where('year', isEqualTo: year)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          return null;
        }

        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final model = BalanceSheetModel.fromMap(data);
        return model.copyWith(id: snapshot.docs.first.id);
      } catch (e) {
        // If index is not ready, try with single where clause
        if (e.toString().contains('index')) {
          final snapshot = await _balanceSheetsCollection
              .where('year', isEqualTo: year)
              .get();

          // Filter by isActive in memory
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isActive'] == true) {
              final model = BalanceSheetModel.fromMap(data);
              return model.copyWith(id: doc.id);
            }
          }
          return null;
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting balance sheet: $e');
      }
      throw Exception('Failed to get balance sheet: $e');
    }
  }

  /// Get all balance sheets
  Future<List<BalanceSheetModel>> getAllBalanceSheets() async {
    try {
      // Try with index first
      try {
        final snapshot = await _balanceSheetsCollection
            .where('isActive', isEqualTo: true)
            .orderBy('year', descending: true)
            .get();

        return snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final model = BalanceSheetModel.fromMap(data);
              return model.copyWith(id: doc.id);
            })
            .toList();
      } catch (e) {
        // If index is not ready, try without orderBy and sort in memory
        if (e.toString().contains('index')) {
          final snapshot = await _balanceSheetsCollection
              .where('isActive', isEqualTo: true)
              .get();

          final balanceSheets = snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final model = BalanceSheetModel.fromMap(data);
                return model.copyWith(id: doc.id);
              })
              .toList();

          // Sort by year descending in memory
          balanceSheets.sort((a, b) => b.year.compareTo(a.year));
          return balanceSheets;
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting balance sheets: $e');
      }
      throw Exception('Failed to get balance sheets: $e');
    }
  }

  /// Update balance sheet
  Future<void> updateBalanceSheet(String balanceSheetId, BalanceSheetModel balanceSheet) async {
    try {
      await _balanceSheetsCollection.doc(balanceSheetId).update(balanceSheet.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating balance sheet: $e');
      }
      throw Exception('Failed to update balance sheet: $e');
    }
  }

  /// Delete balance sheet (soft delete)
  Future<void> deleteBalanceSheet(String balanceSheetId) async {
    try {
      await _balanceSheetsCollection.doc(balanceSheetId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting balance sheet: $e');
      }
      throw Exception('Failed to delete balance sheet: $e');
    }
  }

  /// Get balance sheet by ID
  Future<BalanceSheetModel?> getBalanceSheetById(String balanceSheetId) async {
    try {
      final doc = await _balanceSheetsCollection.doc(balanceSheetId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final model = BalanceSheetModel.fromMap(data);
      return model.copyWith(id: doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting balance sheet: $e');
      }
      throw Exception('Failed to get balance sheet: $e');
    }
  }

  // ============ Notification Management ============

  /// Save notification for a user
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving notification: $e');
      }
      throw Exception('Failed to save notification: $e');
    }
  }

  /// Get all notifications for current user
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return NotificationModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting notifications: $e');
      }
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      final snapshot = await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking all notifications as read: $e');
      }
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notification: $e');
      }
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting all notifications: $e');
      }
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// Stream notifications for real-time updates
  Stream<List<NotificationModel>> getUserNotificationsStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  return NotificationModel.fromMap(data);
                })
                .toList();
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting notifications stream: $e');
      }
      return Stream.value([]);
    }
  }

  /// Stream unread notification count
  Stream<int> getUnreadNotificationCountStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value(0);
      }

      return _notificationsCollection
          .doc(user.uid)
          .collection('user_notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting unread count stream: $e');
      }
      return Stream.value(0);
    }
  }

  // ============ Forum Management ============

  /// Create a forum post
  Future<String> createForumPost(ForumPostModel post) async {
    try {
      final docRef = await _forumPostsCollection.add(post.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating forum post: $e');
      throw Exception('Failed to create forum post: $e');
    }
  }

  /// Get all forum posts
  Stream<List<ForumPostModel>> getForumPostsStream() {
    return _forumPostsCollection
        .where('status', isEqualTo: 'active')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ForumPostModel.fromMap(data);
        }).toList());
  }

  /// Get forum post by ID
  Future<ForumPostModel?> getForumPostById(String postId) async {
    try {
      final doc = await _forumPostsCollection.doc(postId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return ForumPostModel.fromMap(data);
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting forum post: $e');
      return null;
    }
  }

  /// Like/Unlike a forum post
  Future<void> toggleForumPostLike(String postId, String userId) async {
    try {
      final post = await getForumPostById(postId);
      if (post == null) return;
      
      final likedBy = List<String>.from(post.likedBy);
      final isLiked = likedBy.contains(userId);
      
      if (isLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      
      await _forumPostsCollection.doc(postId).update({
        'likedBy': likedBy,
        'likesCount': likedBy.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Add comment to forum post
  Future<String> addForumComment(ForumCommentModel comment) async {
    try {
      final docRef = await _forumCommentsCollection.add(comment.toMap());
      // Update post comment count
      await _forumPostsCollection.doc(comment.postId).update({
        'commentsCount': FieldValue.increment(1),
        'lastActivityAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a post
  Stream<List<ForumCommentModel>> getForumCommentsStream(String postId) {
    return _forumCommentsCollection
        .where('postId', isEqualTo: postId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ForumCommentModel.fromMap(data);
        }).toList());
  }

  // ============ Polls Management ============

  /// Create a poll
  Future<String> createPoll(PollModel poll) async {
    try {
      final docRef = await _pollsCollection.add(poll.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating poll: $e');
      throw Exception('Failed to create poll: $e');
    }
  }

  /// Get all active polls
  Stream<List<PollModel>> getPollsStream() {
    return _pollsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return PollModel.fromMap(data);
        }).toList());
  }

  /// Vote on a poll
  Future<void> voteOnPoll(String pollId, String userId, String optionId) async {
    try {
      final pollDoc = await _pollsCollection.doc(pollId).get();
      if (!pollDoc.exists) throw Exception('Poll not found');
      
      final poll = PollModel.fromMap(pollDoc.data() as Map<String, dynamic>);
      final voters = List<String>.from(poll.voters);
      final votes = Map<String, String>.from(poll.votes);
      
      if (voters.contains(userId)) {
        throw Exception('You have already voted on this poll');
      }
      
      voters.add(userId);
      votes[userId] = optionId;
      
      await _pollsCollection.doc(pollId).update({
        'voters': voters,
        'votes': votes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error voting on poll: $e');
      throw Exception('Failed to vote: $e');
    }
  }

  // ============ Facilities Management ============

  /// Get all facilities
  Stream<List<FacilityModel>> getFacilitiesStream() {
    return _facilitiesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return FacilityModel.fromMap(data);
        }).toList());
  }

  /// Create facility booking
  Future<String> createFacilityBooking(FacilityBookingModel booking) async {
    try {
      final docRef = await _facilityBookingsCollection.add(booking.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get user's facility bookings
  Stream<List<FacilityBookingModel>> getUserFacilityBookingsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _facilityBookingsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return FacilityBookingModel.fromMap(data);
        }).toList());
  }

  // ============ Visitors Management ============

  /// Create visitor entry
  Future<String> createVisitor(VisitorModel visitor) async {
    try {
      final docRef = await _visitorsCollection.add(visitor.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating visitor: $e');
      throw Exception('Failed to create visitor: $e');
    }
  }

  /// Get user's visitors
  Stream<List<VisitorModel>> getUserVisitorsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _visitorsCollection
        .where('residentUserId', isEqualTo: user.uid)
        .orderBy('expectedArrival', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return VisitorModel.fromMap(data);
        }).toList());
  }

  // ============ Events Management ============

  /// Get all events
  Stream<List<EventModel>> getEventsStream() {
    return _eventsCollection
        .where('status', isEqualTo: 'published')
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return EventModel.fromMap(data);
        }).toList());
  }

  // ============ Documents Management ============

  /// Get all documents
  Stream<List<DocumentModel>> getDocumentsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _documentsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            final docModel = DocumentModel.fromMap(data);
            // Filter by access level
            if (docModel.accessLevel == 'public' || 
                docModel.accessLevel == 'members_only' ||
                docModel.uploadedBy == user.uid ||
                docModel.sharedWith.contains(user.uid)) {
              return docModel;
            }
            return null;
          }).whereType<DocumentModel>().toList();
        });
  }

  // ============ Packages Management ============

  /// Get user's packages
  Stream<List<PackageModel>> getUserPackagesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _packagesCollection
        .where('recipientUserId', isEqualTo: user.uid)
        .orderBy('receivedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return PackageModel.fromMap(data);
        }).toList());
  }

  // ============ Emergency Management ============

  /// Create emergency alert
  Future<String> createEmergencyAlert(EmergencyAlertModel alert) async {
    try {
      final docRef = await _emergencyAlertsCollection.add(alert.toMap());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating emergency alert: $e');
      throw Exception('Failed to create emergency alert: $e');
    }
  }
}
