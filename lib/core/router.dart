
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import '../features/learnings/learnings_page.dart';
import '../features/guruji_connect/guruji_connect_page.dart';
import '../features/events/events_page.dart';
import '../features/notifications/notifications_page.dart';
import 'widgets/main_scaffold.dart';
import 'widgets/permission_screen.dart';
import 'utils/permission_checker.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/permissions',
  routes: [
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionChecker(),
    ),
    GoRoute(
      path: '/permission-screen',
      builder: (context, state) => const PermissionScreen(),
    ),
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
    ),
  ],
);
