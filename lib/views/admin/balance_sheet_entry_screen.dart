import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/balance_sheet_model.dart';

class BalanceSheetEntryScreen extends StatefulWidget {
  final int? year;
  final BalanceSheetModel? existingBalanceSheet;

  const BalanceSheetEntryScreen({
    super.key,
    this.year,
    this.existingBalanceSheet,
  });

  @override
  State<BalanceSheetEntryScreen> createState() => _BalanceSheetEntryScreenState();
}

class _BalanceSheetEntryScreenState extends State<BalanceSheetEntryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  
  late int _selectedYear;
  final TextEditingController _societyNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // List of balance sheet items
  final List<BalanceSheetItem> _items = [];
  
  bool _isLoading = false;
  bool _isFinalized = false;
  bool _isEditingSocietyName = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.year ?? DateTime.now().year;
    
    if (widget.existingBalanceSheet != null) {
      _loadExistingData(widget.existingBalanceSheet!);
    } else {
      _initializeDefaultItems();
    }
  }

  void _loadExistingData(BalanceSheetModel balanceSheet) {
    _societyNameController.text = balanceSheet.societyName;
    _notesController.text = balanceSheet.notes ?? '';
    _isFinalized = balanceSheet.isFinalized;
    _items.clear();
    // Ensure items are in the correct order (as saved, which is reversed from creation order)
    _items.addAll(balanceSheet.items);
  }

  void _initializeDefaultItems() {
    // Start with empty list - admin will add items one by one
    _items.clear();
  }

  void _addNewItem() {
    _showAddItemDialog();
  }

  Future<void> _showAddItemDialog() async {
    final itemNameController = TextEditingController();
    final creditController = TextEditingController();
    final debitController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(
          AppStyles.spacing20,
          AppStyles.spacing20,
          AppStyles.spacing20,
          AppStyles.spacing12,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppStyles.spacing20,
          0,
          AppStyles.spacing20,
          AppStyles.spacing12,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppStyles.spacing16,
          AppStyles.spacing8,
          AppStyles.spacing16,
          AppStyles.spacing16,
        ),
        title: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: AppStyles.spacing12),
            Expanded(
              child: Text(
                'Add Balance Sheet Item',
                style: AppStyles.heading5,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: itemNameController,
                    decoration: AppStyles.inputDecoration.copyWith(
                      labelText: 'Item Name',
                      hintText: 'Enter item name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  TextFormField(
                    controller: creditController,
                    decoration: AppStyles.inputDecoration.copyWith(
                      labelText: 'Credit (Rs.)',
                      hintText: '0.00',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Please enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  TextFormField(
                    controller: debitController,
                    decoration: AppStyles.inputDecoration.copyWith(
                      labelText: 'Debit (Rs.)',
                      hintText: '0.00',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Please enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  Text(
                    'Note: At least one of Credit or Debit must be greater than 0',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Expanded(
            child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing12,
                  vertical: AppStyles.spacing12,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppStyles.spacing12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final credit = double.tryParse(creditController.text) ?? 0.0;
                  final debit = double.tryParse(debitController.text) ?? 0.0;

                  if (credit == 0 && debit == 0) {
                    Get.snackbar(
                      'Error',
                      'Please enter at least one amount (Credit or Debit)',
                      backgroundColor: AppColors.error,
                      colorText: AppColors.textOnPrimary,
                    );
                    return;
                  }

                  Get.back(result: {
                    'item': itemNameController.text.trim(),
                    'credit': credit,
                    'debit': debit,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing12,
                  vertical: AppStyles.spacing12,
                ),
              ),
              child: const Text('Add Item'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (result != null) {
      // Add item at the end (last position) to maintain serial order
      setState(() {
        _items.add(BalanceSheetItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + _items.length.toString(),
          item: result['item'],
          credit: result['credit'],
          debit: result['debit'],
        ));
      });

      // Show success message at top after adding
      Get.snackbar(
        'Success',
        'Item added successfully',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(AppStyles.spacing16),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotalCredit() {
    return _items.fold(0.0, (sum, item) => sum + item.credit);
  }

  double _calculateTotalDebit() {
    return _items.fold(0.0, (sum, item) => sum + item.debit);
  }

  double _calculateNetBalance() {
    return _calculateTotalCredit() - _calculateTotalDebit();
  }

  Future<void> _saveBalanceSheet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_societyNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter society name',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
      return;
    }

    // Remove empty items
    final validItems = _items.where((item) => 
      item.item.trim().isNotEmpty && (item.credit > 0 || item.debit > 0)
    ).toList();

    if (validItems.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add at least one item with credit or debit amount',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final totalCredit = _calculateTotalCredit();
      final totalDebit = _calculateTotalDebit();
      final netBalance = _calculateNetBalance();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Items are already in correct order (added sequentially at the end)
      // No need to reverse - they will be saved in the order they appear
      final itemsToSave = validItems;

      final balanceSheet = BalanceSheetModel(
        id: widget.existingBalanceSheet?.id ?? '',
        year: _selectedYear,
        societyName: _societyNameController.text.trim(),
        items: itemsToSave,
        totalCredit: totalCredit,
        totalDebit: totalDebit,
        netBalance: netBalance,
        createdBy: user.uid,
        createdAt: widget.existingBalanceSheet?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isActive: true,
        isFinalized: _isFinalized,
      );

      if (widget.existingBalanceSheet != null) {
        await _firestoreService.updateBalanceSheet(
          widget.existingBalanceSheet!.id,
          balanceSheet,
        );
      } else {
        await _firestoreService.createBalanceSheet(balanceSheet);
      }

      // Show success dialog
      await Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radius16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: AppStyles.spacing12),
              Text(
                'Success',
                style: AppStyles.heading5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            widget.existingBalanceSheet != null
                ? 'Balance sheet updated successfully!'
                : 'Balance sheet created successfully!',
            style: AppStyles.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.back(); // Go back to previous screen
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing20,
                  vertical: AppStyles.spacing8,
                ),
              ),
              child: Text(
                'OK',
                style: AppStyles.buttonSmall.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save balance sheet: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCredit = _calculateTotalCredit();
    final totalDebit = _calculateTotalDebit();
    final netBalance = _calculateNetBalance();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingBalanceSheet != null
              ? 'Edit Balance Sheet $_selectedYear'
              : 'Create Balance Sheet $_selectedYear',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing16,
                  vertical: AppStyles.spacing12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    CustomCard(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: AppStyles.heading5,
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                          
                          // Society Name - Display with Edit option
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Society Name',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppStyles.spacing4),
                                    _isEditingSocietyName
                                        ? TextFormField(
                                            controller: _societyNameController,
                                            decoration: InputDecoration(
                                              hintText: 'Enter society name',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(AppStyles.radius8),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: AppStyles.spacing12,
                                                vertical: AppStyles.spacing12,
                                              ),
                                            ),
                                            autofocus: true,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Please enter society name';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (value) {
                                              if (value.trim().isNotEmpty) {
                                                setState(() {
                                                  _isEditingSocietyName = false;
                                                });
                                              }
                                            },
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isEditingSocietyName = true;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppStyles.spacing12,
                                                vertical: AppStyles.spacing12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(AppStyles.radius8),
                                                border: Border.all(
                                                  color: AppColors.grey200,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _societyNameController.text.isEmpty
                                                          ? 'Tap to enter society name'
                                                          : _societyNameController.text,
                                                      style: AppStyles.bodyLarge.copyWith(
                                                        color: _societyNameController.text.isEmpty
                                                            ? AppColors.textHint
                                                            : AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppStyles.spacing8),
                              if (!_isEditingSocietyName)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.primary),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingSocietyName = true;
                                    });
                                  },
                                  tooltip: 'Edit Society Name',
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: AppColors.success),
                                      onPressed: () {
                                        if (_societyNameController.text.trim().isNotEmpty) {
                                          setState(() {
                                            _isEditingSocietyName = false;
                                          });
                                        } else {
                                          Get.snackbar(
                                            'Error',
                                            'Please enter society name',
                                            backgroundColor: AppColors.error,
                                            colorText: AppColors.textOnPrimary,
                                          );
                                        }
                                      },
                                      tooltip: 'Save',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.error),
                                      onPressed: () {
                                        // Restore original value if editing existing
                                        if (widget.existingBalanceSheet != null) {
                                          _societyNameController.text = widget.existingBalanceSheet!.societyName;
                                        } else {
                                          _societyNameController.clear();
                                        }
                                        setState(() {
                                          _isEditingSocietyName = false;
                                        });
                                      },
                                      tooltip: 'Cancel',
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: AppStyles.spacing16),
                          Row(
                            children: [
                              Text(
                                'Year: ',
                                style: AppStyles.bodyLarge,
                              ),
                              DropdownButton<int>(
                                value: _selectedYear,
                                items: List.generate(
                                  10,
                                  (index) => DateTime.now().year - 5 + index,
                                ).map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }).toList(),
                                onChanged: widget.existingBalanceSheet == null
                                    ? (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedYear = value;
                                          });
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spacing12),
                    
                    // Balance Sheet Table
                    CustomCard(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Balance Sheet Items',
                                  style: AppStyles.heading5,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spacing12),
                              ElevatedButton.icon(
                                onPressed: _addNewItem,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Create'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textOnPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppStyles.spacing16,
                                    vertical: AppStyles.spacing10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                          
                          // Show empty state if no items
                          if (_items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(AppStyles.spacing32),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppStyles.radius12),
                                border: Border.all(
                                  color: AppColors.grey200,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppStyles.spacing16),
                                  Text(
                                    'No items added yet',
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.spacing8),
                                  Text(
                                    'Click "Create" button to add your first item',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Table Header - Responsive (only show if items exist)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // For smaller screens, don't show header
                                    if (constraints.maxWidth < 600) {
                                      return const SizedBox.shrink();
                                    }
                                    // For larger screens, use table layout
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppStyles.spacing12,
                                        vertical: AppStyles.spacing10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              'SR',
                                              style: AppStyles.bodySmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Liabilities / Item',
                                              style: AppStyles.bodySmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Credit (Rs.)',
                                              style: AppStyles.bodySmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Debit (Rs.)',
                                              style: AppStyles.bodySmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Total (Rs.)',
                                              style: AppStyles.bodySmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          const SizedBox(width: 40),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                
                                if (MediaQuery.of(context).size.width >= 600)
                                  const SizedBox(height: AppStyles.spacing8),
                                
                                // Table Rows - Responsive
                                ...List.generate(_items.length, (index) {
                            final item = _items[index];
                            final total = item.credit - item.debit;
                            
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                // For smaller screens, use card layout
                                if (constraints.maxWidth < 600) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
                                    padding: const EdgeInsets.all(AppStyles.spacing12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.grey200),
                                      borderRadius: BorderRadius.circular(AppStyles.radius8),
                                      color: AppColors.surface,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${index + 1}. ${item.item.isEmpty ? "Item" : item.item}',
                                              style: AppStyles.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                              onPressed: () => _removeItem(index),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppStyles.spacing12),
                                        TextFormField(
                                          initialValue: item.item,
                                          decoration: InputDecoration(
                                            labelText: 'Item Name',
                                            hintText: 'Enter item name',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: AppStyles.spacing12,
                                              vertical: AppStyles.spacing12,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _items[index] = item.copyWith(item: value);
                                            });
                                          },
                                        ),
                                        const SizedBox(height: AppStyles.spacing12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: item.credit > 0 ? item.credit.toStringAsFixed(2) : '',
                                                decoration: InputDecoration(
                                                  labelText: 'Credit (Rs.)',
                                                  hintText: '0.00',
                                                  prefixText: '₹ ',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: AppStyles.spacing12,
                                                    vertical: AppStyles.spacing12,
                                                  ),
                                                ),
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                onChanged: (value) {
                                                  final credit = double.tryParse(value) ?? 0.0;
                                                  setState(() {
                                                    _items[index] = item.copyWith(credit: credit);
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: AppStyles.spacing12),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: item.debit > 0 ? item.debit.toStringAsFixed(2) : '',
                                                decoration: InputDecoration(
                                                  labelText: 'Debit (Rs.)',
                                                  hintText: '0.00',
                                                  prefixText: '₹ ',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: AppStyles.spacing12,
                                                    vertical: AppStyles.spacing12,
                                                  ),
                                                ),
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                onChanged: (value) {
                                                  final debit = double.tryParse(value) ?? 0.0;
                                                  setState(() {
                                                    _items[index] = item.copyWith(debit: debit);
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppStyles.spacing12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(AppStyles.spacing12),
                                          decoration: BoxDecoration(
                                            color: total >= 0 
                                                ? AppColors.success.withValues(alpha: 0.1)
                                                : AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppStyles.radius8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Total:',
                                                style: AppStyles.bodyMedium.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '₹${total.toStringAsFixed(2)}',
                                                style: AppStyles.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: total >= 0 ? AppColors.success : AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // For larger screens, use table layout
                                return Container(
                                  margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppStyles.spacing12,
                                    vertical: AppStyles.spacing10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.grey200),
                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                    color: AppColors.surface,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          '${index + 1}',
                                          style: AppStyles.bodyMedium,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          initialValue: item.item,
                                          decoration: InputDecoration(
                                            hintText: 'Item name',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: AppStyles.spacing8,
                                              vertical: AppStyles.spacing8,
                                            ),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _items[index] = item.copyWith(item: value);
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppStyles.spacing8),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item.credit > 0 ? item.credit.toStringAsFixed(2) : '',
                                          decoration: InputDecoration(
                                            hintText: '0.00',
                                            prefixText: '₹ ',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: AppStyles.spacing8,
                                              vertical: AppStyles.spacing8,
                                            ),
                                            isDense: true,
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            final credit = double.tryParse(value) ?? 0.0;
                                            setState(() {
                                              _items[index] = item.copyWith(credit: credit);
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppStyles.spacing8),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item.debit > 0 ? item.debit.toStringAsFixed(2) : '',
                                          decoration: InputDecoration(
                                            hintText: '0.00',
                                            prefixText: '₹ ',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: AppStyles.spacing8,
                                              vertical: AppStyles.spacing8,
                                            ),
                                            isDense: true,
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            final debit = double.tryParse(value) ?? 0.0;
                                            setState(() {
                                              _items[index] = item.copyWith(debit: debit);
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppStyles.spacing8),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppStyles.spacing8,
                                            vertical: AppStyles.spacing8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: total >= 0 
                                                ? AppColors.success.withValues(alpha: 0.1)
                                                : AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppStyles.radius8),
                                          ),
                                          child: Text(
                                            '₹${total.toStringAsFixed(2)}',
                                            style: AppStyles.bodySmall.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: total >= 0 ? AppColors.success : AppColors.error,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppStyles.spacing8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                        onPressed: () => _removeItem(index),
                                        tooltip: 'Delete',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                                }),
                                
                                const SizedBox(height: AppStyles.spacing16),
                                
                                // Totals Row - Responsive
                                LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                // Mobile layout
                                return Container(
                                  padding: const EdgeInsets.all(AppStyles.spacing16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Credit:',
                                            style: AppStyles.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${totalCredit.toStringAsFixed(2)}',
                                            style: AppStyles.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppStyles.spacing8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Debit:',
                                            style: AppStyles.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${totalDebit.toStringAsFixed(2)}',
                                            style: AppStyles.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: AppStyles.spacing16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Net Balance:',
                                            style: AppStyles.heading6.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppStyles.spacing12,
                                              vertical: AppStyles.spacing8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: netBalance >= 0 
                                                  ? AppColors.success.withValues(alpha: 0.2)
                                                  : AppColors.error.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                                            ),
                                            child: Text(
                                              '₹${netBalance.toStringAsFixed(2)}',
                                              style: AppStyles.heading6.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: netBalance >= 0 ? AppColors.success : AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              // Desktop layout
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spacing12,
                                  vertical: AppStyles.spacing10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 50),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'TOTAL',
                                        style: AppStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${totalCredit.toStringAsFixed(2)}',
                                        style: AppStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${totalDebit.toStringAsFixed(2)}',
                                        style: AppStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppStyles.spacing8,
                                          vertical: AppStyles.spacing8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: netBalance >= 0 
                                              ? AppColors.success.withValues(alpha: 0.2)
                                              : AppColors.error.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppStyles.radius8),
                                        ),
                                        child: Text(
                                          '₹${netBalance.toStringAsFixed(2)}',
                                          style: AppStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: netBalance >= 0 ? AppColors.success : AppColors.error,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                  ],
                                ),
                              );
                            },
                          ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spacing12),
                    
                    // Notes
                    CustomCard(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes (Optional)',
                            style: AppStyles.heading6,
                          ),
                          const SizedBox(height: AppStyles.spacing12),
                          TextFormField(
                            controller: _notesController,
                            decoration: AppStyles.inputDecoration.copyWith(
                              hintText: 'Add any additional notes...',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spacing16),
                  ],
                ),
              ),
            ),
            
            // Save Button
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppStyles.shadowMedium,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBalanceSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppStyles.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radius12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                          ),
                        )
                      : Text(
                          'Save Balance Sheet',
                          style: AppStyles.button,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
