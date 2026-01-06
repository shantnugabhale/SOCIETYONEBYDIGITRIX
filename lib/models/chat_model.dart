class ChatMessageModel {
  final String id;
  final String chatId; // Group chat ID or direct chat ID
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String message;
  final String messageType; // 'text', 'image', 'file', 'location', 'voice'
  final List<String> attachments; // URLs for images/files
  final String? replyToMessageId; // For reply to message
  final List<String> readBy; // User IDs who read the message
  final DateTime sentAt;
  final DateTime? editedAt;
  final bool isEdited;
  final bool isDeleted;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.message,
    this.messageType = 'text',
    this.attachments = const [],
    this.replyToMessageId,
    this.readBy = const [],
    required this.sentAt,
    this.editedAt,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImageUrl: map['senderImageUrl'],
      message: map['message'] ?? '',
      messageType: map['messageType'] ?? 'text',
      attachments: List<String>.from(map['attachments'] ?? []),
      replyToMessageId: map['replyToMessageId'],
      readBy: List<String>.from(map['readBy'] ?? []),
      sentAt: DateTime.parse(map['sentAt'] ?? DateTime.now().toIso8601String()),
      editedAt: map['editedAt'] != null 
          ? DateTime.parse(map['editedAt']) 
          : null,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'message': message,
      'messageType': messageType,
      'attachments': attachments,
      'replyToMessageId': replyToMessageId,
      'readBy': readBy,
      'sentAt': sentAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
    };
  }
}

class ChatRoomModel {
  final String id;
  final String name;
  final String type; // 'direct', 'group', 'broadcast'
  final String? description;
  final String? imageUrl;
  final List<String> members; // User IDs
  final List<String> admins; // Admin user IDs (for groups)
  final String? createdBy;
  final DateTime lastMessageAt;
  final ChatMessageModel? lastMessage;
  final Map<String, int> unreadCounts; // userId -> unread count
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoomModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.imageUrl,
    required this.members,
    this.admins = const [],
    this.createdBy,
    required this.lastMessageAt,
    this.lastMessage,
    this.unreadCounts = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'direct',
      description: map['description'],
      imageUrl: map['imageUrl'],
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      createdBy: map['createdBy'],
      lastMessageAt: DateTime.parse(map['lastMessageAt'] ?? DateTime.now().toIso8601String()),
      lastMessage: map['lastMessage'] != null
          ? ChatMessageModel.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'members': members,
      'admins': admins,
      'createdBy': createdBy,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastMessage': lastMessage?.toMap(),
      'unreadCounts': unreadCounts,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

