import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/language/language_selection_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/enhanced_profile_setup_screen.dart';
import '../features/auth/permission_screen.dart';
import '../features/auth/all_permissions_screen.dart';
import '../features/home/home_page.dart';
import '../features/learnings/learnings_page.dart';
import '../features/guruji_connect/guruji_connect_page.dart';
import '../features/kalpataru/kalpataru_page.dart';
import '../features/events/events_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/notifications/notification_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/profile/profiles_list_screen.dart';
import '../features/profile/profile_selection_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/reminders/reminder_form_screen.dart';
import '../features/meditation/meditation_timer_page.dart';
import '../features/meditation/meditation_history_page.dart';
import '../features/learnings/class_days_list_screen.dart';
import '../features/learnings/day_video_screen.dart';
import '../features/settings/ringtone_settings_page.dart';
import '../features/settings/wallpaper_settings_page.dart';
import '../features/audio/now_playing_screen.dart';
import '../features/songs/all_songs_page.dart';
import '../features/guru_journey/guru_journey_page.dart';
import '../features/kundalini_science/kundalini_science_page.dart';
import '../features/benefits/benefits_page.dart';
import '../features/chakras/chakra_detail_page.dart';
import '../features/chakras/chakra_landing_page.dart';
import '../features/video/youtube_player.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'widgets/main_scaffold.dart';
import 'theme/app_theme.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  // Removed refreshListenable: LocalizationService() — language changes should NOT
  // trigger a full route re-evaluation. That caused a double-rebuild on language
  // change (once from SpiritualApp.setState, once from router refresh).
  // The SpiritualApp setState is enough to propagate new locale strings.
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
      path: '/language-selection',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/profile-selection',
      builder: (context, state) => const ProfileSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const EnhancedProfileSetupScreen(),
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
          case '/kalpataru':
            currentIndex = 3; // Kalpataru tab is at index 3
            break;
          case '/events':
            currentIndex = 4; // Events tab is at index 4
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
          path: '/kalpataru',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const KalpataruPage(),
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
      path: '/onboarding',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final dest  = extra?['destination'] as String? ?? '/';
        return OnboardingScreen(destination: dest);
      },
    ),
    GoRoute(
      path: '/guruji-connect',
      builder: (context, state) => const GurujiConnectPage(),
    ),
    GoRoute(
      path: '/guru-journey',
      builder: (context, state) => const GuruJourneyPage(),
    ),
    GoRoute(
      path: '/kundalini-science',
      builder: (context, state) => const KundaliniSciencePage(),
    ),
    GoRoute(
      path: '/benefits',
      builder: (context, state) => const BenefitsPage(),
    ),
    GoRoute(
      path: '/chakras',
      builder: (context, state) => const ChakraLandingPage(),
    ),
    GoRoute(
      path: '/chakra-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialIndex = extra?['initialIndex'] as int? ?? 0;
        return ChakraDetailPage(initialIndex: initialIndex);
      },
    ),
    GoRoute(
      path: '/all-songs',
      builder: (context, state) => const AllSongsPage(),
    ),
    GoRoute(
      path: '/youtube-player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return YouTubeVideoPlayer(
          videoId: extra?['videoId'] as String? ?? '',
          title: extra?['title'] as String? ?? '',
        );
      },
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
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => const ProfileEditScreen(),
        ),
        GoRoute(
          path: 'list',
          builder: (context, state) => const ProfilesListScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EnhancedProfileSetupScreen(isEditMode: true),
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
      path: '/meditation/timer',
      builder: (context, state) => const MeditationTimerPage(),
    ),
    GoRoute(
      path: '/meditation/history',
      builder: (context, state) => const MeditationHistoryPage(),
    ),
    GoRoute(
      path: '/settings/ringtone',
      builder: (context, state) => const RingtoneSettingsPage(),
    ),
    GoRoute(
      path: '/settings/wallpaper',
      builder: (context, state) => const WallpaperSettingsPage(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageSelectionScreen(isFromSettings: true),
    ),
    GoRoute(
      path: '/now-playing',
      builder: (context, state) => const NowPlayingScreen(),
    ),
    // Classes video streaming routes
    GoRoute(
      path: '/classes/:classId/days',
      builder: (context, state) {
        final classIdStr = state.pathParameters['classId']!;
        final classId = int.tryParse(classIdStr) ?? 0;
        final extra = state.extra as Map<String, dynamic>?;
        return ClassDaysListScreen(
          classId: classId,
          classTitle: extra?['classTitle'] ?? 'Class',
          level: extra?['level'] ?? 'Level',
        );
      },
    ),
    GoRoute(
      path: '/classes/days/:dayId/video',
      builder: (context, state) {
        final dayIdStr = state.pathParameters['dayId']!;
        final dayId = int.tryParse(dayIdStr) ?? 0;
        final dayTitle = state.uri.queryParameters['title'] ?? 'Video';
        final dayNumberStr = state.uri.queryParameters['dayNumber'] ?? '1';
        final dayNumber = int.tryParse(dayNumberStr) ?? 1;
        final classIdStr = state.uri.queryParameters['classId'] ?? '1';
        final classId = int.tryParse(classIdStr) ?? 1;
        final level = state.uri.queryParameters['level'] ?? '';
        return DayVideoScreen(
          dayId: dayId,
          classId: classId,
          dayNumber: dayNumber,
          dayTitle: dayTitle,
          level: level,
        );
      },
    ),
  ],
);
