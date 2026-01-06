import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/forum_model.dart';
import '../../models/user_model.dart';
import '../../utils/format_utils.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;

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
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discussion Forum'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<ForumPostModel>>(
        stream: _firestoreService.getForumPostsStream(),
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

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.forum_rounded,
              title: 'No Posts Yet',
              subtitle: 'Be the first to start a discussion!\nShare your thoughts with the community',
              buttonText: 'Create Post',
              iconColor: AppColors.primary,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Stream will automatically update
            },
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
        label: const Text(
          'New Post',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(ForumPostModel post) {
    final isLiked = _currentUser != null && post.likedBy.contains(_currentUser!.id);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      onTap: () => _navigateToPostDetail(post),
      isClickable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isPinned) ...[
            Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'PINNED',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacing8),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${post.authorApartment} • ${FormatUtils.formatDate(post.createdAt)}',
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
                  color: _getCategoryColor(post.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                ),
                child: Text(
                  post.category.toUpperCase(),
                  style: AppStyles.caption.copyWith(
                    color: _getCategoryColor(post.category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          Text(
            post.title,
            style: AppStyles.heading6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppStyles.spacing8),
          Text(
            post.content,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.attachments.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.radius12),
                color: AppColors.grey200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppStyles.radius12),
                child: Image.network(
                  post.attachments.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: AppStyles.spacing12),
          Row(
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likesCount}',
                color: isLiked ? AppColors.error : AppColors.textSecondary,
                onTap: () => _toggleLike(post),
              ),
              const SizedBox(width: AppStyles.spacing16),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: '${post.commentsCount}',
                color: AppColors.textSecondary,
                onTap: () => _navigateToPostDetail(post),
              ),
              const Spacer(),
              if (post.tags.isNotEmpty)
                Wrap(
                  spacing: AppStyles.spacing8,
                  children: post.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing8,
                        vertical: AppStyles.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radius8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing8,
          vertical: AppStyles.spacing4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return AppColors.info;
      case 'complaint':
        return AppColors.error;
      case 'suggestion':
        return AppColors.success;
      case 'event':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _toggleLike(ForumPostModel post) async {
    if (_currentUser == null) return;
    try {
      await _firestoreService.toggleForumPostLike(post.id, _currentUser!.id);
    } catch (e) {
      Get.snackbar('Error', 'Failed to like post: $e');
    }
  }

  void _navigateToPostDetail(ForumPostModel post) {
    Get.toNamed('/forum-post-detail', arguments: post);
  }

  void _showCreatePostDialog() {
    if (_isLoadingUser || _currentUser == null) {
      Get.snackbar('Error', 'Please wait while we load your profile');
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final categoryNotifier = ValueNotifier<String>('general');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius20),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create New Post',
                  style: AppStyles.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacing24),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter post title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppStyles.spacing16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Write your post...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: AppStyles.spacing16),
                ValueListenableBuilder<String>(
                  valueListenable: categoryNotifier,
                  builder: (context, selectedCategory, _) {
                    return DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                        DropdownMenuItem(value: 'suggestion', child: Text('Suggestion')),
                        DropdownMenuItem(value: 'event', child: Text('Event')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          categoryNotifier.value = value;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: AppStyles.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _createPost(
                            titleController.text,
                            contentController.text,
                            categoryNotifier.value,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: const Text('Post'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createPost(String title, String content, String category) async {
    if (title.trim().isEmpty || content.trim().isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    if (_currentUser == null) return;

    try {
      final post = ForumPostModel(
        id: '',
        title: title.trim(),
        content: content.trim(),
        authorId: _currentUser!.id,
        authorName: _currentUser!.name,
        authorApartment: '${_currentUser!.buildingName} - ${_currentUser!.apartmentNumber}',
        category: category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createForumPost(post);
      Get.back(); // Close dialog
      Get.snackbar('Success', 'Post created successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create post: $e');
    }
  }
}
