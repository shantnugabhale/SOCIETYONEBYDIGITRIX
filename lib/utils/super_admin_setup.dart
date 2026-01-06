import '../services/firestore_service.dart';
import '../models/super_admin_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class to set up Super Admin
/// Run this once to create the initial Super Admin
class SuperAdminSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Setup Super Admin with phone number 9773609077
  /// 
  /// IMPORTANT: 
  /// 1. First, login with this phone number in the app
  /// 2. Then run this method to create Super Admin document
  /// 3. Use your Firebase Auth UID as the document ID
  static Future<void> setupSuperAdmin() async {
    try {
      // Get current authenticated user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Please login first with phone number 9773609077');
      }

      // Check if phone number matches
      final phoneNumber = user.phoneNumber;
      if (phoneNumber == null || !phoneNumber.contains('9773609077')) {
        throw Exception('Current user phone number does not match Super Admin number');
      }

      // Create Super Admin document with Firebase Auth UID as document ID
      final superAdmin = SuperAdminModel(
        id: user.uid,
        mobileNumber: '+919773609077', // Normalized format
        name: 'Super Admin',
        email: user.email,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('super_admins')
          .doc(user.uid)
          .set(superAdmin.toMap());

      print('✅ Super Admin created successfully!');
      print('Document ID: ${user.uid}');
      print('Mobile Number: +919773609077');
    } catch (e) {
      print('❌ Error setting up Super Admin: $e');
      rethrow;
    }
  }

  /// Alternative: Create Super Admin manually (without authentication)
  /// Use this if you want to create it before first login
  /// 
  /// WARNING: You'll need to update the document ID later with your Firebase Auth UID
  static Future<String> createSuperAdminManually() async {
    try {
      final superAdmin = SuperAdminModel(
        id: 'temp_super_admin',
        mobileNumber: '+919773609077',
        name: 'Super Admin',
        email: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create with temporary ID
      final docRef = await _firestore
          .collection('super_admins')
          .add(superAdmin.toMap());

      // Update with actual document ID
      await docRef.update({'id': docRef.id});

      print('✅ Super Admin created with temporary ID');
      print('Document ID: ${docRef.id}');
      print('⚠️ IMPORTANT: Update document ID with your Firebase Auth UID after first login');
      
      return docRef.id;
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}

