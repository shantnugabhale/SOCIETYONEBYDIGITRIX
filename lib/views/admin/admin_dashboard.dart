import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/payment_model.dart';
import 'package:intl/intl.dart';
import 'activities_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _totalMembers = 0;
  double _totalRevenue = 0.0;
  int _pendingRequests = 0;
  int _overduePayments = 0;
  bool _isLoadingMembers = true;
  bool _isLoadingMetrics = true;
  final FirestoreService _firestoreService = FirestoreService();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  List<ActivityItem> _recentActivities = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );
    _animationController?.forward();
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
    _animationController?.dispose();
    super.dispose();
  }

  /// Refresh all dashboard data
  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingMembers = true;
      _isLoadingMetrics = true;
    });

    try {
      // Load data in parallel (activities loaded separately to not block other data)
      final results = await Future.wait([
        _firestoreService.getAllMembers(),
        _loadAllPayments(),
        _loadMaintenanceRequests(),
        _loadOverduePayments(),
      ]);
      
      // Load activities separately (non-blocking)
      _loadRecentActivities();

      final members = results[0] as List;
      final totalRevenue = results[1] as double;
      final pendingRequests = results[2] as int;
      final overduePayments = results[3] as int;

      if (mounted) {
        setState(() {
          _totalMembers = members.length;
          _totalRevenue = totalRevenue;
          _pendingRequests = pendingRequests;
          _overduePayments = overduePayments;
          _isLoadingMembers = false;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _isLoadingMetrics = false;
        });
      }
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load dashboard data: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<double> _loadAllPayments() async {
    try {
      // Use FirebaseFirestore directly to get all payments
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // Query all successful payments for current month
      final snapshot = await firestore
          .collection('payments')
          .where('status', isEqualTo: 'success')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final paidDateStr = data['paidDate'] as String?;
        
        if (paidDateStr != null) {
          try {
            final paidDate = DateTime.parse(paidDateStr);
            // Check if payment is from current month
            if (paidDate.year == now.year && 
                paidDate.month == now.month) {
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              total += amount;
            }
          } catch (e) {
            // Skip invalid dates
            continue;
          }
        }
      }

      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> _loadMaintenanceRequests() async {
    try {
      final requests = await _firestoreService.getAllMaintenanceRequests();
      // Count requests that are open or in_progress
      return requests.where((r) => 
        r.status == 'open' || r.status == 'in_progress'
      ).length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _loadOverduePayments() async {
    try {
      final now = DateTime.now();
      final allBills = await _firestoreService.getAllUtilityBills();
      final allMembers = await _firestoreService.getAllMembers();
      
      // Count overdue payments for all members
      // Each member who hasn't paid an overdue bill counts as 1 overdue payment
      int overdueCount = 0;
      
      for (var bill in allBills) {
        if (bill.dueDate.isBefore(now) && bill.status != 'cancelled') {
          // Count how many members haven't paid this overdue bill
          for (var member in allMembers) {
            if (!bill.hasPaidBy(member.id)) {
              overdueCount++;
            }
          }
        }
      }

      return overdueCount;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadRecentActivities() async {
    if (mounted) {
      setState(() {
        _isLoadingActivities = true;
      });
    }
    
    try {
      final activities = <ActivityItem>[];

      // Load recent payments (last 10)
      try {
        final paymentsSnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('status', isEqualTo: 'success')
            .orderBy('paidDate', descending: true)
            .limit(10)
            .get();

        for (var doc in paymentsSnapshot.docs) {
          try {
            final data = doc.data();
            final payment = PaymentModel.fromMap(data).copyWith(id: doc.id);
            final member = await _firestoreService.getMemberProfile(payment.userId);
            final memberInfo = member != null
                ? '${member.apartmentNumber} - ${member.name}'
                : 'Unknown Member';

            activities.add(
              ActivityItem(
                id: payment.id,
                type: 'payment',
                title: 'Payment Received',
                subtitle: '$memberInfo - ${_formatCurrency(payment.amount)}',
                icon: Icons.payment,
                iconColor: AppColors.success,
                timestamp: payment.paidDate,
              ),
            );
          } catch (e) {
            // Skip individual payment errors
            continue;
          }
        }
      } catch (e) {
        // If orderBy fails, try without orderBy and sort in memory
        try {
          final paymentsSnapshot = await FirebaseFirestore.instance
              .collection('payments')
              .where('status', isEqualTo: 'success')
              .limit(20)
              .get();

          final payments = <PaymentModel>[];
          for (var doc in paymentsSnapshot.docs) {
            try {
              final data = doc.data();
              final payment = PaymentModel.fromMap(data).copyWith(id: doc.id);
              payments.add(payment);
            } catch (e) {
              continue;
            }
          }
          
          // Sort by paidDate in memory
          payments.sort((a, b) => b.paidDate.compareTo(a.paidDate));
          
          for (var payment in payments.take(10)) {
            try {
              final member = await _firestoreService.getMemberProfile(payment.userId);
              final memberInfo = member != null
                  ? '${member.apartmentNumber} - ${member.name}'
                  : 'Unknown Member';

              activities.add(
                ActivityItem(
                  id: payment.id,
                  type: 'payment',
                  title: 'Payment Received',
                  subtitle: '$memberInfo - ${_formatCurrency(payment.amount)}',
                  icon: Icons.payment,
                  iconColor: AppColors.success,
                  timestamp: payment.paidDate,
                ),
              );
            } catch (e) {
              continue;
            }
          }
        } catch (e2) {
          // If that also fails, just skip payments
        }
      }

      // Load recent maintenance requests (last 5)
      try {
        final maintenanceRequests = await _firestoreService.getAllMaintenanceRequests();
        for (var request in maintenanceRequests.take(5)) {
          try {
            final member = await _firestoreService.getMemberProfile(request.userId);
            final memberInfo = member != null
                ? '${member.apartmentNumber} - ${request.description}'
                : 'Unknown - ${request.description}';

            activities.add(
              ActivityItem(
                id: request.id,
                type: 'maintenance',
                title: 'Maintenance Request',
                subtitle: memberInfo,
                icon: Icons.build,
                iconColor: AppColors.info,
                timestamp: request.createdAt,
              ),
            );
          } catch (e) {
            continue;
          }
        }
      } catch (e) {
        // Skip if maintenance requests fail
      }

      // Load recent notices (last 5)
      try {
        final notices = await _firestoreService.getAllNoticesForAdmin();
        for (var notice in notices.take(5)) {
          activities.add(
            ActivityItem(
              id: notice.id,
              type: 'notice',
              title: 'New Notice Published',
              subtitle: notice.title,
              icon: Icons.notifications,
              iconColor: AppColors.warning,
              timestamp: notice.publishDate,
            ),
          );
        }
      } catch (e) {
        // Skip if notices fail
      }

      // Load recent members (last 5)
      try {
        final members = await _firestoreService.getAllMembers();
        for (var member in members.take(5)) {
          final daysSinceCreated = DateTime.now().difference(member.createdAt).inDays;
          if (daysSinceCreated <= 30) {
            activities.add(
              ActivityItem(
                id: member.id,
                type: 'member',
                title: 'New Member Added',
                subtitle: '${member.apartmentNumber} - ${member.name}',
                icon: Icons.person_add,
                iconColor: AppColors.primary,
                timestamp: member.createdAt,
              ),
            );
          }
        }
      } catch (e) {
        // Skip if members fail
      }

      // Sort by timestamp (newest first) and take top 10
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (mounted) {
        setState(() {
          _recentActivities = activities.take(10).toList();
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      // Error handling - log error but don't crash
      if (mounted) {
        setState(() {
          _recentActivities = [];
          _isLoadingActivities = false;
        });
      }
      // Silent error - don't show snackbar for activities as it's not critical
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  // Helper method to get responsive text scale
  double _getTextScaleFactor(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.aspectRatio;
    
    // Scale based on screen size
    if (diagonal > 2.5) {
      // Large tablets/landscape
      return 1.4;
    } else if (diagonal > 2.0) {
      // Tablets
      return 1.2;
    } else if (diagonal > 1.8) {
      // Large phones
      return 1.1;
    }
    // Normal phones
    return 1.0;
  }
  
  // Helper method to get responsive icon size
  double _getIconSizeFactor(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.aspectRatio;
    
    // Scale based on screen size
    if (diagonal > 2.5) {
      // Large tablets/landscape
      return 1.5;
    } else if (diagonal > 2.0) {
      // Tablets
      return 1.3;
    } else if (diagonal > 1.8) {
      // Large phones
      return 1.15;
    }
    // Normal phones
    return 1.0;
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final authService = AuthService();
                await authService.signOut();
                Get.offAllNamed('/login');
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to logout: ${e.toString()}',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.textOnPrimary,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.adminDashboard,
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Get.snackbar(
                'Notifications',
                'No new notifications',
                backgroundColor: AppColors.info,
                colorText: AppColors.textOnPrimary,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: _fadeAnimation != null
            ? FadeTransition(
                opacity: _fadeAnimation!,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppStyles.spacing20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radius16),
                boxShadow: AppStyles.shadowMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: AppStyles.heading4.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  Text(
                    'Manage Om Shree Mahavir Society',
                    style: AppStyles.bodyLarge.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppStyles.spacing24),
            
            // Key Metrics
            Text(
              'Key Metrics',
              style: AppStyles.heading5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppStyles.spacing16),
            
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Total Members',
                    value: _isLoadingMembers ? '...' : '$_totalMembers',
                    subtitle: 'Active residents',
                    icon: Icons.people,
                    iconColor: AppColors.primary,
                    onTap: () {
                      Get.toNamed('/member-management');
                    },
                  ),
                ),
                const SizedBox(width: AppStyles.spacing12),
                Expanded(
                  child: InfoCard(
                    title: 'Total Revenue',
                    value: _isLoadingMetrics ? '...' : _formatCurrency(_totalRevenue),
                    subtitle: 'This month',
                    icon: Icons.attach_money,
                    iconColor: AppColors.success,
                    onTap: () {
                      Get.toNamed('/payment-management');
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacing16),
            
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Pending Requests',
                    value: _isLoadingMetrics ? '...' : '$_pendingRequests',
                    subtitle: 'Awaiting approval',
                    icon: Icons.pending_actions,
                    iconColor: AppColors.warning,
                    onTap: () {
                      Get.toNamed('/maintenance-requests');
                    },
                  ),
                ),
                const SizedBox(width: AppStyles.spacing12),
                Expanded(
                  child: InfoCard(
                    title: 'Overdue Payments',
                    value: _isLoadingMetrics ? '...' : '$_overduePayments',
                    subtitle: 'Need attention',
                    icon: Icons.warning,
                    iconColor: AppColors.error,
                    onTap: () {
                      Get.toNamed('/payment-management');
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacing24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: AppStyles.heading5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppStyles.spacing16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppStyles.spacing12,
              mainAxisSpacing: AppStyles.spacing12,
              childAspectRatio: 1.3,
              children: [
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.people,
                  title: 'Members',
                  subtitle: 'Manage residents',
                  color: AppColors.primary,
                  onTap: () {
                    Get.toNamed('/member-management');
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.payment,
                  title: 'Payments',
                  subtitle: 'Payment management',
                  color: AppColors.success,
                  onTap: () {
                    Get.toNamed('/payment-management');
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.receipt,
                  title: 'Utility Bills',
                  subtitle: 'Bill management',
                  color: AppColors.info,
                  onTap: () {
                    Get.toNamed('/utility-bills-management');
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.build,
                  title: 'Maintenance',
                  subtitle: 'Request management',
                  color: AppColors.warning,
                  onTap: () {
                    Get.toNamed('/maintenance-requests');
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.notifications,
                  title: 'Notices',
                  subtitle: 'Notice management',
                  color: AppColors.secondary,
                  onTap: () {
                    Get.toNamed('/notices-management');
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Reports',
                  subtitle: 'View analytics',
                  color: AppColors.accent,
                  onTap: () {
                    Get.toNamed('/reports');
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.account_balance_wallet,
                  title: 'Balance Sheet',
                  subtitle: 'Yearly financials',
                  color: AppColors.primaryDark,
                  onTap: () {
                    Get.toNamed('/balance-sheet');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: AppStyles.spacing24),
            
            // Recent Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: AppStyles.heading5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Get.toNamed('/activities');
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacing16),
            
            CustomCard(
              child: _isLoadingActivities
                  ? Padding(
                      padding: const EdgeInsets.all(AppStyles.spacing32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                            const SizedBox(height: AppStyles.spacing16),
                            Text(
                              'Loading activities...',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _recentActivities.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppStyles.spacing16),
                          child: Center(
                            child: Text(
                              'No recent activities',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ..._recentActivities.take(4).map((activity) {
                              final isLast = activity == _recentActivities.take(4).last;
                              return Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      activity.icon,
                                      color: activity.iconColor,
                                    ),
                                    title: Text(activity.title),
                                    subtitle: Text(activity.subtitle),
                                    trailing: Text(
                                      _formatTimeAgo(activity.timestamp),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (!isLast) const Divider(),
                                ],
                              );
                            }),
                          ],
                        ),
            ),
            
            const SizedBox(height: AppStyles.spacing32),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(AppStyles.spacing16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
        ),
      bottomNavigationBar: BottomNavigationBar(
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
              Get.toNamed('/member-management');
              break;
            case 2:
              Get.toNamed('/payment-management');
              break;
            case 3:
              Get.toNamed('/maintenance-requests');
              break;
            case 4:
              Get.toNamed('/notices-management');
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
            icon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
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
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final textScale = _getTextScaleFactor(context);
    final iconScale = _getIconSizeFactor(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppStyles.spacing16 * textScale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radius12),
          boxShadow: AppStyles.shadowSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28 * iconScale,
              color: color,
            ),
            SizedBox(height: AppStyles.spacing4 * textScale),
            Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: AppStyles.bodySmall.fontSize! * textScale,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2 * textScale),
            Text(
              subtitle,
              style: AppStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: AppStyles.caption.fontSize! * textScale,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
