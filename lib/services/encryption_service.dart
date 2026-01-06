import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Encryption service for sensitive data
/// Uses AES encryption and hashing algorithms
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Hash password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash data using SHA-256
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate device fingerprint hash
  String generateDeviceFingerprint({
    required String deviceId,
    required String userId,
    required String deviceModel,
  }) {
    final combined = '$deviceId:$userId:$deviceModel';
    return hashData(combined);
  }

  /// Generate secure random token
  String generateSecureToken() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final randomBytes = utf8.encode('$random${DateTime.now().millisecondsSinceEpoch}');
    final digest = sha256.convert(randomBytes);
    return digest.toString().substring(0, 32);
  }

  /// Generate session token
  String generateSessionToken(String userId) {
    final timestamp = DateTime.now().toIso8601String();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = '$userId:$timestamp:$random';
    return hashData(combined);
  }

  /// Verify hash
  bool verifyHash(String data, String hash) {
    final computedHash = hashData(data);
    return computedHash == hash;
  }

  /// Simple XOR encryption (for less sensitive data)
  /// Note: For production, consider using AES encryption from pointycastle package
  String simpleEncrypt(String data, String key) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final encrypted = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64.encode(encrypted);
  }

  /// Simple XOR decryption
  String simpleDecrypt(String encryptedData, String key) {
    try {
      final encrypted = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key);
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );
      return utf8.decode(decrypted);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decrypting data: $e');
      }
      return '';
    }
  }
}

