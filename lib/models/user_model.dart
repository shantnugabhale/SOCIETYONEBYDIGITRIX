class UserModel {
  final String id;
  final String email;
  final String name;
  final String mobileNumber;
  final String role; // 'admin', 'member'
  final String apartmentNumber;
  final String buildingName;
  final String profileImageUrl;
  final bool isEmailVerified;
  final bool isMobileVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.mobileNumber,
    required this.role,
    required this.apartmentNumber,
    required this.buildingName,
    this.profileImageUrl = '',
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      role: map['role'] ?? 'member',
      apartmentNumber: map['apartmentNumber'] ?? '',
      buildingName: map['buildingName'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      isMobileVerified: map['isMobileVerified'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'mobileNumber': mobileNumber,
      'role': role,
      'apartmentNumber': apartmentNumber,
      'buildingName': buildingName,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'isMobileVerified': isMobileVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? mobileNumber,
    String? role,
    String? apartmentNumber,
    String? buildingName,
    String? profileImageUrl,
    bool? isEmailVerified,
    bool? isMobileVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      buildingName: buildingName ?? this.buildingName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, mobileNumber: $mobileNumber, role: $role, apartmentNumber: $apartmentNumber, buildingName: $buildingName, profileImageUrl: $profileImageUrl, isEmailVerified: $isEmailVerified, isMobileVerified: $isMobileVerified, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
