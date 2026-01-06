import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/forum_model.dart';
import '../../models/user_model.dart';
import '../../utils/format_utils.dart';

class ForumPostDetailScreen extends StatefulWidget {
  final ForumPostModel post;

  const ForumPostDetailScreen({super.key, required this.post});

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _commentController = TextEditingController();
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
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<ForumPostModel?>(
        stream: Stream.value(widget.post),
        builder: (context, postSnapshot) {
          final post = postSnapshot.data ?? widget.post;
          final isLiked = _currentUser != null && post.likedBy.contains(_currentUser!.id);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Content
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                                    style: AppStyles.bodyLarge.copyWith(
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
                                        style: AppStyles.bodyLarge.copyWith(
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
                              ],
                            ),
                            const SizedBox(height: AppStyles.spacing16),
                            Text(
                              post.title,
                              style: AppStyles.heading5.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppStyles.spacing12),
                            Text(
                              post.content,
                              style: AppStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppStyles.spacing16),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _toggleLike(post),
                                  borderRadius: BorderRadius.circular(AppStyles.radius8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppStyles.spacing8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? AppColors.error : AppColors.textSecondary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post.likesCount}',
                                          style: AppStyles.bodySmall.copyWith(
                                            color: isLiked ? AppColors.error : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppStyles.spacing24),
                      
                      // Comments Section
                      Text(
                        'Comments (${post.commentsCount})',
                        style: AppStyles.heading6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      
                      StreamBuilder<List<ForumCommentModel>>(
                        stream: _firestoreService.getForumCommentsStream(post.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final comments = snapshot.data ?? [];

                          if (comments.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppStyles.spacing32),
                                child: Text(
                                  'No comments yet. Be the first to comment!',
                                  style: AppStyles.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentCard(comments[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Comment Input
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radius12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spacing16,
                            vertical: AppStyles.spacing12,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing12),
                    IconButton(
                      onPressed: _currentUser != null ? _addComment : null,
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentCard(ForumCommentModel comment) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'U',
                  style: AppStyles.bodySmall.copyWith(
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
                      comment.authorName,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${comment.authorApartment} • ${FormatUtils.formatDate(comment.createdAt)}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacing12),
          Text(
            comment.content,
            style: AppStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(ForumPostModel post) async {
    if (_currentUser == null) return;
    try {
      await _firestoreService.toggleForumPostLike(post.id, _currentUser!.id);
    } catch (e) {
      Get.snackbar('Error', 'Failed to like post: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;

    try {
      final comment = ForumCommentModel(
        id: '',
        postId: widget.post.id,
        authorId: _currentUser!.id,
        authorName: _currentUser!.name,
        authorApartment: '${_currentUser!.buildingName} - ${_currentUser!.apartmentNumber}',
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.addForumComment(comment);
      _commentController.clear();
      Get.snackbar('Success', 'Comment added!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment: $e');
    }
  }
}

