import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class MobileOtpVerificationScreen extends StatefulWidget {
  const MobileOtpVerificationScreen({super.key});

  @override
  State<MobileOtpVerificationScreen> createState() => _MobileOtpVerificationScreenState();
  
  static String? phoneNumber;
}

class _MobileOtpVerificationScreenState extends State<MobileOtpVerificationScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;
  bool _canResend = false;
  Timer? _timer;
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
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer <= 0) {
          timer.cancel();
          setState(() {
            _canResend = true;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _getPhoneNumber() {
    final args = Get.arguments;
    if (args != null && args is String) {
      MobileOtpVerificationScreen.phoneNumber = args;
    }
    return MobileOtpVerificationScreen.phoneNumber ?? '+91 98765 43210';
  }

  void _handleOtpVerification() async {
    // Prevent multiple simultaneous verifications
    if (_isLoading) {
      return;
    }

    String otp = _otpControllers.map((controller) => controller.text).join().trim();
    
    // Validate OTP format
    if (otp.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter complete 6-digit OTP',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    // Validate that OTP contains only digits
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      Get.snackbar(
        'Error',
        'OTP must contain only numbers',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP using Firebase Auth
      final authService = AuthService();
      final userCredential = await authService.verifyOTP(otp).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Verification timeout. Please try again.');
        },
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Get authenticated user's phone number from Firebase Auth (most reliable)
      final authenticatedUser = userCredential.user;
      final phoneNumberFromAuth = authenticatedUser?.phoneNumber;
      
      // Fallback to argument phone number if auth phone is null
      final phoneNumber = phoneNumberFromAuth ?? _getPhoneNumber();

      // Check if phone number belongs to super admin FIRST
      final firestoreService = FirestoreService();
      final superAdmin = await firestoreService.getSuperAdminByMobile(phoneNumber).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      if (!mounted) return;

      if (superAdmin != null) {
        // Super Admin - navigate to super admin dashboard
        Get.offAllNamed('/super-admin/dashboard');
        return;
      }

      // Check if phone number belongs to regular admin
      final isAdmin = await firestoreService.isAdmin(phoneNumber).timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!mounted) return;

      if (isAdmin) {
        // Admin user - always navigate to admin dashboard (skip profile setup)
        Get.offAllNamed('/admin-dashboard');
        return;
      }

      // Not an admin - continue with normal user flow
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (!mounted) return;

      // STRICT GATEKEEPER LOGIC: Check approval status BEFORE allowing access
      final profile = await firestoreService.getCurrentUserProfile();
      
      if (profile == null) {
        // No profile - new user, go to building selection
        Get.offNamed('/building-selection');
      } else if (profile.approvalStatus == 'approved') {
        // APPROVED: Allow access to dashboard
        Get.offAllNamed('/dashboard');
      } else {
        // NOT APPROVED: Redirect to pending approval screen
        // This includes: pending, rejected, or any other status
        Get.offAllNamed('/pending-approval');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Invalid OTP';
      bool shouldClearOTP = false;
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again';
          shouldClearOTP = true;
          break;
        case 'session-expired':
        case 'code-expired':
          errorMessage = 'OTP session expired. Please request a new OTP';
          shouldClearOTP = true;
          break;
        case 'missing-verification-id':
          errorMessage = 'Session expired. Please request a new OTP';
          shouldClearOTP = true;
          break;
        default:
          errorMessage = e.message ?? 'OTP verification failed';
          shouldClearOTP = true;
      }

      // Clear OTP fields if needed
      if (shouldClearOTP) {
        for (var controller in _otpControllers) {
          controller.clear();
        }
        // Focus on first field after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _focusNodes[0].requestFocus();
          }
        });
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Clear OTP fields on error
      for (var controller in _otpControllers) {
        controller.clear();
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _focusNodes[0].requestFocus();
        }
      });

      String errorMsg = 'OTP verification failed';
      if (e.toString().contains('timeout')) {
        errorMsg = 'Verification timeout. Please try again';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Network error. Please check your connection';
      }

      Get.snackbar(
        'Error',
        errorMsg,
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _handleResendOtp() async {
    if (_canResend) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final phoneNumber = _getPhoneNumber();
        await authService.resendOTP();
        
        _startResendTimer();
        
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'OTP Sent',
          'New OTP has been sent to $phoneNumber',
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
          'Failed to resend OTP: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    // Only allow digits
    if (value.isNotEmpty && !RegExp(r'^\d$').hasMatch(value)) {
      _otpControllers[index].clear();
      return;
    }
    
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when last digit is entered
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            final otp = _otpControllers.map((c) => c.text).join();
            if (otp.length == 6 && !_isLoading) {
              _handleOtpVerification();
            }
          }
        });
      }
    } else if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.secondary,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            
            // Main Content
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.offNamed('/app-entry');
                    }
                  },
                ),
              ),
              body: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Top section with logo
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                    Icons.verified_user_rounded,
                                    size: 60,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing32),
                                Text(
                                  'Verify Your Number',
                                  style: AppStyles.heading2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppStyles.spacing12),
                                Text(
                                  'Enter the 6-digit code sent to',
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppStyles.spacing12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppStyles.spacing20,
                                    vertical: AppStyles.spacing10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppStyles.radius12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getPhoneNumber(),
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Bottom card with OTP inputs
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppStyles.spacing32),
                    
                    const SizedBox(height: AppStyles.spacing56),
                    
                                // OTP Input Fields
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                    return Container(
                                      width: 52,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppStyles.radius16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _otpControllers[index],
                                        focusNode: _focusNodes[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: AppStyles.heading3.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: AppColors.surface,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppStyles.radius16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppStyles.radius16),
                                            borderSide: const BorderSide(color: AppColors.grey300, width: 2),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppStyles.radius16),
                                            borderSide: const BorderSide(color: AppColors.primary, width: 3),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppStyles.radius16),
                                            borderSide: const BorderSide(color: AppColors.error, width: 2),
                                          ),
                                        ),
                                        onChanged: (value) => _onOtpChanged(index, value),
                                      ),
                                    );
                                  }),
                                ),
                                
                                const SizedBox(height: AppStyles.spacing40),
                                
                                // Verify Button with gradient
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
                                        onTap: _isLoading ? null : _handleOtpVerification,
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
                                                      'Verify & Continue',
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
                                
                                // Resend OTP
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive the code? ",
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (_canResend)
                                      TextButton(
                                        onPressed: _handleResendOtp,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Resend',
                                          style: AppStyles.link.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        'Resend in ${_resendTimer}s',
                                        style: AppStyles.bodyMedium.copyWith(
                                          color: AppColors.textHint,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const SizedBox(height: AppStyles.spacing16),
                                
                                // Change Number
                                TextButton(
                                  onPressed: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      Get.offNamed('/login');
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'Change Mobile Number',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: AppStyles.spacing16),
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
          ],
        ),
      ),
    );
  }
}