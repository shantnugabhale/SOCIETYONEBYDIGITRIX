import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:society_management_app/utils/validators.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/maintenance_request_model.dart';

class CreateMaintenanceRequestScreen extends StatefulWidget {
  const CreateMaintenanceRequestScreen({super.key});

  @override
  State<CreateMaintenanceRequestScreen> createState() =>
      _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState
    extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String _selectedType = 'plumbing';
  String _selectedPriority = 'medium';
  String _requestVisibility = 'personal'; // 'personal' or 'public'
  bool _isLoading = false;
  MaintenanceRequestModel? _editingRequest; // Track if editing

  @override
  void initState() {
    super.initState();
    // Check if we're editing an existing request
    final args = Get.arguments;
    if (args != null && args is MaintenanceRequestModel) {
      _editingRequest = args;
      
      // Verify that current user is the creator of this request
      final currentUser = _authService.currentUser;
      if (currentUser == null || _editingRequest!.userId != currentUser.uid) {
        // User is not the creator - prevent editing
        Get.back();
        Get.snackbar(
          'Error',
          'You can only edit your own maintenance requests',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
        return;
      }
      
      _loadRequestData(_editingRequest!);
    }
  }

  void _loadRequestData(MaintenanceRequestModel request) {
    _titleController.text = request.title;
    _descriptionController.text = request.description;
    _selectedType = request.type;
    _selectedPriority = request.priority;
    _requestVisibility = request.isPublic ? 'public' : 'personal';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showSuccessPopup({required bool isUpdate}) async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppStyles.spacing16),
              
              // Title
              Text(
                isUpdate ? 'Request Updated!' : 'Request Created!',
                style: AppStyles.heading5,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyles.spacing8),
              
              // Message
              Text(
                isUpdate 
                  ? 'Your maintenance request has been updated successfully. You will receive notifications for status updates.'
                  : 'Maintenance request sent for admin. You will receive notifications for status updates.',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyles.spacing24),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppStyles.spacing12),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }


  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get user profile for name and apartment
        final userProfile = await _firestoreService.getCurrentUserProfile();
        final userName = userProfile?.name ?? 'Unknown User';
        final userApartment = userProfile != null
            ? '${userProfile.buildingName}-${userProfile.apartmentNumber}'
            : 'N/A';

        final now = DateTime.now();
        
        if (_editingRequest != null) {
          // Update existing request
          final updatedRequest = _editingRequest!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _selectedType,
            priority: _selectedPriority,
            isPublic: _requestVisibility == 'public',
            updatedAt: now,
          );
          
          await _firestoreService.updateMaintenanceRequest(_editingRequest!.id, updatedRequest);
          
          if (mounted) {
            // Show success popup
            await _showSuccessPopup(isUpdate: true);
            Get.back(result: true);
          }
        } else {
          // Create new request
          final request = MaintenanceRequestModel(
            id: '', // Will be set by Firestore
            userId: user.uid,
            userName: userName,
            userApartment: userApartment,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _selectedType,
            priority: _selectedPriority,
            status: 'open',
            requestedDate: now,
            createdAt: now,
            updatedAt: now,
            isPublic: _requestVisibility == 'public',
          );

          await _firestoreService.createMaintenanceRequest(request);

          if (mounted) {
            // Show success popup
            await _showSuccessPopup(isUpdate: false);
            
            // Return true to indicate success
            Get.back(result: true);
          }
        }
      } catch (e) {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Failed to submit request: ${e.toString()}',
            backgroundColor: AppColors.error,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 3),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
        appBar: AppBar(
        title: Text(
          _editingRequest != null ? 'Edit Maintenance Request' : AppStrings.maintenanceRequest,
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Request Type
              CustomDropdownField<String>(
                label: AppStrings.requestType,
                value: _selectedType,
                isRequired: true,
                items: const [
                  DropdownMenuItem(
                    value: 'plumbing',
                    child: Text('Plumbing'),
                  ),
                  DropdownMenuItem(
                    value: 'electrical',
                    child: Text('Electrical'),
                  ),
                  DropdownMenuItem(
                    value: 'elevator',
                    child: Text('Elevator'),
                  ),
                  DropdownMenuItem(
                    value: 'common_area',
                    child: Text('Common Area'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? 'other';
                  });
                },
              ),
              
              const SizedBox(height: AppStyles.spacing20),
              
              // Priority
              CustomDropdownField<String>(
                label: AppStrings.priority,
                value: _selectedPriority,
                isRequired: true,
                items: const [
                  DropdownMenuItem(
                    value: 'low',
                    child: Text('Low - Not urgent'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Medium - Needs attention'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('High - Urgent'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'medium';
                  });
                },
              ),
              
              const SizedBox(height: AppStyles.spacing20),
              
              // Request Visibility (Personal/Public)
              CustomDropdownField<String>(
                label: 'Visibility',
                hint: 'Select request visibility',
                value: _requestVisibility,
                isRequired: true,
                items: const [
                  DropdownMenuItem(
                    value: 'personal',
                    child: Text('Personal - Only visible to me'),
                  ),
                  DropdownMenuItem(
                    value: 'public',
                    child: Text('Public - Visible to all members'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _requestVisibility = value ?? 'personal';
                  });
                },
              ),
              
              const SizedBox(height: AppStyles.spacing20),

              // Title Field
              CustomInputField(
                label: 'Title',
                hint: 'e.g., "Tap leaking in kitchen"',
                controller: _titleController,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.validateRequired(value, 'Title'),
                isRequired: true,
              ),

              const SizedBox(height: AppStyles.spacing20),
              
              // Description Field
              CustomInputField(
                label: AppStrings.description,
                hint: 'Provide more details about the issue...',
                controller: _descriptionController,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    Validators.validateMinLength(value, 10, 'Description'),
                isRequired: true,
              ),
              
              const SizedBox(height: AppStyles.spacing32),
              
              // Submit Button
              CustomButton(
                text: _editingRequest != null ? 'Update Request' : AppStrings.submit,
                onPressed: _handleSubmit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}