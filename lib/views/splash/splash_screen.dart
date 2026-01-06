import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToNextScreen();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _navigateToNextScreen() async {
    // Wait for splash animation (2 seconds)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Check if user is already authenticated
      final authService = AuthService();
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        // User is logged in - check if super admin first
        final phoneNumber = currentUser.phoneNumber ?? '+91';
        final firestoreService = FirestoreService();
        final superAdmin = await firestoreService.getSuperAdminByMobile(phoneNumber);
        
        if (mounted) {
          if (superAdmin != null) {
            // Super Admin - go to super admin dashboard
            Get.offAllNamed('/super-admin/dashboard');
            return;
          }
          
          // Check if regular admin
          final isAdmin = await firestoreService.isAdmin(phoneNumber);
          if (isAdmin) {
            // Admin user - go to admin dashboard
            Get.offAllNamed('/admin-dashboard');
            return;
          }
          
          // Not admin - check if profile exists and is approved
          final profile = await firestoreService.getCurrentUserProfile();
          
          if (mounted) {
            if (profile != null) {
              // STRICT GATEKEEPER: Check approval status
              if (profile.approvalStatus == 'approved') {
                // Approved - allow access
                Get.offAllNamed('/dashboard');
              } else {
                // Pending or rejected - show pending approval screen
                Get.offAllNamed('/pending-approval');
              }
            } else {
              // User authenticated but no profile - go to building selection
              Get.offAllNamed('/building-selection');
            }
          }
        }
      } else {
        // User not authenticated - go to app entry screen
        if (mounted) {
          Get.offNamed('/app-entry');
        }
      }
    } catch (e) {
      // If any error occurs, go to login screen
      if (mounted) {
        Get.offNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: 50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            
            // Main Content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Society Logo with enhanced shadow
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(35),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          offset: const Offset(0, 15),
                                          blurRadius: 40,
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          offset: const Offset(0, 10),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.home_work_rounded,
                                      size: 70,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.spacing40),
                                  
                                  // App Name
                                  Text(
                                    AppStrings.appName,
                                    style: AppStyles.heading1.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 36,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppStyles.spacing12),
                                  
                                  // App Tagline
                                  Text(
                                    'Co-operative Housing Society',
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 18,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppStyles.spacing56),
                                  
                                  // Enhanced Loading Indicator
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        width: 3,
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Bottom Section with enhanced design
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacing32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Version ${AppStrings.appVersion}',
                              style: AppStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppStyles.spacing12),
                        Text(
                          '© 2024 Society Management App',
                          style: AppStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
