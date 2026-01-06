import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../models/society_model.dart';
import '../../widgets/card_widget.dart';
import '../auth/setup_profile_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole; // 'owner', 'tenant', 'family_member'
  Map<String, dynamic>? _onboardingData;

  @override
  void initState() {
    super.initState();
    _onboardingData = Get.arguments as Map<String, dynamic>?;
  }

  void _selectRole(String role) {
    setState(() => _selectedRole = role);
  }

  void _proceedToProfileSetup() {
    if (_selectedRole == null) {
      Get.snackbar('Error', 'Please select your role');
      return;
    }

    if (_onboardingData == null) {
      Get.snackbar('Error', 'Missing onboarding data');
      return;
    }

    // Add role to onboarding data
    final data = Map<String, dynamic>.from(_onboardingData!);
    data['userType'] = _selectedRole;
    
    // Navigate to profile setup with all data
    Get.toNamed('/setup-profile', arguments: data);
  }

  @override
  Widget build(BuildContext context) {
    final society = _onboardingData?['society'] as SocietyModel?;
    final unit = _onboardingData?['unit'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Your Role'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            if (society != null)
              CustomCard(
                margin: const EdgeInsets.only(bottom: AppStyles.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Details',
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    _buildSummaryRow(Icons.apartment_rounded, 'Society', society.name),
                    if (unit != null)
                      _buildSummaryRow(
                        Icons.home_rounded,
                        'Unit',
                        unit is UnitModel ? unit.fullAddress : unit.toString(),
                      ),
                  ],
                ),
              ),

            Text(
              'I am a...',
              style: AppStyles.heading5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.spacing16),

            // Owner Option
            _buildRoleCard(
              title: 'Owner',
              subtitle: 'I own this property',
              icon: Icons.person_rounded,
              role: 'owner',
              color: AppColors.primary,
            ),
            const SizedBox(height: AppStyles.spacing12),

            // Tenant Option
            _buildRoleCard(
              title: 'Tenant',
              subtitle: 'I am renting this property',
              icon: Icons.badge_rounded,
              role: 'tenant',
              color: AppColors.info,
            ),
            const SizedBox(height: AppStyles.spacing12),

            // Family Member Option
            _buildRoleCard(
              title: 'Family Member',
              subtitle: 'I am a family member of the owner',
              icon: Icons.family_restroom_rounded,
              role: 'family_member',
              color: AppColors.accent,
            ),

            const SizedBox(height: AppStyles.spacing32),

            // Continue Button
            ElevatedButton(
              onPressed: _selectedRole != null ? _proceedToProfileSetup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppStyles.spacing16,
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacing8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppStyles.spacing12),
          Text(
            '$label: ',
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String role,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return CustomCard(
      onTap: () => _selectRole(role),
      isClickable: true,
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
          borderRadius: BorderRadius.circular(AppStyles.radius12),
        ),
        padding: const EdgeInsets.all(AppStyles.spacing16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppStyles.radius12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppStyles.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.heading6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing4),
                  Text(
                    subtitle,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

