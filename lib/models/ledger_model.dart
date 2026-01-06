class LedgerModel {
  final String id;
  final String userId;
  final String apartmentNumber;
  final String buildingName;
  final String transactionType; // 'debit', 'credit'
  final String category; // 'maintenance', 'utility', 'penalty', 'refund', 'other'
  final String description;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String transactionId;
  final String referenceId; // Reference to payment or other transaction
  final String status; // 'pending', 'completed', 'failed', 'cancelled'
  final DateTime transactionDate;
  final DateTime? processedDate;
  final String processedBy;
  final String? remarks;
  final String? receiptUrl;
  final double? balanceBefore;
  final double? balanceAfter;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime? nextDueDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LedgerModel({
    required this.id,
    required this.userId,
    required this.apartmentNumber,
    required this.buildingName,
    required this.transactionType,
    required this.category,
    required this.description,
    required this.amount,
    this.currency = 'INR',
    this.paymentMethod = '',
    this.transactionId = '',
    this.referenceId = '',
    this.status = 'pending',
    required this.transactionDate,
    this.processedDate,
    this.processedBy = '',
    this.remarks = '',
    this.receiptUrl = '',
    this.balanceBefore,
    this.balanceAfter,
    this.isRecurring = false,
    this.recurringFrequency,
    this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LedgerModel.fromMap(Map<String, dynamic> map) {
    return LedgerModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      apartmentNumber: map['apartmentNumber'] ?? '',
      buildingName: map['buildingName'] ?? '',
      transactionType: map['transactionType'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'INR',
      paymentMethod: map['paymentMethod'] ?? '',
      transactionId: map['transactionId'] ?? '',
      referenceId: map['referenceId'] ?? '',
      status: map['status'] ?? 'pending',
      transactionDate: DateTime.parse(map['transactionDate'] ?? DateTime.now().toIso8601String()),
      processedDate: map['processedDate'] != null ? DateTime.parse(map['processedDate']) : null,
      processedBy: map['processedBy'] ?? '',
      remarks: map['remarks'] ?? '',
      receiptUrl: map['receiptUrl'] ?? '',
      balanceBefore: (map['balanceBefore'] ?? 0.0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0.0).toDouble(),
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'],
      nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'apartmentNumber': apartmentNumber,
      'buildingName': buildingName,
      'transactionType': transactionType,
      'category': category,
      'description': description,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'referenceId': referenceId,
      'status': status,
      'transactionDate': transactionDate.toIso8601String(),
      'processedDate': processedDate?.toIso8601String(),
      'processedBy': processedBy,
      'remarks': remarks,
      'receiptUrl': receiptUrl,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LedgerModel copyWith({
    String? id,
    String? userId,
    String? apartmentNumber,
    String? buildingName,
    String? transactionType,
    String? category,
    String? description,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? transactionId,
    String? referenceId,
    String? status,
    DateTime? transactionDate,
    DateTime? processedDate,
    String? processedBy,
    String? remarks,
    String? receiptUrl,
    double? balanceBefore,
    double? balanceAfter,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? nextDueDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LedgerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      buildingName: buildingName ?? this.buildingName,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      referenceId: referenceId ?? this.referenceId,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
      processedDate: processedDate ?? this.processedDate,
      processedBy: processedBy ?? this.processedBy,
      remarks: remarks ?? this.remarks,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isDebit => transactionType == 'debit';
  bool get isCredit => transactionType == 'credit';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  @override
  String toString() {
    return 'LedgerModel(id: $id, userId: $userId, apartmentNumber: $apartmentNumber, buildingName: $buildingName, transactionType: $transactionType, category: $category, description: $description, amount: $amount, currency: $currency, paymentMethod: $paymentMethod, transactionId: $transactionId, referenceId: $referenceId, status: $status, transactionDate: $transactionDate, processedDate: $processedDate, processedBy: $processedBy, remarks: $remarks, receiptUrl: $receiptUrl, balanceBefore: $balanceBefore, balanceAfter: $balanceAfter, isRecurring: $isRecurring, recurringFrequency: $recurringFrequency, nextDueDate: $nextDueDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedgerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
