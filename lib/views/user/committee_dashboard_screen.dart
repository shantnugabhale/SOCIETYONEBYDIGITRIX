import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/payment_model.dart';
import '../../models/maintenance_request_model.dart';
import '../../models/poll_model.dart';
import '../../models/visitor_model.dart';
import '../../utils/format_utils.dart';

/// Committee Dashboard for SocietyOne by Digitrix
/// Goal: Quick decision-making
/// Layout: Status strip + Analytics cards + Action list
class CommitteeDashboardScreen extends StatefulWidget {
  const CommitteeDashboardScreen({super.key});

  @override
  State<CommitteeDashboardScreen> createState() => _CommitteeDashboardScreenState();
}

class _CommitteeDashboardScreenState extends State<CommitteeDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  
  // Status metrics
  int _pendingApprovals = 0;
  double _collectionPercentage = 0.0;
  int _openComplaints = 0;
  int _activePolls = 0;
  
  // Analytics
  double _monthlyCollection = 0.0;
  double _monthlyExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      
      // Load data in parallel - Note: getAllVisitors doesn't exist, using stream
      final visitorStream = _firestoreService.getUserVisitorsStream();
      final results = await Future.wait([
        visitorStream.first.catchError((e) => <VisitorModel>[]),
        _firestoreService.getAllUtilityBills(),
        _firestoreService.getAllMaintenanceRequests(),
        _firestoreService.getPollsStream().first,
        _firestoreService.getUserPayments(),
      ]);
      
      final visitors = results[0] as List<VisitorModel>;
      final bills = results[1] as List;
      final maintenanceRequests = results[2] as List<MaintenanceRequestModel>;
      final polls = results[3] as List<PollModel>;
      final payments = results[4] as List<PaymentModel>;
      
      // Pending approvals (visitors pending approval)
      final pendingVisitors = visitors.where((v) => 
        v.status == 'pending'
      ).length;
      
      // Collection percentage
      final totalBills = bills.length;
      final paidBills = bills.where((bill) {
        // Check if bill is paid by checking payments
        return payments.any((p) => 
          p.billIds.contains(bill.id) && p.status == 'success'
        );
      }).length;
      final collectionPct = totalBills > 0 ? (paidBills / totalBills * 100) : 0.0;
      
      // Open complaints
      final openComplaints = maintenanceRequests.where((r) => 
        r.status == 'open' || r.status == 'in_progress'
      ).length;
      
      // Active polls
      final activePolls = polls.where((p) => 
        p.endDate.isAfter(now) && p.isActive
      ).length;
      
      // Monthly collection (this month)
      final thisMonthPayments = payments.where((p) {
        final paidDate = p.paidDate;
        return paidDate.year == now.year &&
               paidDate.month == now.month &&
               p.status == 'success';
      }).toList();
      final monthlyCollection = thisMonthPayments.fold<double>(
        0.0, (sum, p) => sum + p.amount
      );
      
      if (mounted) {
        setState(() {
          _pendingApprovals = pendingVisitors;
          _collectionPercentage = collectionPct;
          _openComplaints = openComplaints;
          _activePolls = activePolls;
          _monthlyCollection = monthlyCollection;
          _monthlyExpenses = 0.0; // TODO: Load from expenses collection
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Committee Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal Status Strip
              _buildStatusStrip(),
              
              const SizedBox(height: 24),
              
              // Analytics Cards
              _buildAnalyticsSection(),
              
              const SizedBox(height: 24),
              
              // Action List
              _buildActionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStrip() {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusItem(
              'Pending Approvals',
              '$_pendingApprovals',
              Icons.pending_actions_rounded,
              AppColors.warning,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.grey200,
          ),
          Expanded(
            child: _buildStatusItem(
              'Collection',
              '${_collectionPercentage.toStringAsFixed(0)}%',
              Icons.trending_up_rounded,
              AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.grey200,
          ),
          Expanded(
            child: _buildStatusItem(
              'Complaints',
              '$_openComplaints',
              Icons.report_problem_rounded,
              AppColors.error,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.grey200,
          ),
          Expanded(
            child: _buildStatusItem(
              'Active Polls',
              '$_activePolls',
              Icons.poll_rounded,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppStyles.heading5.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: AppStyles.heading5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Monthly Collection',
                FormatUtils.formatCurrency(_monthlyCollection),
                Icons.account_balance_wallet_rounded,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnalyticsCard(
                'Monthly Expenses',
                FormatUtils.formatCurrency(_monthlyExpenses),
                Icons.trending_down_rounded,
                AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppStyles.heading5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppStyles.heading5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionItem(
          'Approve Visitors',
          '$_pendingApprovals pending',
          Icons.person_add_rounded,
          () => Get.toNamed('/visitors'),
        ),
        _buildActionItem(
          'Review Complaints',
          '$_openComplaints open',
          Icons.report_problem_rounded,
          () => Get.toNamed('/maintenance-requests'),
        ),
        _buildActionItem(
          'Create Notice',
          'Publish new notice',
          Icons.notifications_rounded,
          () => Get.toNamed('/notices-management'),
        ),
        _buildActionItem(
          'View Polls',
          '$_activePolls active',
          Icons.poll_rounded,
          () => Get.toNamed('/polls'),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: AppStyles.heading6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

