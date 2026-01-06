class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String category; // 'general', 'maintenance', 'payment', 'meeting', 'emergency', 'other'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'draft', 'published', 'expired', 'archived'
  final String targetAudience; // 'all', 'owners', 'tenants', 'specific'
  final List<String> targetApartments; // Specific apartment numbers
  final String authorId;
  final String authorName;
  final DateTime publishDate;
  final DateTime? expiryDate;
  final DateTime? readByDate;
  final List<String> attachments; // URLs of attached files
  final List<String> readBy; // User IDs who have read the notice
  final List<String> acknowledgedBy; // User IDs who have acknowledged the notice
  final bool requiresAcknowledgment;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'general',
    this.priority = 'medium',
    this.status = 'draft',
    this.targetAudience = 'all',
    this.targetApartments = const [],
    required this.authorId,
    required this.authorName,
    required this.publishDate,
    this.expiryDate,
    this.readByDate,
    this.attachments = const [],
    this.readBy = const [],
    this.acknowledgedBy = const [],
    this.requiresAcknowledgment = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    return NoticeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'general',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'draft',
      targetAudience: map['targetAudience'] ?? 'all',
      targetApartments: List<String>.from(map['targetApartments'] ?? []),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      publishDate: DateTime.parse(map['publishDate'] ?? DateTime.now().toIso8601String()),
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      readByDate: map['readByDate'] != null ? DateTime.parse(map['readByDate']) : null,
      attachments: List<String>.from(map['attachments'] ?? []),
      readBy: List<String>.from(map['readBy'] ?? []),
      acknowledgedBy: List<String>.from(map['acknowledgedBy'] ?? []),
      requiresAcknowledgment: map['requiresAcknowledgment'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'status': status,
      'targetAudience': targetAudience,
      'targetApartments': targetApartments,
      'authorId': authorId,
      'authorName': authorName,
      'publishDate': publishDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'readByDate': readByDate?.toIso8601String(),
      'attachments': attachments,
      'readBy': readBy,
      'acknowledgedBy': acknowledgedBy,
      'requiresAcknowledgment': requiresAcknowledgment,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NoticeModel copyWithId(String id) {
    return NoticeModel(
      id: id,
      title: title,
      content: content,
      category: category,
      priority: priority,
      status: status,
      targetAudience: targetAudience,
      targetApartments: targetApartments,
      authorId: authorId,
      authorName: authorName,
      publishDate: publishDate,
      expiryDate: expiryDate,
      readByDate: readByDate,
      attachments: attachments,
      readBy: readBy,
      acknowledgedBy: acknowledgedBy,
      requiresAcknowledgment: requiresAcknowledgment,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  NoticeModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? priority,
    String? status,
    String? targetAudience,
    List<String>? targetApartments,
    String? authorId,
    String? authorName,
    DateTime? publishDate,
    DateTime? expiryDate,
    DateTime? readByDate,
    List<String>? attachments,
    List<String>? readBy,
    List<String>? acknowledgedBy,
    bool? requiresAcknowledgment,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoticeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      targetAudience: targetAudience ?? this.targetAudience,
      targetApartments: targetApartments ?? this.targetApartments,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      publishDate: publishDate ?? this.publishDate,
      expiryDate: expiryDate ?? this.expiryDate,
      readByDate: readByDate ?? this.readByDate,
      attachments: attachments ?? this.attachments,
      readBy: readBy ?? this.readBy,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      requiresAcknowledgment: requiresAcknowledgment ?? this.requiresAcknowledgment,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isExpiredStatus => status == 'expired';
  bool get isArchived => status == 'archived';
  bool get isActiveNotice => isActive && isPublished;
  bool get isExpiredDate => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high';
  bool get isMediumPriority => priority == 'medium';
  bool get isLowPriority => priority == 'low';
  bool get hasAttachments => attachments.isNotEmpty;
  bool get requiresAck => requiresAcknowledgment;
  int get readCount => readBy.length;
  int get acknowledgedCount => acknowledgedBy.length;
  bool get isReadByUser => readBy.isNotEmpty;
  bool get isAcknowledgedByUser => acknowledgedBy.isNotEmpty;

  @override
  String toString() {
    return 'NoticeModel(id: $id, title: $title, content: $content, category: $category, priority: $priority, status: $status, targetAudience: $targetAudience, targetApartments: $targetApartments, authorId: $authorId, authorName: $authorName, publishDate: $publishDate, expiryDate: $expiryDate, readByDate: $readByDate, attachments: $attachments, readBy: $readBy, acknowledgedBy: $acknowledgedBy, requiresAcknowledgment: $requiresAcknowledgment, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoticeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
