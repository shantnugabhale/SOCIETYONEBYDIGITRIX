import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../models/utility_model.dart';
import '../models/user_model.dart';

class ReceiptService {
  // Society information
  static const String societyName = 'OM SHREE MAHAVIR CO.OP.HSG.SOC.LTD.';
  static const String societyAddress = '123, Gandhi Road, Andheri (West)';
  static const String societyCity = 'Mumbai - 400053';
  static const String registrationNumber = 'Reg. No. MH/HSG/2023/000123';

  // Color scheme
  static const PdfColor primaryColor = PdfColor.fromInt(0x1a237e); // Deep blue
  static const PdfColor accentColor = PdfColor.fromInt(0x283593);
  static const PdfColor lightGray = PdfColor.fromInt(0xf5f5f5);
  static const PdfColor darkGray = PdfColor.fromInt(0x424242);
  static const PdfColor successColor = PdfColor.fromInt(0x2e7d32);
  static const PdfColor lightGrayBorder = PdfColor.fromInt(0xe0e0e0); // Lighter gray for borders
  static const PdfColor mediumGray = PdfColor.fromInt(0x9e9e9e); // Medium gray for text

  /// Generate and show receipt as PDF
  static Future<void> generateAndShowReceipt({
    required PaymentModel payment,
    required List<UtilityModel> bills,
    required UserModel user,
  }) async {
    try {
      // Validate inputs
      if (bills.isEmpty) {
        throw Exception('No bills provided for receipt generation');
      }

      // Filter bills that were paid in this payment
      final paidBills = bills.where((bill) => payment.billIds.contains(bill.id)).toList();
      
      if (paidBills.isEmpty) {
        throw Exception('No paid bills found for this payment');
      }

      final pdf = await _generateReceiptPDF(payment, paidBills, user);
      
      // Save PDF bytes
      final pdfBytes = await pdf.save();
      
      // Check if PDF was generated successfully
      if (pdfBytes.isEmpty) {
        throw Exception('Failed to generate PDF document');
      }

      // Show PDF with error handling
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Failed to generate receipt: ${e.toString()}');
    }
  }

  /// Generate receipt PDF
  static Future<pw.Document> _generateReceiptPDF(
    PaymentModel payment,
    List<UtilityModel> bills,
    UserModel user,
  ) async {
    try {
      final pdf = pw.Document();
      final now = payment.paidDate;

      // Validate bills list
      if (bills.isEmpty) {
        throw Exception('Bills list is empty');
      }

      // Calculate total from bills
      final total = bills.fold<double>(
        0.0,
        (sum, bill) => sum + bill.totalAmount,
      );

      // Validate total
      if (total <= 0) {
        throw Exception('Invalid total amount: $total');
      }

      // Generate bill number from transaction ID or use a default
      final billNumber = payment.transactionId.length >= 8 
          ? payment.transactionId.substring(0, 8)
          : payment.transactionId;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
          build: (pw.Context context) {
            return [
              // Header with gradient-like effect
              _buildHeader(),
              pw.SizedBox(height: 25),
              
              // Receipt Title with decorative box
              _buildReceiptTitle(),
              pw.SizedBox(height: 25),

              // Receipt Number and Date - Enhanced
              _buildReceiptInfo(payment.transactionId, now),
              pw.SizedBox(height: 20),

              // Bill Month and Bill Number - Enhanced
              _buildBillInfo(bills.first, billNumber),
              pw.SizedBox(height: 20),

              // Member Information - Enhanced
              _buildMemberInfo(user),
              pw.SizedBox(height: 25),

              // Charge Table - Enhanced
              _buildChargesTable(bills),
              pw.SizedBox(height: 20),

              // Total Amount - Enhanced
              _buildTotalSection(total),
              pw.SizedBox(height: 20),

              // Payment Details - Enhanced
              _buildPaymentDetails(payment, now),
              pw.SizedBox(height: 30),

              // Signature Line - Enhanced
              _buildSignatureSection(),
              pw.SizedBox(height: 15),

              // Footer - Enhanced
              _buildFooter(),
            ];
          },
        ),
      );

      return pdf;
    } catch (e) {
      throw Exception('Error generating PDF: ${e.toString()}');
    }
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              societyName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
                color: primaryColor,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            height: 2,
            color: PdfColors.white,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            societyAddress,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            societyCity,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              registrationNumber,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReceiptTitle() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: primaryColor, width: 2),
      ),
      child: pw.Center(
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              width: 30,
              height: 3,
              color: primaryColor,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12),
              child: pw.Text(
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                  color: primaryColor,
                ),
              ),
            ),
            pw.Container(
              width: 30,
              height: 3,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildReceiptInfo(String receiptNumber, DateTime date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: darkGray, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Receipt Number',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: darkGray,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  receiptNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 1,
            height: 40,
            color: darkGray,
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Date',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: darkGray,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillInfo(UtilityModel bill, String billNumber) {
    final billMonth = DateFormat('MMMM yyyy').format(bill.dueDate);
    return pw.Row(
      children: [
        // Left accent bar
        pw.Container(
          width: 4,
          height: 50,
          color: primaryColor,
        ),
        // Content with uniform border
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: pw.BoxDecoration(
              color: lightGray,
              border: pw.Border.all(color: darkGray, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        'Bill Month',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      billMonth,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Bill No.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: darkGray,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      billNumber,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMemberInfo(UserModel user) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [lightGray, PdfColors.white],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        border: pw.Border.all(color: primaryColor, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: primaryColor,
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'Member Details',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Member Name',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: darkGray,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      user.name,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Flat Number',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: darkGray,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        '${user.buildingName}-${user.apartmentNumber}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildChargesTable(List<UtilityModel> bills) {
    final tableRows = <pw.TableRow>[];

    // Header with enhanced styling
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: primaryColor,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(
              'Sr. No.',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(
              'Particulars',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(
              'Amount (₹)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );

    // Data rows with alternating colors
    for (int i = 0; i < bills.length; i++) {
      final bill = bills[i];
      final isEven = i % 2 == 0;
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.white : lightGray,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                '${i + 1}',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: darkGray,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                bill.utilityType,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: darkGray,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                bill.totalAmount.toStringAsFixed(0),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: darkGray,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: lightGrayBorder, width: 0.5),
        ),
        children: tableRows,
      ),
    );
  }

  static pw.Widget _buildTotalSection(double total) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [primaryColor, accentColor],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        // Note: BoxShadow might not be fully supported in pdf package
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total Amount Received',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              '₹ ${total.toStringAsFixed(0)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentDetails(PaymentModel payment, DateTime paidDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: successColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: successColor,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '✓',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                'Payment Information',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: successColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: lightGrayBorder, height: 1),
          pw.SizedBox(height: 12),
          _buildDetailRow('Payment Mode', payment.paymentMethod.toUpperCase(), successColor),
          pw.SizedBox(height: 10),
          _buildDetailRow('Paid Date', DateFormat('dd MMM yyyy').format(paidDate), darkGray),
          pw.SizedBox(height: 10),
          _buildDetailRow('Transaction ID', payment.transactionId.length > 40 
              ? '${payment.transactionId.substring(0, 37)}...' 
              : payment.transactionId, darkGray),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value, PdfColor valueColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: darkGray,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 200,
                height: 1,
                color: darkGray,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: darkGray,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Chairman / Secretary / Treasurer',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: mediumGray,
                ),
              ),
              pw.SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: 50,
            height: 2,
            color: primaryColor,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This is a computer generated receipt.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: mediumGray,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'No signature required for digitally generated receipts.',
            style: pw.TextStyle(
              fontSize: 8,
              color: mediumGray,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
