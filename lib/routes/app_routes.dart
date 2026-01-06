import 'package:get/get.dart';
import '../views/splash/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/auth/mobile_otp_verification.dart';
import '../views/user/dashboard_screen.dart';
import '../views/user/payment_screen.dart';
import '../views/user/payment_history_screen.dart';
import '../views/user/profile_screen.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/admin/member_management_screen.dart';
import '../views/admin/payment_management_screen.dart';
import '../views/admin/maintenance_requests_screen.dart';
import '../views/admin/notices_management_screen.dart';
import '../views/admin/utility_bills_management_screen.dart';
import '../views/admin/reports_screen.dart';
import '../views/admin/activities_screen.dart';
import '../views/user/bills_screen.dart';
import '../views/user/maintenance_screen.dart';
import '../views/user/create_maintenance_request_screen.dart';
import '../views/user/notices_screen.dart';
import '../views/auth/setup_profile_screen.dart';
import '../views/user/member_payment_details_screen.dart';
import '../views/user/balance_sheet_view_screen.dart';
import '../views/user/notifications_inbox_screen.dart';
import '../views/admin/balance_sheet_entry_screen.dart';
import '../views/admin/balance_sheet_display_screen.dart';
import '../models/balance_sheet_model.dart';
// New Feature Screens
import '../views/user/forum_screen.dart';
import '../views/user/forum_post_detail_screen.dart';
import '../models/forum_model.dart';
import '../views/user/facilities_screen.dart';
import '../views/user/visitors_screen.dart';
import '../views/user/chat_screen.dart';
import '../views/user/events_screen.dart';
import '../views/user/documents_screen.dart';
import '../views/user/polls_screen.dart';
import '../views/user/packages_screen.dart';
import '../views/user/emergency_screen.dart';
import '../views/user/main_navigation_screen.dart';
import '../views/user/resident_dashboard_screen.dart';
import '../views/user/committee_dashboard_screen.dart';
import '../views/user/security_dashboard_screen.dart';
import '../views/user/activity_screen.dart';
import '../views/user/community_screen.dart';

class AppRoutes {
  static final routes = [
    // Splash
    GetPage(
      name: '/',
      page: () => const SplashScreen(),
    ),
    
    // Authentication
    GetPage(
      name: '/login',
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: '/signup',
      page: () => const SignupScreen(),
    ),
    GetPage(
      name: '/mobile-otp-verification',
      page: () => const MobileOtpVerificationScreen(),
    ),
    GetPage(
      name: '/setup-profile',
      page: () {
        final phoneNumber = Get.arguments as String? ?? '+91 98765 43210';
        return SetupProfileScreen(phoneNumber: phoneNumber);
      },
    ),
    GetPage(
      name: '/forgot-password',
      page: () => const LoginScreen(),
    ),
    
    // User Routes
    GetPage(
      name: '/dashboard',
      page: () => const MainNavigationScreen(),
    ),
    GetPage(
      name: '/resident-dashboard',
      page: () => const ResidentDashboardScreen(),
    ),
    GetPage(
      name: '/committee-dashboard',
      page: () => const CommitteeDashboardScreen(),
    ),
    GetPage(
      name: '/security-dashboard',
      page: () => const SecurityDashboardScreen(),
    ),
    GetPage(
      name: '/profile',
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: '/payments',
      page: () => const PaymentScreen(),
    ),
    GetPage(
      name: '/payment-history',
      page: () => const PaymentHistoryScreen(),
    ),
    GetPage(
      name: '/utility-bills',
      page: () => const BillsScreen(),
    ),
    GetPage(
      name: '/maintenance-status',
      page: () => const MaintenanceScreen(),
    ),
    GetPage(
      name: '/maintenance',
      page: () => const MaintenanceScreen(),
    ),
    GetPage(
      name: '/complaints',
      page: () => const CreateMaintenanceRequestScreen(),
    ),
    GetPage(
      name: '/create-maintenance-request',
      page: () => const CreateMaintenanceRequestScreen(),
    ),
    
    // --- Updated this route ---
    GetPage(
      name: '/notices',
      page: () => const NoticesScreen(), // Was DashboardScreen
    ),
    GetPage(
      name: '/member-payment-details',
      page: () => const MemberPaymentDetailsScreen(),
    ),
    GetPage(
      name: '/balance-sheet-view',
      page: () {
        final args = Get.arguments;
        return BalanceSheetViewScreen(
          year: args is int ? args : null,
        );
      },
    ),
    GetPage(
      name: '/notifications-inbox',
      page: () => const NotificationsInboxScreen(),
    ),
    
    // New Feature Routes
    GetPage(
      name: '/forum',
      page: () => const ForumScreen(),
    ),
    GetPage(
      name: '/forum-post-detail',
      page: () {
        final post = Get.arguments as ForumPostModel;
        return ForumPostDetailScreen(post: post);
      },
    ),
    GetPage(
      name: '/facilities',
      page: () => const FacilitiesScreen(),
    ),
    GetPage(
      name: '/visitors',
      page: () => const VisitorsScreen(),
    ),
    GetPage(
      name: '/chat',
      page: () => const ChatScreen(),
    ),
    GetPage(
      name: '/events',
      page: () => const EventsScreen(),
    ),
    GetPage(
      name: '/documents',
      page: () => const DocumentsScreen(),
    ),
    GetPage(
      name: '/polls',
      page: () => const PollsScreen(),
    ),
    GetPage(
      name: '/packages',
      page: () => const PackagesScreen(),
    ),
    GetPage(
      name: '/emergency',
      page: () => const EmergencyScreen(),
    ),
    // --- End of update ---
    
    GetPage(
      name: '/revenue',
      page: () => const DashboardScreen(),
    ),
    
    // Admin Routes
    GetPage(
      name: '/admin-dashboard',
      page: () => const AdminDashboardScreen(),
    ),
    GetPage(
      name: '/member-management',
      page: () => const MemberManagementScreen(),
    ),
    GetPage(
      name: '/payment-management',
      page: () => const PaymentManagementScreen(),
    ),
    GetPage(
      name: '/utility-bills-management',
      page: () => const UtilityBillsManagementScreen(),
    ),
    GetPage(
      name: '/maintenance-requests',
      page: () => const MaintenanceRequestsScreen(),
    ),
    GetPage(
      name: '/notices-management',
      page: () => const NoticesManagementScreen(),
    ),
    GetPage(
      name: '/reports',
      page: () => const ReportsScreen(),
    ),
    GetPage(
      name: '/activities',
      page: () => const ActivitiesScreen(),
    ),
    GetPage(
      name: '/balance-sheet-entry',
      page: () {
        final args = Get.arguments;
        if (args != null && args is Map<String, dynamic>) {
          BalanceSheetModel? balanceSheet;
          final balanceSheetData = args['balanceSheet'];
          if (balanceSheetData != null) {
            if (balanceSheetData is BalanceSheetModel) {
              balanceSheet = balanceSheetData;
            } else if (balanceSheetData is Map<String, dynamic>) {
              balanceSheet = BalanceSheetModel.fromMap(balanceSheetData);
            }
          }
          return BalanceSheetEntryScreen(
            year: args['year'] as int?,
            existingBalanceSheet: balanceSheet,
          );
        }
        return const BalanceSheetEntryScreen();
      },
    ),
    GetPage(
      name: '/balance-sheet',
      page: () {
        final args = Get.arguments;
        return BalanceSheetDisplayScreen(
          year: args is int ? args : null,
        );
      },
    ),
  ];
}