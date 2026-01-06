import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/input_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/firestore_service.dart';
import '../../models/utility_model.dart';

class UtilityBillsManagementScreen extends StatefulWidget {
  const UtilityBillsManagementScreen({super.key});

  @override
  State<UtilityBillsManagementScreen> createState() => _UtilityBillsManagementScreenState();
}

class _UtilityBillsManagementScreenState extends State<UtilityBillsManagementScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  bool _isLoading = false;
  List<UtilityModel> _utilityBills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUtilityBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUtilityBills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bills = await _firestoreService.getAllUtilityBills();
      setState(() {
        _utilityBills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load utility bills: ${e.toString()}',
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
          'Utility Bills Management',
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
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBillDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveBills(),
                _buildHistoryBills(),
              ],
            ),
    );
  }

  Widget _buildActiveBills() {
    final now = DateTime.now();
    final activeBills = _utilityBills.where((bill) {
      // Only show bills that are not paid/cancelled AND not expired
      return bill.status != 'paid' && bill.status != 'cancelled' && bill.dueDate.isAfter(now);
    }).toList();
    
    if (activeBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No active bills yet',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      itemCount: activeBills.length,
      itemBuilder: (context, index) {
        final bill = activeBills[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppStyles.spacing16),
          child: ListTile(
            leading: Icon(
              _getBillIcon(bill.utilityType),
              color: AppColors.primary,
              size: 32,
            ),
            title: Text('${bill.utilityType.toUpperCase()} Bill'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ₹${bill.totalAmount.toStringAsFixed(0)}'),
                Text('Due: ${_formatDate(bill.dueDate)}'),
                if (bill.overdueAmount > 0) Text('Overdue: ₹${bill.overdueAmount.toStringAsFixed(0)}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditBillDialog(bill);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(bill);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: AppColors.primary),
                      SizedBox(width: AppStyles.spacing8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: AppStyles.spacing8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryBills() {
    final now = DateTime.now();
    final historyBills = _utilityBills.where((bill) {
      // Show bills that are paid, cancelled, OR expired (past due date)
      return bill.status == 'paid' || bill.status == 'cancelled' || bill.dueDate.isBefore(now);
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
              'No history yet',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppStyles.spacing16),
      itemCount: historyBills.length,
      itemBuilder: (context, index) {
        final bill = historyBills[index];
        final now = DateTime.now();
        final isExpired = bill.dueDate.isBefore(now) && bill.status != 'paid' && bill.status != 'cancelled';
        
        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppStyles.spacing16),
          child: ListTile(
            leading: Icon(
              _getBillIcon(bill.utilityType),
              color: bill.status == 'paid' 
                  ? AppColors.success 
                  : isExpired 
                      ? AppColors.error 
                      : AppColors.textSecondary,
              size: 32,
            ),
            title: Text('${bill.utilityType.toUpperCase()} Bill'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ₹${bill.totalAmount.toStringAsFixed(0)}'),
                Text('Due: ${_formatDate(bill.dueDate)}'),
                if (bill.overdueAmount > 0) Text('Overdue: ₹${bill.overdueAmount.toStringAsFixed(0)}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacing8,
                vertical: AppStyles.spacing4,
              ),
              decoration: BoxDecoration(
                color: bill.status == 'paid' 
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isExpired
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppStyles.radius4),
              ),
              child: Text(
                isExpired ? 'EXPIRED' : bill.status.toUpperCase(),
                style: AppStyles.caption.copyWith(
                  color: bill.status == 'paid' 
                      ? AppColors.success 
                      : isExpired
                          ? AppColors.error
                          : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getBillIcon(String billType) {
    switch (billType.toLowerCase()) {
      case 'electricity':
        return Icons.bolt;
      case 'water':
        return Icons.water_drop;
      case 'elevator':
        return Icons.elevator;
      default:
        return Icons.receipt;
    }
  }

  void _showAddBillDialog() {
    Get.dialog(
      _AddUtilityBillDialog(
        onSave: (bill) async {
          try {
            await _firestoreService.createUtilityBill(bill);
            Get.back(); // Close dialog
            _loadUtilityBills(); // Reload data
            Get.snackbar(
              'Success',
              'Utility bill created successfully. All members will be notified.',
              backgroundColor: AppColors.success,
              colorText: AppColors.textOnPrimary,
            );
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to create bill: ${e.toString()}',
              backgroundColor: AppColors.error,
              colorText: AppColors.textOnPrimary,
            );
          }
        },
      ),
    );
  }

  void _showEditBillDialog(UtilityModel bill) {
    Get.dialog(
      _AddUtilityBillDialog(
        bill: bill,
        onSave: (updatedBill) async {
          try {
            await _firestoreService.updateUtilityBill(bill.id, updatedBill);
            Get.back(); // Close dialog
            _loadUtilityBills(); // Reload data
            Get.snackbar(
              'Success',
              'Utility bill updated successfully',
              backgroundColor: AppColors.success,
              colorText: AppColors.textOnPrimary,
            );
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to update bill: ${e.toString()}',
              backgroundColor: AppColors.error,
              colorText: AppColors.textOnPrimary,
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(UtilityModel bill) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Are you sure you want to delete this ${bill.utilityType} bill?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteUtilityBill(bill.id);
                Get.back(); // Close dialog
                _loadUtilityBills(); // Reload data
                Get.snackbar(
                  'Success',
                  'Utility bill deleted successfully',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textOnPrimary,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete bill: ${e.toString()}',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.textOnPrimary,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Dialog for Add/Edit Utility Bill
class _AddUtilityBillDialog extends StatefulWidget {
  final UtilityModel? bill;
  final Function(UtilityModel) onSave;

  const _AddUtilityBillDialog({
    this.bill,
    required this.onSave,
  });

  @override
  State<_AddUtilityBillDialog> createState() => _AddUtilityBillDialogState();
}

class _AddUtilityBillDialogState extends State<_AddUtilityBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _utilityTypeController = TextEditingController();
  final _amountController = TextEditingController();
  final _overdueAmountController = TextEditingController();
  final _dueDateController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _utilityTypeController.text = widget.bill!.utilityType;
      _amountController.text = widget.bill!.totalAmount.toString();
      _overdueAmountController.text = widget.bill!.overdueAmount.toString();
      _dueDateController.text = _formatDate(widget.bill!.dueDate);
    }
  }

  @override
  void dispose() {
    _utilityTypeController.dispose();
    _amountController.dispose();
    _overdueAmountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDateController.text = _formatDate(picked);
      });
    }
  }

  void _saveBill() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Parse date from DD/MM/YYYY format
        final dateParts = _dueDateController.text.trim().split('/');
        if (dateParts.length != 3) {
          throw FormatException('Invalid date format. Expected DD/MM/YYYY');
        }
        
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        
        final dueDate = DateTime(year, month, day);
        
        final bill = UtilityModel(
          id: widget.bill?.id ?? '',
          utilityType: _utilityTypeController.text.trim(),
          totalAmount: double.parse(_amountController.text.trim()),
          overdueAmount: double.parse(_overdueAmountController.text.trim().isEmpty ? '0' : _overdueAmountController.text.trim()),
          dueDate: dueDate,
          createdAt: widget.bill?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        widget.onSave(bill);
      } catch (e) {
        Get.snackbar(
          'Error',
          'Invalid date format: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacing24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.bill == null ? 'Add Utility Bill' : 'Edit Utility Bill',
                  style: AppStyles.heading5,
                ),
                const SizedBox(height: AppStyles.spacing24),
                CustomInputField(
                  label: 'Utility Type',
                  hint: 'e.g., Electricity, Water, Elevator',
                  controller: _utilityTypeController,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter utility type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacing16),
                CustomInputField(
                  label: 'Amount',
                  hint: 'Enter amount',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacing16),
                CustomInputField(
                  label: 'Overdue Amount',
                  hint: 'Enter overdue amount (optional)',
                  controller: _overdueAmountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacing16),
                CustomInputField(
                  label: 'Due Date',
                  hint: 'DD/MM/YYYY',
                  controller: _dueDateController,
                  readOnly: true,
                  onTap: _selectDate,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select due date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing16),
                    Expanded(
                      child: CustomButton(
                        text: widget.bill == null ? 'Add' : 'Update',
                        onPressed: _isSaving ? null : _saveBill,
                        isLoading: _isSaving,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

