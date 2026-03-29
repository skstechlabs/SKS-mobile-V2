import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/auth/permission_screen.dart';
import '../features/auth/all_permissions_screen.dart';
import '../features/home/home_page.dart';
import '../features/learnings/learnings_page.dart';
import '../features/guruji_connect/guruji_connect_page.dart';
import '../features/events/events_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/notifications/notification_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/reminders/reminder_form_screen.dart';
import '../features/meditation/meditation_timer_page.dart';
import '../features/meditation/meditation_history_page.dart';
import 'widgets/main_scaffold.dart';
import 'theme/app_theme.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  // Error handling for navigation issues
  errorBuilder: (context, state) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.saffron,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'Page Not Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The page you are looking for does not exist',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/notification-permission',
      builder: (context, state) => const AllPermissionsScreen(),
    ),
    // GoRoute(
    //   path: '/permissions',
    //   builder: (context, state) => const PermissionChecker(),
    // ),
    // GoRoute(
    //   path: '/permission-screen',
    //   builder: (context, state) => const PermissionScreen(),
    // ),
    ShellRoute(
      builder: (context, state, child) {
        int currentIndex = 0;
        switch (state.matchedLocation) {
          case '/':
            currentIndex = 0;
            break;
          case '/learnings':
            currentIndex = 1;
            break;
          case '/guruji-connect':
            currentIndex = 2;
            break;
          case '/events':
            currentIndex = 3;
            break;
        }
        return MainScaffold(
          currentIndex: currentIndex,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/learnings',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const LearningsPage(),
          ),
        ),
        GoRoute(
          path: '/guruji-connect',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const GurujiConnectPage(),
          ),
        ),
        GoRoute(
          path: '/events',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const EventsPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
      routes: [
        GoRoute(
          path: ':notificationId',
          builder: (context, state) {
            final notificationId = state.pathParameters['notificationId']!;
            return NotificationDetailScreen(notificationId: notificationId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const RemindersScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const ReminderFormScreen(),
        ),
        GoRoute(
          path: 'edit/:reminderId',
          builder: (context, state) {
            final reminderId = int.parse(state.pathParameters['reminderId']!);
            return ReminderFormScreen(reminderId: reminderId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/meditation',
      redirect: (context, state) => '/meditation/timer',
      routes: [
        GoRoute(
          path: 'timer',
          builder: (context, state) => const MeditationTimerPage(),
        ),
        GoRoute(
          path: 'history',
          builder: (context, state) => const MeditationHistoryPage(),
        ),
      ],
    ),
  ],
);
