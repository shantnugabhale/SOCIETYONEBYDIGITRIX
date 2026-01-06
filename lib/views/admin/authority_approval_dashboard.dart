import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/card_widget.dart';
import '../../utils/format_utils.dart';

/// Authority Approval Dashboard
/// Only Chairman, Secretary, or Treasurer can access
/// Shows pending user registrations with address proof
class AuthorityApprovalDashboard extends StatefulWidget {
  const AuthorityApprovalDashboard({super.key});

  @override
  State<AuthorityApprovalDashboard> createState() => _AuthorityApprovalDashboardState();
}

class _AuthorityApprovalDashboardState extends State<AuthorityApprovalDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      if (user == null || !_firestoreService.isCommitteeMember(user)) {
        // Not a committee member - redirect
        Get.offAllNamed('/dashboard');
        return;
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load user data');
    }
  }

  Future<void> _approveUser(UserModel user) async {
    if (_currentUser == null || _currentUser!.committeeRole == null) {
      Get.snackbar('Error', 'Unauthorized');
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Approve User'),
        content: Text('Approve ${user.name} (${user.buildingName} - ${user.apartmentNumber})?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.approveUserByAuthority(
        user.id,
        _currentUser!.id,
        _currentUser!.committeeRole!,
      );
      Get.snackbar(
        'Success',
        'User approved successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    if (_currentUser == null || _currentUser!.committeeRole == null) {
      Get.snackbar('Error', 'Unauthorized');
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter a reason');
                return;
              }
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.rejectUserByAuthority(
        user.id,
        reasonController.text.trim(),
        _currentUser!.id,
        _currentUser!.committeeRole!,
      );
      Get.snackbar(
        'Success',
        'User rejected',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reject: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _viewAddressProof(UserModel user) {
    if (user.addressProofUrl == null || user.addressProofUrl!.isEmpty) {
      Get.snackbar('Info', 'No address proof uploaded');
      return;
    }

    Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Address Proof'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              Expanded(
                child: Image.network(
                  user.addressProofUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Failed to load image'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null || !_firestoreService.isCommitteeMember(_currentUser)) {
      return const Scaffold(
        body: Center(child: Text('Unauthorized')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pending Approvals (${_currentUser!.committeeRole?.toUpperCase()})'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _currentUser!.societyId != null
            ? _firestoreService.getPendingApprovalsForSociety(_currentUser!.societyId!)
            : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final pendingUsers = snapshot.data ?? [];

          if (pendingUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  Text(
                    'No Pending Approvals',
                    style: AppStyles.heading5,
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  Text(
                    'All users have been approved',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppStyles.spacing16),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              return _buildPendingUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingUserCard(UserModel user) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: AppStyles.heading6.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${user.buildingName} - ${user.apartmentNumber}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${user.userType.toUpperCase()} • ${FormatUtils.formatDate(user.createdAt)}',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          if (user.addressProofUrl != null && user.addressProofUrl!.isNotEmpty) ...[
            InkWell(
              onTap: () => _viewAddressProof(user),
              child: Container(
                padding: const EdgeInsets.all(AppStyles.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppStyles.spacing8),
                    const Text('View Address Proof'),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppStyles.spacing12),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppStyles.radius8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppStyles.spacing8),
                  const Text('No address proof uploaded'),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacing12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectUser(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: ElevatedButton(
                  onPressed: user.addressProofUrl != null && user.addressProofUrl!.isNotEmpty
                      ? () => _approveUser(user)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

