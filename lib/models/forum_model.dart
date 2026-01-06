class ForumPostModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String authorApartment;
  final String? authorImageUrl;
  final String category; // 'general', 'maintenance', 'complaint', 'suggestion', 'event', 'other'
  final List<String> tags;
  final List<String> attachments; // Image/document URLs
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy; // User IDs
  final List<String> bookmarkedBy; // User IDs
  final bool isPinned;
  final bool isLocked;
  final String status; // 'active', 'archived', 'deleted'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  ForumPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorApartment,
    this.authorImageUrl,
    this.category = 'general',
    this.tags = const [],
    this.attachments = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.bookmarkedBy = const [],
    this.isPinned = false,
    this.isLocked = false,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  factory ForumPostModel.fromMap(Map<String, dynamic> map) {
    return ForumPostModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorApartment: map['authorApartment'] ?? '',
      authorImageUrl: map['authorImageUrl'],
      category: map['category'] ?? 'general',
      tags: List<String>.from(map['tags'] ?? []),
      attachments: List<String>.from(map['attachments'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      bookmarkedBy: List<String>.from(map['bookmarkedBy'] ?? []),
      isPinned: map['isPinned'] ?? false,
      isLocked: map['isLocked'] ?? false,
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      lastActivityAt: map['lastActivityAt'] != null 
          ? DateTime.parse(map['lastActivityAt']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorApartment': authorApartment,
      'authorImageUrl': authorImageUrl,
      'category': category,
      'tags': tags,
      'attachments': attachments,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'bookmarkedBy': bookmarkedBy,
      'isPinned': isPinned,
      'isLocked': isLocked,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
    };
  }
}

class ForumCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorApartment;
  final String? authorImageUrl;
  final String content;
  final String? parentCommentId; // For nested comments/replies
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final bool isDeleted;

  ForumCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorApartment,
    this.authorImageUrl,
    required this.content,
    this.parentCommentId,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory ForumCommentModel.fromMap(Map<String, dynamic> map) {
    return ForumCommentModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorApartment: map['authorApartment'] ?? '',
      authorImageUrl: map['authorImageUrl'],
      content: map['content'] ?? '',
      parentCommentId: map['parentCommentId'],
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorApartment': authorApartment,
      'authorImageUrl': authorImageUrl,
      'content': content,
      'parentCommentId': parentCommentId,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
    };
  }
}

