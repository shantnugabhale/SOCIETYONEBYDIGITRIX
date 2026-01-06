import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/input_field.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController(); 
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
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    try {
      final authService = AuthService();
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        // User is already logged in - check if super admin first
        final phoneNumber = currentUser.phoneNumber ?? '+91';
        final firestoreService = FirestoreService();
        final superAdmin = await firestoreService.getSuperAdminByMobile(phoneNumber);
        
        if (mounted) {
          if (superAdmin != null) {
            // Super Admin - redirect to super admin dashboard
            Get.offAllNamed('/super-admin/dashboard');
            return;
          }
          
          // Check if regular admin
          final isAdmin = await firestoreService.isAdmin(phoneNumber);
          if (isAdmin) {
            // Admin user - redirect to admin dashboard
            Get.offAllNamed('/admin-dashboard');
            return;
          }
          
          // Not admin - check profile
          final profile = await firestoreService.getCurrentUserProfile();
          
          if (mounted) {
            if (profile != null) {
              // STRICT GATEKEEPER: Check approval status
              if (profile.approvalStatus == 'approved') {
                Get.offAllNamed('/dashboard');
              } else {
                // Pending or rejected - show pending screen
                Get.offAllNamed('/pending-approval');
              }
            } else {
              // User authenticated but no profile
              Get.offAllNamed('/setup-profile', arguments: phoneNumber);
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors and stay on login screen
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get phone number and ensure it has +91 prefix
        String phoneNumber = _mobileController.text.trim();
        // Remove any existing +91 and non-digits, then add +91
        final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final fullPhoneNumber = '+91$cleanedNumber';

        // Send OTP using Firebase Auth
        final authService = AuthService();
        await authService.sendOTP(fullPhoneNumber);

        setState(() {
          _isLoading = false;
        });

        // Navigate to OTP verification screen immediately (don't wait for snackbar)
        Get.toNamed(
          '/mobile-otp-verification',
          arguments: fullPhoneNumber,
        );

        // Show success message after navigation (non-blocking)
        // Only show snackbar if Get.context is available
        Future.delayed(const Duration(milliseconds: 500), () {
          if (Get.context != null && Get.isSnackbarOpen == false) {
            try {
              Get.snackbar(
                'OTP Sent',
                'OTP has been sent to $fullPhoneNumber',
                backgroundColor: AppColors.success,
                colorText: AppColors.textOnPrimary,
                duration: const Duration(seconds: 2),
              );
            } catch (e) {
              debugPrint('Error showing snackbar: $e');
            }
          }
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Failed to send OTP';
        switch (e.code) {
          case 'invalid-phone-number':
            errorMessage = 'Invalid phone number format';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later';
            break;
          case 'quota-exceeded':
            errorMessage = 'SMS quota exceeded. Please try again later';
            break;
          default:
            errorMessage = e.message ?? 'Failed to send OTP';
        }

        Get.snackbar(
          'Error',
          errorMessage,
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
          'Failed to send OTP: ${e.toString()}',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Top decorative elements
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Stack(
                        children: [
                          // Animated background circles
                          Positioned(
                            top: -50,
                            right: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 50,
                            left: -30,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          // Logo and Welcome
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.home_work_rounded,
                                    size: 60,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing16),
                                Text(
                                  'Welcome Back!',
                                  style: AppStyles.heading1.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppStyles.spacing4),
                                Text(
                                  'Your community, connected',
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Login Form Card
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppStyles.spacing24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppStyles.spacing16),
                              Text(
                                'Sign In',
                                style: AppStyles.heading3.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppStyles.spacing8),
                              Text(
                                'Enter your phone number to continue',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                
                              const SizedBox(height: AppStyles.spacing32),
                              
                              // Mobile Number Field
                              CustomInputField(
                                label: AppStrings.mobileNumber,
                                hint: 'Enter your 10-digit mobile number',
                                controller: _mobileController,
                                keyboardType: TextInputType.phone, 
                                textInputAction: TextInputAction.done,
                                prefixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, right: 12),
                                      child: Text(
                                        '+91',
                                        style: AppStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      color: AppColors.grey300,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppStrings.mobileRequired;
                                  }
                                  final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
                                  if (cleanedValue.length != 10) {
                                    return 'Please enter a valid 10-digit mobile number';
                                  }
                                  return null;
                                },
                                isRequired: true,
                              ),
                              
                              const SizedBox(height: AppStyles.spacing32),
                              
                              // Send OTP Button with gradient
                              Material(
                                elevation: 0,
                                borderRadius: BorderRadius.circular(AppStyles.radius16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                    ),
                                    borderRadius: BorderRadius.circular(AppStyles.radius16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isLoading ? null : _handleSendOtp,
                                      borderRadius: BorderRadius.circular(AppStyles.radius16),
                                      child: Container(
                                        width: double.infinity,
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppStyles.spacing24,
                                          vertical: AppStyles.spacing12,
                                        ),
                                        child: _isLoading
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Continue',
                                                    style: AppStyles.button.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: AppStyles.spacing24),
                              
                              // Trust indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.security, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Secure & Private',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}