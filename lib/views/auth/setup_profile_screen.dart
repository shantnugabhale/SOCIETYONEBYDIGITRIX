import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/society_model.dart';

class SetupProfileScreen extends StatefulWidget {
  final String phoneNumber;
  
  const SetupProfileScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _flatNumberController = TextEditingController();
  final _buildingController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _flatNumberController.dispose();
    _buildingController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current authenticated user
        final authService = AuthService();
        final currentUser = authService.currentUser;
        
        if (currentUser == null) {
          throw Exception('User not authenticated. Please login again.');
        }

        // Get onboarding data (society/unit/role) from arguments
        final onboardingData = Get.arguments;
        SocietyModel? society;
        String? userType;
        String? phoneNumber = widget.phoneNumber;
        
        if (onboardingData is Map<String, dynamic>) {
          society = onboardingData['society'] as SocietyModel?;
          userType = onboardingData['userType'] as String?;
          phoneNumber = onboardingData['phoneNumber'] as String? ?? phoneNumber;
        }

        // Save profile to Firestore with society/unit/role data
        final firestoreService = FirestoreService();
        await firestoreService.saveMemberProfile(
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty 
              ? null 
              : _middleNameController.text.trim(),
          surname: _surnameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: phoneNumber ?? '+91',
          flatNumber: _flatNumberController.text.trim(),
          building: _buildingController.text.trim(),
          societyId: society?.id,
          societyName: society?.name,
          userType: userType,
        );

        setState(() {
          _isLoading = false;
        });

        // Show success message
        Get.snackbar(
          'Success',
          'Profile setup completed!',
          backgroundColor: AppColors.success,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );

        // STRICT ONBOARDING: Navigate to address proof upload (mandatory)
        // After upload, user will be forcefully logged out
        Get.offAllNamed('/address-proof-upload');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'Error',
          'Authentication error: ${e.message ?? 'Failed to save profile'}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'Error',
          'Failed to save profile: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
        title: Text(
          'Profile Setup',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppStyles.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppStyles.spacing32),
                      
                      // Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            size: 40,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppStyles.spacing40),
                      
                      // First Name and Surname in First Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomInputField(
                              label: 'First Name',
                              hint: 'First name',
                              controller: _firstNameController,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'First name is required';
                                }
                                if (value.length < 2) {
                                  return 'First name must be at least 2 characters';
                                }
                                return null;
                              },
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacing16),
                          Expanded(
                            child: CustomInputField(
                              label: 'Surname',
                              hint: 'Surname',
                              controller: _surnameController,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Surname is required';
                                }
                                if (value.length < 2) {
                                  return 'Surname must be at least 2 characters';
                                }
                                return null;
                              },
                              isRequired: true,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppStyles.spacing20),
                      
                      // Middle Name in Second Row
                      CustomInputField(
                        label: 'Middle Name',
                        hint: 'Middle name (optional)',
                        controller: _middleNameController,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                        isRequired: false,
                      ),
                      
                      const SizedBox(height: AppStyles.spacing20),
                      
                      // Email Field
                      CustomInputField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.primary,
                        ),
                        validator: Validators.validateEmail,
                        isRequired: true,
                      ),
                      
                      const SizedBox(height: AppStyles.spacing20),
                      
                      // Phone Number (Display only - pre-filled)
                      CustomInputField(
                        label: 'Phone Number',
                        controller: TextEditingController(text: widget.phoneNumber),
                        enabled: false,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      
                      const SizedBox(height: AppStyles.spacing20),
                      
                      // Flat Number Field
                      CustomInputField(
                        label: 'Flat Number',
                        hint: 'e.g., 201',
                        controller: _flatNumberController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.home_outlined,
                          color: AppColors.primary,
                        ),
                        validator: Validators.validateApartmentNumber,
                        isRequired: true,
                      ),
                      
                      const SizedBox(height: AppStyles.spacing20),
                      
                      // Building/Block Field
                      CustomInputField(
                        label: 'Building/Block',
                        hint: 'e.g., Block A',
                        controller: _buildingController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(
                          Icons.business_outlined,
                          color: AppColors.primary,
                        ),
                        validator: Validators.validateBuildingName,
                        isRequired: true,
                      ),
                      
                      const SizedBox(height: AppStyles.spacing40),
                      
                      // Save Profile Button
                      CustomButton(
                        text: 'Complete Setup',
                        onPressed: _handleSaveProfile,
                        isLoading: _isLoading,
                        icon: Icons.check_circle_outline,
                      ),
                      
                      const SizedBox(height: AppStyles.spacing32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
