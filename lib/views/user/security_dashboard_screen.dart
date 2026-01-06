import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/visitor_model.dart';
import '../../utils/format_utils.dart';

/// Security Dashboard for SocietyOne by Digitrix
/// Goal: Speed and clarity
/// Layout: Large date/time + Very large buttons + Offline mode indicator
class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isOffline = false;
  int _approvedVisitorsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startClock();
  }

  void _startClock() {
    // Update time every second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _startClock();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final visitors = await _firestoreService.getUserVisitorsStream().first;
      
      final todayVisitors = visitors.where((v) {
        final visitDate = v.expectedArrival;
        return visitDate.year == now.year &&
               visitDate.month == now.month &&
               visitDate.day == now.day &&
               v.status == 'approved';
      }).length;
      
      if (mounted) {
        setState(() {
          _approvedVisitorsToday = todayVisitors;
        });
      }
    } catch (e) {
      // Handle error silently for security dashboard
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Solid Color Header (NO gradients)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Column(
                children: [
                  // Offline Mode Indicator
                  if (_isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.cloud_off, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Offline Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isOffline) const SizedBox(height: 12),
                  
                  // Large Date & Time
                  Text(
                    _getCurrentDate(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCurrentTime(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Very Large Buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: _buildLargeButton(
                        title: 'New Entry',
                        subtitle: 'Register visitor or delivery',
                        icon: Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        onTap: () => Get.toNamed('/visitors'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildLargeButton(
                        title: 'Approved Visitors',
                        subtitle: '$_approvedVisitorsToday visitors today',
                        icon: Icons.verified_user_rounded,
                        color: AppColors.success,
                        onTap: () => Get.toNamed('/visitors'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildLargeButton(
                        title: 'Deliveries',
                        subtitle: 'Package management',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.info,
                        onTap: () => Get.toNamed('/packages'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildLargeButton(
                        title: 'SOS',
                        subtitle: 'Emergency alert',
                        icon: Icons.emergency_rounded,
                        color: AppColors.error,
                        onTap: () => Get.toNamed('/emergency'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

