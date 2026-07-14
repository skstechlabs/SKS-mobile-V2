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
import 'core/services/secure_storage_service.dart';
import 'core/providers/audio_provider.dart';
import 'core/constants/app_env.dart';
import 'core/utils/environment_checker.dart';
import 'features/auth/auth_state.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/image_preloader_service.dart';
import 'firebase_options.dart';

/// Safe wrapper: run [fn] and swallow any exception, logging with [label].
Future<void> _safe(String label, Future<void> Function() fn) async {
  try {
    await fn();
    developer.log('✅ $label');
  } catch (e, st) {
    developer.log('❌ $label failed: $e', stackTrace: st);
  }
}

void main() async {
  // Always first — required before any Flutter plugin call.
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('========================================');
  developer.log('🚀 APP STARTING');
  developer.log('========================================');

  try {
    await _runInitialization();
  } catch (e, st) {
    developer.log('💥 CRITICAL: initialization threw: $e', stackTrace: st);
  }

  runApp(const SpiritualApp());

  // ── Deferred: runs after the first frame is painted ─────────────────────
  Future.microtask(() async {
    await _safe('AudioProvider (deferred)', () => AudioProvider().initialize());
    // Re-link OneSignal to the authenticated user after the widget tree is up
    if (!kIsWeb) {
      await _safe('OneSignal user re-link', () async {
        final auth = AuthState();
        if (auth.user != null) {
          OneSignal.login(auth.user!.uid);
          if (OneSignal.Notifications.permission) {
            OneSignal.User.pushSubscription.optIn();
          }
        }
      });
    }
  });
}

/// All initialization steps.  Every step is wrapped in _safe() so a single
/// failure never prevents runApp() from being reached.
Future<void> _runInitialization() async {
  // ── 1. Environment check ──────────────────────────────────────────────────
  try {
    EnvironmentChecker.checkEnvironment();
    if (!EnvironmentChecker.isConfigured()) {
      developer.log('⚠️ WARNING: Environment not fully configured');
    }
  } catch (_) {}

  // ── 2. Version migration — clears stale caches before anything reads them ─
  await _safe('VersionMigration',
      () => VersionMigrationService.instance.initialize());

  // ── 3. Firebase — critical for Google auth & Crashlytics ─────────────────
  await _safe('Firebase', () async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      developer.log('✅ Firebase initialized');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate') || msg.contains('already')) {
        developer.log('✅ Firebase already initialized (warm restart)');
        return; // Not an error
      }
      rethrow; // Let _safe() catch and log it
    }
  });

  // ── 4. SecureStorage — must be ready before ApiService reads tokens ───────
  await _safe('SecureStorageService',
      () async => SecureStorageService().initialize());

  // ── 5. ApiService — needs SecureStorage for JWT token lookup ─────────────
  await _safe('ApiService', () async => ApiService().initialize());

  // ── 6. ConnectivityService — needed by ApiService for online/offline logic ─
  await _safe('ConnectivityService',
      () => ConnectivityService().initialize());

  // ── 7. Localization — must complete before runApp so tr() never returns "" ─
  await _safe('LocalizationService',
      () => LocalizationService().initialize());

  // ── 8. AuthState — must complete before splash routing decisions ──────────
  //    Reads cached user + validates JWT exists (clears stale session if not)
  await _safe('AuthState', () => AuthState().initialize());

  // ── 9. NotificationStorage — non-critical, parallel-safe ─────────────────
  await _safe('NotificationStorage',
      () => NotificationStorageService().initialize());

  // ── 10. AudioService ──────────────────────────────────────────────────────
  if (!kIsWeb) {
    await _safe('AudioService', () async {
      // video_player's processingState.idle means not yet started;
      // check via a try-init pattern rather than the deprecated .running flag
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
      } catch (e) {
        if (e.toString().contains('already')) {
          developer.log('ℹ️ AudioService already running');
        } else {
          rethrow;
        }
      }
    });

    await _safe('EnhancedAudioPlayerService',
        () => EnhancedAudioPlayerService().initialize());
  }

  // ── 11. OneSignal — push notifications (does NOT require Firebase) ─────────
  if (!kIsWeb) {
    await _safe('OneSignal', () async {
      // Only enable verbose logging in debug builds
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      } else {
        OneSignal.Debug.setLogLevel(OSLogLevel.none);
      }

      OneSignal.initialize(AppEnv.oneSignalAppId);

      // Request notification permission (non-blocking — user may deny)
      await OneSignal.Notifications.requestPermission(false);

      final svc = OneSignalService();
      svc.setupNotificationHandlers();
      svc.markInitialized();

      // Link the authenticated user so targeted pushes work
      final auth = AuthState();
      if (auth.user != null) {
        OneSignal.login(auth.user!.uid);
        if (OneSignal.Notifications.permission) {
          OneSignal.User.pushSubscription.optIn();
        }
        developer.log('🔔 OneSignal linked to user: ${auth.user!.uid}');
      } else {
        developer.log('🔔 OneSignal initialized (no user logged in yet)');
      }

      svc.onNavigateToNotification = (id) {
        appRouter.push('/notifications/$id');
      };
    });
  }

  // ── 12. System UI ─────────────────────────────────────────────────────────
  await _safe('SystemChrome', () async {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  });

  // ── 13. Flutter error handler ─────────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('Flutter Error: ${details.exception}',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack);
  };

  // ── 14. Image preloader — fire-and-forget, never blocks startup ───────────
  _safe('ImagePreloader', () => ImagePreloaderService().preloadToDisk());

  developer.log('✅ All initialization complete — launching app');
}

// ── App Widget ────────────────────────────────────────────────────────────────

class SpiritualApp extends StatefulWidget {
  const SpiritualApp({super.key});

  @override
  State<SpiritualApp> createState() => _SpiritualAppState();
}

class _SpiritualAppState extends State<SpiritualApp> {
  final LocalizationService _locSvc = LocalizationService();

  @override
  void initState() {
    super.initState();
    _locSvc.addListener(_onLocaleChanged);
    // If translations weren't ready during main() (e.g. rootBundle wasn't
    // ready on very first frame), retry now — the widget tree is live.
    if (!_locSvc.isInitialized || _locSvc.currentLocale.languageCode == 'en') {
      _locSvc.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _locSvc.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SKS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locSvc.currentLocale,
      supportedLocales: LocalizationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      builder: (context, child) {
        // In debug mode show a readable error widget instead of red screen
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
                        const Icon(Icons.error_outline,
                            color: AppTheme.saffron, size: 60),
                        const SizedBox(height: 20),
                        const Text('Something went wrong',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),
                        Text('${details.exception}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
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
