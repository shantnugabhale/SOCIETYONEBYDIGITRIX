class PaymentModel {
  final String id;
  final String userId;
  final double amount;
  final String transactionId;
  final String paymentMethod;
  final String status; // 'success', 'failed', 'pending'
  final List<String> billIds; // Array of utility bill IDs paid
  final DateTime paidDate;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionId,
    required this.paymentMethod,
    this.status = 'success',
    this.billIds = const [],
    required this.paidDate,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      transactionId: map['transactionId'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'online',
      status: map['status'] ?? 'success',
      billIds: (map['billIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      paidDate: DateTime.parse(map['paidDate'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'status': status,
      'billIds': billIds,
      'paidDate': paidDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? transactionId,
    String? paymentMethod,
    String? status,
    List<String>? billIds,
    DateTime? paidDate,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      billIds: billIds ?? this.billIds,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, userId: $userId, amount: $amount, transactionId: $transactionId, paymentMethod: $paymentMethod, status: $status, billIds: $billIds, paidDate: $paidDate, createdAt: $createdAt)';
  }
}
