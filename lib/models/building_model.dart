class BuildingModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String? contactNumber;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BuildingModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    this.contactNumber,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuildingModel.fromMap(Map<String, dynamic> map) {
    return BuildingModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      contactNumber: map['contactNumber'],
      email: map['email'],
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
      'contactNumber': contactNumber,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress => '$address, $city, $state - $pinCode';
}

