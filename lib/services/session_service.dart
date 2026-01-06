import 'dart:async';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';

/// Session management service
/// Handles session timeout, auto-logout, and activity tracking
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  final AuthService _authService = AuthService();

  // Session timeout duration (30 minutes of inactivity)
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  // Max session duration (24 hours)
  static const Duration maxSessionDuration = Duration(hours: 24);

  Timer? _sessionTimer;
  DateTime? _sessionStartTime;
  DateTime? _lastActivityTime;

  /// Initialize session
  Future<void> initializeSession() async {
    try {
      _sessionStartTime = DateTime.now();
      _lastActivityTime = DateTime.now();
      
      // Save session info
      await _secureStorage.write(
        SecureStorageService.keySessionExpiry,
        _sessionStartTime!.add(maxSessionDuration).toIso8601String(),
      );
      await _updateLastActivity();

      // Start session timer
      _startSessionTimer();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing session: $e');
      }
    }
  }

  /// Update last activity time
  Future<void> updateActivity() async {
    _lastActivityTime = DateTime.now();
    await _updateLastActivity();
    _resetSessionTimer();
  }

  /// Update last activity in secure storage
  Future<void> _updateLastActivity() async {
    if (_lastActivityTime != null) {
      await _secureStorage.write(
        SecureStorageService.keyLastActivity,
        _lastActivityTime!.toIso8601String(),
      );
    }
  }

  /// Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkSessionTimeout();
    });
  }

  /// Reset session timer
  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _startSessionTimer();
  }

  /// Check if session has timed out
  Future<bool> _checkSessionTimeout() async {
    if (_lastActivityTime == null || _sessionStartTime == null) {
      return false;
    }

    final now = DateTime.now();
    
    // Check max session duration
    if (now.difference(_sessionStartTime!) > maxSessionDuration) {
      await endSession();
      return true;
    }

    // Check inactivity timeout
    if (now.difference(_lastActivityTime!) > sessionTimeout) {
      await endSession();
      return true;
    }

    return false;
  }

  /// Check session validity on app resume
  Future<bool> validateSession() async {
    try {
      final lastActivityStr = await _secureStorage.read(
        SecureStorageService.keyLastActivity,
      );
      
      if (lastActivityStr == null) {
        return false;
      }

      final lastActivity = DateTime.parse(lastActivityStr);
      final now = DateTime.now();

      // Check if session expired due to inactivity
      if (now.difference(lastActivity) > sessionTimeout) {
        await endSession();
        return false;
      }

      // Check max session duration
      final sessionExpiryStr = await _secureStorage.read(
        SecureStorageService.keySessionExpiry,
      );
      
      if (sessionExpiryStr != null) {
        final sessionExpiry = DateTime.parse(sessionExpiryStr);
        if (now.isAfter(sessionExpiry)) {
          await endSession();
          return false;
        }
      }

      // Update last activity
      _lastActivityTime = lastActivity;
      _sessionStartTime = _lastActivityTime!.subtract(
        now.difference(lastActivity),
      );
      await updateActivity();

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error validating session: $e');
      }
      return false;
    }
  }

  /// End session and logout
  Future<void> endSession() async {
    try {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _sessionStartTime = null;
      _lastActivityTime = null;

      // Clear session data
      await _secureStorage.delete(SecureStorageService.keySessionExpiry);
      await _secureStorage.delete(SecureStorageService.keyLastActivity);

      // Sign out user
      await _authService.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error ending session: $e');
      }
    }
  }

  /// Get session duration
  Duration? getSessionDuration() {
    if (_sessionStartTime == null) {
      return null;
    }
    return DateTime.now().difference(_sessionStartTime!);
  }

  /// Get time until session timeout
  Duration? getTimeUntilTimeout() {
    if (_lastActivityTime == null) {
      return null;
    }
    final timeout = _lastActivityTime!.add(sessionTimeout);
    final remaining = timeout.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
}

