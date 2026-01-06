import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/poll_model.dart';
import '../../models/user_model.dart';
import '../../utils/format_utils.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Polls & Surveys'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PollModel>>(
        stream: _firestoreService.getPollsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final polls = snapshot.data ?? [];

          if (polls.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.poll_rounded,
              title: 'No Polls Available',
              subtitle: 'There are no active polls at the moment.\nCheck back later for new surveys',
              iconColor: AppColors.warning,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: polls.length,
              itemBuilder: (context, index) {
                return _buildPollCard(polls[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPollCard(PollModel poll) {
    final hasVoted = _currentUser != null && poll.voters.contains(_currentUser!.id);
    final voteCounts = poll.voteCounts;
    final totalVotes = poll.totalVotes;
    final isExpired = poll.endDate.isBefore(DateTime.now());

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.title,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      poll.description,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacing8,
                    vertical: AppStyles.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                  ),
                  child: Text(
                    'ENDED',
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing16),
          ...poll.options.map((option) {
            final votes = voteCounts[option.id] ?? 0;
            final percentage = totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
            final isSelected = hasVoted && poll.votes[_currentUser?.id] == option.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppStyles.radius8),
                                color: AppColors.grey200,
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spacing12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option.text,
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.textOnPrimary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      hasVoted ? '${percentage.toStringAsFixed(0)}%' : '',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: isSelected
                                            ? AppColors.textOnPrimary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!hasVoted && !isExpired) ...[
                        const SizedBox(width: AppStyles.spacing8),
                        IconButton(
                          onPressed: () => _voteOnPoll(poll, option.id),
                          icon: const Icon(Icons.check_circle_outline),
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppStyles.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Votes: $totalVotes',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Ends: ${FormatUtils.formatDate(poll.endDate)}',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _voteOnPoll(PollModel poll, String optionId) async {
    if (_currentUser == null) {
      Get.snackbar('Error', 'Please login to vote');
      return;
    }

    try {
      await _firestoreService.voteOnPoll(poll.id, _currentUser!.id, optionId);
      Get.snackbar('Success', 'Your vote has been recorded!');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
