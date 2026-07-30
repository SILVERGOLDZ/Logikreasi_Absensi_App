import 'package:absensi_app/screens/admin/register_user_screen.dart';
import 'package:absensi_app/screens/change_password_screen.dart';
import 'package:absensi_app/screens/home_screen.dart';
import 'package:absensi_app/screens/mail_screen.dart';
import 'package:absensi_app/screens/settings/downloaded_attachment_screen.dart';

import '../models/leave_model.dart';
import '../screens/admin/create_announcement_screen.dart';
import '../screens/admin/holiday_management_screen.dart';
import '../screens/admin/leave_approval_screen.dart';
import '../screens/announcement/detail_announcement_screen.dart';
import '../screens/announcement/list_announcement_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/leave/leave_detail_screen.dart';
import '../screens/leave/leave_form_screen.dart';
import '../screens/leave/leave_screen.dart';
import '../screens/login_register/login_screen.dart';
import '../screens/login_register/register_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/test_screen.dart';
import '../services/auth/auth_service.dart';
import '../widgets/bottom_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String login = '/login';
  static const String registerUser = '/register-user';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String calendar = '/calendar';
  static const String mail = '/mail';
  static const String profile = '/profile';

  static const String test = '/test';
  static const String announcement = '/announcement';
  static const String createAnnouncement = '/admin/announcement/create';
  static const String adminHoliday = '/admin/holiday';

  static const String leave = '/leave';
  static const String leaveCreate = '/leave/create';
  static const String leaveApproval = '/leave/approval';
  static const String leaveDetail = '/leave/detail';
  static const String downloaded = '/settings/downloaded';

  static const String changePassword = '/settings/change-password';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthService authService) {
  // final GlobalKey<NavigatorState> rootNavigatorKey =
  // GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    redirect: (context, state) async {

      final isLoggedIn = authService.isAuthenticated;
      final location = state.matchedLocation;

      final publicRoutes = [AppRoutes.login];

      if (isLoggedIn && publicRoutes.contains(location)) {
        return AppRoutes.attendance;
      }

      if (!isLoggedIn && !publicRoutes.contains(location)) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerUser,
        name: 'register-user',
        builder: (context, state) => const RegisterUserScreen(),
      ),
      GoRoute(
        path: AppRoutes.test,
        name: 'test',
        builder: (context, state) => const TestScreen(),
      ),

      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) => const ListPengumumanScreen(),
      ),
      GoRoute(
        path: '/announcement/:id',
        builder: (context, state) => DetailPengumumanScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.createAnnouncement,
        builder: (context, state) => const CreatePengumumanScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHoliday,
        name: 'admin-holiday',
        builder: (context, state) => const HolidayManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.leave,
        name: 'leave',
        builder: (context, state) => const LeaveScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaveCreate,
        name: 'leave-create',
        builder: (context, state) => const LeaveFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaveApproval,
        name: 'leave-approval',
        builder: (context, state) => const LeaveApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaveDetail,
        name: 'leave-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return LeaveDetailScreen(
            leave: extra['leave'] as LeaveModel,
            canApprove: extra['canApprove'] as bool? ?? false,
            onApprove: extra['onApprove'] as Future<bool> Function(String?)?,
            onReject: extra['onReject'] as Future<bool> Function(String?)?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.downloaded,
        name: 'downloaded',
        builder: (context, state) => const DownloadedAttachmentsScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.attendance,
                name: 'attendance',
                builder: (context, state) => const AttendanceScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mail,
                name: 'mail',
                builder: (context, state) => const MailScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Path: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.attendance),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}