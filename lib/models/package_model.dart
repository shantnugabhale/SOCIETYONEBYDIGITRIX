class PackageModel {
  final String id;
  final String recipientUserId;
  final String recipientName;
  final String recipientApartment;
  final String recipientPhone;
  final String courierName; // e.g., 'Amazon', 'Flipkart', 'DTDC'
  final String? trackingNumber;
  final String? senderName;
  final String? senderAddress;
  final String packageType; // 'document', 'parcel', 'food', 'other'
  final int? numberOfItems;
  final String status; // 'pending', 'received', 'collected', 'returned', 'lost'
  final DateTime receivedDate;
  final DateTime? collectedDate;
  final String? collectedBy;
  final String? receivedBy; // Security/staff name
  final String? location; // Where it's stored (e.g., 'Security Desk', 'Room 101')
  final String? imageUrl; // Photo of package
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  PackageModel({
    required this.id,
    required this.recipientUserId,
    required this.recipientName,
    required this.recipientApartment,
    required this.recipientPhone,
    required this.courierName,
    this.trackingNumber,
    this.senderName,
    this.senderAddress,
    this.packageType = 'parcel',
    this.numberOfItems,
    this.status = 'received',
    required this.receivedDate,
    this.collectedDate,
    this.collectedBy,
    this.receivedBy,
    this.location,
    this.imageUrl,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending' || status == 'received';
  Duration? get waitingDuration {
    if (collectedDate != null) {
      return collectedDate!.difference(receivedDate);
    }
    return DateTime.now().difference(receivedDate);
  }

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id'] ?? '',
      recipientUserId: map['recipientUserId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientApartment: map['recipientApartment'] ?? '',
      recipientPhone: map['recipientPhone'] ?? '',
      courierName: map['courierName'] ?? '',
      trackingNumber: map['trackingNumber'],
      senderName: map['senderName'],
      senderAddress: map['senderAddress'],
      packageType: map['packageType'] ?? 'parcel',
      numberOfItems: map['numberOfItems'],
      status: map['status'] ?? 'received',
      receivedDate: DateTime.parse(map['receivedDate'] ?? DateTime.now().toIso8601String()),
      collectedDate: map['collectedDate'] != null 
          ? DateTime.parse(map['collectedDate']) 
          : null,
      collectedBy: map['collectedBy'],
      receivedBy: map['receivedBy'],
      location: map['location'],
      imageUrl: map['imageUrl'],
      remarks: map['remarks'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientUserId': recipientUserId,
      'recipientName': recipientName,
      'recipientApartment': recipientApartment,
      'recipientPhone': recipientPhone,
      'courierName': courierName,
      'trackingNumber': trackingNumber,
      'senderName': senderName,
      'senderAddress': senderAddress,
      'packageType': packageType,
      'numberOfItems': numberOfItems,
      'status': status,
      'receivedDate': receivedDate.toIso8601String(),
      'collectedDate': collectedDate?.toIso8601String(),
      'collectedBy': collectedBy,
      'receivedBy': receivedBy,
      'location': location,
      'imageUrl': imageUrl,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

