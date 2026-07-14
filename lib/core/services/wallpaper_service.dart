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
  // Key that tracks when the CDN list was last refreshed
  static const String _prefKeyListFetchedAt = 'wallpaper_list_fetched_at';
  static const Duration _rotationInterval = Duration(minutes: 15);
  // How long to treat the fetched wallpaper list as fresh before re-checking CDN.
  // Using 1 hour so new wallpapers added to the CDN appear within the hour.
  static const Duration _listCacheTtl = Duration(hours: 1);

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
    if (_isInitializing) {
      debugPrint('ℹ️ WallpaperService already initializing');
      return;
    }

    _isInitializing = true;
    try {
      final _ = _dioInstance;

      // Load from cache first — gives instant wallpaper list without network
      await _loadWallpapersFromCache();

      // Stagger the network call by 3 seconds so it doesn't compete with
      // ApiService, AudioProvider and other services that all hit the server
      // at app startup simultaneously (causes "Connection reset by peer").
      await Future.delayed(const Duration(seconds: 3));

      await _loadWallpapersFromAPIWithRetry();
      debugPrint('✅ WallpaperService initialized with ${_wallpapers.length} wallpapers from CDN');

      final enabled = await isEnabled();
      if (enabled) {
        _startAutoRotation();
      }
    } catch (e) {
      debugPrint('❌ WallpaperService initialization failed: $e');
      // Cache was already loaded above — just continue with what we have
    } finally {
      _isInitializing = false;
    }
  }

  /// Load wallpapers from API and persist the fetch timestamp.
  Future<void> _loadWallpapersFromAPI() async {
    try {
      final baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
          ? AppEnv.apiBaseUrl 
          : 'https://app.sivakundalini.org';
      
      final response = await _dioInstance.get('$baseUrl/api/wallpapers');
      
      if (response.data['success'] == true) {
        _wallpapers = List<Map<String, dynamic>>.from(response.data['wallpapers']);
        _isLoaded = true;
        
        // Persist the list AND record when we fetched it (for TTL checks)
        await _cacheWallpapers();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _prefKeyListFetchedAt, DateTime.now().toIso8601String());
        
        debugPrint('✅ Loaded ${_wallpapers.length} wallpapers from CDN');
      }
    } catch (e) {
      debugPrint('❌ Error loading wallpapers from API: $e');
      rethrow;
    }
  }

  /// Load wallpapers from API with exponential backoff retry (max 3 attempts).
  Future<void> _loadWallpapersFromAPIWithRetry() async {
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _loadWallpapersFromAPI();
        return; // success
      } catch (e) {
        if (attempt < maxAttempts) {
          final delay = Duration(seconds: attempt * 2); // 2s, 4s
          debugPrint('⚠️ Wallpaper API attempt $attempt/$maxAttempts failed, retrying in ${delay.inSeconds}s: $e');
          await Future.delayed(delay);
        } else {
          debugPrint('❌ Wallpaper API failed after $maxAttempts attempts: $e');
          rethrow;
        }
      }
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

  /// Load wallpapers from SharedPreferences cache.
  /// Parses the JSON URL array stored by _cacheWallpapers() so wallpapers
  /// are available immediately on startup and when the server is unreachable.
  Future<void> _loadWallpapersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Primary: parse the native-readable JSON URL array
      final urlsJson = prefs.getString(_prefKeyCachedUrls);
      if (urlsJson != null && urlsJson.isNotEmpty) {
        // Parse JSON array: ["https://...", "https://...", ...]
        final cleaned = urlsJson.trim();
        if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
          final inner = cleaned.substring(1, cleaned.length - 1);
          final urls = inner
              .split(',')
              .map((s) => s.trim().replaceAll('"', ''))
              .where((s) => s.startsWith('http'))
              .toList();

          if (urls.isNotEmpty) {
            // ── Stale URL detection ────────────────────────────────────
            // Old R2 bucket (pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev)
            // served 404s. Discard any cached list that still contains those
            // URLs so we always fetch fresh ones from the API on next launch.
            final hasStaleUrls = urls.any((u) =>
                u.contains('pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev') ||
                u.contains('/Wallpapers/Guruji.JPG'));

            if (hasStaleUrls) {
              debugPrint('⚠️ Stale wallpaper URLs detected in cache — clearing to force refresh');
              await prefs.remove(_prefKeyCachedUrls);
              await prefs.remove(_prefKeyCachedWallpapers);
              await prefs.remove(_prefKeyListFetchedAt);
              return; // will fetch fresh from API
            }

            _wallpapers = urls.map((u) => {
              'url': u,
              'filename': u.split('/').last,
            }).toList();
            _isLoaded = true;
            debugPrint('📦 Loaded ${_wallpapers.length} wallpapers from cache');
            return;
          }
        }
      }

      debugPrint('ℹ️ No cached wallpaper URLs found');
    } catch (e) {
      debugPrint('⚠️ Error loading wallpapers from cache: $e');
    }
  }

  /// Ensure wallpapers are loaded — refreshes from CDN if the cached list
  /// is older than [_listCacheTtl] (1 hour) so new wallpapers always appear.
  Future<void> _ensureLoaded() async {
    // Check if the in-memory list has passed the TTL
    if (_isLoaded && _wallpapers.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final fetchedAtStr = prefs.getString(_prefKeyListFetchedAt);
        if (fetchedAtStr != null) {
          final fetchedAt = DateTime.parse(fetchedAtStr);
          if (DateTime.now().difference(fetchedAt) < _listCacheTtl) {
            return; // Still fresh — use the cached list
          }
          debugPrint('🔄 Wallpaper list TTL expired — refreshing from CDN');
        }
      } catch (_) {}
      // TTL expired or couldn't read timestamp → force refresh
      _isLoaded = false;
    }

    if (_isInitializing) return;

    // Try cache first for instant availability
    if (_wallpapers.isEmpty) {
      await _loadWallpapersFromCache();
    }

    // Then try to refresh from API (with retry)
    if (!_isLoaded || _wallpapers.isEmpty) {
      try {
        await _loadWallpapersFromAPIWithRetry();
      } catch (e) {
        debugPrint('⚠️ CDN refresh failed, using cached list (${_wallpapers.length} items): $e');
        // If we have wallpapers from cache, that's fine — don't fail
        if (_wallpapers.isEmpty) {
          rethrow;
        }
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

    // Schedule native alarm — the receiver handles all Android version
    // differences, permission checks, and rescheduling after each rotation.
    if (!kIsWeb) {
      platform.invokeMethod('scheduleWallpaperAlarm', {
        'intervalMs': _rotationInterval.inMilliseconds,
      }).catchError((e) => debugPrint('⚠️ scheduleWallpaperAlarm error: $e'));
    }

    // Dart timer as a foreground backup (fires while app is open).
    // This handles the case where AlarmManager wakes up inexactly — the
    // Dart timer ensures the wallpaper changes precisely at 15 min in-app.
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

  /// Get list of all available wallpapers.
  /// Always checks for new CDN wallpapers when called from the settings page.
  Future<List<String>> getAvailableWallpapers({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _isLoaded = false;
      }
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
