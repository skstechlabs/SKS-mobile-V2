import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';

/// Wallpaper Service
/// 
/// Manages rotating wallpapers from daily wisdom images
class WallpaperService {
  static final WallpaperService _instance = WallpaperService._internal();
  factory WallpaperService() => _instance;
  WallpaperService._internal();

  static const String _taskName = 'rotateWallpaper';
  static const String _prefKeyEnabled = 'wallpaper_rotation_enabled';
  static const String _prefKeyCurrentIndex = 'wallpaper_current_index';
  static const String _prefKeyLastUpdate = 'wallpaper_last_update';

  // List of daily wisdom images
  static const List<String> _wisdomImages = [
    'assets/images/daily_wisdom_images/Guruji_25.webp',
    'assets/images/daily_wisdom_images/Guruji_26.webp',
    'assets/images/daily_wisdom_images/Guruji_30.webp',
    'assets/images/daily_wisdom_images/Guruji_32.jpeg',
  ];

  /// Initialize the wallpaper service
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('✅ WallpaperService initialized');
    } catch (e) {
      debugPrint('❌ WallpaperService initialization failed: $e');
    }
  }

  /// Check if wallpaper rotation is enabled
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKeyEnabled) ?? false;
    } catch (e) {
      debugPrint('Error checking wallpaper status: $e');
      return false;
    }
  }

  /// Enable wallpaper rotation
  Future<bool> enable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, true);
      await prefs.setInt(_prefKeyCurrentIndex, 0);

      // Set initial wallpaper
      await _setNextWallpaper();

      // Schedule periodic task (every 15 minutes)
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('✅ Wallpaper rotation enabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling wallpaper rotation: $e');
      return false;
    }
  }

  /// Disable wallpaper rotation
  Future<bool> disable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, false);

      // Cancel the periodic task
      await Workmanager().cancelByUniqueName(_taskName);

      debugPrint('✅ Wallpaper rotation disabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling wallpaper rotation: $e');
      return false;
    }
  }

  /// Set next wallpaper in rotation
  Future<void> _setNextWallpaper() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentIndex = prefs.getInt(_prefKeyCurrentIndex) ?? 0;

      // Get next image
      final imagePath = _wisdomImages[currentIndex % _wisdomImages.length];

      // Copy asset to file
      final file = await _copyAssetToFile(imagePath);

      // Set as wallpaper
      await WallpaperManager.setWallpaperFromFile(
        file.path,
        WallpaperManager.HOME_SCREEN,
      );

      // Update index and timestamp
      await prefs.setInt(_prefKeyCurrentIndex, currentIndex + 1);
      await prefs.setString(_prefKeyLastUpdate, DateTime.now().toIso8601String());

      debugPrint('✅ Wallpaper set: $imagePath (index: $currentIndex)');
    } catch (e) {
      debugPrint('❌ Error setting wallpaper: $e');
      rethrow;
    }
  }

  /// Copy asset to temporary file
  Future<File> _copyAssetToFile(String assetPath) async {
    try {
      // Check if running on web
      if (kIsWeb) {
        throw UnsupportedError('Wallpaper setting is not supported on web');
      }
      
      // Load asset
      final byteData = await rootBundle.load(assetPath);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final filePath = '${directory.path}/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint('Error copying asset: $e');
      rethrow;
    }
  }

  /// Manually trigger wallpaper change
  Future<void> changeNow() async {
    try {
      final enabled = await isEnabled();
      if (!enabled) {
        throw Exception('Wallpaper rotation is not enabled');
      }

      await _setNextWallpaper();
    } catch (e) {
      debugPrint('Error changing wallpaper: $e');
      rethrow;
    }
  }

  /// Get current wallpaper info
  Future<Map<String, dynamic>> getCurrentInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentIndex = prefs.getInt(_prefKeyCurrentIndex) ?? 0;
      final lastUpdate = prefs.getString(_prefKeyLastUpdate);

      final imageIndex = (currentIndex - 1) % _wisdomImages.length;
      final imagePath = imageIndex >= 0 ? _wisdomImages[imageIndex] : _wisdomImages[0];

      return {
        'enabled': await isEnabled(),
        'currentImage': imagePath,
        'currentIndex': currentIndex,
        'lastUpdate': lastUpdate,
        'totalImages': _wisdomImages.length,
      };
    } catch (e) {
      debugPrint('Error getting wallpaper info: $e');
      return {
        'enabled': false,
        'currentImage': null,
        'currentIndex': 0,
        'lastUpdate': null,
        'totalImages': _wisdomImages.length,
      };
    }
  }

  /// Set specific wallpaper by index
  Future<void> setWallpaperByIndex(int index) async {
    try {
      // Check if running on web
      if (kIsWeb) {
        throw UnsupportedError('Wallpaper setting is not supported on web. This feature only works on mobile devices.');
      }
      
      if (index < 0 || index >= _wisdomImages.length) {
        throw Exception('Invalid wallpaper index');
      }

      final imagePath = _wisdomImages[index];
      final file = await _copyAssetToFile(imagePath);

      await WallpaperManager.setWallpaperFromFile(
        file.path,
        WallpaperManager.HOME_SCREEN,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyCurrentIndex, index + 1);
      await prefs.setString(_prefKeyLastUpdate, DateTime.now().toIso8601String());

      debugPrint('✅ Wallpaper set to index $index: $imagePath');
    } catch (e) {
      debugPrint('❌ Error setting wallpaper by index: $e');
      rethrow;
    }
  }

  /// Get list of all available wallpapers
  List<String> getAvailableWallpapers() {
    return List.from(_wisdomImages);
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🔄 Background task started: $task');

      if (task == WallpaperService._taskName) {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool(WallpaperService._prefKeyEnabled) ?? false;

        if (enabled) {
          final service = WallpaperService();
          await service._setNextWallpaper();
          debugPrint('✅ Background wallpaper rotation completed');
        } else {
          debugPrint('⏭️ Wallpaper rotation is disabled, skipping');
        }
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}
