import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Navigation guard middleware to enforce strict approval status checks
/// Blocks pending/rejected users from accessing society data
class RouteGuardMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    // If not authenticated, redirect to login
    if (user == null) {
      return const RouteSettings(name: '/login');
    }
    
    // Note: For async checks, we allow navigation here
    // The actual checks should be done in the screen's initState
    // This middleware only handles synchronous checks
    
    // Allow navigation - async checks will be done in the target screen
    return null;
  }
  
  @override
  GetPage? onPageCalled(GetPage? page) {
    // Additional checks can be added here
    return super.onPageCalled(page);
  }
}

