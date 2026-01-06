import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage service for storing sensitive data
/// Uses device keychain/keystore for encryption at rest
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // iOS and Android configuration
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  /// Store sensitive data securely
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error writing to secure storage: $e');
      }
      rethrow;
    }
  }

  /// Read sensitive data securely
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading from secure storage: $e');
      }
      return null;
    }
  }

  /// Delete sensitive data
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting from secure storage: $e');
      }
    }
  }

  /// Delete all secure data (for logout)
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting all from secure storage: $e');
      }
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking key in secure storage: $e');
      }
      return false;
    }
  }

  /// Read all keys
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading all from secure storage: $e');
      }
      return {};
    }
  }

  // Keys for secure storage
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyDeviceId = 'device_id';
  static const String keySessionExpiry = 'session_expiry';
  static const String keyLastActivity = 'last_activity';
  static const String keyTrustedDevice = 'trusted_device';
}

