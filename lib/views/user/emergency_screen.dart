import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

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
                        onTap: () {
                          // TODO: Send emergency alert
                        },
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
                              const Icon(
                                Icons.emergency_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SEND EMERGENCY ALERT',
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

