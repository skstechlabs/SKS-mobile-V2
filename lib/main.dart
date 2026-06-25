import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:developer' as developer;
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'core/services/audio_handler.dart';
import 'core/services/api_service.dart';
import 'core/services/onesignal_service.dart';
import 'core/services/notification_storage_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/enhanced_audio_player_service.dart';
import 'core/services/version_migration_service.dart';
import 'core/providers/audio_provider.dart';
import 'core/constants/app_env.dart';
import 'core/utils/environment_checker.dart';
import 'features/auth/auth_state.dart';
import 'core/services/connectivity_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    developer.log('========================================');
    developer.log('🔍 CHECKING ENVIRONMENT CONFIGURATION');
    developer.log('========================================');
    EnvironmentChecker.checkEnvironment();

    if (!EnvironmentChecker.isConfigured()) {
      developer.log('⚠️⚠️⚠️ WARNING: Environment not configured! ⚠️⚠️⚠️');
    }

    // ── Version Migration: Run FIRST to handle app upgrades ──
    // This clears stale caches that may cause issues after APK updates
    try {
      await VersionMigrationService.instance.initialize();
      developer.log('✅ Version migration check complete');
    } catch (e) {
      developer.log('⚠️ Version migration check failed: $e');
      // Continue anyway - app should still work
    }

    // Firebase - CRITICAL: Must succeed or app cannot function
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      developer.log('✅ Firebase initialized successfully');
    } catch (e) {
      developer.log('❌ CRITICAL: Firebase initialization failed: $e');
      developer.log('Stack trace: ${StackTrace.current}');
      // Rethrow to prevent app from continuing without Firebase
      rethrow;
    }

    // API Service
    try {
      ApiService().initialize();
      developer.log('✅ API Service initialized');
    } catch (e) {
      developer.log('❌ API Service init failed: $e');
    }

    // Run non-critical services in parallel to speed up startup
    await Future.wait([
      // Notification Storage
      NotificationStorageService().initialize().then((_) {
        developer.log('✅ Notification Storage initialized');
      }).catchError((e) {
        developer.log('❌ Notification Storage init failed: $e');
      }),

      // Localization — must complete before UI, keep sequential below
      Future.value(),

      // ConnectivityService
      ConnectivityService().initialize().then((_) {
        developer.log('✅ ConnectivityService initialized');
      }).catchError((e) {
        developer.log('❌ ConnectivityService init failed: $e');
      }),
    ]);

    // Localization — must be ready before runApp
    try {
      await LocalizationService().initialize();
      developer.log('✅ Localization initialized');
    } catch (e) {
      developer.log('❌ Localization init failed: $e');
    }

    // AuthState — must be ready before runApp (used by splash logic)
    try {
      await AuthState().initialize();
      developer.log('✅ AuthState initialized');
    } catch (e) {
      developer.log('❌ AuthState init failed: $e');
    }

    // AudioService — needed for playback background service
    try {
      await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.spiritual.app.channel.audio',
          androidNotificationChannelName: 'SKS Audio',
          androidNotificationChannelDescription: 'SKS Audio Playback',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
        ),
      );
      developer.log('✅ AudioService initialized');
    } catch (e) {
      developer.log('❌ AudioService init failed: $e');
    }

    // Enhanced Audio Player Service
    try {
      await EnhancedAudioPlayerService().initialize();
      developer.log('✅ Enhanced Audio Player initialized');
    } catch (e) {
      developer.log('❌ Enhanced Audio Player init failed: $e');
    }

    // AudioProvider — defer API network call to AFTER runApp so it
    // does NOT block the first frame from rendering.
    // It will initialize lazily when the audio page is first opened.

    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log('Flutter Error: ${details.exception}',
          name: 'FlutterError', error: details.exception, stackTrace: details.stack);
    };

    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    } catch (e) {
      developer.log('❌ SystemChrome UI style failed: $e');
    }

    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      developer.log('❌ SystemChrome orientations failed: $e');
    }

    developer.log('🚀 Starting app...');

    // ── OneSignal: correct initialization order ────────────────────────────────
    // Order per docs: initialize → requestPermission → login(uid)
    // requestPermission MUST come before login so the FCM token is registered first.
    if (!kIsWeb) {
      try {
        // Step 1: verbose logging
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

        // Step 2: initialize with App ID (before runApp)
        OneSignal.initialize(AppEnv.oneSignalAppId);
        developer.log('✅ OneSignal.initialize() called');

        // Step 3: register event handlers immediately after initialize
        final oneSignalService = OneSignalService();
        oneSignalService.setupNotificationHandlers();
        oneSignalService.markInitialized();

        // Step 4: Check if permission was already granted (WITHOUT prompting)
        // Do NOT call requestPermission() here - we want to ask only on the permissions screen
        // or when user clicks the bell icon
        final permissionGranted = OneSignal.Notifications.permission;
        developer.log('🔔 Notification permission on startup (no prompt): $permissionGranted');

        // Step 5: if user is already logged in AND permission granted, link them immediately
        final authState = AuthState();
        if (authState.user != null && permissionGranted) {
          OneSignal.login(authState.user!.uid);
          OneSignal.User.pushSubscription.optIn();
          developer.log('✅ OneSignal.login(${authState.user!.uid}) called on startup');
        } else if (authState.user != null && !permissionGranted) {
          developer.log('⚠️ User logged in but no notification permission - will register after permission granted');
        }

        // Step 6: set navigation callback (router available after runApp)
        oneSignalService.onNavigateToNotification = (notificationId) {
          appRouter.push('/notifications/$notificationId');
        };

        developer.log('✅ OneSignal setup complete');
      } catch (e) {
        developer.log('❌ OneSignal setup failed: $e');
      }
    }

    // ── Start the app ──────────────────────────────────────────────────────────
    runApp(const SpiritualApp());

    // ── Post-runApp deferred work — does NOT block first frame ────────────────
    Future.microtask(() async {
      // AudioProvider — deferred network call (was blocking startup before)
      try {
        await AudioProvider().initialize();
        developer.log('✅ AudioProvider initialized (deferred)');
      } catch (e) {
        developer.log('❌ AudioProvider init failed (deferred): $e');
      }
    });

    // ── Post-runApp: re-link logged-in user if permission was already granted ──
    if (!kIsWeb) {
      Future.microtask(() async {
        try {
          final authState = AuthState();
          // permission is a synchronous bool getter — no await needed
          final hasPermission = OneSignal.Notifications.permission;
          if (authState.user != null && hasPermission) {
            OneSignal.login(authState.user!.uid);
            OneSignal.User.pushSubscription.optIn();
            developer.log('✅ OneSignal post-runApp re-link: ${authState.user!.uid}');
          }
        } catch (e) {
          developer.log('❌ OneSignal post-runApp link failed: $e');
        }
      });
    }
  } catch (e, stackTrace) {
    developer.log('❌ CRITICAL: App initialization failed: $e');
    developer.log('Stack trace: $stackTrace');
    runApp(const SpiritualApp());
  }
}

class SpiritualApp extends StatefulWidget {
  const SpiritualApp({super.key});

  @override
  State<SpiritualApp> createState() => _SpiritualAppState();
}

class _SpiritualAppState extends State<SpiritualApp> {
  final LocalizationService _localizationService = LocalizationService();

  @override
  void initState() {
    super.initState();
    _localizationService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localizationService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SKS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _localizationService.currentLocale,
      supportedLocales: LocalizationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Removed ValueKey — it forced full widget tree disposal on language change,
      // wiping all page state. The setState() in _onLocaleChanged is sufficient
      // to propagate the new locale to all context.tr() calls.
      routerConfig: appRouter,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      builder: (context, child) {
        if (kDebugMode) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            developer.log('Widget Error: ${details.exception}');
            return Material(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.saffron, size: 60),
                        const SizedBox(height: 20),
                        const Text('Something went wrong',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),
                        const Text('Please restart the app',
                            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        const SizedBox(height: 10),
                        Text('${details.exception}',
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            );
          };
        }
        if (child == null) return Container(color: Colors.white);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.3,
                ),
          ),
          child: child,
        );
      },
    );
  }
}
