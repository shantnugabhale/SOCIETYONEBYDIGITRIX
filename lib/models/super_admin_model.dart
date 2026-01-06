class SuperAdminModel {
  final String id;
  final String mobileNumber;
  final String name;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SuperAdminModel({
    required this.id,
    required this.mobileNumber,
    required this.name,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SuperAdminModel.fromMap(Map<String, dynamic> map) {
    return SuperAdminModel(
      id: map['id'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'name': name,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

