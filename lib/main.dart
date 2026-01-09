import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:developer' as developer;
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'core/services/audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(const SpiritualApp());
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
    );
  }
}
