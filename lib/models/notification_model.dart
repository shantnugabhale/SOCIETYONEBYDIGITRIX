class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'notice', 'maintenance', 'payment', 'balance_sheet', 'general'
  final String? category; // For notices: 'general', 'maintenance', 'payment', etc.
  final String? priority; // 'urgent', 'high', 'medium', 'low'
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // ID of related item (noticeId, requestId, etc.)
  final Map<String, dynamic>? data; // Additional data
  final String? imageUrl;
  final List<String>? attachments;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.category,
    this.priority,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
    this.data,
    this.imageUrl,
    this.attachments,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      category: map['category'],
      priority: map['priority'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      relatedId: map['relatedId'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      imageUrl: map['imageUrl'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'relatedId': relatedId,
      'data': data,
      'imageUrl': imageUrl,
      'attachments': attachments,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? category,
    String? priority,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
    Map<String, dynamic>? data,
    String? imageUrl,
    List<String>? attachments,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      attachments: attachments ?? this.attachments,
    );
  }
}

