class EventModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'festival', 'meeting', 'sports', 'cultural', 'community', 'other'
  final String organizerId;
  final String organizerName;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String? venue;
  final int? maxAttendees;
  final List<String> attendees; // User IDs
  final List<String> images;
  final double? registrationFee;
  final bool requiresRegistration;
  final bool isPublic;
  final String status; // 'draft', 'published', 'cancelled', 'completed'
  final List<String> tags;
  final DateTime? registrationDeadline;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizerId,
    required this.organizerName,
    required this.startDate,
    required this.endDate,
    this.location,
    this.venue,
    this.maxAttendees,
    this.attendees = const [],
    this.images = const [],
    this.registrationFee,
    this.requiresRegistration = false,
    this.isPublic = true,
    this.status = 'published',
    this.tags = const [],
    this.registrationDeadline,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  bool get isPast => endDate.isBefore(DateTime.now());
  bool get isFull => maxAttendees != null && attendees.length >= maxAttendees!;

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      location: map['location'],
      venue: map['venue'],
      maxAttendees: map['maxAttendees'],
      attendees: List<String>.from(map['attendees'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      registrationFee: map['registrationFee'] != null 
          ? (map['registrationFee'] as num).toDouble() 
          : null,
      requiresRegistration: map['requiresRegistration'] ?? false,
      isPublic: map['isPublic'] ?? true,
      status: map['status'] ?? 'published',
      tags: List<String>.from(map['tags'] ?? []),
      registrationDeadline: map['registrationDeadline'] != null 
          ? DateTime.parse(map['registrationDeadline']) 
          : null,
      contactPerson: map['contactPerson'],
      contactPhone: map['contactPhone'],
      contactEmail: map['contactEmail'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'venue': venue,
      'maxAttendees': maxAttendees,
      'attendees': attendees,
      'images': images,
      'registrationFee': registrationFee,
      'requiresRegistration': requiresRegistration,
      'isPublic': isPublic,
      'status': status,
      'tags': tags,
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

