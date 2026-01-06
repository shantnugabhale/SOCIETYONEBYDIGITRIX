import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/document_model.dart';
import '../../utils/format_utils.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<DocumentModel>>(
        stream: FirestoreService().getDocumentsStream(),
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

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.description_rounded,
              title: 'No Documents Available',
              subtitle: 'There are no documents available at the moment.\nContact admin for more information',
              iconColor: AppColors.info,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return _buildDocumentCard(documents[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      onTap: () {
        // Open document
      },
      isClickable: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacing12),
            decoration: BoxDecoration(
              color: _getFileTypeColor(document.fileType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppStyles.radius12),
            ),
            child: Icon(
              _getFileTypeIcon(document.fileType),
              color: _getFileTypeColor(document.fileType),
              size: 32,
            ),
          ),
          const SizedBox(width: AppStyles.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: AppStyles.heading6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppStyles.spacing4),
                Text(
                  document.description.isNotEmpty
                      ? document.description
                      : 'No description',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppStyles.spacing4),
                Row(
                  children: [
                    Text(
                      _formatFileSize(document.fileSize),
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing8),
                    Text(
                      '•',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing8),
                    Text(
                      FormatUtils.formatDate(document.createdAt),
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Download or view document
            },
            icon: const Icon(Icons.download_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'word':
        return Icons.description;
      case 'excel':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return AppColors.error;
      case 'image':
        return AppColors.success;
      case 'word':
        return AppColors.info;
      case 'excel':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
