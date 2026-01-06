import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../models/utility_model.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/notice_model.dart';
import '../../utils/format_utils.dart';

class MemberPaymentStats {
  final UserModel member;
  final int paidCount;
  final double paidAmount;
  final int pendingCount;
  final double pendingAmount;
  final int overdueCount;
  final double overdueAmount;

  MemberPaymentStats({
    required this.member,
    required this.paidCount,
    required this.paidAmount,
    required this.pendingCount,
    required this.pendingAmount,
    required this.overdueCount,
    required this.overdueAmount,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
  
  // Method to refresh profile when navigating back
  static void refreshProfile() {
    // This will be called via Get when needed
  }
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;
  
  // Quick Overview Data
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoadingOverview = true;
  double _totalPaymentsThisMonth = 0.0;
  int _pendingBillsCount = 0;
  int _activeMaintenanceRequests = 0;
  int _newNoticesCount = 0;
  
  // Recent Payments and Upcoming Bills
  List<PaymentModel> _recentPayments = [];
  List<UtilityModel> _upcomingBills = [];
  
  // Member Payment Stats
  List<MemberPaymentStats> _memberPaymentStats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    
    _setupNotifications();
    
    _loadUserProfile();
    _loadDashboardData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    try {
      final profile = await _firestoreService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load profile: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  /// Get user's full name or fallback
  String _getUserName() {
    return _userProfile?.name ?? 'User';
  }

  /// Get user's address or fallback
  String _getUserAddress() {
    if (_userProfile == null) {
      return 'Loading...';
    }
    final flat = _userProfile!.apartmentNumber;
    final block = _userProfile!.buildingName;
    if (flat.isEmpty && block.isEmpty) {
      return 'No address set';
    }
    return 'Flat $flat, $block';
  }

  /// Load dashboard data from Firestore
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOverview = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      final now = DateTime.now();

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _firestoreService.getUserPayments(),
        _firestoreService.getAllUtilityBills(),
        _firestoreService.getAllMembers(),
        _firestoreService.getUserMaintenanceRequests().catchError((e) {
          if (kDebugMode) debugPrint('Failed to load maintenance requests: $e');
          return <MaintenanceRequestModel>[];
        }),
        _firestoreService.getAllNotices().catchError((e) {
          if (kDebugMode) debugPrint('Failed to load notices: $e');
          return <NoticeModel>[];
        }),
      ]);

      final payments = results[0] as List<PaymentModel>;
      final allBills = results[1] as List<UtilityModel>;
      final allMembers = results[2] as List<UserModel>;
      final maintenanceRequests = results[3] as List<MaintenanceRequestModel>;
      final notices = results[4] as List<NoticeModel>;

      // Calculate total payments this month
      final paymentsThisMonth = payments.where((payment) {
        final paidDate = payment.paidDate;
        return paidDate.year == now.year &&
               paidDate.month == now.month &&
               payment.status == 'success';
      }).toList();

      final totalThisMonth = paymentsThisMonth.fold<double>(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

      // Calculate pending bills (unpaid by user - includes both future and overdue)
      final pendingBills = allBills.where((bill) {
        return !bill.hasPaidBy(userId) &&
               bill.status != 'cancelled';
      }).toList();

      // Get upcoming bills (due in next 30 days)
      final upcomingBills = allBills.where((bill) {
        final daysUntilDue = bill.dueDate.difference(now).inDays;
        return !bill.hasPaidBy(userId) &&
               bill.status != 'cancelled' &&
               daysUntilDue >= 0 &&
               daysUntilDue <= 30;
      }).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // Get recent payments (last 3)
      final recentPayments = payments
          .where((p) => p.status == 'success')
          .take(3)
          .toList();

      // Calculate active maintenance requests (open or in_progress)
      final activeMaintenanceRequests = maintenanceRequests
          .where((r) => r.status == 'open' || r.status == 'in_progress')
          .length;

      // Calculate new/unread notices count
      final newNoticesCount = userId.isNotEmpty
          ? notices.where((notice) =>
              notice.status == 'published' &&
              notice.isActive &&
              !notice.readBy.contains(userId)).length
          : notices.where((notice) =>
              notice.status == 'published' && notice.isActive).length;

      // Calculate Member Payment Stats - optimized with single pass
      final activeBills = allBills.where((b) => b.status != 'cancelled').toList();
      final memberStats = allMembers.map((member) {
        int paidCount = 0;
        double paidAmount = 0;
        int pendingCount = 0;
        double pendingAmount = 0;
        int overdueCount = 0;
        double overdueAmount = 0;

        for (var bill in activeBills) {
          if (bill.hasPaidBy(member.id)) {
            paidCount++;
            paidAmount += bill.totalAmount;
          } else if (bill.isOverdue) {
            overdueCount++;
            overdueAmount += bill.totalAmount;
          } else {
            pendingCount++;
            pendingAmount += bill.totalAmount;
          }
        }

        return MemberPaymentStats(
          member: member,
          paidCount: paidCount,
          paidAmount: paidAmount,
          pendingCount: pendingCount,
          pendingAmount: pendingAmount,
          overdueCount: overdueCount,
          overdueAmount: overdueAmount,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _totalPaymentsThisMonth = totalThisMonth;
        _pendingBillsCount = pendingBills.length;
        _upcomingBills = upcomingBills.take(3).toList();
        _recentPayments = recentPayments;
        _activeMaintenanceRequests = activeMaintenanceRequests;
        _newNoticesCount = newNoticesCount;
        _memberPaymentStats = memberStats;
        _isLoadingOverview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOverview = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load dashboard data: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Refresh all dashboard data
  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserProfile(),
      _loadDashboardData(),
    ]);
  }

  // Setup notifications and save FCM token
  Future<void> _setupNotifications() async {
    // Get FCM token
    String? token = await NotificationService().getFCMToken();
    
    // Save token to database if available
    if (token != null) {
      await _firestoreService.saveUserToken(token);
    }
  }

  // Helper method to get responsive text scale - memoized for performance
  double _getTextScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 1.4; // Large tablets/landscape
    if (width > 600) return 1.2; // Tablets
    if (width > 400) return 1.1; // Large phones
    return 1.0; // Normal phones
  }
  
  // Helper method to get responsive icon size - memoized for performance
  double _getIconSizeFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 1.5; // Large tablets/landscape
    if (width > 600) return 1.3; // Tablets
    if (width > 400) return 1.15; // Large phones
    return 1.0; // Normal phones
  }

  Widget _buildMemberPaymentDetails() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final int memberFlex = isTablet ? 4 : 3;
    final int otherFlex = isTablet ? 3 : 2;
    
    // Limit to 3 members for dashboard view
    final displayCount = _memberPaymentStats.length > 3 ? 3 : _memberPaymentStats.length;
    final displayStats = _memberPaymentStats.take(displayCount).toList();
    
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacing8,
              vertical: AppStyles.spacing12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppStyles.radius12),
                topRight: Radius.circular(AppStyles.radius12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: memberFlex,
                  child: Text(
                    'Member',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14 : 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Expanded(
                  flex: otherFlex,
                  child: Text(
                    'Paid',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14 : 13,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: otherFlex,
                  child: Text(
                    'Pending',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14 : 13,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: otherFlex,
                  child: Text(
                    'Overdue',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14 : 13,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Member list
          if (_isLoadingOverview)
            const Padding(
              padding: EdgeInsets.all(AppStyles.spacing24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_memberPaymentStats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacing24),
              child: Center(
                child: Text(
                  'No member data available',
                  style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayStats.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.grey200,
              ),
              itemBuilder: (context, index) {
                final stats = displayStats[index];
                return _buildMemberPaymentRow(stats, isTablet, memberFlex, otherFlex);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMemberPaymentRow(MemberPaymentStats stats, bool isTablet, int memberFlex, int otherFlex) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacing8,
        vertical: AppStyles.spacing12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Info
          Expanded(
            flex: memberFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stats.member.name,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 14 : 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.member.apartmentNumber}, ${stats.member.buildingName}',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 12 : 11,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Paid
          Expanded(
            flex: otherFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${stats.paidCount}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FormatUtils.formatCurrency(stats.paidAmount),
                  style: AppStyles.caption.copyWith(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Pending
          Expanded(
            flex: otherFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${stats.pendingCount}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FormatUtils.formatCurrency(stats.pendingAmount),
                  style: AppStyles.caption.copyWith(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Overdue
          Expanded(
            flex: otherFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${stats.overdueCount}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FormatUtils.formatCurrency(stats.overdueAmount),
                  style: AppStyles.caption.copyWith(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = _getTextScaleFactor(context);
    final iconScale = _getIconSizeFactor(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.dashboard,
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        flexibleSpace: Container(
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
        ),
        actions: [
          // Emergency Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              tooltip: 'Emergency',
              onPressed: () {
                Get.toNamed('/emergency');
              },
            ),
          ),
          StreamBuilder<int>(
            stream: _firestoreService.getUnreadNotificationCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Get.toNamed('/notifications-inbox');
                    },
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Get.toNamed('/profile');
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(AppStyles.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section - Enhanced
                _AnimatedContainer(
                  delay: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppStyles.spacing24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                          AppColors.secondary,
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radius24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getTimeBasedGreeting()},',
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.spacing8),
                                  _isLoadingProfile
                                      ? Container(
                                          height: 28,
                                          width: 180,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        )
                                      : Text(
                                          _getUserName(),
                                          style: AppStyles.heading3.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        ),
                                  const SizedBox(height: AppStyles.spacing12),
                                  _isLoadingProfile
                                      ? Container(
                                          height: 20,
                                          width: 220,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _getUserAddress(),
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
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
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
              
                const SizedBox(height: AppStyles.spacing24),
                
                // Quick Stats
                _AnimatedContainer(
                  delay: 100,
                  child: Text(
                    'Quick Overview',
                    style: AppStyles.heading5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                
                _AnimatedContainer(
                  delay: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Total Payments',
                          value: _isLoadingOverview 
                              ? '...' 
                              : FormatUtils.formatCurrency(_totalPaymentsThisMonth),
                          subtitle: 'This month',
                          icon: Icons.payment,
                          iconColor: AppColors.success,
                          iconSize: 20 * iconScale,
                          textScaleFactor: textScale,
                          onTap: () {
                            Get.toNamed('/payments');
                          },
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing12),
                      Expanded(
                        child: InfoCard(
                          title: 'Pending Bills',
                          value: _isLoadingOverview 
                              ? '...' 
                              : '$_pendingBillsCount',
                          subtitle: 'Due soon',
                          icon: Icons.pending_actions,
                          iconColor: AppColors.warning,
                          iconSize: 20 * iconScale,
                          textScaleFactor: textScale,
                          onTap: () {
                            Get.toNamed('/utility-bills');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppStyles.spacing16),
                
                _AnimatedContainer(
                  delay: 300,
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Maintenance',
                          value: _isLoadingOverview 
                              ? '...' 
                              : '$_activeMaintenanceRequests',
                          subtitle: 'Active requests',
                          icon: Icons.build,
                          iconColor: AppColors.info,
                          iconSize: 20 * iconScale,
                          textScaleFactor: textScale,
                          onTap: () {
                            Get.toNamed('/maintenance');
                          },
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing4),
                      Expanded(
                        child: InfoCard(
                          title: 'Notices',
                          value: _isLoadingOverview 
                              ? '...' 
                              : '$_newNoticesCount',
                          subtitle: 'New notices',
                          icon: Icons.notifications,
                          iconColor: AppColors.primary,
                          iconSize: 20 * iconScale,
                          textScaleFactor: textScale,
                          onTap: () {
                            Get.toNamed('/notices');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppStyles.spacing24),
                
                // Recent Payments
                _AnimatedContainer(
                  delay: 400,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Payments',
                        style: AppStyles.heading5.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.toNamed('/payment-history');
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                
                _isLoadingOverview
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(AppStyles.spacing16),
                        child: CircularProgressIndicator(),
                      ))
                    : _recentPayments.isEmpty
                        ? _AnimatedContainer(
                            delay: 500,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppStyles.spacing16),
                                child: Text(
                                  'No recent payments',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < _recentPayments.length; i++) ...[
                                _AnimatedContainer(
                                  delay: 500 + (i * 100),
                                  child: PaymentCard(
                                    title: 'Payment for ${_recentPayments[i].billIds.length} bills',
                                    amount: FormatUtils.formatCurrency(_recentPayments[i].amount),
                                    status: _recentPayments[i].status == 'success' ? 'Paid' : 'Pending',
                                    dueDate: FormatUtils.formatDate(_recentPayments[i].paidDate),
                                    onTap: () {
                                      Get.toNamed('/payment-history');
                                    },
                                  ),
                                ),
                                if (i < _recentPayments.length - 1)
                                  const SizedBox(height: AppStyles.spacing12),
                              ],
                            ],
                          ),
                
                const SizedBox(height: AppStyles.spacing24),
                
                // Upcoming Bills
                _AnimatedContainer(
                  delay: 800,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Bills',
                        style: AppStyles.heading5.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.toNamed('/utility-bills');
                        },
                        child: Text(
                          'View All',
                          style: AppStyles.link,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                
                _AnimatedContainer(
                  delay: 900,
                  child: _isLoadingOverview
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(AppStyles.spacing16),
                          child: CircularProgressIndicator(),
                        ))
                      : _upcomingBills.isEmpty
                          ? CustomCard(
                              child: Padding(
                                padding: const EdgeInsets.all(AppStyles.spacing16),
                                child: Center(
                                  child: Text(
                                    'No upcoming bills',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : CustomCard(
                              child: Column(
                                children: [
                                  for (int i = 0; i < _upcomingBills.length; i++) ...[
                                    ListTile(
                                      leading: Icon(
                                        FormatUtils.getBillIcon(_upcomingBills[i].utilityType),
                                        color: FormatUtils.getBillColor(_upcomingBills[i].utilityType),
                                      ),
                                      title: Text('${_upcomingBills[i].utilityType} Bill'),
                                      subtitle: Text('Due: ${FormatUtils.formatDate(_upcomingBills[i].dueDate)}'),
                                      trailing: Text(
                                        FormatUtils.formatCurrency(_upcomingBills[i].totalAmount),
                                        style: AppStyles.heading6.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      onTap: () {
                                        Get.toNamed('/utility-bills');
                                      },
                                    ),
                                    if (i < _upcomingBills.length - 1) const Divider(),
                                  ],
                                ],
                              ),
                            ),
                ),
                
                const SizedBox(height: AppStyles.spacing24),
                
                // Member Payment Details
                _AnimatedContainer(
                  delay: 1000,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Member Payment',
                              style: AppStyles.heading5.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Details',
                              style: AppStyles.heading5.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_memberPaymentStats.length > 3)
                        TextButton(
                          onPressed: () {
                            Get.toNamed('/member-payment-details');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerRight,
                          ),
                          child: Text(
                            'View All',
                            style: AppStyles.link.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                _AnimatedContainer(
                  delay: 1100,
                  child: _buildMemberPaymentDetails(),
                ),
                
                const SizedBox(height: AppStyles.spacing24),
                
                // Quick Actions
                _AnimatedContainer(
                  delay: 1200,
                  child: Text(
                    'Quick Actions',
                    style: AppStyles.heading5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                
                _AnimatedContainer(
                  delay: 1300,
                  child: Column(
                    children: [
                      CustomButton(
                        text: 'Make Payment',
                        icon: Icons.payment,
                        onPressed: () {
                          Get.toNamed('/payments');
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing12),
                      CustomButton(
                        text: 'Report Issue',
                        type: ButtonType.outline,
                        icon: Icons.report_problem,
                        onPressed: () {
                          Get.toNamed('/complaints');
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing12),
                      CustomButton(
                        text: 'Balance Sheet',
                        type: ButtonType.outline,
                        icon: Icons.account_balance_wallet,
                        onPressed: () {
                          Get.toNamed('/balance-sheet-view');
                        },
                      ),
                    ],
                  ),
                ),
                
                // New Features Section
                _AnimatedContainer(
                  delay: 1400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More Features',
                        style: AppStyles.heading5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      Wrap(
                        spacing: AppStyles.spacing12,
                        runSpacing: AppStyles.spacing12,
                        children: [
                          _buildFeatureCard(
                            context,
                            icon: Icons.forum,
                            title: 'Forum',
                            color: AppColors.primary,
                            onTap: () => Get.toNamed('/forum'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.chat_bubble_outline,
                            title: 'Chat',
                            color: AppColors.secondary,
                            onTap: () => Get.toNamed('/chat'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.sports_tennis,
                            title: 'Facilities',
                            color: AppColors.accent,
                            onTap: () => Get.toNamed('/facilities'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.person_add,
                            title: 'Visitors',
                            color: AppColors.info,
                            onTap: () => Get.toNamed('/visitors'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.poll,
                            title: 'Polls',
                            color: AppColors.warning,
                            onTap: () => Get.toNamed('/polls'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.event,
                            title: 'Events',
                            color: AppColors.success,
                            onTap: () => Get.toNamed('/events'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.folder,
                            title: 'Documents',
                            color: AppColors.secondaryDark,
                            onTap: () => Get.toNamed('/documents'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.inventory_2,
                            title: 'Packages',
                            color: AppColors.accentDark,
                            onTap: () => Get.toNamed('/packages'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppStyles.spacing32),
              ],
            ),
          ),
        ),
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
            
            switch (index) {
              case 0:
                // Dashboard - already here
                break;
              case 1:
                Get.toNamed('/payments');
                break;
              case 2:
                Get.toNamed('/utility-bills');
                break;
              case 3:
                Get.toNamed('/maintenance-status');
                break;
              case 4:
                Get.toNamed('/notices');
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Maintenance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notices',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
        padding: const EdgeInsets.all(AppStyles.spacing16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radius12),
          border: Border.all(color: AppColors.grey200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppStyles.spacing8),
            Text(
              title,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedContainer extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedContainer({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedContainer> createState() => _AnimatedContainerState();
}

class _AnimatedContainerState extends State<_AnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}