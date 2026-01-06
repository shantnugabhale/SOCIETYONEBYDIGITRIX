import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _flatNumberController = TextEditingController();
  final _buildingController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      final firestoreService = FirestoreService();
      final profile = await firestoreService.getCurrentUserProfile();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
          
          // Populate controllers with fetched data
          if (profile != null) {
            _nameController.text = profile.name;
            _emailController.text = profile.email;
            _mobileController.text = profile.mobileNumber;
            _flatNumberController.text = profile.apartmentNumber;
            _buildingController.text = profile.buildingName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        Get.snackbar(
          'Error',
          'Failed to load profile: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _flatNumberController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Cancel editing - reload original data
      if (_userProfile != null) {
        _nameController.text = _userProfile!.name;
        _emailController.text = _userProfile!.email;
        _mobileController.text = _userProfile!.mobileNumber;
        _flatNumberController.text = _userProfile!.apartmentNumber;
        _buildingController.text = _userProfile!.buildingName;
      }
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final firestoreService = FirestoreService();
        
        // Parse name into first, middle, surname
        final nameParts = _nameController.text.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
        final surname = nameParts.length > 1 ? nameParts.last : '';
        final middleName = nameParts.length > 2 
            ? nameParts.sublist(1, nameParts.length - 1).join(' ') 
            : null;

        // Update profile in Firestore
        await firestoreService.updateMemberProfile(
          firstName: firstName,
          middleName: middleName?.isEmpty ?? true ? null : middleName,
          surname: surname,
          email: _emailController.text.trim(),
          flatNumber: _flatNumberController.text.trim(),
          building: _buildingController.text.trim(),
        );

        // Reload profile to get updated data
        await _loadUserProfile();

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        Get.snackbar(
          'Success',
          'Profile updated successfully!',
          backgroundColor: AppColors.success,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'Error',
          'Failed to update profile: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final authService = AuthService();
                await authService.signOut();
                Get.offAllNamed('/login');
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to logout: ${e.toString()}',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.textOnPrimary,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.profile,
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppStyles.spacing24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyles.radius16),
                  boxShadow: AppStyles.shadowSmall,
                ),
                child: Column(
                  children: [
                    // Profile Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: AppStyles.shadowMedium,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    _isLoadingProfile
                        ? const CircularProgressIndicator()
                        : Text(
                            _userProfile?.name ?? 'Loading...',
                            style: AppStyles.heading5.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                    const SizedBox(height: AppStyles.spacing4),
                    _isLoadingProfile
                        ? const SizedBox(height: 20)
                        : Text(
                            _userProfile != null && 
                            _userProfile!.apartmentNumber.isNotEmpty &&
                            _userProfile!.buildingName.isNotEmpty
                                ? 'Flat ${_userProfile!.apartmentNumber}, ${_userProfile!.buildingName}'
                                : 'No address set',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppStyles.spacing24),
              
              // Personal Information
              Text(
                'Personal Information',
                style: AppStyles.heading5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyles.spacing16),
              
              CustomInputField(
                label: 'Full Name',
                controller: _nameController,
                enabled: _isEditing,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
                isRequired: true,
              ),
              
              const SizedBox(height: AppStyles.spacing20),
              
              CustomInputField(
                label: AppStrings.email,
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.emailRequired;
                  }
                  if (!GetUtils.isEmail(value)) {
                    return AppStrings.emailInvalid;
                  }
                  return null;
                },
                isRequired: true,
              ),
              
              const SizedBox(height: AppStyles.spacing20),
              
              CustomInputField(
                label: 'Mobile Number',
                controller: _mobileController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  return null;
                },
                isRequired: true,
              ),
              
              const SizedBox(height: AppStyles.spacing24),
              
              // Address Information
              Text(
                'Address Information',
                style: AppStyles.heading5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyles.spacing16),
              
              CustomInputField(
                label: 'Flat Number',
                controller: _flatNumberController,
                enabled: _isEditing,
                prefixIcon: const Icon(
                  Icons.home_outlined,
                  color: AppColors.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Flat number is required';
                  }
                  return null;
                },
                isRequired: true,
              ),
              
              const SizedBox(height: AppStyles.spacing20),
              
              CustomInputField(
                label: 'Building/Block',
                controller: _buildingController,
                enabled: _isEditing,
                prefixIcon: const Icon(
                  Icons.business_outlined,
                  color: AppColors.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Building is required';
                  }
                  return null;
                },
                isRequired: true,
              ),
              
              const SizedBox(height: AppStyles.spacing32),
              
              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        type: ButtonType.outline,
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing16),
                    Expanded(
                      child: CustomButton(
                        text: 'Save Changes',
                        onPressed: _handleSave,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                CustomButton(
                  text: 'Edit Profile',
                  onPressed: _toggleEdit,
                ),
                const SizedBox(height: AppStyles.spacing16),
                CustomButton(
                  text: AppStrings.logout,
                  type: ButtonType.outline,
                  onPressed: _handleLogout,
                ),
              ],
              
              const SizedBox(height: AppStyles.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
