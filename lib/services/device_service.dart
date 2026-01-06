import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'encryption_service.dart';
import 'secure_storage_service.dart';

/// Device management service for device fingerprinting and trusted device management
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final EncryptionService _encryption = EncryptionService();
  final SecureStorageService _secureStorage = SecureStorageService();

  String? _deviceId;
  String? _deviceFingerprint;

  /// Get device ID
  Future<String> getDeviceId() async {
    if (_deviceId != null) {
      return _deviceId!;
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else {
        _deviceId = 'unknown';
      }

      // Store device ID securely
      if (_deviceId != null && _deviceId != 'unknown') {
        await _secureStorage.write(
          SecureStorageService.keyDeviceId,
          _deviceId!,
        );
      }

      return _deviceId ?? 'unknown';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting device ID: $e');
      }
      return 'unknown';
    }
  }

  /// Get device model information
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      Map<String, String> info = {
        'deviceId': deviceId,
      };

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info.addAll({
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt.toString(),
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info.addAll({
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor ?? 'unknown',
        });
      } else {
        info['platform'] = 'Unknown';
      }

      return info;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting device info: $e');
      }
      return {'deviceId': 'unknown', 'platform': 'Unknown'};
    }
  }

  /// Generate device fingerprint
  Future<String> generateDeviceFingerprint(String userId) async {
    if (_deviceFingerprint != null) {
      return _deviceFingerprint!;
    }

    try {
      final deviceInfo = await getDeviceInfo();
      final deviceId = deviceInfo['deviceId'] ?? 'unknown';
      final deviceModel = '${deviceInfo['brand'] ?? ''} ${deviceInfo['model'] ?? ''}'.trim();

      _deviceFingerprint = _encryption.generateDeviceFingerprint(
        deviceId: deviceId,
        userId: userId,
        deviceModel: deviceModel,
      );

      return _deviceFingerprint!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating device fingerprint: $e');
      }
      return 'unknown';
    }
  }

  /// Check if device is trusted
  Future<bool> isTrustedDevice(String userId) async {
    try {
      final storedFingerprint = await _secureStorage.read(
        SecureStorageService.keyTrustedDevice,
      );

      if (storedFingerprint == null) {
        return false;
      }

      final currentFingerprint = await generateDeviceFingerprint(userId);
      return storedFingerprint == currentFingerprint;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking trusted device: $e');
      }
      return false;
    }
  }

  /// Mark device as trusted
  Future<void> markAsTrusted(String userId) async {
    try {
      final fingerprint = await generateDeviceFingerprint(userId);
      await _secureStorage.write(
        SecureStorageService.keyTrustedDevice,
        fingerprint,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking device as trusted: $e');
      }
    }
  }

  /// Remove trusted device status
  Future<void> removeTrustedDevice() async {
    try {
      await _secureStorage.delete(SecureStorageService.keyTrustedDevice);
      _deviceFingerprint = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing trusted device: $e');
      }
    }
  }

  /// Get device display name
  Future<String> getDeviceDisplayName() async {
    try {
      final deviceInfo = await getDeviceInfo();
      if (Platform.isAndroid) {
        return '${deviceInfo['brand'] ?? 'Android'} ${deviceInfo['model'] ?? 'Device'}';
      } else if (Platform.isIOS) {
        return '${deviceInfo['name'] ?? 'iOS'} ${deviceInfo['model'] ?? 'Device'}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}

