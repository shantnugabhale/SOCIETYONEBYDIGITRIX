import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../services/receipt_service.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../widgets/card_widget.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<PaymentModel> _payments = [];
  UserModel? _currentUser;
  bool _fromPaymentSuccess = false;

  @override
  void initState() {
    super.initState();
    // Check if we came from payment success
    final args = Get.arguments;
    if (args != null && args is Map && args['fromPaymentSuccess'] == true) {
      _fromPaymentSuccess = true;
    }
    _loadPayments();
  }

  // Handle back button - go to dashboard if came from payment success
  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop && _fromPaymentSuccess) {
      Get.offAllNamed('/dashboard');
    }
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payments = await _firestoreService.getUserPayments();
      final user = await _firestoreService.getCurrentUserProfile();
      setState(() {
        _payments = payments;
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load payments: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showReceipt(PaymentModel payment) async {
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Fetch user profile and bills
      _currentUser ??= await _firestoreService.getCurrentUserProfile();

      // Fetch all utility bills
      final allBills = await _firestoreService.getAllUtilityBills();

      // Close loading dialog
      Get.back();

      // Generate and show PDF receipt
      await ReceiptService.generateAndShowReceipt(
        payment: payment,
        bills: allBills,
        user: _currentUser!,
      );
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
    return PopScope<Object?>(
      canPop: !_fromPaymentSuccess,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Payment History',
            style: AppStyles.heading6.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_fromPaymentSuccess) {
                Get.offAllNamed('/dashboard');
              } else {
                Get.back();
              }
            },
          ),
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return CustomCard(
                      margin: const EdgeInsets.only(bottom: AppStyles.spacing16),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(AppStyles.spacing12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppStyles.radius8),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          '₹${payment.amount.toStringAsFixed(2)}',
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paid on ${_formatDate(payment.paidDate)}'),
                            Text('ID: ${payment.transactionId.substring(0, 12)}...'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.receipt),
                          onPressed: () => _showReceipt(payment),
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

