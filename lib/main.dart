import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Notification Service (non-blocking)
    NotificationService().initialize().catchError((error) {
      debugPrint('Error initializing NotificationService: $error');
    });
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }
  
  runApp(const MyApp());
}

/// Wrapper widget to use initState() for FCM token printing
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Print FCM Token using initState()
    _printFCMToken();
  }

  /// Function to get and print FCM token
  Future<void> _printFCMToken() async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getFCMToken();
      
      if (token != null) {
        debugPrint('═══════════════════════════════════════');
        debugPrint('FCM Token: $token');
        debugPrint('═══════════════════════════════════════');
      } else {
        debugPrint('FCM Token: Not available');
      }
    } catch (e) {
      debugPrint('Error getting FCM Token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}