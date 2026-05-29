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

    // Notification Storage
    try {
      await NotificationStorageService().initialize();
      developer.log('✅ Notification Storage initialized');
    } catch (e) {
      developer.log('❌ Notification Storage init failed: $e');
    }

    // Localization
    try {
      await LocalizationService().initialize();
      developer.log('✅ Localization initialized');
    } catch (e) {
      developer.log('❌ Localization init failed: $e');
    }

    // AuthState
    try {
      await AuthState().initialize();
      developer.log('✅ AuthState initialized');
    } catch (e) {
      developer.log('❌ AuthState init failed: $e');
    }

    // ConnectivityService
    try {
      await ConnectivityService().initialize();
      developer.log('✅ ConnectivityService initialized');
    } catch (e) {
      developer.log('❌ ConnectivityService init failed: $e');
    }

    // AudioService
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

        // Step 4: Check if permission was already granted
        // requestPermission(false) = silent check, no OS dialog shown on startup.
        // We only want to link the user if they already granted permission previously.
        final permissionGranted = await OneSignal.Notifications.requestPermission(false);
        developer.log('🔔 Notification permission on startup: $permissionGranted');

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
      key: ValueKey(_localizationService.currentLocale.languageCode),
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
