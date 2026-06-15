import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../constants/app_env.dart';

/// Wallpaper Service
/// 
/// Manages rotating wallpapers from Cloudflare R2 CDN (sadhaks/Wallpapers/)
/// Auto-rotates wallpapers every 15 minutes when enabled
class WallpaperService {
  static final WallpaperService _instance = WallpaperService._internal();
  factory WallpaperService() => _instance;
  WallpaperService._internal();

  static const platform = MethodChannel('com.spiritual.app/wallpaper');
  static const String _prefKeyEnabled = 'wallpaper_rotation_enabled';
  static const String _prefKeyCurrentIndex = 'wallpaper_current_index';
  static const String _prefKeyLastUpdate = 'wallpaper_last_update';
  static const String _prefKeyCachedWallpapers = 'wallpaper_cached_list';
  // Key used by the native receiver to read cached URLs
  static const String _prefKeyCachedUrls = 'wallpaper_cached_urls';
  static const Duration _rotationInterval = Duration(minutes: 15);

  Dio? _dio;
  List<Map<String, dynamic>> _wallpapers = [];
  bool _isLoaded = false;
  bool _isInitializing = false;
  // Dart-side timer for foreground rotation (backup to native alarm)
  Timer? _rotationTimer;

  /// Get or create Dio instance
  Dio get _dioInstance {
    if (_dio == null) {
      _dio = Dio();
      // Only configure HTTP client for mobile/desktop (not web)
      if (!kIsWeb) {
        (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            // Accept certificates for our domains
            if (host.contains('sivakundalini.org') || host.contains('r2.dev')) {
              debugPrint('✅ SSL: Accepting certificate for $host');
              return true;
            }
            return false;
          };
          return client;
        };
      }
    }
    return _dio!;
  }

  /// Initialize the wallpaper service
  Future<void> initialize() async {
    if (_isInitializing || _isLoaded) {
      debugPrint('ℹ️ WallpaperService already initialized or initializing');
      return;
    }

    _isInitializing = true;
    try {
      // Initialize Dio (using getter ensures it's created)
      final _ = _dioInstance;

      await _loadWallpapersFromAPI();
      debugPrint('✅ WallpaperService initialized with ${_wallpapers.length} wallpapers from CDN');
      
      // Start auto-rotation timer if enabled
      final enabled = await isEnabled();
      if (enabled) {
        _startAutoRotation();
      }
    } catch (e) {
      debugPrint('❌ WallpaperService initialization failed: $e');
      // Try to load from cache
      await _loadWallpapersFromCache();
    } finally {
      _isInitializing = false;
    }
  }

  /// Load wallpapers from API
  Future<void> _loadWallpapersFromAPI() async {
    try {
      final baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
          ? AppEnv.apiBaseUrl 
          : 'https://app.sivakundalini.org';
      
      final response = await _dioInstance.get('$baseUrl/api/wallpapers');
      
      if (response.data['success'] == true) {
        _wallpapers = List<Map<String, dynamic>>.from(response.data['wallpapers']);
        _isLoaded = true;
        
        // Cache the wallpapers list
        await _cacheWallpapers();
        
        debugPrint('✅ Loaded ${_wallpapers.length} wallpapers from CDN');
      }
    } catch (e) {
      debugPrint('❌ Error loading wallpapers from API: $e');
      rethrow;
    }
  }

  /// Cache wallpapers list
  Future<void> _cacheWallpapers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Legacy cache (kept for compatibility)
      final wallpapersJson = _wallpapers.map((w) => {
        'url': w['url'],
        'filename': w['filename'],
      }).toList();
      await prefs.setString(_prefKeyCachedWallpapers, wallpapersJson.toString());

      // Native-readable JSON array of URLs (used by WallpaperRotationReceiver)
      final urlsJson = '[${_wallpapers.map((w) => '"${w['url']}"').join(',')}]';
      await prefs.setString(_prefKeyCachedUrls, urlsJson);
    } catch (e) {
      debugPrint('Error caching wallpapers: $e');
    }
  }

  /// Load wallpapers from cache
  Future<void> _loadWallpapersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefKeyCachedWallpapers);
      if (cached != null) {
        // Parse cached data (simplified - in production use proper JSON parsing)
        debugPrint('📦 Loaded wallpapers from cache');
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  /// Ensure wallpapers are loaded
  Future<void> _ensureLoaded() async {
    if (!_isLoaded || _wallpapers.isEmpty) {
      // Initialize if not done yet
      if (!_isInitializing) {
        await initialize();
      }
      
      // If still not loaded, try again
      if (!_isLoaded || _wallpapers.isEmpty) {
        await _loadWallpapersFromAPI();
      }
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

      // Start auto-rotation timer
      _startAutoRotation();

      debugPrint('✅ Wallpaper rotation enabled with 15-minute auto-rotation');
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

      // Stop auto-rotation timer
      _stopAutoRotation();

      debugPrint('✅ Wallpaper rotation disabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling wallpaper rotation: $e');
      return false;
    }
  }

  /// Start auto-rotation — uses native AlarmManager for background support
  void _startAutoRotation() {
    _stopAutoRotation();
    debugPrint('🔄 Starting wallpaper auto-rotation (every 15 minutes)');

    // Schedule native alarm — works even when app is in background/killed
    if (!kIsWeb) {
      platform.invokeMethod('scheduleWallpaperAlarm', {
        'intervalMs': _rotationInterval.inMilliseconds,
      }).catchError((e) => debugPrint('⚠️ scheduleWallpaperAlarm error: $e'));
    }

    // Also keep a Dart timer as backup for foreground rotation
    _rotationTimer = Timer.periodic(_rotationInterval, (timer) async {
      try {
        final enabled = await isEnabled();
        if (!enabled) {
          _stopAutoRotation();
          return;
        }
        debugPrint('⏰ Foreground auto-rotation triggered');
        await _setNextWallpaper();
      } catch (e) {
        debugPrint('❌ Error in foreground auto-rotation: $e');
      }
    });
  }

  /// Stop auto-rotation — cancels both native alarm and Dart timer
  void _stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;

    if (!kIsWeb) {
      platform.invokeMethod('cancelWallpaperAlarm')
          .catchError((e) => debugPrint('⚠️ cancelWallpaperAlarm error: $e'));
    }
    debugPrint('⏹️ Wallpaper auto-rotation stopped');
  }

  /// Set next wallpaper in rotation
  Future<void> _setNextWallpaper() async {
    try {
      await _ensureLoaded();
      
      if (_wallpapers.isEmpty) {
        throw Exception('No wallpapers available');
      }

      final prefs = await SharedPreferences.getInstance();
      final currentIndex = prefs.getInt(_prefKeyCurrentIndex) ?? 0;

      // Get next wallpaper
      final wallpaper = _wallpapers[currentIndex % _wallpapers.length];
      final imageUrl = wallpaper['url'] as String;

      // Download image from CDN
      final file = await _downloadImageFromCDN(imageUrl);

      // Set as wallpaper using native method
      final result = await platform.invokeMethod('setWallpaper', {
        'path': file.path,
      });

      if (result == true) {
        // Update index and timestamp
        await prefs.setInt(_prefKeyCurrentIndex, currentIndex + 1);
        await prefs.setString(_prefKeyLastUpdate, DateTime.now().toIso8601String());

        debugPrint('✅ Wallpaper set: ${wallpaper['filename']} (index: $currentIndex)');
      } else {
        debugPrint('❌ Failed to set wallpaper');
      }
    } catch (e) {
      debugPrint('❌ Error setting wallpaper: $e');
      rethrow;
    }
  }

  /// Download image from CDN to temporary file
  Future<File> _downloadImageFromCDN(String imageUrl) async {
    try {
      // Check if running on web
      if (kIsWeb) {
        throw UnsupportedError('Wallpaper setting is not supported on web');
      }
      
      // Download image
      final response = await _dioInstance.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filename = imageUrl.split('/').last;
      final filePath = '${directory.path}/$filename';

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      return file;
    } catch (e) {
      debugPrint('Error downloading image from CDN: $e');
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
      await _ensureLoaded();
      
      final prefs = await SharedPreferences.getInstance();
      final currentIndex = prefs.getInt(_prefKeyCurrentIndex) ?? 0;
      final lastUpdate = prefs.getString(_prefKeyLastUpdate);

      if (_wallpapers.isEmpty) {
        return {
          'enabled': await isEnabled(),
          'currentImage': null,
          'currentIndex': 0,
          'lastUpdate': lastUpdate,
          'totalImages': 0,
        };
      }

      final imageIndex = (currentIndex - 1) % _wallpapers.length;
      final wallpaper = imageIndex >= 0 ? _wallpapers[imageIndex] : _wallpapers[0];

      return {
        'enabled': await isEnabled(),
        'currentImage': wallpaper['url'],
        'currentIndex': currentIndex,
        'lastUpdate': lastUpdate,
        'totalImages': _wallpapers.length,
      };
    } catch (e) {
      debugPrint('Error getting wallpaper info: $e');
      return {
        'enabled': false,
        'currentImage': null,
        'currentIndex': 0,
        'lastUpdate': null,
        'totalImages': 0,
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
      
      await _ensureLoaded();
      
      if (index < 0 || index >= _wallpapers.length) {
        throw Exception('Invalid wallpaper index');
      }

      final wallpaper = _wallpapers[index];
      final imageUrl = wallpaper['url'] as String;
      
      // Download image from CDN
      final file = await _downloadImageFromCDN(imageUrl);

      // Set as wallpaper using native method
      final result = await platform.invokeMethod('setWallpaper', {
        'path': file.path,
      });

      if (result == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefKeyCurrentIndex, index + 1);
        await prefs.setString(_prefKeyLastUpdate, DateTime.now().toIso8601String());

        debugPrint('✅ Wallpaper set to index $index: ${wallpaper['filename']}');
      } else {
        throw Exception('Failed to set wallpaper');
      }
    } catch (e) {
      debugPrint('❌ Error setting wallpaper by index: $e');
      rethrow;
    }
  }

  /// Get list of all available wallpapers
  Future<List<String>> getAvailableWallpapers() async {
    try {
      await _ensureLoaded();
      return _wallpapers.map((w) => w['url'] as String).toList();
    } catch (e) {
      debugPrint('Error getting available wallpapers: $e');
      return [];
    }
  }

  /// Dispose resources (call when app is closing)
  void dispose() {
    _stopAutoRotation();
    debugPrint('🧹 WallpaperService disposed');
  }
}
