import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'firestore_service.dart';
import 'auth_service.dart';
import '../models/notification_model.dart';

// Background message handler (called when notification arrives while app is closed)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background Notification Received: ${message.messageId}');
  await NotificationService.handleBackgroundNotification(message);
}

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 1. Initial Setup Function
  Future<void> initialize() async {
    try {
    // Permission Request (required for iOS and Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
        // Continue anyway - topic subscription can work without permission
    }

    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Subscribe to all_users topic (all residents) - Not supported on web
      if (!kIsWeb) {
        try {
          await _firebaseMessaging.subscribeToTopic("all_users");
          debugPrint('Subscribed to topic: all_users');
        } catch (e) {
          debugPrint('Error subscribing to topic: $e');
        }
      } else {
        debugPrint('Topic subscription not supported on web platform');
      }

      // Subscribe admins/maintenance staff to maintenance_admins topic - Not supported on web
      if (!kIsWeb) {
        try {
          final authService = AuthService();
          final currentUser = authService.currentUser;
          if (currentUser != null) {
            final phoneNumber = currentUser.phoneNumber ?? '';
            if (phoneNumber.isNotEmpty) {
              final firestoreService = FirestoreService();
              final isAdmin = await firestoreService.isAdmin(phoneNumber);
              if (isAdmin) {
                await _firebaseMessaging.subscribeToTopic("maintenance_admins");
                debugPrint('Subscribed to topic: maintenance_admins');
              }
            }
          }
        } catch (e) {
          debugPrint('Error subscribing to maintenance_admins topic: $e');
        }
      }

    // Local Notification setup for Foreground Notifications
    await _setupLocalNotifications();

    // Setup listeners for Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Notification: ${message.notification?.title}');
      _showForegroundNotification(message);
      _saveNotification(message); // Save notification to Firestore
    });
    
    // Handle notification click when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification Clicked!');
      _handleNotificationNavigation(message);
    });

    // Handle notification click when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });
    } catch (e) {
      debugPrint('Error in NotificationService.initialize(): $e');
      // Don't rethrow - allow app to continue even if notifications fail
    }
  }

  // 2. Get FCM Token (this token should be saved in member's profile)
  Future<String?> getFCMToken() async {
    try {
      // On web, FCM token requires service worker to be registered
      if (kIsWeb) {
        try {
          // Request permission first on web
          await _firebaseMessaging.requestPermission();
        } catch (e) {
          debugPrint('Error requesting permission on web: $e');
        }
      }
      
      String? token = await _firebaseMessaging.getToken(
        vapidKey: kIsWeb ? 'BGM5lnN101uTrUcOOAja1TPn4_VnnsqaecC4SN-JfkRi-8hCxdE2UmlPPcqyKRMDIH5_nejMsBNCzfuLb3nJ8sw' : null,
      );
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      // On web, service worker errors are expected if not properly configured
      if (kIsWeb) {
        debugPrint('Note: FCM on web requires firebase-messaging-sw.js service worker');
      }
      return null;
    }
  }

  // 3. Local Notification Setup (for Android)
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // App Icon

    // iOS Settings (Optional, if implementing iOS)
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // Create notification channels for better organization
    await _createNotificationChannels();
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Important notices and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);
  }


  // 4. Show Notification (this function is used when app is running)
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      final notificationType = message.data['type'] ?? 'notice';
      
      // Handle maintenance notifications differently
      if (notificationType == 'maintenance') {
        await _showMaintenanceNotification(message, notification);
        return;
      }

      // Get attachment info from data
      String? imageUrl;
      bool hasPdf = false;
      int attachmentCount = 0;
      
      if (message.data.containsKey('imageUrl') && message.data['imageUrl']?.isNotEmpty == true) {
        imageUrl = message.data['imageUrl'];
      } else if (android?.imageUrl != null) {
        imageUrl = android!.imageUrl;
      }
      
      if (message.data.containsKey('hasAttachments') && message.data['hasAttachments'] == 'true') {
        attachmentCount = int.tryParse(message.data['attachmentCount'] ?? '0') ?? 0;
        final pdfCount = int.tryParse(message.data['pdfCount'] ?? '0') ?? 0;
        hasPdf = pdfCount > 0;
      }

      // Build professional notification with proper structure
      AndroidNotificationDetails androidDetails;
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Download image for big picture notification with timeout
          final response = await http.get(Uri.parse(imageUrl))
              .timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final imageBytes = response.bodyBytes;
            final bigPicture = ByteArrayAndroidBitmap(imageBytes);
            
            // Professional rich notification with image
            androidDetails = AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Important notices and updates from society management',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              styleInformation: BigPictureStyleInformation(
                bigPicture,
                largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                contentTitle: notification.title ?? 'New Notice Published',
                summaryText: _buildSummaryText(notification.body, hasPdf, attachmentCount),
                htmlFormatContentTitle: true,
                htmlFormatSummaryText: true,
              ),
              enableVibration: true,
              playSound: true,
              showWhen: true,
              when: DateTime.now().millisecondsSinceEpoch,
              category: AndroidNotificationCategory.message,
              visibility: NotificationVisibility.public,
            );
          } else {
            androidDetails = _buildStandardNotification(notification, hasPdf, attachmentCount);
          }
        } catch (e) {
          debugPrint('Error downloading notification image: $e');
          androidDetails = _buildStandardNotification(notification, hasPdf, attachmentCount);
        }
      } else if (hasPdf) {
        // PDF notification with custom style
        androidDetails = _buildPdfNotification(notification, attachmentCount);
      } else {
        // Standard notification
        androidDetails = _buildStandardNotification(notification, hasPdf, attachmentCount);
      }

      // Build payload for navigation
      String payload = '';
      if (message.data.containsKey('noticeId')) {
        payload = 'notice:${message.data['noticeId']}';
      } else if (message.data.containsKey('requestId')) {
        payload = 'maintenance:${message.data['requestId']}';
      }

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'New Notice',
        _buildNotificationBody(notification.body, hasPdf, attachmentCount),
        NotificationDetails(
          android: androidDetails,
        ),
        payload: payload,
      );
    }
  }

  // Show maintenance notification with priority information
  Future<void> _showMaintenanceNotification(RemoteMessage message, RemoteNotification notification) async {
    final priority = message.data['priority'] ?? 'medium';
    final requestId = message.data['requestId'] ?? '';
    
    // Determine priority-based importance and color
    Importance importance;
    Priority priorityLevel;
    String priorityLabel = '';
    String priorityEmoji = '';
    
    if (priority.toLowerCase() == 'high') {
      importance = Importance.max;
      priorityLevel = Priority.max;
      priorityLabel = 'High Priority';
      priorityEmoji = '🔴';
    } else if (priority.toLowerCase() == 'low') {
      importance = Importance.defaultImportance;
      priorityLevel = Priority.defaultPriority;
      priorityLabel = 'Low Priority';
      priorityEmoji = '🟢';
    } else {
      importance = Importance.high;
      priorityLevel = Priority.high;
      priorityLabel = 'Normal Priority';
      priorityEmoji = '🟡';
    }

    // Build notification title with priority (if not already included)
    String notificationTitle = notification.title ?? 'Maintenance Update';
    if (!notificationTitle.contains(priorityEmoji) && !notificationTitle.contains(priorityLabel)) {
      notificationTitle = '$priorityEmoji $notificationTitle';
    }

    // Build notification body with priority info prominently displayed
    String notificationBody = notification.body ?? '';
    
    // Always show priority at the beginning of the body for clarity
    String priorityInfo = '$priorityEmoji Priority: $priorityLabel';
    
    // If body doesn't already contain priority info, prepend it
    if (!notificationBody.contains('Priority') && !notificationBody.contains('priority')) {
      notificationBody = '$priorityInfo\n\n$notificationBody';
    } else {
      // If priority is already in body, ensure it's at the top
      notificationBody = notificationBody.replaceAll(RegExp(r'[🔴🟡🟢]\s*[Pp]riority[:\s]*[Ll]ow|[Nn]ormal|[Hh]igh', caseSensitive: false), '');
      notificationBody = '$priorityInfo\n\n$notificationBody';
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Maintenance Notifications',
      channelDescription: 'Maintenance request updates and notifications',
      importance: importance,
      priority: priorityLevel,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableVibration: true,
      playSound: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        notificationBody,
        contentTitle: notificationTitle,
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
        summaryText: '$priorityLabel • Tap to view details',
      ),
    );

    // Build payload for navigation
    String payload = '';
    if (requestId.isNotEmpty) {
      payload = 'maintenance:$requestId';
    }

    await _localNotifications.show(
      notification.hashCode,
      notificationTitle,
      notificationBody,
      NotificationDetails(
        android: androidDetails,
      ),
      payload: payload,
    );
  }

  // Build summary text for notifications (without attachment text)
  String _buildSummaryText(String? body, bool hasPdf, int attachmentCount) {
    return body ?? '';
  }

  // Build notification body text (without attachment text)
  String _buildNotificationBody(String? body, bool hasPdf, int attachmentCount) {
    return body ?? '';
  }

  // Build standard notification
  AndroidNotificationDetails _buildStandardNotification(
    RemoteNotification notification,
    bool hasPdf,
    int attachmentCount,
  ) {
    return AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important notices and updates from society management',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableVibration: true,
      playSound: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: hasPdf && attachmentCount > 0
          ? BigTextStyleInformation(
              _buildNotificationBody(notification.body, hasPdf, attachmentCount),
              contentTitle: notification.title ?? 'New Notice Published',
              htmlFormatContentTitle: true,
              htmlFormatBigText: true,
            )
          : null,
    );
  }

  // Build PDF-specific notification
  AndroidNotificationDetails _buildPdfNotification(
    RemoteNotification notification,
    int attachmentCount,
  ) {
    return AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important notices and updates from society management',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableVibration: true,
      playSound: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        _buildNotificationBody(notification.body, true, attachmentCount),
        contentTitle: notification.title ?? 'New Notice',
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
        summaryText: 'Tap to view details',
      ),
    );
  }

  // 5. Handle notification navigation
  void _handleNotificationNavigation(RemoteMessage message) {
    try {
      if (message.data.containsKey('type')) {
        final type = message.data['type'];
        
        if (type == 'notice') {
          final noticeId = message.data['noticeId'];
          if (noticeId != null && noticeId.isNotEmpty) {
            // Navigate to notices screen
            debugPrint('Navigate to notice: $noticeId');
            Get.toNamed('/notices');
          }
        } else if (type == 'maintenance') {
          final requestId = message.data['requestId'];
          if (requestId != null && requestId.isNotEmpty) {
            // Navigate to maintenance screen
            debugPrint('Navigate to maintenance request: $requestId');
            Get.toNamed('/maintenance');
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }

  // Handle notification tap from local notifications
  void _handleNotificationTap(String payload) {
    try {
      if (payload.startsWith('notice:')) {
        final noticeId = payload.replaceFirst('notice:', '');
        debugPrint('Navigate to notice from tap: $noticeId');
        // Navigate to notices screen
        Get.toNamed('/notices');
      } else if (payload.startsWith('maintenance:')) {
        final requestId = payload.replaceFirst('maintenance:', '');
        debugPrint('Navigate to maintenance from tap: $requestId');
        // Navigate to maintenance screen
        Get.toNamed('/maintenance');
      } else if (payload.startsWith('balance_sheet:')) {
        debugPrint('Navigate to balance sheet from tap');
        Get.toNamed('/balance-sheet-view');
      } else if (payload.startsWith('payment:')) {
        debugPrint('Navigate to payment from tap');
        Get.toNamed('/payments');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Save notification to Firestore for history
  Future<void> _saveNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final firestoreService = FirestoreService();
      final notificationType = message.data['type'] ?? 'general';
      final relatedId = message.data['noticeId'] ?? 
                       message.data['requestId'] ?? 
                       message.data['paymentId'] ?? 
                       null;

      // Parse attachments safely
      List<String>? attachments;
      if (message.data['attachments'] != null) {
        final attachmentsData = message.data['attachments'];
        if (attachmentsData is List) {
          attachments = List<String>.from(attachmentsData);
        } else if (attachmentsData is String) {
          attachments = attachmentsData.split(',').where((s) => s.trim().isNotEmpty).toList();
        }
      }

      final notificationModel = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        type: notificationType,
        category: message.data['category'],
        priority: message.data['priority'],
        createdAt: message.sentTime ?? DateTime.now(),
        isRead: false,
        relatedId: relatedId,
        data: message.data,
        imageUrl: message.data['imageUrl'],
        attachments: attachments,
      );

      await firestoreService.saveNotification(notificationModel);
    } catch (e) {
      debugPrint('Error saving notification: $e');
      // Don't throw - notification display should still work
    }
  }

  // Handle background notification (also save it)
  static Future<void> handleBackgroundNotification(RemoteMessage message) async {
    debugPrint('Background Notification Received: ${message.messageId}');
    // Save notification even when app is in background
    try {
      final notification = message.notification;
      if (notification == null) return;

      final firestoreService = FirestoreService();
      final notificationType = message.data['type'] ?? 'general';
      final relatedId = message.data['noticeId'] ?? 
                       message.data['requestId'] ?? 
                       message.data['paymentId'] ?? 
                       null;

      // Parse attachments safely
      List<String>? attachments;
      if (message.data['attachments'] != null) {
        final attachmentsData = message.data['attachments'];
        if (attachmentsData is List) {
          attachments = List<String>.from(attachmentsData);
        } else if (attachmentsData is String) {
          attachments = attachmentsData.split(',').where((s) => s.trim().isNotEmpty).toList();
        }
      }

      final notificationModel = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        type: notificationType,
        category: message.data['category'],
        priority: message.data['priority'],
        createdAt: message.sentTime ?? DateTime.now(),
        isRead: false,
        relatedId: relatedId,
        data: message.data,
        imageUrl: message.data['imageUrl'],
        attachments: attachments,
      );

      await firestoreService.saveNotification(notificationModel);
    } catch (e) {
      debugPrint('Error saving background notification: $e');
    }
  }
}
