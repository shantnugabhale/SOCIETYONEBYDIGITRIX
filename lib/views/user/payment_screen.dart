import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/input_field.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/utility_model.dart';
import '../../models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late Razorpay _razorpay;
  
  bool _isLoading = false;
  bool _isLoadingBills = false;
  List<UtilityModel> _utilityBills = [];
  double _totalAmount = 0.0;

  // Razorpay Test Key
  static const String _razorpayKeyId = 'rzp_test_Rb1emPA3KsVeHs';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadUtilityBills();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() {
        _isLoading = false;
      });
      
      // Save payment to Firestore
      final userId = _authService.currentUser?.uid ?? '';
      final payment = PaymentModel(
        id: '',
        userId: userId,
        amount: _totalAmount,
        transactionId: response.paymentId ?? '',
        paymentMethod: 'online',
        status: 'success',
        billIds: _utilityBills.map((bill) => bill.id).toList(),
        paidDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.createPayment(payment);
      
      // Mark all utility bills as paid by this user
      for (var bill in _utilityBills) {
        // Add user ID to paidBy list
        final updatedPaidBy = List<String>.from(bill.paidBy);
        if (!updatedPaidBy.contains(userId)) {
          updatedPaidBy.add(userId);
        }
        
        final updatedBill = bill.copyWith(
          paidBy: updatedPaidBy,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateUtilityBill(bill.id, updatedBill);
      }
      
      // Show success and receipt
      Get.snackbar(
        'Success',
        'Payment successful! The admin will be notified.',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

      // Navigate to payment history and clear navigation stack so back goes to dashboard
      Future.delayed(const Duration(seconds: 1), () {
        // Clear navigation stack and go to payment history
        // This ensures back button from payment history goes to dashboard
        Get.offAllNamed('/payment-history', arguments: {'fromPaymentSuccess': true});
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Warning',
        'Payment successful but failed to save: ${e.toString()}',
        backgroundColor: AppColors.warning,
        colorText: AppColors.textOnPrimary,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isLoading = false;
    });
    
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message}',
      backgroundColor: AppColors.error,
      colorText: AppColors.textOnPrimary,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet',
      'Wallet Name: ${response.walletName}',
      backgroundColor: AppColors.info,
      colorText: AppColors.textOnPrimary,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> _loadUtilityBills() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBills = true;
    });

    try {
      final bills = await _firestoreService.getAllUtilityBills();
      final userId = _authService.currentUser?.uid ?? '';
      
      // Filter only bills that this user hasn't paid yet
      final now = DateTime.now();
      final unpaidBills = bills.where((bill) =>
        !bill.hasPaidBy(userId) && bill.status != 'cancelled'
      ).toList();

      // Calculate total amount with overdue penalties - optimized
      final total = unpaidBills.fold<double>(0.0, (sum, bill) {
        final billAmount = bill.dueDate.isBefore(now)
            ? bill.totalAmount + bill.overdueAmount
            : bill.totalAmount;
        return sum + billAmount;
      });
      
      if (!mounted) return;
      setState(() {
        _utilityBills = unpaidBills;
        _totalAmount = total;
        _amountController.text = total.toStringAsFixed(2);
        _isLoadingBills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingBills = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load bills: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  void _handlePayment() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      _openRazorpayCheckout(amount);
    }
  }

  void _openRazorpayCheckout(double amount) {
    setState(() {
      _isLoading = true;
    });

    // Configure payment options
    final options = <String, dynamic>{
      'key': _razorpayKeyId,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Society Management',
      'description': 'Utility Bills Payment',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'external': {
        'wallets': ['paytm']
      },
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to open payment gateway: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.makePayment,
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _isLoadingBills
          ? const Center(child: CircularProgressIndicator())
          : _utilityBills.isEmpty
              ? Center(
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
                        'No pending payments',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Summary
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Summary',
                                style: AppStyles.heading6.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppStyles.spacing16),
                              
                              // List of utility bills
                              ..._utilityBills.map<Widget>((bill) {
                                final now = DateTime.now();
                                final isExpired = bill.dueDate.isBefore(now);
                                final hasOverdue = isExpired && bill.overdueAmount > 0;
                                final billAmount = bill.totalAmount;
                                final totalWithOverdue = hasOverdue 
                                    ? billAmount + bill.overdueAmount 
                                    : billAmount;
                                
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${bill.utilityType} Bill',
                                                style: AppStyles.bodyMedium.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (hasOverdue)
                                                Text(
                                                  'Overdue',
                                                  style: AppStyles.bodySmall.copyWith(
                                                    color: AppColors.warning,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        hasOverdue
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '₹${billAmount.toStringAsFixed(0)}',
                                                    style: AppStyles.bodyMedium.copyWith(
                                                      color: AppColors.textSecondary,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${totalWithOverdue.toStringAsFixed(0)}',
                                                    style: AppStyles.bodyLarge.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                '₹${billAmount.toStringAsFixed(0)}',
                                                style: AppStyles.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                      ],
                                    ),
                                    const SizedBox(height: AppStyles.spacing8),
                                  ],
                                );
                              }),
                              
                              const Divider(),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: AppStyles.heading6.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '₹${_totalAmount.toStringAsFixed(0)}',
                                    style: AppStyles.heading5.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppStyles.spacing24),
                        
                        // Payment Details
                        Text(
                          'Payment Details',
                          style: AppStyles.heading5.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacing16),
                        
                        // Amount Field
                        CustomInputField(
                          label: 'Amount',
                          hint: 'Enter amount',
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            Icons.currency_rupee,
                            color: AppColors.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.amountRequired;
                            }
                            if (double.tryParse(value) == null) {
                              return AppStrings.amountInvalid;
                            }
                            return null;
                          },
                          isRequired: true,
                        ),
                        
                        const SizedBox(height: AppStyles.spacing32),
                        
                        // Pay Now Button
                        CustomButton(
                          text: 'Pay Now',
                          onPressed: _handlePayment,
                          isLoading: _isLoading,
                          icon: Icons.payment,
                        ),
                        
                        const SizedBox(height: AppStyles.spacing16),
                        
                        // Security Notice
                        Container(
                          padding: const EdgeInsets.all(AppStyles.spacing16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppStyles.radius8),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.security,
                                color: AppColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: AppStyles.spacing12),
                              Expanded(
                                child: Text(
                                  'Your payment is secure and encrypted',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppStyles.spacing32),
                      ],
                    ),
                  ),
                ),
    );
  }

}
