import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/maintenance_request_model.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<MaintenanceRequestModel> _activeRequests = [];
  List<MaintenanceRequestModel> _historyRequests = [];
  
  // Check if current user is the creator of the request
  bool _isRequestCreator(MaintenanceRequestModel request) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;
    return request.userId == currentUser.uid;
  }

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRequests();
  }

  Future<void> _loadMaintenanceRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _firestoreService.getUserMaintenanceRequests();
      
      setState(() {
        _activeRequests = requests.where((r) => r.isActiveRequest).toList();
        _historyRequests = requests.where((r) => !r.isActiveRequest || r.isCompleted || r.isClosed).toList();
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

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
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

  String _formatPriority(String priority) {
    return priority.substring(0, 1).toUpperCase() + priority.substring(1);
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.maintenance,
            style: AppStyles.heading6.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Active Requests'),
              Tab(text: 'History'),
            ],
            indicatorColor: AppColors.textOnPrimary,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
            labelStyle: AppStyles.bodyLarge,
            unselectedLabelStyle: AppStyles.bodyMedium,
            dividerColor: Colors.transparent,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildActiveRequests(),
                  _buildHistoryRequests(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Get.toNamed('/create-maintenance-request');
            if (result == true) {
              // Request was successfully created
              await _loadMaintenanceRequests(); // Refresh after returning
            } else {
              // Just refresh in case something changed
              _loadMaintenanceRequests();
            }
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.textOnPrimary),
        ),
      ),
    );
  }

  /// Builds the list for the "Active Requests" tab
  Widget _buildActiveRequests() {
    if (_activeRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No active requests',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final request in _activeRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Info Section
                    Container(
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppStyles.radius12),
                          topRight: Radius.circular(AppStyles.radius12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request.userApartment,
                                        style: AppStyles.heading6.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (request.isPublic)
                                      Container(
                                        margin: const EdgeInsets.only(left: AppStyles.spacing8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppStyles.spacing8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppStyles.radius4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.public,
                                              size: 12,
                                              color: AppColors.info,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Public',
                                              style: AppStyles.caption.copyWith(
                                                color: AppColors.info,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacing12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppStyles.spacing8, // Reduced padding
                              vertical: 4, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                            ),
                            child: Text(
                              _formatStatus(request.status).toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(request.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Request Details
                    Padding(
                      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.title,
                                      style: AppStyles.heading6.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppStyles.spacing4),
                                    Text(
                                      request.description,
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spacing12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.priority_high,
                                    size: 16,
                                    color: _getPriorityColor(request.priority),
                                  ),
                                  const SizedBox(width: AppStyles.spacing4),
                                  Text(
                                    _formatPriority(request.priority).toUpperCase(),
                                    style: AppStyles.bodySmall.copyWith(
                                      color: _getPriorityColor(request.priority),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatDate(request.requestedDate),
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Edit and Delete buttons (only for open/in_progress requests and only if user is the creator)
                          if ((request.status == 'open' || request.status == 'in_progress') && _isRequestCreator(request)) ...[
                            const SizedBox(height: AppStyles.spacing12),
                            Row(
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
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the list for the "History" tab
  Widget _buildHistoryRequests() {
    if (_historyRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No history requests',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final request in _historyRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Info Section
                    Container(
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppStyles.radius12),
                          topRight: Radius.circular(AppStyles.radius12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request.userApartment,
                                        style: AppStyles.heading6.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (request.isPublic)
                                      Container(
                                        margin: const EdgeInsets.only(left: AppStyles.spacing8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppStyles.spacing8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppStyles.radius4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.public,
                                              size: 12,
                                              color: AppColors.info,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Public',
                                              style: AppStyles.caption.copyWith(
                                                color: AppColors.info,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacing12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppStyles.spacing8, // Reduced padding
                              vertical: 4, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                            ),
                            child: Text(
                              _formatStatus(request.status).toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(request.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Request Details
                    Padding(
                      padding: const EdgeInsets.all(AppStyles.spacing12), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.title,
                                      style: AppStyles.heading6.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppStyles.spacing4),
                                    Text(
                                      request.description,
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spacing12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.priority_high,
                                    size: 16,
                                    color: _getPriorityColor(request.priority),
                                  ),
                                  const SizedBox(width: AppStyles.spacing4),
                                  Text(
                                    _formatPriority(request.priority).toUpperCase(),
                                    style: AppStyles.bodySmall.copyWith(
                                      color: _getPriorityColor(request.priority),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatDate(request.requestedDate),
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Edit and Delete buttons (only for open/in_progress requests in history and only if user is the creator)
                          if ((request.status == 'open' || request.status == 'in_progress') && _isRequestCreator(request)) ...[
                            const SizedBox(height: AppStyles.spacing12),
                            Row(
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
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      case 'in_progress':
        return AppColors.info;
      case 'open':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
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
