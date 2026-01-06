class VotingModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final List<VotingOption> options;
  final List<String> eligibleVoters; // User IDs who can vote
  final Map<String, String> votes; // userId -> optionId
  final bool isAnonymous;
  final String status; // 'draft', 'active', 'completed', 'cancelled'
  final DateTime startDate;
  final DateTime endDate;
  final int minimumVotesRequired; // Quorum
  final bool requiresMajority; // True = need >50%, False = most votes wins
  final String? result;
  final DateTime createdAt;
  final DateTime updatedAt;

  VotingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.options,
    this.eligibleVoters = const [],
    this.votes = const {},
    this.isAnonymous = false,
    this.status = 'draft',
    required this.startDate,
    required this.endDate,
    this.minimumVotesRequired = 1,
    this.requiresMajority = true,
    this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalVotes => votes.length;
  bool get hasReachedQuorum => totalVotes >= minimumVotesRequired;
  bool get isActive => status == 'active' && DateTime.now().isBefore(endDate);

  factory VotingModel.fromMap(Map<String, dynamic> map) {
    return VotingModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => VotingOption.fromMap(e as Map<String, dynamic>))
              .toList() ?? [],
      eligibleVoters: List<String>.from(map['eligibleVoters'] ?? []),
      votes: Map<String, String>.from(map['votes'] ?? {}),
      isAnonymous: map['isAnonymous'] ?? false,
      status: map['status'] ?? 'draft',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      minimumVotesRequired: map['minimumVotesRequired'] ?? 1,
      requiresMajority: map['requiresMajority'] ?? true,
      result: map['result'],
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
      'eligibleVoters': eligibleVoters,
      'votes': votes,
      'isAnonymous': isAnonymous,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'minimumVotesRequired': minimumVotesRequired,
      'requiresMajority': requiresMajority,
      'result': result,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class VotingOption {
  final String id;
  final String text;
  final int voteCount;

  VotingOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
  });

  factory VotingOption.fromMap(Map<String, dynamic> map) {
    return VotingOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      voteCount: map['voteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
    };
  }
}

