class FacilityModel {
  final String id;
  final String name;
  final String description;
  final String type; // 'sports_court', 'swimming_pool', 'gym', 'clubhouse', 'park', 'playground', 'other'
  final String location;
  final int maxCapacity;
  final double hourlyRate; // 0 if free
  final List<String> images;
  final List<String> amenities; // e.g., ['wifi', 'parking', 'changing_room']
  final bool requiresApproval;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FacilityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    this.maxCapacity = 1,
    this.hourlyRate = 0.0,
    this.images = const [],
    this.amenities = const [],
    this.requiresApproval = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacilityModel.fromMap(Map<String, dynamic> map) {
    return FacilityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      location: map['location'] ?? '',
      maxCapacity: map['maxCapacity'] ?? 1,
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      requiresApproval: map['requiresApproval'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'location': location,
      'maxCapacity': maxCapacity,
      'hourlyRate': hourlyRate,
      'images': images,
      'amenities': amenities,
      'requiresApproval': requiresApproval,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FacilityBookingModel {
  final String id;
  final String facilityId;
  final String facilityName;
  final String userId;
  final String userName;
  final String userApartment;
  final DateTime startTime;
  final DateTime endTime;
  final int numberOfGuests;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled', 'completed'
  final String? rejectionReason;
  final double totalAmount;
  final String paymentStatus; // 'pending', 'paid', 'refunded'
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  FacilityBookingModel({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.userId,
    required this.userName,
    required this.userApartment,
    required this.startTime,
    required this.endTime,
    this.numberOfGuests = 1,
    this.status = 'pending',
    this.rejectionReason,
    this.totalAmount = 0.0,
    this.paymentStatus = 'pending',
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => endTime.difference(startTime);

  factory FacilityBookingModel.fromMap(Map<String, dynamic> map) {
    return FacilityBookingModel(
      id: map['id'] ?? '',
      facilityId: map['facilityId'] ?? '',
      facilityName: map['facilityName'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userApartment: map['userApartment'] ?? '',
      startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(map['endTime'] ?? DateTime.now().toIso8601String()),
      numberOfGuests: map['numberOfGuests'] ?? 1,
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'pending',
      remarks: map['remarks'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'userId': userId,
      'userName': userName,
      'userApartment': userApartment,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'status': status,
      'rejectionReason': rejectionReason,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

