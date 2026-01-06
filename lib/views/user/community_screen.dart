import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';

/// Community Screen - Access to community features
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Features',
              style: AppStyles.heading5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildFeatureCard(
              title: 'Forum',
              subtitle: 'Discuss with neighbors',
              icon: Icons.forum_rounded,
              color: AppColors.primary,
              onTap: () => Get.toNamed('/forum'),
            ),
            
            _buildFeatureCard(
              title: 'Events',
              subtitle: 'Upcoming society events',
              icon: Icons.event_rounded,
              color: AppColors.success,
              onTap: () => Get.toNamed('/events'),
            ),
            
            _buildFeatureCard(
              title: 'Polls',
              subtitle: 'Vote on important matters',
              icon: Icons.poll_rounded,
              color: AppColors.info,
              onTap: () => Get.toNamed('/polls'),
            ),
            
            _buildFeatureCard(
              title: 'Facilities',
              subtitle: 'Book community facilities',
              icon: Icons.sports_tennis_rounded,
              color: AppColors.warning,
              onTap: () => Get.toNamed('/facilities'),
            ),
            
            _buildFeatureCard(
              title: 'Chat',
              subtitle: 'Quick chat with members',
              icon: Icons.chat_bubble_rounded,
              color: AppColors.secondary,
              onTap: () => Get.toNamed('/chat'),
            ),
            
            _buildFeatureCard(
              title: 'Documents',
              subtitle: 'Shared documents and files',
              icon: Icons.folder_rounded,
              color: AppColors.accent,
              onTap: () => Get.toNamed('/documents'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: onTap,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: AppStyles.heading6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

