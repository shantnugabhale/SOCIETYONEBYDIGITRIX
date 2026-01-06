import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem {
  final String id;
  final String type; // 'payment', 'maintenance', 'notice', 'member'
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final DateTime timestamp;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.timestamp,
  });
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<ActivityItem> _allActivities = [];

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activities = <ActivityItem>[];

      // Load payments - get all payments from collection
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .orderBy('paidDate', descending: true)
          .get();
      final payments = paymentsSnapshot.docs.map((doc) {
        final data = doc.data();
        final model = PaymentModel.fromMap(data);
        return model.copyWith(id: doc.id);
      }).toList();
      for (var payment in payments) {
        if (payment.status == 'success') {
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
        }
      }

      // Load maintenance requests
      final maintenanceRequests = await _firestoreService.getAllMaintenanceRequests();
      for (var request in maintenanceRequests) {
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
      }

      // Load notices - use admin method to get all notices
      final notices = await _firestoreService.getAllNoticesForAdmin();
      for (var notice in notices) {
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

      // Load members (new members)
      final members = await _firestoreService.getAllMembers();
      for (var member in members) {
        // Only show members created in the last 30 days
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

      // Sort by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _allActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load activities: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
      }
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today, ${DateFormat('MMM dd, yyyy').format(date)}';
    } else if (difference == 1) {
      return 'Yesterday, ${DateFormat('MMM dd, yyyy').format(date)}';
    } else if (difference < 7) {
      return '${DateFormat('EEEE').format(date)}, ${DateFormat('MMM dd, yyyy').format(date)}';
    } else {
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'All Activities',
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllActivities,
              color: AppColors.primary,
              child: _allActivities.isEmpty
                  ? Center(
                      child: Text(
                        'No activities found',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      itemCount: _allActivities.length,
                      separatorBuilder: (context, index) {
                        final current = _allActivities[index];
                        final previous = index > 0 ? _allActivities[index - 1] : null;

                        // Show date separator if date changed
                        final currentDate = DateTime(
                          current.timestamp.year,
                          current.timestamp.month,
                          current.timestamp.day,
                        );
                        final previousDate = previous != null
                            ? DateTime(
                                previous.timestamp.year,
                                previous.timestamp.month,
                                previous.timestamp.day,
                              )
                            : null;

                        if (previousDate == null || !currentDate.isAtSameMomentAs(previousDate)) {
                          return Column(
                            children: [
                              const SizedBox(height: AppStyles.spacing8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spacing12,
                                  vertical: AppStyles.spacing8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                                ),
                                child: Text(
                                  _formatDate(current.timestamp),
                                  style: AppStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppStyles.spacing8),
                            ],
                          );
                        }

                        return const Divider(height: 1);
                      },
                      itemBuilder: (context, index) {
                        final activity = _allActivities[index];
                        return CustomCard(
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(AppStyles.spacing8),
                              decoration: BoxDecoration(
                                color: activity.iconColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppStyles.radius8),
                              ),
                              child: Icon(
                                activity.icon,
                                color: activity.iconColor,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              activity.title,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  activity.subtitle,
                                  style: AppStyles.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(activity.timestamp),
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

