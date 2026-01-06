class EmergencyAlertModel {
  final String id;
  final String userId;
  final String userName;
  final String userApartment;
  final String userPhone;
  final String emergencyType; // 'medical', 'fire', 'security', 'accident', 'other'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String? location;
  final String? description;
  final String status; // 'active', 'acknowledged', 'resolved', 'false_alarm'
  final List<String> notifiedTo; // Admin/staff IDs
  final List<String> responders; // Staff/emergency services
  final DateTime alertTime;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyAlertModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userApartment,
    required this.userPhone,
    required this.emergencyType,
    this.severity = 'high',
    this.location,
    this.description,
    this.status = 'active',
    this.notifiedTo = const [],
    this.responders = const [],
    required this.alertTime,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active' || status == 'acknowledged';

  factory EmergencyAlertModel.fromMap(Map<String, dynamic> map) {
    return EmergencyAlertModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userApartment: map['userApartment'] ?? '',
      userPhone: map['userPhone'] ?? '',
      emergencyType: map['emergencyType'] ?? '',
      severity: map['severity'] ?? 'high',
      location: map['location'],
      description: map['description'],
      status: map['status'] ?? 'active',
      notifiedTo: List<String>.from(map['notifiedTo'] ?? []),
      responders: List<String>.from(map['responders'] ?? []),
      alertTime: DateTime.parse(map['alertTime'] ?? DateTime.now().toIso8601String()),
      acknowledgedAt: map['acknowledgedAt'] != null 
          ? DateTime.parse(map['acknowledgedAt']) 
          : null,
      acknowledgedBy: map['acknowledgedBy'],
      resolvedAt: map['resolvedAt'] != null 
          ? DateTime.parse(map['resolvedAt']) 
          : null,
      resolvedBy: map['resolvedBy'],
      resolutionNotes: map['resolutionNotes'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userApartment': userApartment,
      'userPhone': userPhone,
      'emergencyType': emergencyType,
      'severity': severity,
      'location': location,
      'description': description,
      'status': status,
      'notifiedTo': notifiedTo,
      'responders': responders,
      'alertTime': alertTime.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': acknowledgedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolutionNotes': resolutionNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String type; // 'police', 'fire', 'ambulance', 'security', 'hospital', 'other'
  final String? email;
  final String? address;
  final int priority; // Lower number = higher priority
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.email,
    this.address,
    this.priority = 1,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? '',
      email: map['email'],
      address: map['address'],
      priority: map['priority'] ?? 1,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'email': email,
      'address': address,
      'priority': priority,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

