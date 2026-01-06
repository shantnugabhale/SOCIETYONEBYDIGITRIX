import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/excel_export_service.dart';
import '../../models/balance_sheet_model.dart';

class BalanceSheetViewScreen extends StatefulWidget {
  final int? year;

  const BalanceSheetViewScreen({
    super.key,
    this.year,
  });

  @override
  State<BalanceSheetViewScreen> createState() => _BalanceSheetViewScreenState();
}

class _BalanceSheetViewScreenState extends State<BalanceSheetViewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<BalanceSheetModel> _balanceSheets = [];
  BalanceSheetModel? _selectedBalanceSheet;
  bool _isViewMode = false; // Track if viewing details

  @override
  void initState() {
    super.initState();
    if (widget.year != null) {
      _isViewMode = true;
    }
    _loadBalanceSheets();
  }

  Future<void> _loadBalanceSheets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balanceSheets = await _firestoreService.getAllBalanceSheets();
      
      setState(() {
        _balanceSheets = balanceSheets;
        if (widget.year != null) {
          _selectedBalanceSheet = balanceSheets.firstWhere(
            (bs) => bs.year == widget.year,
            orElse: () => balanceSheets.isNotEmpty ? balanceSheets.first : balanceSheets.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load balance sheets: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  void _viewBalanceSheet(BalanceSheetModel balanceSheet) {
    setState(() {
      _selectedBalanceSheet = balanceSheet;
      _isViewMode = true;
    });
  }

  void _backToList() {
    setState(() {
      _isViewMode = false;
      _selectedBalanceSheet = null;
    });
  }

  Future<void> _exportToExcel() async {
    if (_selectedBalanceSheet == null) {
      Get.snackbar(
        'Error',
        'No balance sheet selected',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final file = await ExcelExportService.exportBalanceSheetToExcel(_selectedBalanceSheet!);
      
      Get.back(); // Close loading dialog

      // Show success and ask to open file
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Export Successful'),
          content: Text('Balance sheet exported to:\n${file.path}'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Open File'),
            ),
          ],
        ),
      );

      if (result == true) {
        // Use open_filex which handles FileProvider automatically on Android
        try {
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done) {
            Get.snackbar(
              'Error',
              'Failed to open file: ${result.message}',
              backgroundColor: AppColors.error,
              colorText: AppColors.textOnPrimary,
            );
          }
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to open file: ${e.toString()}',
            backgroundColor: AppColors.error,
            colorText: AppColors.textOnPrimary,
          );
        }
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to export: ${e.toString()}',
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
          _isViewMode ? 'Balance Sheet ${_selectedBalanceSheet?.year ?? ""}' : 'Balance Sheets',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        leading: _isViewMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToList,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isViewMode && _selectedBalanceSheet != null
              ? _buildViewMode()
              : _buildListMode(),
    );
  }

  Widget _buildListMode() {
    if (_balanceSheets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No balance sheets found',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacing12,
        vertical: AppStyles.spacing8,
      ),
      itemCount: _balanceSheets.length,
      itemBuilder: (context, index) {
        final balanceSheet = _balanceSheets[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
          padding: const EdgeInsets.all(AppStyles.spacing12),
          isClickable: true,
          onTap: () => _viewBalanceSheet(balanceSheet),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Center(
                  child: Text(
                    '${balanceSheet.year}',
                    style: AppStyles.heading6.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Sheet ${balanceSheet.year}',
                      style: AppStyles.heading6,
                    ),
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      balanceSheet.societyName,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      'Net: ₹${balanceSheet.netBalance.toStringAsFixed(2)}',
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: balanceSheet.netBalance >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewMode() {
    if (_selectedBalanceSheet == null) {
      return const Center(child: Text('No balance sheet selected'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacing12,
        vertical: AppStyles.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Premium Style with White Text
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppStyles.radius12),
            ),
            padding: const EdgeInsets.all(AppStyles.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedBalanceSheet!.societyName,
                            style: AppStyles.heading5.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppStyles.spacing8),
                          Text(
                            'Balance Sheet ${_selectedBalanceSheet!.year}',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedBalanceSheet!.isFinalized)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacing8,
                          vertical: AppStyles.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppStyles.radius4),
                          border: Border.all(
                            color: AppColors.success,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'FINALIZED',
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing16),
                // Export button only (no edit button for users)
                ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export to Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppStyles.spacing12,
                      horizontal: AppStyles.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radius8),
                    ),
                    elevation: 2,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppStyles.spacing8),
          
          // Balance Sheet Table - Bank Passbook Style with Horizontal Scroll
          CustomCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header - Bank Passbook Style
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.spacing16,
                      vertical: AppStyles.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppStyles.radius12),
                        topRight: Radius.circular(AppStyles.radius12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            'SR',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Text(
                            'Liabilities / Item',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            'Credit (Rs.)',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            'Debit (Rs.)',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            'Total (Rs.)',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table Rows - Bank Passbook Style
                  if (_selectedBalanceSheet!.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      child: Center(
                        child: Text(
                          'No items found',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_selectedBalanceSheet!.items.length, (index) {
                            final item = _selectedBalanceSheet!.items[index];
                            final total = item.credit - item.debit;
                            final isLast = index == _selectedBalanceSheet!.items.length - 1;
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppStyles.spacing16,
                                vertical: AppStyles.spacing12,
                              ),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? AppColors.white : AppColors.grey50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.grey200,
                                    width: isLast ? 0 : 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${index + 1}',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 250,
                                    child: Text(
                                      item.item,
                                      style: AppStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: item.credit > 0
                                        ? Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '₹${item.credit.toStringAsFixed(2)}',
                                              style: AppStyles.bodySmall.copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              softWrap: false,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              '-',
                                              style: AppStyles.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: item.debit > 0
                                        ? Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '₹${item.debit.toStringAsFixed(2)}',
                                              style: AppStyles.bodySmall.copyWith(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              softWrap: false,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              '-',
                                              style: AppStyles.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        total < 0 
                                            ? '-₹${total.abs().toStringAsFixed(2)}'
                                            : '₹${total.toStringAsFixed(2)}',
                                        style: AppStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: total >= 0 ? AppColors.success : AppColors.error,
                                        ),
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                  
                  // Totals Row - Bank Passbook Style
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacing16,
                          vertical: AppStyles.spacing16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppStyles.radius12),
                            bottomRight: Radius.circular(AppStyles.radius12),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                '',
                                style: AppStyles.bodySmall,
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: Text(
                                'TOTAL',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: Text(
                                '₹${_selectedBalanceSheet!.totalCredit.toStringAsFixed(2)}',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.right,
                                softWrap: false,
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: Text(
                                '₹${_selectedBalanceSheet!.totalDebit.toStringAsFixed(2)}',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.right,
                                softWrap: false,
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _selectedBalanceSheet!.netBalance < 0
                                      ? '-₹${_selectedBalanceSheet!.netBalance.abs().toStringAsFixed(2)}'
                                      : '₹${_selectedBalanceSheet!.netBalance.toStringAsFixed(2)}',
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedBalanceSheet!.netBalance >= 0 
                                        ? AppColors.success 
                                        : AppColors.error,
                                    fontSize: 15,
                                  ),
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          
          // Profit/Loss Section
          const SizedBox(height: AppStyles.spacing8),
          CustomCard(
            padding: const EdgeInsets.all(AppStyles.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit & Loss',
                  style: AppStyles.heading6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Income (Credit):',
                      style: AppStyles.bodyMedium,
                    ),
                    Text(
                      '₹${_selectedBalanceSheet!.totalCredit.toStringAsFixed(2)}',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Expenses (Debit):',
                      style: AppStyles.bodyMedium,
                    ),
                    Text(
                      '₹${_selectedBalanceSheet!.totalDebit.toStringAsFixed(2)}',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppStyles.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBalanceSheet!.netBalance >= 0 ? 'Net Profit:' : 'Net Loss:',
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedBalanceSheet!.netBalance < 0
                          ? '-₹${_selectedBalanceSheet!.netBalance.abs().toStringAsFixed(2)}'
                          : '₹${_selectedBalanceSheet!.netBalance.toStringAsFixed(2)}',
                      style: AppStyles.heading5.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _selectedBalanceSheet!.netBalance >= 0 
                            ? AppColors.success 
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Notes - Compact
          if (_selectedBalanceSheet!.notes != null &&
              _selectedBalanceSheet!.notes!.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing8),
            CustomCard(
              padding: const EdgeInsets.all(AppStyles.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: AppStyles.heading6,
                  ),
                  const SizedBox(height: AppStyles.spacing4),
                  Text(
                    _selectedBalanceSheet!.notes!,
                    style: AppStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppStyles.spacing8),
        ],
      ),
    );
  }
}

