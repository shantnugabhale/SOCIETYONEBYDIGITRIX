class UserModel {
  final String id;
  final String email;
  final String name;
  final String mobileNumber;
  final String role; // 'admin', 'member', 'security', 'committee'
  final String? societyId; // Multi-tenancy: Society ID
  final String? societyName; // Society name for quick access
  final String apartmentNumber;
  final String buildingName; // Block/Wing name
  final String userType; // 'owner', 'tenant', 'family_member'
  final String? committeeRole; // 'chairman', 'secretary', 'treasurer', null
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final String? addressProofUrl; // Mandatory address proof document URL
  final bool addressProofVerified; // Authority verification status
  final String? approvedByRole; // 'chairman', 'secretary', 'treasurer'
  final String? approvedBy; // User ID who approved
  final bool hideContactInDirectory; // Privacy toggle
  final String profileImageUrl;
  final bool isEmailVerified;
  final bool isMobileVerified;
  final bool isKycVerified; // KYC status
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.mobileNumber,
    required this.role,
    this.societyId,
    this.societyName,
    required this.apartmentNumber,
    required this.buildingName,
    this.userType = 'owner',
    this.committeeRole,
    this.approvalStatus = 'pending',
    this.rejectionReason,
    this.addressProofUrl,
    this.addressProofVerified = false,
    this.approvedByRole,
    this.hideContactInDirectory = false,
    this.profileImageUrl = '',
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    this.isKycVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      role: map['role'] ?? 'member',
      societyId: map['societyId'],
      societyName: map['societyName'],
      apartmentNumber: map['apartmentNumber'] ?? '',
      buildingName: map['buildingName'] ?? '',
      userType: map['userType'] ?? 'owner',
      committeeRole: map['committeeRole'],
      approvalStatus: map['approvalStatus'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      addressProofUrl: map['addressProofUrl'],
      addressProofVerified: map['addressProofVerified'] ?? false,
      approvedByRole: map['approvedByRole'],
      hideContactInDirectory: map['hideContactInDirectory'] ?? false,
      profileImageUrl: map['profileImageUrl'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      isMobileVerified: map['isMobileVerified'] ?? false,
      isKycVerified: map['isKycVerified'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      approvedBy: map['approvedBy'],
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
      'societyId': societyId,
      'societyName': societyName,
      'apartmentNumber': apartmentNumber,
      'buildingName': buildingName,
      'userType': userType,
      'committeeRole': committeeRole,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
      'addressProofUrl': addressProofUrl,
      'addressProofVerified': addressProofVerified,
      'approvedByRole': approvedByRole,
      'hideContactInDirectory': hideContactInDirectory,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'isMobileVerified': isMobileVerified,
      'isKycVerified': isKycVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? mobileNumber,
    String? role,
    String? societyId,
    String? societyName,
    String? apartmentNumber,
    String? buildingName,
    String? userType,
    String? committeeRole,
    String? approvalStatus,
    String? rejectionReason,
    String? addressProofUrl,
    bool? addressProofVerified,
    String? approvedByRole,
    bool? hideContactInDirectory,
    String? profileImageUrl,
    bool? isEmailVerified,
    bool? isMobileVerified,
    bool? isKycVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      societyId: societyId ?? this.societyId,
      societyName: societyName ?? this.societyName,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      buildingName: buildingName ?? this.buildingName,
      userType: userType ?? this.userType,
      committeeRole: committeeRole ?? this.committeeRole,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      addressProofUrl: addressProofUrl ?? this.addressProofUrl,
      addressProofVerified: addressProofVerified ?? this.addressProofVerified,
      approvedByRole: approvedByRole ?? this.approvedByRole,
      hideContactInDirectory: hideContactInDirectory ?? this.hideContactInDirectory,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
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
