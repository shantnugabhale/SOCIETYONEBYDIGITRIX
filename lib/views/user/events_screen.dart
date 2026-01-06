import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import '../../utils/format_utils.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Events & Calendar'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().getEventsStream(),
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

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.event_rounded,
              title: 'No Events Scheduled',
              subtitle: 'There are no upcoming events at the moment.\nCheck back later for new events',
              iconColor: AppColors.warning,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(events[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isUpcoming = event.isUpcoming;
    final isOngoing = event.isOngoing;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      event.organizerName,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing8,
                  vertical: AppStyles.spacing4,
                ),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? AppColors.success.withValues(alpha: 0.1)
                      : isUpcoming
                          ? AppColors.info.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Text(
                  isOngoing
                      ? 'ONGOING'
                      : isUpcoming
                          ? 'UPCOMING'
                          : 'PAST',
                  style: AppStyles.caption.copyWith(
                    color: isOngoing
                        ? AppColors.success
                        : isUpcoming
                            ? AppColors.info
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          Text(
            event.description,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppStyles.spacing12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppStyles.spacing8),
              Text(
                '${FormatUtils.formatDate(event.startDate)} - ${FormatUtils.formatDate(event.endDate)}',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (event.venue != null) ...[
            const SizedBox(height: AppStyles.spacing8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppStyles.spacing8),
                Expanded(
                  child: Text(
                    event.venue!,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (event.maxAttendees != null) ...[
            const SizedBox(height: AppStyles.spacing8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppStyles.spacing8),
                Text(
                  '${event.attendees.length}/${event.maxAttendees} attendees',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
