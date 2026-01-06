class ExpenseModel {
  final String id;
  final String category; // 'maintenance', 'repairs', 'utilities', 'security', 'staff', 'events', 'amenities', 'other'
  final String subCategory;
  final String description;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final String paidBy; // User/staff ID
  final String paidByName;
  final String paymentMethod; // 'cash', 'cheque', 'online', 'card'
  final String? vendorId;
  final String? vendorName;
  final String? billNumber;
  final String? billUrl; // Receipt/bill image URL
  final String status; // 'pending', 'approved', 'rejected', 'paid'
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? remarks;
  final bool isRecurring;
  final String? recurringFrequency; // 'monthly', 'quarterly', 'yearly'
  final DateTime? nextDueDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.category,
    this.subCategory = '',
    required this.description,
    required this.amount,
    this.currency = 'INR',
    required this.expenseDate,
    required this.paidBy,
    required this.paidByName,
    this.paymentMethod = 'cash',
    this.vendorId,
    this.vendorName,
    this.billNumber,
    this.billUrl,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.remarks,
    this.isRecurring = false,
    this.recurringFrequency,
    this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'INR',
      expenseDate: DateTime.parse(map['expenseDate'] ?? DateTime.now().toIso8601String()),
      paidBy: map['paidBy'] ?? '',
      paidByName: map['paidByName'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      vendorId: map['vendorId'],
      vendorName: map['vendorName'],
      billNumber: map['billNumber'],
      billUrl: map['billUrl'],
      status: map['status'] ?? 'pending',
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null 
          ? DateTime.parse(map['approvedAt']) 
          : null,
      rejectionReason: map['rejectionReason'],
      remarks: map['remarks'],
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'],
      nextDueDate: map['nextDueDate'] != null 
          ? DateTime.parse(map['nextDueDate']) 
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'amount': amount,
      'currency': currency,
      'expenseDate': expenseDate.toIso8601String(),
      'paidBy': paidBy,
      'paidByName': paidByName,
      'paymentMethod': paymentMethod,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'billNumber': billNumber,
      'billUrl': billUrl,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'remarks': remarks,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

