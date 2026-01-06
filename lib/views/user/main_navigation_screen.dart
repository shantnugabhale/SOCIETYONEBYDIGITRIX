import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'resident_dashboard_screen.dart';
import 'committee_dashboard_screen.dart';
import 'security_dashboard_screen.dart';
import 'activity_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import '../../widgets/elder_mode_provider.dart';

/// Main Navigation Screen with 4 tabs
/// Tabs: Home, Activity, Community, Profile
/// Shows role-based dashboard on Home tab
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final ElderModeProvider _elderModeProvider = ElderModeProvider();
  UserModel? _userProfile;
  String _userRole = 'member'; // 'member', 'committee', 'security', 'admin'

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final profile = await FirestoreService().getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _userRole = profile?.role ?? 'member';
          // Map admin to committee for dashboard purposes
          if (_userRole == 'admin') {
            _userRole = 'committee';
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Widget _getHomeScreen() {
    switch (_userRole) {
      case 'committee':
        return const CommitteeDashboardScreen();
      case 'security':
        return const SecurityDashboardScreen();
      case 'member':
      default:
        return const ResidentDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _getHomeScreen(),
          const ActivityScreen(),
          const CommunityScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

