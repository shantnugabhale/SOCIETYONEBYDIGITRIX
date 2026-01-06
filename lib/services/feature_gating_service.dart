import '../models/society_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Service to manage feature-based billing and access control
class FeatureGatingService {
  static final FeatureGatingService _instance = FeatureGatingService._internal();
  factory FeatureGatingService() => _instance;
  FeatureGatingService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Master list of all available features
  static const Map<String, String> MASTER_FEATURES = {
    'notice_board': 'Notice Board',
    'visitor_management': 'Visitor Management',
    'maintenance_complaints': 'Maintenance Complaints',
    'billing_payments': 'Billing & Payments',
    'resident_directory': 'Resident Directory',
    'community_chat': 'Community Chat',
    'parking_management': 'Parking Management',
    'document_repository': 'Document Repository',
    'emergency_alerts': 'Emergency Alerts',
    'gatekeeper_app': 'Gatekeeper App',
    'facility_booking': 'Facility Booking',
    'forum_discussions': 'Forum Discussions',
    'polls_surveys': 'Polls & Surveys',
    'events_calendar': 'Events & Calendar',
    'package_tracking': 'Package Tracking',
  };

  /// Check if a feature is enabled for the current user's society
  Future<bool> isFeatureEnabled(String featureKey) async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      if (user == null || user.societyId == null) {
        return false;
      }

      final society = await _firestoreService.getSocietyById(user.societyId!);
      if (society == null) {
        return false;
      }

      return society.enabledFeatures[featureKey] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if a feature is enabled for a specific society
  Future<bool> isFeatureEnabledForSociety(String societyId, String featureKey) async {
    try {
      final society = await _firestoreService.getSocietyById(societyId);
      if (society == null) {
        return false;
      }

      return society.enabledFeatures[featureKey] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all enabled features for current user's society
  Future<List<String>> getEnabledFeatures() async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      if (user == null || user.societyId == null) {
        return [];
      }

      final society = await _firestoreService.getSocietyById(user.societyId!);
      if (society == null) {
        return [];
      }

      return society.enabledFeatures.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all available features (master list)
  static Map<String, String> getAllFeatures() {
    return MASTER_FEATURES;
  }

  /// Get feature display name
  static String getFeatureName(String featureKey) {
    return MASTER_FEATURES[featureKey] ?? featureKey;
  }
}

