import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

/// STRICT PENDING VERIFICATION SCREEN (LOCKED MODE)
/// 
/// This screen is shown when approvalStatus == 'pending' or 'rejected'
/// 
/// Restrictions:
/// - No back navigation
/// - No bottom tabs
/// - No drawer
/// - No deep linking
/// - No API access to society data
/// - ONLY Logout button enabled
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isChecking = false;

  /// Check approval status (Refresh Status button)
  Future<void> _checkApprovalStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final profile = await _firestoreService.getCurrentUserProfile();
      if (profile != null && profile.approvalStatus == 'approved') {
        // Approved - redirect to dashboard
        Get.offAllNamed('/dashboard');
      } else {
        // Still pending or rejected
        Get.snackbar(
          'Info',
          profile?.approvalStatus == 'rejected'
              ? 'Your request has been rejected. Please contact society committee.'
              : 'Your request is still pending approval',
          backgroundColor: AppColors.info,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check status: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Logout (ONLY enabled action)
  Future<void> _logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      Get.offAllNamed('/app-entry');
    }
  }

  /// STRICT: Block back navigation
  void _onWillPop() {
    // Prevent back navigation - user must logout
    Get.snackbar(
      'Access Restricted',
      'Please logout to exit',
      backgroundColor: AppColors.warning,
      colorText: AppColors.textOnPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        // STRICT: No AppBar (prevents back button)
        appBar: null,
        // STRICT: No bottom navigation
        bottomNavigationBar: null,
        // STRICT: No drawer
        drawer: null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spacing32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        size: 60,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing32),
                    
                    // Title
                    Text(
                      'Address Proof Verification Pending',
                      style: AppStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    
                    // Message
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spacing20),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your address proof is under verification by society committee members.',
                            style: AppStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppStyles.spacing12),
                          Text(
                            'You will get access to all features after approval.',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing32),
                    
                    // Committee Info
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: AppStyles.spacing8),
                              Text(
                                'Verification by:',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spacing8),
                          _buildCommitteeRole('Chairman'),
                          _buildCommitteeRole('Secretary'),
                          _buildCommitteeRole('Treasurer'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing48),
                    
                    // Refresh Status Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkApprovalStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacing32,
                            vertical: AppStyles.spacing16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radius12),
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded),
                                  SizedBox(width: 8),
                                  Text('Refresh Status'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    
                    // Logout Button (ONLY enabled action)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacing32,
                            vertical: AppStyles.spacing16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radius12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommitteeRole(String role) {
    return Padding(
      padding: const EdgeInsets.only(top: AppStyles.spacing8),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppStyles.spacing8),
          Text(
            role,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

