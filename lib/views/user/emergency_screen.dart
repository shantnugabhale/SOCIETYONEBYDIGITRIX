import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/emergency_model.dart';
import '../../services/auth_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isSending = false;

  Future<void> _sendEmergencyAlert(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        title: const Text('Confirm Emergency Alert'),
        content: const Text(
          'This will send an emergency alert to all admins and emergency contacts. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      final user = await _firestoreService.getCurrentUserProfile();
      if (user == null) {
        Get.snackbar('Error', 'User not found');
        return;
      }

      final alert = EmergencyAlertModel(
        id: '',
        userId: _authService.currentUser?.uid ?? '',
        userName: user.name,
        userApartment: '${user.buildingName} - ${user.apartmentNumber}',
        userPhone: user.mobileNumber,
        emergencyType: 'medical',
        severity: 'high',
        description: 'Emergency alert sent from mobile app',
        location: '${user.buildingName} - ${user.apartmentNumber}',
        status: 'active',
        alertTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createEmergencyAlert(alert);
      
      if (mounted) {
        Get.snackbar(
          'Alert Sent',
          'Emergency alert has been sent to all contacts',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to send alert: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.error.withValues(alpha: 0.1),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spacing32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppStyles.spacing32),
                Text(
                  'Emergency Alert',
                  style: AppStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyles.spacing12),
                Text(
                  'Use this only in case of a real emergency.\nYour alert will be sent to all admins and emergency contacts.',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyles.spacing48),
                Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(AppStyles.radius16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.error, Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radius16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.5),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSending ? null : () => _sendEmergencyAlert(context),
                        borderRadius: BorderRadius.circular(AppStyles.radius16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacing24,
                            vertical: AppStyles.spacing16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSending)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.emergency_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              if (!_isSending) const SizedBox(width: 12),
                              Text(
                                _isSending ? 'SENDING...' : 'SEND EMERGENCY ALERT',
                                style: AppStyles.button.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'This will notify all emergency contacts',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
