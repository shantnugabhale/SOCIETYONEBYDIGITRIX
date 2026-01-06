class MaintenanceRequestModel {
  final String id;
  final String userId; // User who requested
  final String userName; // Member name
  final String userApartment; // Building-Apartment format
  final String title;
  final String description;
  final String type; // 'plumbing', 'electrical', 'elevator', 'common_area', 'other'
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'open', 'in_progress', 'completed', 'closed'
  final String? assignedTo; // Admin/staff name assigned
  final DateTime requestedDate;
  final DateTime? completedDate;
  final String? remarks; // Admin remarks
  final bool isPublic; // true = visible to all members, false = only requester
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userApartment,
    required this.title,
    required this.description,
    required this.type,
    this.priority = 'medium',
    this.status = 'open',
    this.assignedTo,
    required this.requestedDate,
    this.completedDate,
    this.remarks,
    this.isPublic = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceRequestModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceRequestModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userApartment: map['userApartment'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'other',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'open',
      assignedTo: map['assignedTo'],
      requestedDate: DateTime.parse(map['requestedDate'] ?? DateTime.now().toIso8601String()),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      remarks: map['remarks'],
      isPublic: map['isPublic'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userApartment': userApartment,
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'requestedDate': requestedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'remarks': remarks,
      'isPublic': isPublic,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MaintenanceRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userApartment,
    String? title,
    String? description,
    String? type,
    String? priority,
    String? status,
    String? assignedTo,
    DateTime? requestedDate,
    DateTime? completedDate,
    String? remarks,
    bool? isPublic,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userApartment: userApartment ?? this.userApartment,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      requestedDate: requestedDate ?? this.requestedDate,
      completedDate: completedDate ?? this.completedDate,
      remarks: remarks ?? this.remarks,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isClosed => status == 'closed';
  bool get isActiveRequest => isActive && (isOpen || isInProgress);

  @override
  String toString() {
    return 'MaintenanceRequestModel(id: $id, userId: $userId, userName: $userName, title: $title, type: $type, priority: $priority, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenanceRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

