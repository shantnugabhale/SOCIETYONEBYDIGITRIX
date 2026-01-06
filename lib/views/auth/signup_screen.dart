import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _flatNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _flatNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // Navigate to building selection (first step in signup flow)
      Get.toNamed('/building-selection');
    }
  }

  void _handleLogin() {
    Get.toNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Welcome Text
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: AppStyles.shadowMedium,
                      ),
                      child: const Icon(
                        Icons.home_work,
                        size: 40,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing24),
                    Text(
                      'Join Our Society',
                      style: AppStyles.heading2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.spacing8),
                    Text(
                      'Create your society account',
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                const SizedBox(height: AppStyles.spacing48),
                
                // Name Field
                CustomInputField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  isRequired: true,
                ),
                
                const SizedBox(height: AppStyles.spacing20),
                
                // Email Field
                CustomInputField(
                  label: AppStrings.email,
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                
                // Mobile Field
                CustomInputField(
                  label: 'Mobile Number',
                  hint: 'Enter your mobile number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textSecondary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mobile number is required';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid mobile number';
                    }
                    return null;
                  },
                  isRequired: true,
                ),
                
                const SizedBox(height: AppStyles.spacing20),
                
                // Flat Number Field
                CustomInputField(
                  label: 'Flat Number',
                  hint: 'Enter your flat number',
                  controller: _flatNumberController,
                  textInputAction: TextInputAction.next,
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
                
                // Password Field
                CustomInputField(
                  label: AppStrings.password,
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.passwordRequired;
                    }
                    if (value.length < 6) {
                      return AppStrings.passwordTooShort;
                    }
                    return null;
                  },
                  isRequired: true,
                ),
                
                const SizedBox(height: AppStyles.spacing20),
                
                // Confirm Password Field
                CustomInputField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _toggleConfirmPasswordVisibility,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  isRequired: true,
                ),
                
                const SizedBox(height: AppStyles.spacing32),
                
                // Signup Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: AppStyles.spacing24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleLogin,
                      child: Text(
                        AppStrings.login,
                        style: AppStyles.link,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppStyles.spacing16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
