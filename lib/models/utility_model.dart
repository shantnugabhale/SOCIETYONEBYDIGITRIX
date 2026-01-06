class UtilityModel {
  final String id;
  final String utilityType; // Service name
  final double totalAmount; // Amount
  final double overdueAmount;
  final DateTime dueDate;
  final String status; // 'pending', 'paid', 'overdue', 'cancelled'
  final List<String> paidBy; // Array of user IDs who have paid this bill
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UtilityModel({
    required this.id,
    required this.utilityType,
    required this.totalAmount,
    this.overdueAmount = 0.0,
    required this.dueDate,
    this.status = 'pending',
    this.paidBy = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UtilityModel.fromMap(Map<String, dynamic> map) {
    return UtilityModel(
      id: map['id'] ?? '',
      utilityType: map['utilityType'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      overdueAmount: (map['overdueAmount'] ?? 0.0).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      paidBy: (map['paidBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'utilityType': utilityType,
      'totalAmount': totalAmount,
      'overdueAmount': overdueAmount,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidBy': paidBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UtilityModel copyWith({
    String? id,
    String? utilityType,
    double? totalAmount,
    double? overdueAmount,
    DateTime? dueDate,
    String? status,
    List<String>? paidBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UtilityModel(
      id: id ?? this.id,
      utilityType: utilityType ?? this.utilityType,
      totalAmount: totalAmount ?? this.totalAmount,
      overdueAmount: overdueAmount ?? this.overdueAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidBy: paidBy ?? this.paidBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue' || (status == 'pending' && DateTime.now().isAfter(dueDate));
  bool get isCancelled => status == 'cancelled';
  
  // Check if a specific user has paid this bill
  bool hasPaidBy(String userId) => paidBy.contains(userId);

  @override
  String toString() {
    return 'UtilityModel(id: $id, utilityType: $utilityType, totalAmount: $totalAmount, overdueAmount: $overdueAmount, dueDate: $dueDate, status: $status, paidBy: $paidBy, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UtilityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
