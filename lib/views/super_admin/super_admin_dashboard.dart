import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  int _buildingsCount = 0;
  int _societiesCount = 0;
  int _totalMembers = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final buildings = await _firestoreService.getAllBuildings();
      int societies = 0;
      for (var building in buildings) {
        final buildingSocieties = await _firestoreService.getSocietiesByBuilding(building.id);
        societies += buildingSocieties.length;
      }
      final members = await _firestoreService.getAllMembers();
      
      setState(() {
        _buildingsCount = buildings.length;
        _societiesCount = societies;
        _totalMembers = members.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load data: ${e.toString()}');
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    Get.offAllNamed('/app-entry');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacing24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radius16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppStyles.spacing12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppStyles.radius12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Super Admin',
                                    style: AppStyles.heading3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'System Management',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing24),

                  // Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.business_rounded,
                          title: 'Buildings',
                          value: _buildingsCount.toString(),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.home_work_rounded,
                          title: 'Societies',
                          value: _societiesCount.toString(),
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people_rounded,
                          title: 'Members',
                          value: _totalMembers.toString(),
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacing24),

                  // Management Options
                  Text(
                    'Management',
                    style: AppStyles.heading5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing16),

                  _buildManagementCard(
                    icon: Icons.business_rounded,
                    title: 'Buildings Management',
                    subtitle: 'Add, edit, and manage buildings',
                    color: AppColors.primary,
                    onTap: () => Get.toNamed('/super-admin/buildings'),
                  ),
                  const SizedBox(height: AppStyles.spacing12),

                  _buildManagementCard(
                    icon: Icons.home_work_rounded,
                    title: 'Societies Management',
                    subtitle: 'Add, edit, and manage societies',
                    color: AppColors.secondary,
                    onTap: () => Get.toNamed('/super-admin/societies'),
                  ),
                  const SizedBox(height: AppStyles.spacing12),

                  _buildManagementCard(
                    icon: Icons.people_rounded,
                    title: 'Committee Assignment',
                    subtitle: 'Assign committee members to societies',
                    color: AppColors.info,
                    onTap: () => Get.toNamed('/super-admin/committee'),
                  ),
                  const SizedBox(height: AppStyles.spacing12),

                  _buildManagementCard(
                    icon: Icons.settings_rounded,
                    title: 'Feature Management',
                    subtitle: 'Enable/disable features per society',
                    color: AppColors.warning,
                    onTap: () => Get.toNamed('/super-admin/features'),
                  ),
                  const SizedBox(height: AppStyles.spacing12),
                  
                  _buildManagementCard(
                    icon: Icons.list_rounded,
                    title: 'View All Buildings',
                    subtitle: 'Search and view all buildings',
                    color: AppColors.info,
                    onTap: () => Get.toNamed('/super-admin/buildings'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppStyles.spacing8),
          Text(
            value,
            style: AppStyles.heading4.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppStyles.spacing4),
          Text(
            title,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppStyles.radius12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.radius12),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppStyles.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

