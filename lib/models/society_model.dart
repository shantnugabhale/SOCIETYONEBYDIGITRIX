class SocietyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String? buildingId; // Parent building ID (for Super Admin management)
  final double? latitude;
  final double? longitude;
  final String? gstin;
  final int totalUnits;
  final int occupiedUnits;
  final int vacantUnits;
  final List<String> blocks; // Block/Wing names
  final List<String> amenities; // Available amenities
  final String? contactNumber;
  final String? email;
  final String? website;
  final String? logoUrl;
  // Feature-based billing: Map of feature keys to enabled status
  final Map<String, bool> enabledFeatures;
  // Committee members: Map of role (chairman/secretary/treasurer) to userId
  final Map<String, String?> committeeMembers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SocietyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    this.buildingId,
    this.latitude,
    this.longitude,
    this.gstin,
    this.totalUnits = 0,
    this.occupiedUnits = 0,
    this.vacantUnits = 0,
    this.blocks = const [],
    this.amenities = const [],
    this.contactNumber,
    this.email,
    this.website,
    this.logoUrl,
    this.enabledFeatures = const {},
    this.committeeMembers = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocietyModel.fromMap(Map<String, dynamic> map) {
    // Parse enabledFeatures
    final enabledFeaturesMap = map['enabledFeatures'];
    final enabledFeatures = enabledFeaturesMap != null && enabledFeaturesMap is Map
        ? Map<String, bool>.from(enabledFeaturesMap.map((key, value) => MapEntry(key.toString(), value == true)))
        : <String, bool>{};
    
    // Parse committeeMembers
    final committeeMembersMap = map['committeeMembers'];
    final committeeMembers = committeeMembersMap != null && committeeMembersMap is Map
        ? Map<String, String?>.from(committeeMembersMap.map((key, value) => MapEntry(key.toString(), value?.toString())))
        : <String, String?>{};
    
    return SocietyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      buildingId: map['buildingId'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      gstin: map['gstin'],
      totalUnits: map['totalUnits'] ?? 0,
      occupiedUnits: map['occupiedUnits'] ?? 0,
      vacantUnits: map['vacantUnits'] ?? 0,
      blocks: List<String>.from(map['blocks'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      contactNumber: map['contactNumber'],
      email: map['email'],
      website: map['website'],
      logoUrl: map['logoUrl'],
      enabledFeatures: enabledFeatures,
      committeeMembers: committeeMembers,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'buildingId': buildingId,
      'latitude': latitude,
      'longitude': longitude,
      'gstin': gstin,
      'totalUnits': totalUnits,
      'occupiedUnits': occupiedUnits,
      'vacantUnits': vacantUnits,
      'blocks': blocks,
      'amenities': amenities,
      'contactNumber': contactNumber,
      'email': email,
      'website': website,
      'logoUrl': logoUrl,
      'enabledFeatures': enabledFeatures,
      'committeeMembers': committeeMembers,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress => '$address, $city, $state - $pinCode';
}

class UnitModel {
  final String id;
  final String societyId;
  final String block; // Block/Wing name
  final String unitNumber; // Flat/Unit number
  final String floorNumber;
  final String status; // 'occupied', 'vacant', 'under_construction'
  final String? ownerId; // Current owner's user ID
  final String? tenantId; // Current tenant's user ID
  final double? area; // Area in sq.ft
  final int? bedrooms;
  final DateTime? possessionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UnitModel({
    required this.id,
    required this.societyId,
    required this.block,
    required this.unitNumber,
    this.floorNumber = '',
    this.status = 'vacant',
    this.ownerId,
    this.tenantId,
    this.area,
    this.bedrooms,
    this.possessionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'] ?? '',
      societyId: map['societyId'] ?? '',
      block: map['block'] ?? '',
      unitNumber: map['unitNumber'] ?? '',
      floorNumber: map['floorNumber'] ?? '',
      status: map['status'] ?? 'vacant',
      ownerId: map['ownerId'],
      tenantId: map['tenantId'],
      area: map['area'] != null ? (map['area'] as num).toDouble() : null,
      bedrooms: map['bedrooms'],
      possessionDate: map['possessionDate'] != null
          ? DateTime.parse(map['possessionDate'])
          : null,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'societyId': societyId,
      'block': block,
      'unitNumber': unitNumber,
      'floorNumber': floorNumber,
      'status': status,
      'ownerId': ownerId,
      'tenantId': tenantId,
      'area': area,
      'bedrooms': bedrooms,
      'possessionDate': possessionDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress => '$block - $unitNumber';
}

