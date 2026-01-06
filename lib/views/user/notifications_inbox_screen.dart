import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedType; // null means "All"
  String? _selectedFilter; // 'all', 'unread', 'read'

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'notice':
        return Icons.notifications;
      case 'maintenance':
        return Icons.build;
      case 'payment':
        return Icons.payment;
      case 'balance_sheet':
        return Icons.account_balance_wallet;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'notice':
        return AppColors.primary;
      case 'maintenance':
        return AppColors.info;
      case 'payment':
        return AppColors.success;
      case 'balance_sheet':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'notice':
        return 'Notice';
      case 'maintenance':
        return 'Maintenance';
      case 'payment':
        return 'Payment';
      case 'balance_sheet':
        return 'Balance Sheet';
      default:
        return 'General';
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _firestoreService.markNotificationAsRead(notification.id);
      Get.snackbar(
        'Success',
        'Notification marked as read',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark as read: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _firestoreService.markAllNotificationsAsRead();
      Get.snackbar(
        'Success',
        'All notifications marked as read',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark all as read: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _firestoreService.deleteNotification(notification.id);
      Get.snackbar(
        'Success',
        'Notification deleted',
        backgroundColor: AppColors.success,
        colorText: AppColors.textOnPrimary,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Navigate based on type
    switch (notification.type) {
      case 'notice':
        Get.toNamed('/notices');
        break;
      case 'maintenance':
        Get.toNamed('/maintenance');
        break;
      case 'payment':
        Get.toNamed('/payments');
        break;
      case 'balance_sheet':
        Get.toNamed('/balance-sheet-view');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _firestoreService.getUserNotificationsStream(),
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
                  const SizedBox(height: AppStyles.spacing16),
                  Text(
                    'Error loading notifications',
                    style: AppStyles.bodyLarge.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            );
          }

          final allNotifications = snapshot.data ?? [];
          
          // Apply filters
          var filteredNotifications = allNotifications;
          
          if (_selectedType != null) {
            filteredNotifications = filteredNotifications
                .where((n) => n.type == _selectedType)
                .toList();
          }
          
          if (_selectedFilter == 'unread') {
            filteredNotifications = filteredNotifications
                .where((n) => !n.isRead)
                .toList();
          } else if (_selectedFilter == 'read') {
            filteredNotifications = filteredNotifications
                .where((n) => n.isRead)
                .toList();
          }

          if (filteredNotifications.isEmpty) {
            return Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacing12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', _selectedType == null, () {
                                setState(() => _selectedType = null);
                              }),
                              const SizedBox(width: AppStyles.spacing8),
                              _buildFilterChip('Notices', _selectedType == 'notice', () {
                                setState(() => _selectedType = 'notice');
                              }),
                              const SizedBox(width: AppStyles.spacing8),
                              _buildFilterChip('Maintenance', _selectedType == 'maintenance', () {
                                setState(() => _selectedType = 'maintenance');
                              }),
                              const SizedBox(width: AppStyles.spacing8),
                              _buildFilterChip('Payment', _selectedType == 'payment', () {
                                setState(() => _selectedType = 'payment');
                              }),
                              const SizedBox(width: AppStyles.spacing8),
                              _buildFilterChip('Balance Sheet', _selectedType == 'balance_sheet', () {
                                setState(() => _selectedType = 'balance_sheet');
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppStyles.spacing16),
                        Text(
                          'No notifications found',
                          style: AppStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              // Filter chips
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing12),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', _selectedType == null, () {
                              setState(() => _selectedType = null);
                            }),
                            const SizedBox(width: AppStyles.spacing8),
                            _buildFilterChip('Notices', _selectedType == 'notice', () {
                              setState(() => _selectedType = 'notice');
                            }),
                            const SizedBox(width: AppStyles.spacing8),
                            _buildFilterChip('Maintenance', _selectedType == 'maintenance', () {
                              setState(() => _selectedType = 'maintenance');
                            }),
                            const SizedBox(width: AppStyles.spacing8),
                            _buildFilterChip('Payment', _selectedType == 'payment', () {
                              setState(() => _selectedType = 'payment');
                            }),
                            const SizedBox(width: AppStyles.spacing8),
                            _buildFilterChip('Balance Sheet', _selectedType == 'balance_sheet', () {
                              setState(() => _selectedType = 'balance_sheet');
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Read/Unread filter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacing12,
                  vertical: AppStyles.spacing8,
                ),
                child: Row(
                  children: [
                    _buildStatusChip('All', _selectedFilter == null, () {
                      setState(() => _selectedFilter = null);
                    }),
                    const SizedBox(width: AppStyles.spacing8),
                    _buildStatusChip('Unread', _selectedFilter == 'unread', () {
                      setState(() => _selectedFilter = 'unread');
                    }),
                    const SizedBox(width: AppStyles.spacing8),
                    _buildStatusChip('Read', _selectedFilter == 'read', () {
                      setState(() => _selectedFilter = 'read');
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Notifications list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.spacing12),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final iconColor = _getNotificationColor(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppStyles.spacing16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppStyles.radius12),
        ),
        child: const Icon(Icons.delete, color: AppColors.textOnPrimary),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
        padding: const EdgeInsets.all(AppStyles.spacing12),
        isClickable: true,
        onTap: () => _handleNotificationTap(notification),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppStyles.radius8),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacing12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacing4),
                  Text(
                    notification.body,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacing8,
                          vertical: AppStyles.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radius4),
                        ),
                        child: Text(
                          _getNotificationTypeLabel(notification.type),
                          style: AppStyles.caption.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'mark_read' && !notification.isRead) {
                  _markAsRead(notification);
                } else if (value == 'delete') {
                  _deleteNotification(notification);
                }
              },
              itemBuilder: (context) => [
                if (!notification.isRead)
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.done, size: 20),
                        SizedBox(width: 8),
                        Text('Mark as read'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

