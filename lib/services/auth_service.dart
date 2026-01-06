import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  String? _phoneNumber;
  Completer<void>? _verificationIdCompleter;

  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
  String? get verificationId => _verificationId;
  String? get phoneNumber => _phoneNumber;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _phoneNumber = phoneNumber;
      
      // Verify phone number format
      if (!phoneNumber.startsWith('+')) {
        throw Exception('Phone number must include country code (e.g., +91)');
      }

      // Reset verification ID and completer before sending new OTP
      _verificationId = null;
      _verificationIdCompleter?.completeError('New OTP requested');
      _verificationIdCompleter = Completer<void>();

      // For web, use reCAPTCHA verifier
      if (kIsWeb) {
        // On web, RecaptchaVerifier is automatically handled by Firebase
        // The web platform will show a reCAPTCHA challenge
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification completed (SMS code sent automatically)
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            _verificationIdCompleter?.completeError(e);
            throw Exception(e.message ?? 'Verification failed: ${e.code}');
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            if (kDebugMode) {
              debugPrint('Verification ID (Web): $verificationId');
            }
            if (!_verificationIdCompleter!.isCompleted) {
              _verificationIdCompleter!.complete();
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
            if (!_verificationIdCompleter!.isCompleted) {
              _verificationIdCompleter!.complete();
            }
          },
          timeout: const Duration(seconds: 60),
        );
      } else {
        // For Android and iOS
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification completed
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            _verificationIdCompleter?.completeError(e);
            throw Exception(e.message ?? 'Verification failed: ${e.code}');
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            if (kDebugMode) {
              debugPrint('Verification ID: $verificationId');
            }
            if (!_verificationIdCompleter!.isCompleted) {
              _verificationIdCompleter!.complete();
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
            if (!_verificationIdCompleter!.isCompleted) {
              _verificationIdCompleter!.complete();
            }
          },
          timeout: const Duration(seconds: 60),
        );
      }
      
      // Wait for verification ID to be set
      await _verificationIdCompleter!.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () {
          throw Exception('OTP sending timeout. Please try again.');
        },
      );
    } catch (e) {
      _verificationIdCompleter = null;
      if (kDebugMode) {
        debugPrint('Error sending OTP: $e');
      }
      rethrow;
    }
  }

  /// Verify OTP code
  Future<UserCredential> verifyOTP(String otpCode) async {
    try {
      // Wait a bit if verification ID is still being set
      if (_verificationId == null && _verificationIdCompleter != null) {
        try {
          await _verificationIdCompleter!.future.timeout(
            const Duration(seconds: 2),
          );
        } catch (e) {
          // Ignore timeout, proceed with check
        }
      }

      if (_verificationId == null) {
        throw FirebaseAuthException(
          code: 'missing-verification-id',
          message: 'Verification ID not found. Please request OTP again.',
        );
      }

      final verificationIdToUse = _verificationId!;

      // Create phone auth credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationIdToUse,
        smsCode: otpCode,
      );

      // Sign in with credential with retry logic
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential).timeout(
          const Duration(seconds: 10),
        );
      } on FirebaseAuthException catch (e) {
        // If invalid code or expired session, clear verification ID
        if (e.code == 'invalid-verification-code' || 
            e.code == 'session-expired' ||
            e.code == 'code-expired') {
          _verificationId = null;
          _verificationIdCompleter = null;
        }
        rethrow;
      } catch (e) {
        // For timeout or other errors, rethrow
        rethrow;
      }

      // Clear verification ID only after successful verification
      _verificationId = null;
      _verificationIdCompleter = null;
      
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error verifying OTP: $e');
      }
      rethrow;
    }
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    if (_phoneNumber == null) {
      throw Exception('Phone number not found');
    }
    // Clear old verification ID before resending
    final phoneNumber = _phoneNumber!;
    _verificationId = null;
    _verificationIdCompleter = null;
    await sendOTP(phoneNumber);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _phoneNumber = null;
    _verificationIdCompleter?.completeError('User signed out');
    _verificationIdCompleter = null;
  }

  /// Get current user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current user phone number
  String? getUserPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error signing in with email: $e');
      }
      rethrow;
    }
  }

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating user with email: $e');
      }
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending password reset email: $e');
      }
      rethrow;
    }
  }
}
