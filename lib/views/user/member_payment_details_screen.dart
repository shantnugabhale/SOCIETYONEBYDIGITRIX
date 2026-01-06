import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

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

class MemberPaymentDetailsScreen extends StatefulWidget {
  const MemberPaymentDetailsScreen({super.key});

  @override
  State<MemberPaymentDetailsScreen> createState() => _MemberPaymentDetailsScreenState();
}

class _MemberPaymentDetailsScreenState extends State<MemberPaymentDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<MemberPaymentSummary> _memberPaymentSummaries = [];

  @override
  void initState() {
    super.initState();
    _loadMemberPaymentSummaries();
  }

  Future<void> _loadMemberPaymentSummaries() async {
    setState(() {
      _isLoading = true;
    });

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load member payment details: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Adjusted flex factors to match Dashboard UI
    final int memberFlex = isTablet ? 4 : 3;
    final int otherFlex = isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Member Payment Details',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppStyles.spacing16),
                  Text(
                    'Loading payment details...',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _memberPaymentSummaries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppStyles.spacing24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppStyles.spacing16),
                        Text(
                          'No Payment Data',
                          style: AppStyles.heading6.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacing8),
                        Text(
                          'No member payment data available',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMemberPaymentSummaries,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(AppStyles.spacing16),
                    child: CustomCard(
                      padding: EdgeInsets.zero, // Remove default padding to maximize space
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppStyles.spacing8, // Reduced padding
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
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _memberPaymentSummaries.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.grey200,
                            ),
                            itemBuilder: (context, index) {
                              final summary = _memberPaymentSummaries[index];
                              return _buildMemberPaymentRow(summary, isTablet);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildMemberPaymentRow(MemberPaymentSummary summary, bool isTablet) {
    // Adjusted flex factors to match Dashboard UI
    final int memberFlex = isTablet ? 4 : 3;
    final int otherFlex = isTablet ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacing8, // Reduced padding
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
                  summary.member.name,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 14 : 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.member.apartmentNumber}, ${summary.member.buildingName}',
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
                    horizontal: 8, // Reduced internal padding
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${summary.fullyPaidCount}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(summary.fullyPaidAmount),
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
                    '${summary.pendingCount}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(summary.pendingAmount),
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
                    '${summary.overdueCount}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(summary.overdueAmount),
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
}

