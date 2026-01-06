import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/receipt_service.dart';
import '../../models/utility_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../utils/format_utils.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  List<UtilityModel> _utilityBills = [];
  List<PaymentModel> _payments = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUtilityBills();
  }

  Future<void> _loadUtilityBills() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Load data in parallel for better performance
      final results = await Future.wait([
        _firestoreService.getAllUtilityBills(),
        _firestoreService.getUserPayments(),
        _firestoreService.getCurrentUserProfile(),
      ]);

      if (!mounted) return;
      setState(() {
        _utilityBills = results[0] as List<UtilityModel>;
        _payments = results[1] as List<PaymentModel>;
        _currentUser = results[2] as UserModel?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load bills: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  Future<void> _showMonthlyReceipt(String monthYear, List<UtilityModel> paidBills) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Collect all payment IDs for these bills
      final Set<String> paymentIds = {};
      for (var bill in paidBills) {
        for (var payment in _payments) {
          if (payment.billIds.contains(bill.id)) {
            paymentIds.add(payment.id);
          }
        }
      }

      if (paymentIds.isEmpty) {
        Get.back();
        Get.snackbar(
          'Error',
          'No payment found for bills in $monthYear',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
        return;
      }

      // Find all payments that cover these bills
      final relevantPayments = _payments.where((p) => paymentIds.contains(p.id)).toList();

      // Calculate total amount from the bills themselves (not payments, to avoid double counting)
      final totalAmount = paidBills.fold<double>(
        0.0,
        (sum, bill) => sum + bill.totalAmount,
      );

      // Get the latest payment date
      final latestPaidDate = relevantPayments.map((p) => p.paidDate).reduce(
        (a, b) => a.isAfter(b) ? a : b,
      );

      // Create a combined payment model for receipt generation
      // Use the first payment's transaction ID as primary, or combine them
      final transactionIds = relevantPayments.map((p) => p.transactionId).join(', ');
      final combinedPayment = PaymentModel(
        id: relevantPayments.first.id,
        userId: relevantPayments.first.userId,
        amount: totalAmount,
        transactionId: transactionIds.length > 50 
            ? '${transactionIds.substring(0, 47)}...'
            : transactionIds,
        paymentMethod: relevantPayments.first.paymentMethod,
        status: 'success',
        billIds: paidBills.map((b) => b.id).toList(),
        paidDate: latestPaidDate,
        createdAt: relevantPayments.first.createdAt,
      );

      // Generate and show PDF receipt
      await ReceiptService.generateAndShowReceipt(
        payment: combinedPayment,
        bills: paidBills,
        user: _currentUser!,
      );

      // Close loading dialog
      Get.back();
    } catch (e) {
      Get.back(); // Close loading dialog if open
      Get.snackbar(
        'Error',
        'Failed to generate receipt: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.utilities,
            style: AppStyles.heading6.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
            indicatorColor: AppColors.textOnPrimary,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
            labelStyle: AppStyles.bodyLarge,
            unselectedLabelStyle: AppStyles.bodyMedium,
            dividerColor: Colors.transparent,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUpcomingBills(),
                  _buildHistoryBills(),
                ],
              ),
      ),
    );
  }

  /// Builds the list for the "Upcoming" tab
  Widget _buildUpcomingBills() {
    final userId = _authService.currentUser?.uid ?? '';
    final now = DateTime.now();
    final upcomingBills = _utilityBills.where((bill) {
      // Show bills that this user hasn't paid AND not cancelled AND not expired
      return !bill.hasPaidBy(userId) && bill.status != 'cancelled' && bill.dueDate.isAfter(now);
    }).toList();

    if (upcomingBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No upcoming bills',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomCard(
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingBills.length,
                  itemBuilder: (context, index) {
                    final bill = upcomingBills[index];
                    final isLast = index == upcomingBills.length - 1;
                    
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            FormatUtils.getBillIcon(bill.utilityType),
                            color: FormatUtils.getBillColor(bill.utilityType),
                          ),
                          title: Text('${bill.utilityType} Bill'),
                          subtitle: Text('Due: ${FormatUtils.formatDateShort(bill.dueDate)}'),
                          trailing: Text(
                            '₹${bill.totalAmount.toStringAsFixed(0)}',
                            style: AppStyles.heading6.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (!isLast) const Divider(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list for the "History" tab
  Widget _buildHistoryBills() {
    final userId = _authService.currentUser?.uid ?? '';
    final now = DateTime.now();
    final historyBills = _utilityBills.where((bill) {
      // Show bills that this user has paid, OR all cancelled/expired bills
      return bill.hasPaidBy(userId) || bill.status == 'cancelled' || bill.dueDate.isBefore(now);
    }).toList();

    if (historyBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No payment history',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group bills by month - optimized
    final Map<String, List<UtilityModel>> groupedBills = {};
    for (var bill in historyBills) {
      final monthYear = '${FormatUtils.getMonthName(bill.dueDate.month)} ${bill.dueDate.year}';
      groupedBills.putIfAbsent(monthYear, () => []).add(bill);
    }

    // Sort months in descending order
    final sortedMonths = groupedBills.keys.toList()
      ..sort((a, b) {
        final aParts = a.split(' ');
        final bParts = b.split(' ');
        final aYear = int.parse(aParts[1]);
        final bYear = int.parse(bParts[1]);
        if (aYear != bYear) return bYear.compareTo(aYear);
        
        final aMonth = FormatUtils.getMonthIndex(aParts[0]);
        final bMonth = FormatUtils.getMonthIndex(bParts[0]);
        return bMonth.compareTo(aMonth);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var month in sortedMonths) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  month,
                  style: AppStyles.heading5,
                ),
                Builder(
                  builder: (context) {
                    // Get paid bills for this month
                    final paidBillsForMonth = groupedBills[month]!
                        .where((bill) => bill.hasPaidBy(userId))
                        .toList();
                    
                    // Only show receipt button if there are paid bills
                    if (paidBillsForMonth.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return TextButton.icon(
                      onPressed: () => _showMonthlyReceipt(month, paidBillsForMonth),
                      icon: const Icon(
                        Icons.receipt,
                        size: 18,
                      ),
                      label: const Text('Receipt'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacing16),
            for (var bill in groupedBills[month]!) ...[
              Builder(
                builder: (context) {
                  final isPaidByUser = bill.hasPaidBy(userId);
                  final now = DateTime.now();
                  final isExpired = bill.dueDate.isBefore(now);
                  
                  return PaymentCard(
                    title: '${bill.utilityType} Bill',
                    amount: '₹${bill.totalAmount.toStringAsFixed(0)}',
                    status: isPaidByUser
                        ? 'Paid'
                        : bill.status == 'cancelled'
                            ? 'Cancelled'
                            : isExpired
                                ? 'Overdue'
                                : 'Pending',
                    dueDate: FormatUtils.formatDateShort(bill.dueDate),
                    onTap: null, // Removed receipt functionality from individual bills
                  );
                },
              ),
              const SizedBox(height: AppStyles.spacing12),
            ],
            const SizedBox(height: AppStyles.spacing24),
          ],
        ],
      ),
    );
  }

}
