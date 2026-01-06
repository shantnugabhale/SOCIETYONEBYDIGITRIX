import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../models/utility_model.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/notice_model.dart';
import '../../models/visitor_model.dart';
import '../../models/event_model.dart';
import '../../utils/format_utils.dart';
import 'ai_assistant_screen.dart';

/// Modern Resident Dashboard for SocietyOne by Digitrix
/// Design: Simple, calm, action-oriented
/// Layout: Gradient header + 2x2 action grid + Recent notices/events
class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() => _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  UserModel? _userProfile;
  bool _isLoading = true;
  
  // Dashboard data
  double _dueMaintenanceAmount = 0.0;
  int _todayVisitorsCount = 0;
  int _openComplaintsCount = 0;
  int _newNoticesCount = 0;
  
  List<NoticeModel> _recentNotices = [];
  List<EventModel> _upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser?.uid ?? '';
      final now = DateTime.now();
      
      // Load user profile
      final profile = await _firestoreService.getCurrentUserProfile();
      
      // Load data in parallel
      final results = await Future.wait([
        _firestoreService.getUserPayments(),
        _firestoreService.getAllUtilityBills(),
        _firestoreService.getUserMaintenanceRequests(),
        _firestoreService.getAllNotices(),
        _firestoreService.getUserVisitorsStream().first,
        _firestoreService.getEventsStream().first.catchError((e) => <EventModel>[]),
      ]);
      
      final payments = results[0] as List<PaymentModel>;
      final bills = results[1] as List<UtilityModel>;
      final maintenanceRequests = results[2] as List<MaintenanceRequestModel>;
      final notices = results[3] as List<NoticeModel>;
      final visitors = results[4] as List<VisitorModel>;
      final events = results[5] as List<EventModel>;
      
      // Calculate due maintenance (unpaid bills)
      final unpaidBills = bills.where((bill) => 
        !bill.hasPaidBy(userId) && 
        bill.status != 'cancelled'
      ).toList();
      final dueAmount = unpaidBills.fold<double>(
        0.0, 
        (sum, bill) => sum + bill.totalAmount
      );
      
      // Today's visitors
      final todayVisitors = visitors.where((v) {
        final visitDate = v.expectedArrival;
        return visitDate.year == now.year &&
               visitDate.month == now.month &&
               visitDate.day == now.day;
      }).length;
      
      // Open complaints
      final openComplaints = maintenanceRequests.where((r) => 
        r.status == 'open' || r.status == 'in_progress'
      ).length;
      
      // New notices (unread)
      final newNotices = notices.where((n) =>
        n.status == 'published' &&
        n.isActive &&
        !n.readBy.contains(userId)
      ).length;
      
      // Recent notices (last 3)
      final recentNotices = notices
          .where((n) => n.status == 'published' && n.isActive)
          .toList()
        ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
      
      // Upcoming events (next 3)
      final upcomingEvents = events
          .where((e) => e.isUpcoming && e.status == 'published')
          .take(3)
          .toList();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _dueMaintenanceAmount = dueAmount;
          _todayVisitorsCount = todayVisitors;
          _openComplaintsCount = openComplaints;
          _newNoticesCount = newNotices;
          _recentNotices = recentNotices.take(3).toList();
          _upcomingEvents = upcomingEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Delay snackbar until after first frame to ensure overlay is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Get.snackbar(
              'Error',
              'Failed to load dashboard: ${e.toString()}',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        });
      }
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getTimeBasedGreeting()},',
                                style: AppStyles.bodyLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userProfile?.name ?? 'Resident',
                                style: AppStyles.heading3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _userProfile != null
                                          ? 'Flat ${_userProfile!.apartmentNumber}, ${_userProfile!.buildingName}'
                                          : 'Loading...',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: _userProfile?.profileImageUrl.isNotEmpty == true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Image.network(
                                    _userProfile!.profileImageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.account_circle_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 2x2 Primary Action Grid
                  _buildActionGrid(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Notices
                  if (_recentNotices.isNotEmpty) ...[
                    _buildSectionHeader('Recent Notices', () {
                      Get.toNamed('/notices');
                    }),
                    const SizedBox(height: 12),
                    ..._recentNotices.map((notice) => _buildNoticeItem(notice)),
                    const SizedBox(height: 24),
                  ],
                  
                  // Upcoming Events (if available)
                  _buildSectionHeader('Upcoming Events', () {
                    Get.toNamed('/events');
                  }),
                  const SizedBox(height: 12),
                  _buildUpcomingEvents(),
                  
                  // Add padding for FAB and bottom navigation
                  SizedBox(
                    height: 100 + MediaQuery.of(context).padding.bottom,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      
      // AI Assistant FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(
            const AiAssistantScreen(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Ask SocietyOne',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          title: 'Pay Maintenance',
          subtitle: _isLoading 
              ? 'Loading...' 
              : FormatUtils.formatCurrency(_dueMaintenanceAmount),
          icon: Icons.payment_rounded,
          color: AppColors.success,
          onTap: () => Get.toNamed('/payments'),
        ),
        _buildActionCard(
          title: 'Visitors',
          subtitle: _isLoading 
              ? 'Loading...' 
              : '$_todayVisitorsCount today',
          icon: Icons.person_add_rounded,
          color: AppColors.info,
          onTap: () => Get.toNamed('/visitors'),
        ),
        _buildActionCard(
          title: 'Complaints',
          subtitle: _isLoading 
              ? 'Loading...' 
              : '$_openComplaintsCount open',
          icon: Icons.report_problem_rounded,
          color: AppColors.warning,
          onTap: () => Get.toNamed('/complaints'),
        ),
        _buildActionCard(
          title: 'Notices',
          subtitle: _isLoading 
              ? 'Loading...' 
              : '$_newNoticesCount new',
          icon: Icons.notifications_rounded,
          color: AppColors.primary,
          onTap: () => Get.toNamed('/notices'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppStyles.heading6.copyWith(
                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppStyles.heading5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildNoticeItem(NoticeModel notice) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Get.toNamed('/notices'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: AppStyles.heading6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notice.content,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              FormatUtils.formatDate(notice.publishDate),
              style: AppStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    if (_isLoading) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_upcomingEvents.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No upcoming events',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _upcomingEvents.map((event) {
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => Get.toNamed('/events'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppStyles.heading6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  FormatUtils.formatDate(event.startDate),
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}


