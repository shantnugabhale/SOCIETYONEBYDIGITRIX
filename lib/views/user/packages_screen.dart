import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/package_model.dart';
import '../../utils/format_utils.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Packages'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PackageModel>>(
        stream: FirestoreService().getUserPackagesStream(),
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

          final packages = snapshot.data ?? [];

          if (packages.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'No Packages',
              subtitle: 'You don\'t have any packages at the moment.\nPackages will appear here when received',
              iconColor: AppColors.accent,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                return _buildPackageCard(packages[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.courierName,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (package.trackingNumber != null)
                      Text(
                        'Tracking: ${package.trackingNumber}',
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
                  color: _getStatusColor(package.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Text(
                  package.status.toUpperCase(),
                  style: AppStyles.caption.copyWith(
                    color: _getStatusColor(package.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          if (package.senderName != null)
            _buildInfoRow(Icons.person, 'From', package.senderName!),
          _buildInfoRow(
            Icons.calendar_today,
            'Received',
            FormatUtils.formatDate(package.receivedDate),
          ),
          if (package.location != null)
            _buildInfoRow(Icons.location_on, 'Location', package.location!),
          if (package.remarks != null && package.remarks!.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing8),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing12),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(AppStyles.radius8),
              ),
              child: Text(
                package.remarks!,
                style: AppStyles.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacing8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppStyles.spacing8),
          Text(
            '$label: ',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return AppColors.info;
      case 'collected':
        return AppColors.success;
      case 'returned':
        return AppColors.warning;
      case 'lost':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
