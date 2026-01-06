import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../utils/format_utils.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
        title: const Text('Chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () {
              Get.snackbar('Info', 'Create group chat feature coming soon!');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _firestoreService.getChatRoomsStream(),
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

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No Chats Yet',
              subtitle: 'Start a conversation with your neighbors!\nTap the + button to create a new chat',
              iconColor: AppColors.primary,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                return _buildChatRoomCard(rooms[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.snackbar('Info', 'New chat feature coming soon!');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomCard(ChatRoomModel room) {
    final lastMessage = room.lastMessage;
    final unreadCount = room.unreadCounts[_currentUser?.id ?? ''] ?? 0;
    final isGroup = room.type == 'group';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      onTap: () {
        Get.snackbar('Info', 'Chat detail screen coming soon!');
      },
      isClickable: true,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: isGroup
                    ? const Icon(Icons.group_rounded, color: AppColors.primary, size: 28)
                    : Text(
                        room.name.isNotEmpty ? room.name[0].toUpperCase() : 'U',
                        style: AppStyles.heading6.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppStyles.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: AppStyles.heading6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lastMessage != null)
                      Text(
                        FormatUtils.formatTime(lastMessage.sentAt),
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing4),
                if (lastMessage != null)
                  Text(
                    lastMessage.messageType == 'text'
                        ? lastMessage.message
                        : lastMessage.messageType == 'image'
                            ? '📷 Image'
                            : lastMessage.messageType == 'file'
                                ? '📎 File'
                                : 'Message',
                    style: AppStyles.bodySmall.copyWith(
                      color: unreadCount > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'No messages yet',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
