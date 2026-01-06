import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../models/balance_sheet_model.dart';

class ExcelExportService {
  /// Export balance sheet to Excel file with improved UI and Profit/Loss calculation
  static Future<File> exportBalanceSheetToExcel(BalanceSheetModel balanceSheet) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // Delete default sheet
      
      // Create main balance sheet
      final sheet = excel['Balance Sheet ${balanceSheet.year}'];
      
      // Set column widths (improved for better readability)
      sheet.setColumnWidth(0, 10);  // SR No.
      sheet.setColumnWidth(1, 40);  // Liabilities / Item
      sheet.setColumnWidth(2, 20);  // Credit
      sheet.setColumnWidth(3, 20);  // Debit
      sheet.setColumnWidth(4, 20);  // Total
      
      int rowIndex = 0;
      
      // Calculate Profit/Loss
      final profitLoss = balanceSheet.totalCredit - balanceSheet.totalDebit;
      final isProfit = profitLoss >= 0;
      
      // Header with improved styling
      final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      headerCell.value = '${balanceSheet.societyName}';
      headerCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 18,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      
      rowIndex++;
      
      // Subtitle
      final subtitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      subtitleCell.value = 'Balance Sheet for the Year ${balanceSheet.year}';
      subtitleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      
      rowIndex += 2;
      
      // Table Header with improved styling
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      
      final srHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      srHeader.value = 'SR No.';
      srHeader.cellStyle = headerStyle;
      
      final itemHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      itemHeader.value = 'Liabilities / Item';
      itemHeader.cellStyle = headerStyle;
      
      final creditHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      creditHeader.value = 'Credit (Rs.)';
      creditHeader.cellStyle = headerStyle;
      
      final debitHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      debitHeader.value = 'Debit (Rs.)';
      debitHeader.cellStyle = headerStyle;
      
      final totalHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      totalHeader.value = 'Total (Rs.)';
      totalHeader.cellStyle = headerStyle;
      
      rowIndex++;
      
      // Table Rows with improved formatting
      for (int i = 0; i < balanceSheet.items.length; i++) {
        final item = balanceSheet.items[i];
        final total = item.credit - item.debit;
        
        // SR No.
        final srCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        srCell.value = i + 1;
        srCell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
        );
        
        // Item
        final itemCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        itemCell.value = item.item;
        
        // Credit (formatted as number with 2 decimal places)
        final creditCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
        creditCell.value = item.credit.toStringAsFixed(2);
        creditCell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
        );
        
        // Debit (formatted as number with 2 decimal places)
        final debitCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        debitCell.value = item.debit.toStringAsFixed(2);
        debitCell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
        );
        
        // Total (formatted as number with 2 decimal places)
        final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        totalCell.value = total.toStringAsFixed(2);
        totalCell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
        );
        
        rowIndex++;
      }
      
      // Empty row before totals
      rowIndex++;
      
      // Totals Row with improved styling
      final totalRowStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
      );
      
      final totalLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      totalLabelCell.value = 'TOTAL';
      totalLabelCell.cellStyle = totalRowStyle;
      
      // Empty cell
      final emptyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      emptyCell.value = '';
      
      final totalCreditCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      totalCreditCell.value = balanceSheet.totalCredit.toStringAsFixed(2);
      totalCreditCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      final totalDebitCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      totalDebitCell.value = balanceSheet.totalDebit.toStringAsFixed(2);
      totalDebitCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      final netBalanceCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      netBalanceCell.value = balanceSheet.netBalance.toStringAsFixed(2);
      netBalanceCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      rowIndex += 2;
      
      // Profit/Loss Row
      final profitLossLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      profitLossLabelCell.value = isProfit ? 'PROFIT' : 'LOSS';
      profitLossLabelCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 13,
        horizontalAlign: HorizontalAlign.Center,
      );
      
      // Empty cells
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = '';
      
      final profitLossCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      profitLossCell.value = profitLoss.abs().toStringAsFixed(2);
      profitLossCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      // Merge profit/loss label cells for better presentation
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
                  CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      
      rowIndex += 2;
      
      // Summary Section
      final summaryStyle = CellStyle(
        bold: true,
        fontSize: 12,
      );
      
      final summaryLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      summaryLabelCell.value = 'Summary:';
      summaryLabelCell.cellStyle = summaryStyle;
      rowIndex++;
      
      final totalIncomeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      totalIncomeCell.value = 'Total Income (Credit):';
      totalIncomeCell.cellStyle = CellStyle(fontSize: 11);
      final totalIncomeValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      totalIncomeValueCell.value = balanceSheet.totalCredit.toStringAsFixed(2);
      totalIncomeValueCell.cellStyle = CellStyle(
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Right,
      );
      rowIndex++;
      
      final totalExpenseCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      totalExpenseCell.value = 'Total Expenses (Debit):';
      totalExpenseCell.cellStyle = CellStyle(fontSize: 11);
      final totalExpenseValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      totalExpenseValueCell.value = balanceSheet.totalDebit.toStringAsFixed(2);
      totalExpenseValueCell.cellStyle = CellStyle(
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Right,
      );
      rowIndex++;
      
      final netProfitLossCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      netProfitLossCell.value = isProfit ? 'Net Profit:' : 'Net Loss:';
      netProfitLossCell.cellStyle = CellStyle(
        fontSize: 11,
        bold: true,
      );
      final netProfitLossValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      netProfitLossValueCell.value = profitLoss.abs().toStringAsFixed(2);
      netProfitLossValueCell.cellStyle = CellStyle(
        fontSize: 11,
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
      );
      
      rowIndex += 2;
      
      // Notes
      if (balanceSheet.notes != null && balanceSheet.notes!.isNotEmpty) {
        final notesLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        notesLabel.value = 'Notes:';
        notesLabel.cellStyle = CellStyle(bold: true, fontSize: 11);
        rowIndex++;
        
        final notesCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        notesCell.value = balanceSheet.notes!;
        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
                    CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        rowIndex++;
      }
      
      // Footer
      rowIndex += 2;
      final footerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      footerCell.value = 'Generated on: ${DateTime.now().toString().split('.')[0]}';
      footerCell.cellStyle = CellStyle(
        fontSize: 10,
      );
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
      
      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Balance_Sheet_${balanceSheet.year}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = path.join(directory.path, fileName);
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        if (kDebugMode) {
          debugPrint('Excel file saved to: $filePath');
        }
        
        return file;
      } else {
        throw Exception('Failed to generate Excel file');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting to Excel: $e');
      }
      throw Exception('Failed to export balance sheet: $e');
    }
  }
}
