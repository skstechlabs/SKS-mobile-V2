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
  // Always guaranteed first — required before any Flutter plugin call.
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('========================================');
  developer.log('🚀 APP STARTING');
  developer.log('========================================');

  try {
    await _runInitialization();
  } catch (e, st) {
    // This should never happen because _runInitialization swallows all errors,
    // but as an absolute last resort we still launch the app.
    developer.log('💥 CRITICAL: initialization threw: $e', stackTrace: st);
  }

  runApp(const SpiritualApp());

  // ── Deferred post-runApp work ────────────────────────────────────────────
  // These fire after the first frame is rendered — never block startup.
  Future.microtask(() async {
    await _safe('AudioProvider (deferred)', () => AudioProvider().initialize());

    if (!kIsWeb) {
      await _safe('OneSignal post-runApp re-link', () async {
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

/// All initialization logic lives here so that a rethrow in any step doesn't
/// bypass `runApp()`. Every step uses `_safe()` or has its own try-catch.
Future<void> _runInitialization() async {
  // ── 1. Environment check (synchronous, never throws) ──────────────────────
  try {
    EnvironmentChecker.checkEnvironment();
    if (!EnvironmentChecker.isConfigured()) {
      developer.log('⚠️ WARNING: Environment not fully configured');
    }
  } catch (_) {}

  // ── 2. Version migration — must run before any cache is read ─────────────
  await _safe('VersionMigration', () => VersionMigrationService.instance.initialize());

  // ── 3. Firebase — CRITICAL. Without it auth and notifications won't work,
  //    but we still launch the app so the user sees something useful.  ────────
  bool firebaseOk = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseOk = true;
    developer.log('✅ Firebase initialized');
  } catch (e) {
    developer.log('❌ Firebase FAILED: $e — app will launch without auth');
  }

  // ── 4. SecureStorageService — must come before ApiService (token fallback) ─
  await _safe('SecureStorageService', () async => SecureStorageService().initialize());

  // ── 5. ApiService — must come before Localization (lang backend sync) ──────
  await _safe('ApiService', () async => ApiService().initialize());

  // ── 6. Parallel non-critical services ─────────────────────────────────────
  await Future.wait([
    _safe('NotificationStorage', () => NotificationStorageService().initialize()),
    _safe('ConnectivityService', () => ConnectivityService().initialize()),
  ]);

  // ── 7. Localization — must complete before runApp so tr() works ───────────
  await _safe('LocalizationService', () => LocalizationService().initialize());

  // ── 8. AuthState — must complete before splash routing decisions ──────────
  await _safe('AuthState', () => AuthState().initialize());

  // ── 9. AudioService — guard against warm-restart double-init ─────────────
  await _safe('AudioService', () async {
    if (!AudioService.running) {
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
    } else {
      developer.log('ℹ️ AudioService already running');
    }
  });

  // ── 10. Enhanced Audio Player — re-initializes safely on warm restart ─────
  await _safe('EnhancedAudioPlayerService',
      () => EnhancedAudioPlayerService().initialize());

  // ── 11. System UI ─────────────────────────────────────────────────────────
  _safe('SystemChrome', () async {
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

  // ── 12. OneSignal ─────────────────────────────────────────────────────────
  if (!kIsWeb && firebaseOk) {
    await _safe('OneSignal', () async {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(AppEnv.oneSignalAppId);

      final svc = OneSignalService();
      svc.setupNotificationHandlers();
      svc.markInitialized();

      final permitted = OneSignal.Notifications.permission;
      developer.log('🔔 Notification permission on startup: $permitted');

      final auth = AuthState();
      if (auth.user != null) {
        OneSignal.login(auth.user!.uid);
        if (permitted) OneSignal.User.pushSubscription.optIn();
      }

      svc.onNavigateToNotification = (id) {
        appRouter.push('/notifications/$id');
      };
    });
  }

  // ── 13. Flutter error handler ─────────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('Flutter Error: ${details.exception}',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack);
  };

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
