import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/visitor_model.dart';
import '../../models/user_model.dart';
import '../../utils/format_utils.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visitor Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<VisitorModel>>(
        stream: _firestoreService.getUserVisitorsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final visitors = snapshot.data ?? [];

          if (visitors.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.person_add_rounded,
              title: 'No Visitors',
              subtitle: 'You haven\'t registered any visitors yet.\nAdd a visitor to get started',
              buttonText: 'Add Visitor',
              iconColor: AppColors.info,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: visitors.length,
              itemBuilder: (context, index) {
                return _buildVisitorCard(visitors[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVisitorDialog(),
        backgroundColor: AppColors.info,
        icon: const Icon(Icons.person_add_rounded, color: AppColors.textOnPrimary),
        label: const Text(
          'Add Visitor',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.info.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.visitorName,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      visitor.visitorPhone,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing8,
                  vertical: AppStyles.spacing4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(visitor.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Text(
                  visitor.status.toUpperCase(),
                  style: AppStyles.caption.copyWith(
                    color: _getStatusColor(visitor.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          _buildInfoRow(Icons.calendar_today, 'Expected Arrival', FormatUtils.formatDate(visitor.expectedArrival)),
          if (visitor.purpose.isNotEmpty)
            _buildInfoRow(Icons.info_outline, 'Purpose', visitor.purpose),
          if (visitor.numberOfVisitors > 1)
            _buildInfoRow(Icons.people, 'Number of Visitors', '${visitor.numberOfVisitors}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacing8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppStyles.spacing8),
          Text(
            '$label: ',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'checked_in':
        return AppColors.info;
      case 'checked_out':
        return AppColors.textSecondary;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  void _showAddVisitorDialog() {
    if (_currentUser == null) {
      Get.snackbar('Error', 'Please wait while we load your profile');
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final purposeNotifier = ValueNotifier<String>('personal');
    final arrivalDate = ValueNotifier<DateTime>(DateTime.now());

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius20),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Visitor',
                  style: AppStyles.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacing24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Visitor Name *',
                    hintText: 'Enter visitor name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppStyles.spacing16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'Enter email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppStyles.spacing16),
                ValueListenableBuilder<String>(
                  valueListenable: purposeNotifier,
                  builder: (context, selectedPurpose, _) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedPurpose,
                      decoration: const InputDecoration(
                        labelText: 'Purpose *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'personal', child: Text('Personal')),
                        DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                        DropdownMenuItem(value: 'service', child: Text('Service')),
                        DropdownMenuItem(value: 'guest', child: Text('Guest')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) purposeNotifier.value = value;
                      },
                    );
                  },
                ),
                const SizedBox(height: AppStyles.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _createVisitor(
                          nameController.text,
                          phoneController.text,
                          emailController.text,
                          purposeNotifier.value,
                          arrivalDate.value,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: const Text('Add Visitor'),
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

  Future<void> _createVisitor(
    String name,
    String phone,
    String email,
    String purpose,
    DateTime arrival,
  ) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      Get.snackbar('Error', 'Please fill in all required fields');
      return;
    }

    if (_currentUser == null) return;

    try {
      final visitor = VisitorModel(
        id: '',
        residentUserId: _currentUser!.id,
        residentName: _currentUser!.name,
        residentApartment: '${_currentUser!.buildingName} - ${_currentUser!.apartmentNumber}',
        visitorName: name.trim(),
        visitorPhone: phone.trim(),
        visitorEmail: email.trim(),
        purpose: purpose,
        expectedArrival: arrival,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createVisitor(visitor);
      Get.back(); // Close dialog
      Get.snackbar('Success', 'Visitor added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add visitor: $e');
    }
  }
}
