class VisitorModel {
  final String id;
  final String residentUserId;
  final String residentName;
  final String residentApartment;
  final String visitorName;
  final String visitorPhone;
  final String visitorEmail;
  final int numberOfVisitors;
  final String purpose; // 'personal', 'delivery', 'service', 'guest', 'other'
  final String status; // 'pending', 'approved', 'checked_in', 'checked_out', 'rejected', 'expired'
  final String? qrCode;
  final String? qrCodeUrl;
  final DateTime expectedArrival;
  final DateTime? actualArrival;
  final DateTime? expectedDeparture;
  final DateTime? actualDeparture;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? idProofType; // 'aadhaar', 'pan', 'driving_license', 'other'
  final String? idProofNumber;
  final String? idProofImageUrl;
  final String? checkedInBy; // Security guard name/ID
  final String? checkedOutBy;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitorModel({
    required this.id,
    required this.residentUserId,
    required this.residentName,
    required this.residentApartment,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorEmail = '',
    this.numberOfVisitors = 1,
    this.purpose = 'personal',
    this.status = 'pending',
    this.qrCode,
    this.qrCodeUrl,
    required this.expectedArrival,
    this.actualArrival,
    this.expectedDeparture,
    this.actualDeparture,
    this.vehicleNumber,
    this.vehicleType,
    this.idProofType,
    this.idProofNumber,
    this.idProofImageUrl,
    this.checkedInBy,
    this.checkedOutBy,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'checked_in' || status == 'approved';
  bool get isExpired => expectedArrival.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  factory VisitorModel.fromMap(Map<String, dynamic> map) {
    return VisitorModel(
      id: map['id'] ?? '',
      residentUserId: map['residentUserId'] ?? '',
      residentName: map['residentName'] ?? '',
      residentApartment: map['residentApartment'] ?? '',
      visitorName: map['visitorName'] ?? '',
      visitorPhone: map['visitorPhone'] ?? '',
      visitorEmail: map['visitorEmail'] ?? '',
      numberOfVisitors: map['numberOfVisitors'] ?? 1,
      purpose: map['purpose'] ?? 'personal',
      status: map['status'] ?? 'pending',
      qrCode: map['qrCode'],
      qrCodeUrl: map['qrCodeUrl'],
      expectedArrival: DateTime.parse(map['expectedArrival'] ?? DateTime.now().toIso8601String()),
      actualArrival: map['actualArrival'] != null 
          ? DateTime.parse(map['actualArrival']) 
          : null,
      expectedDeparture: map['expectedDeparture'] != null 
          ? DateTime.parse(map['expectedDeparture']) 
          : null,
      actualDeparture: map['actualDeparture'] != null 
          ? DateTime.parse(map['actualDeparture']) 
          : null,
      vehicleNumber: map['vehicleNumber'],
      vehicleType: map['vehicleType'],
      idProofType: map['idProofType'],
      idProofNumber: map['idProofNumber'],
      idProofImageUrl: map['idProofImageUrl'],
      checkedInBy: map['checkedInBy'],
      checkedOutBy: map['checkedOutBy'],
      remarks: map['remarks'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'residentUserId': residentUserId,
      'residentName': residentName,
      'residentApartment': residentApartment,
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      'visitorEmail': visitorEmail,
      'numberOfVisitors': numberOfVisitors,
      'purpose': purpose,
      'status': status,
      'qrCode': qrCode,
      'qrCodeUrl': qrCodeUrl,
      'expectedArrival': expectedArrival.toIso8601String(),
      'actualArrival': actualArrival?.toIso8601String(),
      'expectedDeparture': expectedDeparture?.toIso8601String(),
      'actualDeparture': actualDeparture?.toIso8601String(),
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'idProofImageUrl': idProofImageUrl,
      'checkedInBy': checkedInBy,
      'checkedOutBy': checkedOutBy,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

