import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/payment_model.dart';
import '../../models/maintenance_request_model.dart';
import '../../utils/format_utils.dart';

/// Activity Screen - Shows recent activity history
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<ActivityItem> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _firestoreService.getUserPayments(),
        _firestoreService.getUserMaintenanceRequests(),
      ]);
      
      final payments = results[0] as List<PaymentModel>;
      final maintenanceRequests = results[1] as List<MaintenanceRequestModel>;
      
      final activities = <ActivityItem>[];
      
      // Add payment activities
      for (var payment in payments.take(10)) {
        activities.add(ActivityItem(
          title: 'Payment made',
          subtitle: FormatUtils.formatCurrency(payment.amount),
          date: payment.paidDate,
          icon: Icons.payment_rounded,
          color: AppColors.success,
        ));
      }
      
      // Add maintenance request activities
      for (var request in maintenanceRequests.take(10)) {
        activities.add(ActivityItem(
          title: 'Maintenance request',
          subtitle: request.description,
          date: request.requestedDate,
          icon: Icons.build_rounded,
          color: AppColors.info,
        ));
      }
      
      // Sort by date (newest first)
      activities.sort((a, b) => b.date.compareTo(a.date));
      
      if (mounted) {
        setState(() {
          _activities = activities.take(20).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activity yet',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadActivities,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      return _buildActivityItem(_activities[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildActivityItem(ActivityItem item) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.title,
          style: AppStyles.heading6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.subtitle),
            const SizedBox(height: 4),
            Text(
              FormatUtils.formatDate(item.date),
              style: AppStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
  });
}

