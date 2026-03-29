import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
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
import 'core/constants/app_env.dart';
import 'firebase_options.dart';

void main() async {
  // Wrap everything in try-catch to prevent white screen
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('✅ Firebase initialized successfully');
    } catch (e) {
      developer.log('❌ Firebase initialization failed: $e');
      // Continue anyway - app can work without Firebase initially
    }
    
    // Initialize API Service with error handling
    try {
      ApiService().initialize();
      developer.log('✅ API Service initialized successfully');
    } catch (e) {
      developer.log('❌ API Service initialization failed: $e');
    }
    
    // Initialize Notification Storage with error handling
    try {
      await NotificationStorageService().initialize();
      developer.log('✅ Notification Storage initialized successfully');
    } catch (e) {
      developer.log('❌ Notification Storage initialization failed: $e');
    }
    
    // Initialize AudioService for background playback
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
      developer.log('✅ AudioService initialized successfully');
    } catch (e) {
      developer.log('❌ AudioService initialization failed: $e');
    }
    
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log('Flutter Error: ${details.exception}', 
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack
      );
    };
    
    // Set system UI overlay style
    try {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppTheme.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    } catch (e) {
      developer.log('❌ SystemChrome UI style failed: $e');
    }

    // Performance optimizations
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
    
    // Start the app first
    runApp(const SpiritualApp());
    
    // Initialize OneSignal AFTER runApp (per official documentation)
    // Only on mobile platforms (not web)
    if (!kIsWeb) {
      // Delay OneSignal initialization to avoid blocking app startup
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          // Enable verbose logging for debugging
          OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
          
          // Initialize with App ID
          OneSignal.initialize(AppEnv.oneSignalAppId);
          
          // Setup notification handlers through service
          final oneSignalService = OneSignalService();
          oneSignalService.setupNotificationHandlers();
          
          // Set up navigation callback for when notification is clicked
          oneSignalService.onNavigateToNotification = (notificationId) {
            appRouter.push('/notifications/$notificationId');
          };
          
          developer.log('✅ OneSignal initialized successfully');
        } catch (e) {
          developer.log('❌ OneSignal initialization failed: $e');
        }
      });
    }
  } catch (e, stackTrace) {
    developer.log('❌ CRITICAL: App initialization failed: $e');
    developer.log('Stack trace: $stackTrace');
    // Still try to run the app
    runApp(const SpiritualApp());
  }
}

class SpiritualApp extends StatelessWidget {
  const SpiritualApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SKS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      // Performance optimizations
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      // Responsive design support with error handling
      builder: (context, child) {
        // Only set error widget in debug mode
        // In release, let errors propagate naturally
        if (kDebugMode) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            developer.log('Widget Error: ${details.exception}');
            developer.log('Stack trace: ${details.stack}');
            return Material(
              child: Container(
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
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Please restart the app',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${details.exception}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          };
        }
        
        if (child == null) {
          return Container(color: Colors.white);
        }
        
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
