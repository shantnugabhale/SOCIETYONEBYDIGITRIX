class MemberModel {
  final String id;
  final String userId;
  final String apartmentNumber;
  final String buildingName;
  final String floorNumber;
  final String flatNumber;
  final String ownerName;
  final String ownerMobile;
  final String ownerEmail;
  final String tenantName;
  final String tenantMobile;
  final String tenantEmail;
  final bool isOwner;
  final bool isTenant;
  final DateTime moveInDate;
  final DateTime? moveOutDate;
  final String emergencyContactName;
  final String emergencyContactMobile;
  final String emergencyContactRelation;
  final String vehicleNumber;
  final String vehicleType;
  final String parkingSlot;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberModel({
    required this.id,
    required this.userId,
    required this.apartmentNumber,
    required this.buildingName,
    required this.floorNumber,
    required this.flatNumber,
    required this.ownerName,
    required this.ownerMobile,
    required this.ownerEmail,
    this.tenantName = '',
    this.tenantMobile = '',
    this.tenantEmail = '',
    this.isOwner = true,
    this.isTenant = false,
    required this.moveInDate,
    this.moveOutDate,
    this.emergencyContactName = '',
    this.emergencyContactMobile = '',
    this.emergencyContactRelation = '',
    this.vehicleNumber = '',
    this.vehicleType = '',
    this.parkingSlot = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      apartmentNumber: map['apartmentNumber'] ?? '',
      buildingName: map['buildingName'] ?? '',
      floorNumber: map['floorNumber'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerMobile: map['ownerMobile'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      tenantName: map['tenantName'] ?? '',
      tenantMobile: map['tenantMobile'] ?? '',
      tenantEmail: map['tenantEmail'] ?? '',
      isOwner: map['isOwner'] ?? true,
      isTenant: map['isTenant'] ?? false,
      moveInDate: DateTime.parse(map['moveInDate'] ?? DateTime.now().toIso8601String()),
      moveOutDate: map['moveOutDate'] != null ? DateTime.parse(map['moveOutDate']) : null,
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactMobile: map['emergencyContactMobile'] ?? '',
      emergencyContactRelation: map['emergencyContactRelation'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      parkingSlot: map['parkingSlot'] ?? '',
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
      'floorNumber': floorNumber,
      'flatNumber': flatNumber,
      'ownerName': ownerName,
      'ownerMobile': ownerMobile,
      'ownerEmail': ownerEmail,
      'tenantName': tenantName,
      'tenantMobile': tenantMobile,
      'tenantEmail': tenantEmail,
      'isOwner': isOwner,
      'isTenant': isTenant,
      'moveInDate': moveInDate.toIso8601String(),
      'moveOutDate': moveOutDate?.toIso8601String(),
      'emergencyContactName': emergencyContactName,
      'emergencyContactMobile': emergencyContactMobile,
      'emergencyContactRelation': emergencyContactRelation,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'parkingSlot': parkingSlot,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MemberModel copyWith({
    String? id,
    String? userId,
    String? apartmentNumber,
    String? buildingName,
    String? floorNumber,
    String? flatNumber,
    String? ownerName,
    String? ownerMobile,
    String? ownerEmail,
    String? tenantName,
    String? tenantMobile,
    String? tenantEmail,
    bool? isOwner,
    bool? isTenant,
    DateTime? moveInDate,
    DateTime? moveOutDate,
    String? emergencyContactName,
    String? emergencyContactMobile,
    String? emergencyContactRelation,
    String? vehicleNumber,
    String? vehicleType,
    String? parkingSlot,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      buildingName: buildingName ?? this.buildingName,
      floorNumber: floorNumber ?? this.floorNumber,
      flatNumber: flatNumber ?? this.flatNumber,
      ownerName: ownerName ?? this.ownerName,
      ownerMobile: ownerMobile ?? this.ownerMobile,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      tenantName: tenantName ?? this.tenantName,
      tenantMobile: tenantMobile ?? this.tenantMobile,
      tenantEmail: tenantEmail ?? this.tenantEmail,
      isOwner: isOwner ?? this.isOwner,
      isTenant: isTenant ?? this.isTenant,
      moveInDate: moveInDate ?? this.moveInDate,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactMobile: emergencyContactMobile ?? this.emergencyContactMobile,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      parkingSlot: parkingSlot ?? this.parkingSlot,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MemberModel(id: $id, userId: $userId, apartmentNumber: $apartmentNumber, buildingName: $buildingName, floorNumber: $floorNumber, flatNumber: $flatNumber, ownerName: $ownerName, ownerMobile: $ownerMobile, ownerEmail: $ownerEmail, tenantName: $tenantName, tenantMobile: $tenantMobile, tenantEmail: $tenantEmail, isOwner: $isOwner, isTenant: $isTenant, moveInDate: $moveInDate, moveOutDate: $moveOutDate, emergencyContactName: $emergencyContactName, emergencyContactMobile: $emergencyContactMobile, emergencyContactRelation: $emergencyContactRelation, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType, parkingSlot: $parkingSlot, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
