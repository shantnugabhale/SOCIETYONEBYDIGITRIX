class DocumentModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'property', 'tenancy', 'legal', 'financial', 'committee', 'other'
  final String fileUrl;
  final String fileType; // 'pdf', 'image', 'word', 'excel', 'other'
  final int fileSize; // in bytes
  final String uploadedBy;
  final String uploadedByName;
  final String accessLevel; // 'public', 'members_only', 'committee_only', 'private'
  final List<String> sharedWith; // User IDs who have access
  final String? folderId; // For organizing documents
  final List<String> tags;
  final int downloadCount;
  final DateTime? expiryDate;
  final bool requiresAcknowledgment;
  final List<String> acknowledgedBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedByName,
    this.accessLevel = 'members_only',
    this.sharedWith = const [],
    this.folderId,
    this.tags = const [],
    this.downloadCount = 0,
    this.expiryDate,
    this.requiresAcknowledgment = false,
    this.acknowledgedBy = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      accessLevel: map['accessLevel'] ?? 'members_only',
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      folderId: map['folderId'],
      tags: List<String>.from(map['tags'] ?? []),
      downloadCount: map['downloadCount'] ?? 0,
      expiryDate: map['expiryDate'] != null 
          ? DateTime.parse(map['expiryDate']) 
          : null,
      requiresAcknowledgment: map['requiresAcknowledgment'] ?? false,
      acknowledgedBy: List<String>.from(map['acknowledgedBy'] ?? []),
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
      'category': category,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'accessLevel': accessLevel,
      'sharedWith': sharedWith,
      'folderId': folderId,
      'tags': tags,
      'downloadCount': downloadCount,
      'expiryDate': expiryDate?.toIso8601String(),
      'requiresAcknowledgment': requiresAcknowledgment,
      'acknowledgedBy': acknowledgedBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class DocumentFolderModel {
  final String id;
  final String name;
  final String? description;
  final String? parentFolderId;
  final String createdBy;
  final int documentCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentFolderModel({
    required this.id,
    required this.name,
    this.description,
    this.parentFolderId,
    required this.createdBy,
    this.documentCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentFolderModel.fromMap(Map<String, dynamic> map) {
    return DocumentFolderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      parentFolderId: map['parentFolderId'],
      createdBy: map['createdBy'] ?? '',
      documentCount: map['documentCount'] ?? 0,
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
      'parentFolderId': parentFolderId,
      'createdBy': createdBy,
      'documentCount': documentCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

