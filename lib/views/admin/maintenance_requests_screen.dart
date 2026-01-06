import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/user_model.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() => _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<MaintenanceRequestModel> _pendingRequests = [];
  List<MaintenanceRequestModel> _inProgressRequests = [];
  List<MaintenanceRequestModel> _completedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMaintenanceRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all maintenance requests (not filtered by status)
      final allRequests = await _firestoreService.getAllMaintenanceRequests();

      setState(() {
        _pendingRequests = allRequests.where((r) => r.status == 'open').toList();
        _inProgressRequests = allRequests.where((r) => r.status == 'in_progress').toList();
        _completedRequests = allRequests.where((r) => r.status == 'completed' || r.status == 'closed').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load maintenance requests: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<UserModel?> _getMemberProfile(String userId) async {
    try {
      return await _firestoreService.getMemberProfile(userId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildMemberProfileSection(MaintenanceRequestModel request) {
    return FutureBuilder<UserModel?>(
      future: _getMemberProfile(request.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final member = snapshot.data;
        if (member == null) {
          // Fallback to data from request
          return Container(
            padding: const EdgeInsets.all(AppStyles.spacing8), // Reduced padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primaryLight.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppStyles.radius8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.userName,
                  style: AppStyles.heading6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppStyles.spacing4),
                Text(
                  'Flat ${request.userApartment}',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppStyles.spacing8), // Reduced padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primaryLight.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppStyles.radius8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Profile Icon/Avatar
              CircleAvatar(
                radius: 20, // Reduced radius
                backgroundColor: AppColors.primary,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spacing8),
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: AppStyles.heading6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Flat ${member.apartmentNumber}, ${member.buildingName}',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (member.mobileNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.mobileNumber,
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _updateRequestStatus(String requestId, String newStatus, String? assignedTo) async {
    try {
      final request = await _firestoreService.getMaintenanceRequestById(requestId);
      if (request == null) return;

      final updatedRequest = request.copyWith(
        status: newStatus,
        assignedTo: assignedTo ?? request.assignedTo,
        completedDate: newStatus == 'completed' ? DateTime.now() : request.completedDate,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateMaintenanceRequest(requestId, updatedRequest);
      await _loadMaintenanceRequests(); // Refresh list
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to update request: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Maintenance Requests',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingRequests(),
                _buildInProgressRequests(),
                _buildCompletedRequests(),
              ],
            ),
    );
  }

  Widget _buildPendingRequests() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No pending requests',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
      children: [
        for (final request in _pendingRequests)
          Padding(
            padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member Profile Section
                  Padding(
                    padding: const EdgeInsets.all(AppStyles.spacing8), // Reduced padding
                    child: _buildMemberProfileSection(request),
                  ),
                  const Divider(height: 1),
                  // Request Details
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    leading: const Icon(Icons.build, color: AppColors.warning),
                    title: Text(
                      request.title,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Type: ${_formatType(request.type)}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing8,
                        vertical: AppStyles.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(request.priority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                      ),
                      child: Text(
                        _formatPriority(request.priority),
                        style: AppStyles.bodySmall.copyWith(
                          color: _getPriorityColor(request.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: Text(
                      request.description,
                      style: AppStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12, vertical: 4), // Reduced padding
                    child: Text(
                      'Requested: ${_formatDate(request.requestedDate)}',
                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _updateRequestStatus(request.id, 'in_progress', null);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Start Work', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _updateRequestStatus(request.id, 'completed', null);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Complete', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  // Edit and Delete buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editRequest(request),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppStyles.spacing8),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteRequest(request),
                            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                            label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppStyles.spacing8),
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInProgressRequests() {
    if (_inProgressRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No requests in progress',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
      children: [
        for (final request in _inProgressRequests)
          Padding(
            padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member Profile Section
                  Padding(
                    padding: const EdgeInsets.all(AppStyles.spacing8), // Reduced padding
                    child: _buildMemberProfileSection(request),
                  ),
                  const Divider(height: 1),
                  // Request Details
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    leading: const Icon(Icons.build, color: AppColors.info),
                    title: Text(
                      request.title,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Type: ${_formatType(request.type)}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing8,
                        vertical: AppStyles.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: Text(
                      request.description,
                      style: AppStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12, vertical: 4), // Reduced padding
                    child: Text(
                      'Requested: ${_formatDate(request.requestedDate)}',
                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateRequestStatus(request.id, 'completed', null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Mark as Completed', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  // Edit and Delete buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editRequest(request),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppStyles.spacing8),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteRequest(request),
                            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                            label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppStyles.spacing8),
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletedRequests() {
    if (_completedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No completed requests',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
      children: [
        for (final request in _completedRequests)
          Padding(
            padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member Profile Section
                  Padding(
                    padding: const EdgeInsets.all(AppStyles.spacing8), // Reduced padding
                    child: _buildMemberProfileSection(request),
                  ),
                  const Divider(height: 1),
                  // Request Details
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    leading: const Icon(Icons.check_circle, color: AppColors.success),
                    title: Text(
                      request.title,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Type: ${_formatType(request.type)}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing8,
                        vertical: AppStyles.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                      ),
                      child: Text(
                        _formatStatus(request.status),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                    child: Text(
                      request.description,
                      style: AppStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12, vertical: 4), // Reduced padding
                    child: Text(
                      'Completed: ${request.completedDate != null ? _formatDate(request.completedDate!) : _formatDate(request.updatedAt)}',
                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  if (request.remarks != null && request.remarks!.isNotEmpty) ...[
                    const SizedBox(height: AppStyles.spacing8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing12), // Reduced padding
                      child: Container(
                        padding: const EdgeInsets.all(AppStyles.spacing8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppStyles.radius8),
                        ),
                        child: Text(
                          'Remarks: ${request.remarks}',
                          style: AppStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppStyles.spacing12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatPriority(String priority) {
    return priority.substring(0, 1).toUpperCase() + priority.substring(1);
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'plumbing':
        return 'Plumbing';
      case 'electrical':
        return 'Electrical';
      case 'elevator':
        return 'Elevator';
      case 'common_area':
        return 'Common Area';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  Future<void> _editRequest(MaintenanceRequestModel request) async {
    final result = await Get.toNamed(
      '/create-maintenance-request',
      arguments: request, // Pass request for editing
    );
    if (result == true) {
      await _loadMaintenanceRequests();
    }
  }

  Future<void> _deleteRequest(MaintenanceRequestModel request) async {
    final confirm = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppStyles.spacing16),
              Text(
                'Delete Request?',
                style: AppStyles.heading5,
              ),
              const SizedBox(height: AppStyles.spacing8),
              Text(
                'Are you sure you want to delete this maintenance request? This action cannot be undone.',
                style: AppStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyles.spacing20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textOnPrimary,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteMaintenanceRequest(request.id);
        
        if (mounted) {
          Get.snackbar(
            'Success',
            'Request deleted successfully',
            backgroundColor: AppColors.success,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 2),
          );
          await _loadMaintenanceRequests();
        }
      } catch (e) {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Failed to delete request: ${e.toString()}',
            backgroundColor: AppColors.error,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }
}

