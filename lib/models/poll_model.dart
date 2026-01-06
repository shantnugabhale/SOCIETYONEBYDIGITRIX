class PollModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final List<PollOption> options;
  final List<String> voters; // User IDs who voted
  final Map<String, String> votes; // userId -> optionId
  final bool isAnonymous;
  final bool allowMultipleChoice;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PollModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.options,
    this.voters = const [],
    this.votes = const {},
    this.isAnonymous = false,
    this.allowMultipleChoice = false,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalVotes => voters.length;
  
  Map<String, int> get voteCounts {
    final counts = <String, int>{};
    for (final option in options) {
      counts[option.id] = 0;
    }
    for (final vote in votes.values) {
      counts[vote] = (counts[vote] ?? 0) + 1;
    }
    return counts;
  }

  factory PollModel.fromMap(Map<String, dynamic> map) {
    return PollModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => PollOption.fromMap(e as Map<String, dynamic>))
              .toList() ?? [],
      voters: List<String>.from(map['voters'] ?? []),
      votes: Map<String, String>.from(map['votes'] ?? {}),
      isAnonymous: map['isAnonymous'] ?? false,
      allowMultipleChoice: map['allowMultipleChoice'] ?? false,
      isActive: map['isActive'] ?? true,
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'options': options.map((e) => e.toMap()).toList(),
      'voters': voters,
      'votes': votes,
      'isAnonymous': isAnonymous,
      'allowMultipleChoice': allowMultipleChoice,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PollOption {
  final String id;
  final String text;
  final int? voteCount;

  PollOption({
    required this.id,
    required this.text,
    this.voteCount,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      voteCount: map['voteCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      if (voteCount != null) 'voteCount': voteCount,
    };
  }
}

