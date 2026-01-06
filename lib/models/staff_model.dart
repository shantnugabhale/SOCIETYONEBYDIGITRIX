class StaffModel {
  final String id;
  final String name;
  final String role; // 'security', 'maintenance', 'housekeeping', 'gardener', 'electrician', 'plumber', 'other'
  final String phoneNumber;
  final String email;
  final String? address;
  final String? photoUrl;
  final String? idProofType;
  final String? idProofNumber;
  final String? idProofImageUrl;
  final DateTime joinDate;
  final DateTime? leaveDate;
  final String shift; // 'morning', 'afternoon', 'night', 'full_day'
  final String status; // 'active', 'inactive', 'on_leave', 'terminated'
  final double? salary;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String> assignedAreas; // Building names or areas
  final Map<String, dynamic>? additionalInfo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.phoneNumber,
    this.email = '',
    this.address,
    this.photoUrl,
    this.idProofType,
    this.idProofNumber,
    this.idProofImageUrl,
    required this.joinDate,
    this.leaveDate,
    this.shift = 'full_day',
    this.status = 'active',
    this.salary,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.assignedAreas = const [],
    this.additionalInfo,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      address: map['address'],
      photoUrl: map['photoUrl'],
      idProofType: map['idProofType'],
      idProofNumber: map['idProofNumber'],
      idProofImageUrl: map['idProofImageUrl'],
      joinDate: DateTime.parse(map['joinDate'] ?? DateTime.now().toIso8601String()),
      leaveDate: map['leaveDate'] != null 
          ? DateTime.parse(map['leaveDate']) 
          : null,
      shift: map['shift'] ?? 'full_day',
      status: map['status'] ?? 'active',
      salary: map['salary'] != null ? (map['salary'] as num).toDouble() : null,
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      assignedAreas: List<String>.from(map['assignedAreas'] ?? []),
      additionalInfo: map['additionalInfo'] != null 
          ? Map<String, dynamic>.from(map['additionalInfo']) 
          : null,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'photoUrl': photoUrl,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'idProofImageUrl': idProofImageUrl,
      'joinDate': joinDate.toIso8601String(),
      'leaveDate': leaveDate?.toIso8601String(),
      'shift': shift,
      'status': status,
      'salary': salary,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'assignedAreas': assignedAreas,
      'additionalInfo': additionalInfo,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class StaffAttendanceModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'present', 'absent', 'late', 'on_leave', 'half_day'
  final String? remarks;
  final double? overtimeHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffAttendanceModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'present',
    this.remarks,
    this.overtimeHours,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get workingHours {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return null;
  }

  factory StaffAttendanceModel.fromMap(Map<String, dynamic> map) {
    return StaffAttendanceModel(
      id: map['id'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      checkInTime: map['checkInTime'] != null 
          ? DateTime.parse(map['checkInTime']) 
          : null,
      checkOutTime: map['checkOutTime'] != null 
          ? DateTime.parse(map['checkOutTime']) 
          : null,
      status: map['status'] ?? 'present',
      remarks: map['remarks'],
      overtimeHours: map['overtimeHours'] != null 
          ? (map['overtimeHours'] as num).toDouble() 
          : null,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status,
      'remarks': remarks,
      'overtimeHours': overtimeHours,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

