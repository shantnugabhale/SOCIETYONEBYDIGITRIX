import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Biometric authentication service
/// Supports fingerprint, face ID, and other biometric methods
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting available biometrics: $e');
      }
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        if (kDebugMode) {
          debugPrint('Biometric authentication not available');
        }
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometrics, not device PIN/pattern
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error during biometric authentication: $e');
      }
      return false;
    }
  }

  /// Stop authentication (if in progress)
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping authentication: $e');
      }
      return false;
    }
  }

  /// Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.iris:
        return 'Iris';
      default:
        return 'Biometric';
    }
  }

  /// Get user-friendly biometric description
  Future<String> getBiometricDescription() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return 'Biometric authentication not available';
      }

      final types = biometrics.map((b) => getBiometricTypeName(b)).toList();
      if (types.length == 1) {
        return types.first;
      }
      return types.join(' or ');
    } catch (e) {
      return 'Biometric authentication';
    }
  }
}

