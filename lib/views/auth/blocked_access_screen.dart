import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// STRICT ACCESS CONTROL: Users blocked until authority approval
/// This screen is shown when user is authenticated but NOT approved
/// User is FORCEFULLY logged out and cannot access any society data
class BlockedAccessScreen extends StatefulWidget {
  const BlockedAccessScreen({super.key});

  @override
  State<BlockedAccessScreen> createState() => _BlockedAccessScreenState();
}

class _BlockedAccessScreenState extends State<BlockedAccessScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isChecking = false;
  String? _statusMessage;
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    try {
      final profile = await _firestoreService.getCurrentUserProfile();
      
      if (profile == null) {
        // No profile - force logout
        await _forceLogout();
        return;
      }

      setState(() {
        _statusMessage = _getStatusMessage(profile.approvalStatus);
        _rejectionReason = profile.rejectionReason;
        _isChecking = false;
      });

      // If approved, redirect to dashboard
      if (profile.approvalStatus == 'approved') {
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Error checking status. Please try again.';
      });
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your address proof is under verification by society authorities.\n\nOnly Chairman, Secretary, or Treasurer can approve your request.';
      case 'rejected':
        return 'Your registration request has been rejected by society authorities.';
      default:
        return 'Your access is pending approval.';
    }
  }

  Future<void> _forceLogout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      // Even if logout fails, navigate to login
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Disable back button - user cannot navigate back
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.spacing32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Blocked Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 60,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing32),

                  // Title
                  Text(
                    'Access Blocked',
                    style: AppStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppStyles.spacing16),

                  // Status Message
                  if (_isChecking)
                    const CircularProgressIndicator()
                  else if (_statusMessage != null) ...[
                    Text(
                      _statusMessage!,
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_rejectionReason != null && _rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: AppStyles.spacing16),
                      Container(
                        padding: const EdgeInsets.all(AppStyles.spacing16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radius12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason:',
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppStyles.spacing8),
                            Text(
                              _rejectionReason!,
                              style: AppStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: AppStyles.spacing48),

                  // Authority Info
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacing16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radius12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: AppStyles.spacing8),
                            Text(
                              'Who can approve?',
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppStyles.spacing12),
                        _buildAuthorityRow('Chairman'),
                        _buildAuthorityRow('Secretary'),
                        _buildAuthorityRow('Treasurer'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppStyles.spacing32),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: _isChecking ? null : _checkApprovalStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing32,
                        vertical: AppStyles.spacing16,
                      ),
                    ),
                    child: const Text('Refresh Status'),
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  OutlinedButton(
                    onPressed: _forceLogout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing32,
                        vertical: AppStyles.spacing16,
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorityRow(String role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacing8),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: AppStyles.spacing8),
          Text(
            role,
            style: AppStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

