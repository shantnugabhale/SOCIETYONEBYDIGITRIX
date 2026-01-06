import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  
  // Statistics
  int _totalMembers = 0;
  double _totalRevenue = 0.0;
  double _thisMonthRevenue = 0.0;
  int _totalPayments = 0;
  int _successfulPayments = 0;
  int _pendingPayments = 0;
  int _failedPayments = 0;
  int _totalBills = 0;
  int _paidBills = 0;
  int _pendingBills = 0;
  int _overdueBills = 0;
  double _paidBillsAmount = 0.0;
  double _pendingBillsAmount = 0.0;
  double _overdueBillsAmount = 0.0;
  int _totalMaintenanceRequests = 0;
  int _openRequests = 0;
  int _inProgressRequests = 0;
  int _completedRequests = 0;
  
  // Monthly revenue data
  List<Map<String, dynamic>> _monthlyRevenue = [];
  
  // Member payment data
  List<MemberPaymentSummary> _memberPaymentSummaries = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadMemberStats(),
        _loadPaymentStats(),
        _loadBillStats(),
        _loadMaintenanceStats(),
        _loadMonthlyRevenue(),
        _loadMemberPaymentSummaries(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load reports: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
      }
    }
  }

  Future<void> _loadMemberStats() async {
    try {
      final members = await _firestoreService.getAllMembers();
      setState(() {
        _totalMembers = members.length;
      });
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _loadPaymentStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);

      final snapshot = await firestore
          .collection('payments')
          .get();

      double totalRevenue = 0.0;
      double thisMonthTotal = 0.0;
      int totalPayments = snapshot.docs.length;
      int successful = 0;
      int pending = 0;
      int failed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final paidDateStr = data['paidDate'] as String?;

        if (status == 'success') {
          successful++;
          totalRevenue += amount;

          if (paidDateStr != null) {
            try {
              final paidDate = DateTime.parse(paidDateStr);
              if (paidDate.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
                thisMonthTotal += amount;
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        } else if (status == 'pending') {
          pending++;
        } else if (status == 'failed' || status == 'cancelled') {
          failed++;
        }
      }

      setState(() {
        _totalRevenue = totalRevenue;
        _thisMonthRevenue = thisMonthTotal;
        _totalPayments = totalPayments;
        _successfulPayments = successful;
        _pendingPayments = pending;
        _failedPayments = failed;
      });
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _loadBillStats() async {
    try {
      final bills = await _firestoreService.getAllUtilityBills();
      final now = DateTime.now();

      int total = bills.length;
      int paid = 0;
      int pending = 0;
      int overdue = 0;
      double paidAmount = 0.0;
      double pendingAmount = 0.0;
      double overdueAmount = 0.0;

      for (var bill in bills) {
        if (bill.status == 'cancelled') continue;

        final billTotal = bill.totalAmount + bill.overdueAmount;

        if (bill.paidBy.isNotEmpty) {
          paid++;
          paidAmount += billTotal;
        } else if (bill.dueDate.isBefore(now)) {
          overdue++;
          overdueAmount += billTotal;
        } else {
          pending++;
          pendingAmount += billTotal;
        }
      }

      setState(() {
        _totalBills = total;
        _paidBills = paid;
        _pendingBills = pending;
        _overdueBills = overdue;
        _paidBillsAmount = paidAmount;
        _pendingBillsAmount = pendingAmount;
        _overdueBillsAmount = overdueAmount;
      });
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _loadMaintenanceStats() async {
    try {
      final requests = await _firestoreService.getAllMaintenanceRequests();

      int total = requests.length;
      int open = 0;
      int inProgress = 0;
      int completed = 0;

      for (var request in requests) {
        if (request.status == 'open') {
          open++;
        } else if (request.status == 'in_progress') {
          inProgress++;
        } else if (request.status == 'completed' || request.status == 'closed') {
          completed++;
        }
      }

      setState(() {
        _totalMaintenanceRequests = total;
        _openRequests = open;
        _inProgressRequests = inProgress;
        _completedRequests = completed;
      });
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _loadMonthlyRevenue() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final List<Map<String, dynamic>> monthlyData = [];

      // Get last 6 months
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(monthDate.year, monthDate.month, 1);
        final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);

        final snapshot = await firestore
            .collection('payments')
            .where('status', isEqualTo: 'success')
            .get();

        double monthTotal = 0.0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final paidDateStr = data['paidDate'] as String?;

          if (paidDateStr != null) {
            try {
              final paidDate = DateTime.parse(paidDateStr);
              if (paidDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                  paidDate.isBefore(monthEnd.add(const Duration(days: 1)))) {
                final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                monthTotal += amount;
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        }

        monthlyData.add({
          'month': DateFormat('MMM yyyy').format(monthDate),
          'revenue': monthTotal,
        });
      }

      setState(() {
        _monthlyRevenue = monthlyData;
      });
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _loadMemberPaymentSummaries() async {
    try {
      final members = await _firestoreService.getAllMembers();
      final bills = await _firestoreService.getAllUtilityBills();
      final now = DateTime.now();

      final summaries = <MemberPaymentSummary>[];

      for (var member in members) {
        int fullyPaidCount = 0;
        double fullyPaidAmount = 0.0;
        int pendingCount = 0;
        double pendingAmount = 0.0;
        int overdueCount = 0;
        double overdueAmount = 0.0;

        for (var bill in bills) {
          if (bill.status == 'cancelled') continue;

          final hasPaid = bill.hasPaidBy(member.id);
          final isOverdue = bill.dueDate.isBefore(now);

          if (hasPaid) {
            fullyPaidCount++;
            fullyPaidAmount += bill.totalAmount;
          } else if (isOverdue) {
            overdueCount++;
            overdueAmount += bill.totalAmount + bill.overdueAmount;
          } else {
            pendingCount++;
            pendingAmount += bill.totalAmount;
          }
        }

        summaries.add(
          MemberPaymentSummary(
            member: member,
            fullyPaidCount: fullyPaidCount,
            fullyPaidAmount: fullyPaidAmount,
            pendingCount: pendingCount,
            pendingAmount: pendingAmount,
            overdueCount: overdueCount,
            overdueAmount: overdueAmount,
          ),
        );
      }

      // Sort by overdue amount (descending), then by pending amount
      summaries.sort((a, b) {
        final overdueCompare = b.overdueAmount.compareTo(a.overdueAmount);
        if (overdueCompare != 0) {
          return overdueCompare;
        }
        return b.pendingAmount.compareTo(a.pendingAmount);
      });

      setState(() {
        _memberPaymentSummaries = summaries;
      });
    } catch (e) {
      // Error handling
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

  Widget _buildRevenueChart() {
    if (_monthlyRevenue.isEmpty) {
      return Center(
        child: Text(
          'No revenue data available',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Convert monthly revenue to FlSpot data
    final spots = _monthlyRevenue.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['revenue'] as double);
    }).toList();

    // Calculate min and max for better visualization
    final revenues = _monthlyRevenue.map((d) => d['revenue'] as double).toList();
    final maxRevenue = revenues.reduce((a, b) => a > b ? a : b);
    final minRevenue = revenues.reduce((a, b) => a < b ? a : b);
    final yMax = maxRevenue * 1.2; // Add 20% padding
    final yMin = minRevenue > 0 ? (minRevenue * 0.8) : 0.0; // Add 20% padding or start from 0
    final interval = (yMax - yMin) / 5.0;

    // Get responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing8, vertical: AppStyles.spacing8),
      child: LineChart(
        LineChartData(
          minY: yMin,
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.grey200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isTablet ? 40 : 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _monthlyRevenue.length) {
                    final month = _monthlyRevenue[value.toInt()]['month'] as String;
                    // Show abbreviated month for small screens
                    final displayText = isTablet ? month : month.split(' ')[0];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        displayText,
                        style: AppStyles.caption.copyWith(
                          fontSize: isTablet ? 12 : 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isTablet ? 50 : 40,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      _formatCurrency(value),
                      style: AppStyles.caption.copyWith(
                        fontSize: isTablet ? 11 : 9,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: isTablet ? 5 : 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChart() {
    if (_totalPayments == 0) {
      return Center(
        child: Text(
          'No payment data available',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Get responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Calculate percentages for pie chart
    final total = _totalPayments.toDouble();
    final successfulPercent = (_successfulPayments / total) * 100;
    final pendingPercent = (_pendingPayments / total) * 100;
    final failedPercent = (_failedPayments / total) * 100;

    // Create pie chart sections
    final sections = <PieChartSectionData>[];

    if (successfulPercent > 0) {
      sections.add(
        PieChartSectionData(
          value: successfulPercent,
          title: '${successfulPercent.toStringAsFixed(1)}%',
          color: AppColors.success,
          radius: isTablet ? 60 : 50,
          titleStyle: AppStyles.bodySmall.copyWith(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
    }

    if (pendingPercent > 0) {
      sections.add(
        PieChartSectionData(
          value: pendingPercent,
          title: '${pendingPercent.toStringAsFixed(1)}%',
          color: AppColors.warning,
          radius: isTablet ? 60 : 50,
          titleStyle: AppStyles.bodySmall.copyWith(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
    }

    if (failedPercent > 0) {
      sections.add(
        PieChartSectionData(
          value: failedPercent,
          title: '${failedPercent.toStringAsFixed(1)}%',
          color: AppColors.error,
          radius: isTablet ? 60 : 50,
          titleStyle: AppStyles.bodySmall.copyWith(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: isTablet ? 2 : 1,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: isTablet ? 40 : 30,
                startDegreeOffset: -90,
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: isTablet ? 1 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  'Successful',
                  _successfulPayments,
                  AppColors.success,
                  isTablet,
                ),
                const SizedBox(height: AppStyles.spacing12),
                _buildLegendItem(
                  'Pending',
                  _pendingPayments,
                  AppColors.warning,
                  isTablet,
                ),
                const SizedBox(height: AppStyles.spacing12),
                _buildLegendItem(
                  'Failed',
                  _failedPayments,
                  AppColors.error,
                  isTablet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, bool isTablet) {
    return Row(
      children: [
        Container(
          width: isTablet ? 16 : 12,
          height: isTablet ? 16 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppStyles.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppStyles.bodySmall.copyWith(
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
              Text(
                '$value transactions',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 11 : 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUtilityBillsStatusChart() {
    if (_totalBills == 0) {
      return Center(
        child: Text(
          'No utility bills data available',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Get responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Calculate percentages for pie chart
    final total = _totalBills.toDouble();
    final paidPercent = (_paidBills / total) * 100;
    final pendingPercent = (_pendingBills / total) * 100;
    final overduePercent = (_overdueBills / total) * 100;

    // Create pie chart sections
    final sections = <PieChartSectionData>[];

    if (paidPercent > 0) {
      sections.add(
        PieChartSectionData(
          value: paidPercent,
          title: '${paidPercent.toStringAsFixed(1)}%',
          color: AppColors.success,
          radius: isTablet ? 60 : 50,
          titleStyle: AppStyles.bodySmall.copyWith(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
    }

    if (pendingPercent > 0) {
      sections.add(
        PieChartSectionData(
          value: pendingPercent,
          title: '${pendingPercent.toStringAsFixed(1)}%',
          color: AppColors.warning,
          radius: isTablet ? 60 : 50,
          titleStyle: AppStyles.bodySmall.copyWith(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
    }

    if (overduePercent > 0) {
      sections.add(
        PieChartSectionData(
          value: overduePercent,
          title: '${overduePercent.toStringAsFixed(1)}%',
          color: AppColors.error,
          radius: isTablet ? 60 : 50,
          titleStyle: AppStyles.bodySmall.copyWith(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: isTablet ? 2 : 1,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: isTablet ? 40 : 30,
                startDegreeOffset: -90,
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: isTablet ? 1 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUtilityLegendItem(
                  'Paid',
                  _paidBills,
                  _paidBillsAmount,
                  AppColors.success,
                  isTablet,
                ),
                const SizedBox(height: AppStyles.spacing12),
                _buildUtilityLegendItem(
                  'Pending',
                  _pendingBills,
                  _pendingBillsAmount,
                  AppColors.warning,
                  isTablet,
                ),
                const SizedBox(height: AppStyles.spacing12),
                _buildUtilityLegendItem(
                  'Overdue',
                  _overdueBills,
                  _overdueBillsAmount,
                  AppColors.error,
                  isTablet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityLegendItem(
    String label,
    int count,
    double amount,
    Color color,
    bool isTablet,
  ) {
    return Row(
      children: [
        Container(
          width: isTablet ? 16 : 12,
          height: isTablet ? 16 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppStyles.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppStyles.bodySmall.copyWith(
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
              Text(
                '$count bills • ${_formatCurrency(amount)}',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 11 : 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reports & Analytics',
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
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(AppStyles.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Overview
                    Text(
                      'Revenue Overview',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Total Revenue',
                            value: _formatCurrency(_totalRevenue),
                            subtitle: 'All time',
                            icon: Icons.account_balance_wallet,
                            iconColor: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'This Month',
                            value: _formatCurrency(_thisMonthRevenue),
                            subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
                            icon: Icons.trending_up,
                            iconColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    // Monthly Revenue Chart
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppStyles.spacing16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Revenue (Last 6 Months)',
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing4),
                                Text(
                                  'Revenue trend over the past 6 months',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Responsive chart height
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: _buildRevenueChart(),
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                          // Monthly data list
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing16),
                            child: Column(
                              children: _monthlyRevenue.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(
                                                alpha: 1.0 - (index * 0.12),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: AppStyles.spacing8),
                                          Text(
                                            data['month'],
                                            style: AppStyles.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatCurrency(data['revenue']),
                                        style: AppStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spacing24),
                    
                    // Payment Status Chart
                    Text(
                      'Payment Distribution',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppStyles.spacing16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Status Overview',
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing4),
                                Text(
                                  'Breakdown of payment transactions',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: _buildPaymentStatusChart(),
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spacing24),
                    
                    // Payment Statistics
                    Text(
                      'Payment Statistics',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Total Payments',
                            value: '$_totalPayments',
                            subtitle: 'All transactions',
                            icon: Icons.payment,
                            iconColor: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'Successful',
                            value: '$_successfulPayments',
                            subtitle: 'Completed',
                            icon: Icons.check_circle,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Pending',
                            value: '$_pendingPayments',
                            subtitle: 'Awaiting',
                            icon: Icons.pending,
                            iconColor: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'Failed',
                            value: '$_failedPayments',
                            subtitle: 'Errors',
                            icon: Icons.error,
                            iconColor: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppStyles.spacing24),
                    
                    // Member Statistics
                    Text(
                      'Member Statistics',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    InfoCard(
                      title: 'Total Members',
                      value: '$_totalMembers',
                      subtitle: 'Registered residents',
                      icon: Icons.people,
                      iconColor: AppColors.primary,
                    ),
                    
                    const SizedBox(height: AppStyles.spacing24),
                    
                    // Utility Bills Statistics
                    Text(
                      'Utility Bills Statistics',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Total Bills',
                            value: '$_totalBills',
                            subtitle: 'All bills',
                            icon: Icons.receipt,
                            iconColor: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'Paid',
                            value: '$_paidBills',
                            subtitle: 'Completed',
                            icon: Icons.check,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Pending',
                            value: '$_pendingBills',
                            subtitle: 'Upcoming',
                            icon: Icons.schedule,
                            iconColor: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'Overdue',
                            value: '$_overdueBills',
                            subtitle: 'Late',
                            icon: Icons.warning,
                            iconColor: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppStyles.spacing24),
                    
                    // Utility Bills Distribution
                    Text(
                      'Utility Bills Distribution',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppStyles.spacing16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Utility Bills Status Overview',
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing4),
                                Text(
                                  'Breakdown of utility bills by status',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: _buildUtilityBillsStatusChart(),
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spacing24),
                    
                    // Maintenance Statistics
                    Text(
                      'Maintenance Statistics',
                      style: AppStyles.heading5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'Total Requests',
                            value: '$_totalMaintenanceRequests',
                            subtitle: 'All requests',
                            icon: Icons.build,
                            iconColor: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'Open',
                            value: '$_openRequests',
                            subtitle: 'New',
                            icon: Icons.folder_open,
                            iconColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            title: 'In Progress',
                            value: '$_inProgressRequests',
                            subtitle: 'Active',
                            icon: Icons.hourglass_empty,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacing12),
                        Expanded(
                          child: InfoCard(
                            title: 'Completed',
                            value: '$_completedRequests',
                            subtitle: 'Closed',
                            icon: Icons.done_all,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    
                                         const SizedBox(height: AppStyles.spacing32),
                     
                     // Member Payment Details
                     Text(
                       'Member Payment Details',
                       style: AppStyles.heading5.copyWith(
                         color: AppColors.textPrimary,
                       ),
                     ),
                     const SizedBox(height: AppStyles.spacing16),
                     _buildMemberPaymentDetails(),
                     
                     const SizedBox(height: AppStyles.spacing32),
                   ],
                 ),
               ),
             ),
     );
   }

  Widget _buildMemberPaymentDetails() {
    if (_memberPaymentSummaries.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacing16),
          child: Center(
            child: Text(
              'No member payment data available',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return CustomCard(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppStyles.spacing16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppStyles.radius12),
                topRight: Radius.circular(AppStyles.radius12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: isTablet ? 3 : 2,
                  child: Text(
                    'Member',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Paid',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pending',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Overdue',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Member list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _memberPaymentSummaries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final summary = _memberPaymentSummaries[index];
              return _buildMemberPaymentRow(summary, isTablet);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPaymentRow(MemberPaymentSummary summary, bool isTablet) {
    return InkWell(
      onTap: () {
        // Could navigate to detailed member payment page
      },
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppStyles.spacing16 : AppStyles.spacing12),
        child: Row(
          children: [
            // Member Info
            Expanded(
              flex: isTablet ? 3 : 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.member.name,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.member.apartmentNumber}, ${summary.member.buildingName}',
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: isTablet ? 12 : 10,
                    ),
                  ),
                ],
              ),
            ),
            // Paid
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${summary.fullyPaidCount}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 12 : 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(summary.fullyPaidAmount),
                    style: AppStyles.caption.copyWith(
                      fontSize: isTablet ? 10 : 9,
                    ),
                  ),
                ],
              ),
            ),
            // Pending
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${summary.pendingCount}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 12 : 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(summary.pendingAmount),
                    style: AppStyles.caption.copyWith(
                      fontSize: isTablet ? 10 : 9,
                    ),
                  ),
                ],
              ),
            ),
            // Overdue
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${summary.overdueCount}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 12 : 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(summary.overdueAmount),
                    style: AppStyles.caption.copyWith(
                      fontSize: isTablet ? 10 : 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 }

// Helper class for member payment summary
class MemberPaymentSummary {
  final UserModel member;
  final int fullyPaidCount;
  final double fullyPaidAmount;
  final int pendingCount;
  final double pendingAmount;
  final int overdueCount;
  final double overdueAmount;

  MemberPaymentSummary({
    required this.member,
    required this.fullyPaidCount,
    required this.fullyPaidAmount,
    required this.pendingCount,
    required this.pendingAmount,
    required this.overdueCount,
    required this.overdueAmount,
  });
}
