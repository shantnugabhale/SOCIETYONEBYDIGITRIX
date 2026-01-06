class MeetingModel {
  final String id;
  final String title;
  final String agenda;
  final String? description;
  final String organizerId;
  final String organizerName;
  final DateTime scheduledDate;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? meetingLink; // For online meetings
  final String meetingType; // 'physical', 'online', 'hybrid'
  final List<String> attendees; // User IDs
  final List<String> requiredAttendees; // User IDs (mandatory)
  final List<String> optionalAttendees; // User IDs
  final Map<String, String> attendanceStatus; // userId -> 'accepted', 'declined', 'tentative', 'pending'
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled', 'postponed'
  final List<String> agendaItems;
  final String? minutes; // Meeting minutes/notes
  final String? minutesUrl; // URL to minutes document
  final List<String> attachments;
  final List<String> actionItems; // Follow-up items
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingModel({
    required this.id,
    required this.title,
    required this.agenda,
    this.description,
    required this.organizerId,
    required this.organizerName,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.meetingLink,
    this.meetingType = 'physical',
    this.attendees = const [],
    this.requiredAttendees = const [],
    this.optionalAttendees = const [],
    this.attendanceStatus = const {},
    this.status = 'scheduled',
    this.agendaItems = const [],
    this.minutes,
    this.minutesUrl,
    this.attachments = const [],
    this.actionItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  Duration get duration => endTime.difference(startTime);

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      agenda: map['agenda'] ?? '',
      description: map['description'],
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      scheduledDate: DateTime.parse(map['scheduledDate'] ?? DateTime.now().toIso8601String()),
      startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(map['endTime'] ?? DateTime.now().toIso8601String()),
      location: map['location'] ?? '',
      meetingLink: map['meetingLink'],
      meetingType: map['meetingType'] ?? 'physical',
      attendees: List<String>.from(map['attendees'] ?? []),
      requiredAttendees: List<String>.from(map['requiredAttendees'] ?? []),
      optionalAttendees: List<String>.from(map['optionalAttendees'] ?? []),
      attendanceStatus: Map<String, String>.from(map['attendanceStatus'] ?? {}),
      status: map['status'] ?? 'scheduled',
      agendaItems: List<String>.from(map['agendaItems'] ?? []),
      minutes: map['minutes'],
      minutesUrl: map['minutesUrl'],
      attachments: List<String>.from(map['attachments'] ?? []),
      actionItems: List<String>.from(map['actionItems'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'agenda': agenda,
      'description': description,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'meetingLink': meetingLink,
      'meetingType': meetingType,
      'attendees': attendees,
      'requiredAttendees': requiredAttendees,
      'optionalAttendees': optionalAttendees,
      'attendanceStatus': attendanceStatus,
      'status': status,
      'agendaItems': agendaItems,
      'minutes': minutes,
      'minutesUrl': minutesUrl,
      'attachments': attachments,
      'actionItems': actionItems,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

