import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Audit logging service for security events
/// Logs important security events for monitoring and compliance
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  CollectionReference get _auditLogsCollection => 
      _firestore.collection('audit_logs');

  /// Log security event
  Future<void> logEvent({
    required String eventType,
    required String eventDescription,
    String? userId,
    Map<String, dynamic>? metadata,
    bool isSuccess = true,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final user = userId ?? currentUser?.uid ?? 'unknown';

      // Get device information
      String deviceId = 'unknown';
      String deviceModel = 'unknown';
      
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          deviceModel = '${androidInfo.brand} ${androidInfo.model}';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown';
          deviceModel = '${iosInfo.model} ${iosInfo.name}';
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error getting device info: $e');
        }
      }

      final logEntry = {
        'userId': user,
        'eventType': eventType,
        'eventDescription': eventDescription,
        'isSuccess': isSuccess,
        'deviceId': deviceId,
        'deviceModel': deviceModel,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      };

      await _auditLogsCollection.add(logEntry);
    } catch (e) {
      // Don't throw error - audit logging should not break app functionality
      if (kDebugMode) {
        debugPrint('Error logging audit event: $e');
      }
    }
  }

  /// Log login event
  Future<void> logLogin({
    required String userId,
    required bool isSuccess,
    String? failureReason,
    bool isBiometric = false,
  }) async {
    await logEvent(
      eventType: 'login',
      eventDescription: isBiometric 
          ? 'Biometric login attempt' 
          : 'Login attempt',
      userId: userId,
      isSuccess: isSuccess,
      metadata: {
        'isBiometric': isBiometric,
        if (failureReason != null) 'failureReason': failureReason,
      },
    );
  }

  /// Log logout event
  Future<void> logLogout({String? userId}) async {
    await logEvent(
      eventType: 'logout',
      eventDescription: 'User logout',
      userId: userId,
      isSuccess: true,
    );
  }

  /// Log session timeout
  Future<void> logSessionTimeout({String? userId}) async {
    await logEvent(
      eventType: 'session_timeout',
      eventDescription: 'Session expired due to inactivity',
      userId: userId,
      isSuccess: false,
    );
  }

  /// Log data access
  Future<void> logDataAccess({
    required String resourceType,
    required String resourceId,
    String? userId,
    String? action,
  }) async {
    await logEvent(
      eventType: 'data_access',
      eventDescription: 'Data access',
      userId: userId,
      isSuccess: true,
      metadata: {
        'resourceType': resourceType,
        'resourceId': resourceId,
        'action': action ?? 'read',
      },
    );
  }

  /// Log data modification
  Future<void> logDataModification({
    required String resourceType,
    required String resourceId,
    String? userId,
    String? action,
    Map<String, dynamic>? changes,
  }) async {
    await logEvent(
      eventType: 'data_modification',
      eventDescription: 'Data modification',
      userId: userId,
      isSuccess: true,
      metadata: {
        'resourceType': resourceType,
        'resourceId': resourceId,
        'action': action ?? 'update',
        if (changes != null) 'changes': changes,
      },
    );
  }

  /// Log security violation
  Future<void> logSecurityViolation({
    required String violationType,
    required String description,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      eventType: 'security_violation',
      eventDescription: description,
      userId: userId,
      isSuccess: false,
      metadata: {
        'violationType': violationType,
        ...?metadata,
      },
    );
  }

  /// Log payment transaction
  Future<void> logPayment({
    required String paymentId,
    required double amount,
    String? userId,
    bool isSuccess = true,
    String? failureReason,
  }) async {
    await logEvent(
      eventType: 'payment',
      eventDescription: 'Payment transaction',
      userId: userId,
      isSuccess: isSuccess,
      metadata: {
        'paymentId': paymentId,
        'amount': amount,
        if (failureReason != null) 'failureReason': failureReason,
      },
    );
  }

  /// Log authentication failure
  Future<void> logAuthFailure({
    required String reason,
    String? userId,
  }) async {
    await logEvent(
      eventType: 'auth_failure',
      eventDescription: 'Authentication failure',
      userId: userId,
      isSuccess: false,
      metadata: {
        'reason': reason,
      },
    );
  }
}

