import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/input_field.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Sign in with email and password
        await authService.signInWithEmailAndPassword(email, password);

        if (!mounted) return;

        // Check if user is super admin
        final firestoreService = FirestoreService();
        final user = authService.currentUser;
        if (user?.email != null) {
          // For email login, check admin status by email
          // Note: This might need adjustment based on your admin structure
        }

        // Check approval status
        final profile = await firestoreService.getCurrentUserProfile();

        if (!mounted) return;

        if (profile == null) {
          // No profile - go to society selection
          Get.offAllNamed('/society-selection');
        } else if (profile.approvalStatus == 'approved') {
          // Approved - allow access
          Get.offAllNamed('/dashboard');
        } else {
          // Pending or rejected - show pending screen
          Get.offAllNamed('/pending-approval');
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Login failed';
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
          default:
            errorMessage = e.message ?? 'Login failed';
        }

        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'Error',
          'Login failed: ${e.toString()}',
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Top section
                    Padding(
                      padding: const EdgeInsets.all(AppStyles.spacing24),
                      child: Column(
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
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
                          const SizedBox(height: AppStyles.spacing32),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.email_rounded,
                              size: 50,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppStyles.spacing24),
                          Text(
                            'Login with Email',
                            style: AppStyles.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
                                'Enter your email and password',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppStyles.spacing32),

                              // Email Field
                              CustomInputField(
                                label: 'Email Address',
                                hint: 'Enter your email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.email_rounded),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!GetUtils.isEmail(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                isRequired: true,
                              ),
                              const SizedBox(height: AppStyles.spacing24),

                              // Password Field
                              CustomInputField(
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                isRequired: true,
                              ),
                              const SizedBox(height: AppStyles.spacing16),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                    Get.snackbar(
                                      'Info',
                                      'Forgot password feature coming soon',
                                      backgroundColor: AppColors.info,
                                      colorText: AppColors.textOnPrimary,
                                    );
                                  },
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: AppStyles.spacing32),

                              // Login Button
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
                                      onTap: _isLoading ? null : _handleEmailLogin,
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
                                                    'Sign In',
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

                              // Sign up link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.toNamed('/signup'),
                                    child: const Text('Sign Up'),
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

