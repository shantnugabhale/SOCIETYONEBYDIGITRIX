class BalanceSheetItem {
  final String id;
  final String item; // Liabilities / Item name
  final double credit; // Credit amount (Income/Revenue)
  final double debit; // Debit amount (Expenses)
  final double total; // Total (Credit - Debit)

  BalanceSheetItem({
    required this.id,
    required this.item,
    this.credit = 0.0,
    this.debit = 0.0,
    double? total,
  }) : total = total ?? (credit - debit);

  factory BalanceSheetItem.fromMap(Map<String, dynamic> map) {
    final credit = (map['credit'] ?? 0.0).toDouble();
    final debit = (map['debit'] ?? 0.0).toDouble();
    return BalanceSheetItem(
      id: map['id'] ?? '',
      item: map['item'] ?? '',
      credit: credit,
      debit: debit,
      total: (map['total'] ?? (credit - debit)).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item': item,
      'credit': credit,
      'debit': debit,
      'total': total,
    };
  }

  BalanceSheetItem copyWith({
    String? id,
    String? item,
    double? credit,
    double? debit,
    double? total,
  }) {
    final newCredit = credit ?? this.credit;
    final newDebit = debit ?? this.debit;
    return BalanceSheetItem(
      id: id ?? this.id,
      item: item ?? this.item,
      credit: newCredit,
      debit: newDebit,
      total: total ?? (newCredit - newDebit),
    );
  }
}

class BalanceSheetModel {
  final String id;
  final int year;
  final String societyName;
  
  // List of balance sheet items
  final List<BalanceSheetItem> items;
  
  // Calculated totals
  final double totalCredit;
  final double totalDebit;
  final double netBalance; // totalCredit - totalDebit
  
  // Metadata
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool isActive;
  final bool isFinalized; // Whether balance sheet is finalized/locked

  BalanceSheetModel({
    required this.id,
    required this.year,
    required this.societyName,
    required this.items,
    double? totalCredit,
    double? totalDebit,
    double? netBalance,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isActive = true,
    this.isFinalized = false,
  }) : totalCredit = totalCredit ?? _calculateTotalCredit(items),
        totalDebit = totalDebit ?? _calculateTotalDebit(items),
        netBalance = netBalance ?? ((totalCredit ?? _calculateTotalCredit(items)) - (totalDebit ?? _calculateTotalDebit(items)));

  static double _calculateTotalCredit(List<BalanceSheetItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.credit);
  }

  static double _calculateTotalDebit(List<BalanceSheetItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.debit);
  }

  factory BalanceSheetModel.fromMap(Map<String, dynamic> map) {
    final itemsList = map['items'] as List? ?? [];
    final items = itemsList
        .map((item) => BalanceSheetItem.fromMap(item as Map<String, dynamic>))
        .toList();
    
    return BalanceSheetModel(
      id: map['id'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      societyName: map['societyName'] ?? '',
      items: items,
      totalCredit: (map['totalCredit'] ?? _calculateTotalCredit(items)).toDouble(),
      totalDebit: (map['totalDebit'] ?? _calculateTotalDebit(items)).toDouble(),
      netBalance: (map['netBalance'] ?? (_calculateTotalCredit(items) - _calculateTotalDebit(items))).toDouble(),
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      isFinalized: map['isFinalized'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'societyName': societyName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'netBalance': netBalance,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
      'isFinalized': isFinalized,
    };
  }

  BalanceSheetModel copyWith({
    String? id,
    int? year,
    String? societyName,
    List<BalanceSheetItem>? items,
    double? totalCredit,
    double? totalDebit,
    double? netBalance,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
    bool? isFinalized,
  }) {
    final updatedItems = items ?? this.items;
    return BalanceSheetModel(
      id: id ?? this.id,
      year: year ?? this.year,
      societyName: societyName ?? this.societyName,
      items: updatedItems,
      totalCredit: totalCredit ?? _calculateTotalCredit(updatedItems),
      totalDebit: totalDebit ?? _calculateTotalDebit(updatedItems),
      netBalance: netBalance ?? (_calculateTotalCredit(updatedItems) - _calculateTotalDebit(updatedItems)),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }

  // Common items for balance sheet
  static const List<String> defaultItems = [
    'Maintenance Fees',
    'Parking Fees',
    'Late Fees',
    'Penalty Charges',
    'Interest Income',
    'Rental Income',
    'Electricity',
    'Water',
    'Elevator Maintenance',
    'Security',
    'Cleaning',
    'Gardening',
    'Repairs & Maintenance',
    'Insurance',
    'Property Tax',
    'Legal Fees',
    'Audit Fees',
    'Bank Charges',
    'Staff Salaries',
    'Office Supplies',
    'Internet & Phone',
    'Other Income',
    'Other Expenses',
  ];
}
