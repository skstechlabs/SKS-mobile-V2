import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize API Service
  ApiService().initialize();
  
  // Initialize Notification Storage
  await NotificationStorageService().initialize();
  
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
  } catch (e) {
    developer.log('AudioService initialization failed: $e');
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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Performance optimizations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Start the app first
  runApp(const SpiritualApp());
  
  // Initialize OneSignal AFTER runApp (per official documentation)
  // Only on mobile platforms (not web)
  if (!kIsWeb) {
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
      // Responsive design support
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
