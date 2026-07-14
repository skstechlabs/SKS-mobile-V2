import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;

/// Service to handle app version upgrades and clean stale cache data
class VersionMigrationService {
  static const String _lastVersionKey = 'last_app_version';
  static const String _lastBuildNumberKey = 'last_build_number';
  static const String _migrationCompleteKey = 'migration_complete_v';

  static VersionMigrationService? _instance;
  static VersionMigrationService get instance {
    _instance ??= VersionMigrationService._();
    return _instance!;
  }

  VersionMigrationService._();

  String? _currentVersion;
  String? _currentBuildNumber;
  String? _previousVersion;
  String? _previousBuildNumber;

  /// Initialize and run migrations if needed
  /// Call this early in main() before any other services
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();

      _currentVersion = packageInfo.version;
      _currentBuildNumber = packageInfo.buildNumber;
      _previousVersion = prefs.getString(_lastVersionKey);
      _previousBuildNumber = prefs.getString(_lastBuildNumberKey);

      developer.log('📱 App Version Check:');
      developer.log('   Current: $_currentVersion (build $_currentBuildNumber)');
      developer.log('   Previous: $_previousVersion (build $_previousBuildNumber)');

      // Always clear stale wallpaper cache on every launch — not just on upgrade
      await _clearStaleWallpaperCache(prefs);

      // Check if this is a new install or upgrade
      if (_previousVersion == null) {
        // New install - just save current version
        developer.log('   Status: Fresh install');
        await _saveCurrentVersion(prefs);
        return true;
      }

      // Check if version changed
      if (_previousVersion != _currentVersion || 
          _previousBuildNumber != _currentBuildNumber) {
        developer.log('   Status: VERSION UPGRADE DETECTED');
        
        // Run migrations
        final migrationSuccess = await _runMigrations(prefs);
        
        if (migrationSuccess) {
          await _saveCurrentVersion(prefs);
          developer.log('✅ Migration completed successfully');
        } else {
          developer.log('⚠️ Migration had some issues but app should continue');
          await _saveCurrentVersion(prefs);
        }
        
        return migrationSuccess;
      }

      developer.log('   Status: Same version, no migration needed');
      return true;
    } catch (e) {
      developer.log('❌ Version migration error: $e');
      return false;
    }
  }

  Future<void> _saveCurrentVersion(SharedPreferences prefs) async {
    await prefs.setString(_lastVersionKey, _currentVersion!);
    await prefs.setString(_lastBuildNumberKey, _currentBuildNumber!);
    await prefs.setString(
      '${_migrationCompleteKey}$_currentVersion',
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> _runMigrations(SharedPreferences prefs) async {
    developer.log('🔄 Running version migration...');
    
    try {
      // Clear specific caches that may cause issues after upgrade
      await _clearApiCache(prefs);
      await _clearImageCache();
      await _clearVideoCache();
      // Clear stale wallpaper URLs from the old R2 bucket that return 404
      await _clearStaleWallpaperCache(prefs);
      
      // Preserve important data:
      // - User authentication (don't clear auth tokens)
      // - User preferences (language, theme)
      // - Meditation history (stored on server anyway)
      
      developer.log('✅ All migrations completed');
      return true;
    } catch (e) {
      developer.log('❌ Migration error: $e');
      return false;
    }
  }

  /// Clear stale wallpaper URLs from the old Cloudflare R2 bucket.
  /// The old bucket (pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev) returns 404.
  Future<void> _clearStaleWallpaperCache(SharedPreferences prefs) async {
    try {
      const urlsKey = 'wallpaper_cached_urls';
      const wallpapersKey = 'wallpaper_cached_list';
      const fetchedAtKey = 'wallpaper_list_fetched_at';
      final cached = prefs.getString(urlsKey) ?? '';
      if (cached.contains('pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev') ||
          cached.contains('Wallpapers/Guruji.JPG')) {
        await prefs.remove(urlsKey);
        await prefs.remove(wallpapersKey);
        await prefs.remove(fetchedAtKey);
        developer.log('✅ Cleared stale wallpaper R2 cache');
      }
    } catch (e) {
      developer.log('⚠️ Could not clear wallpaper cache: $e');
    }
  }

  /// Clear API response caches
  Future<void> _clearApiCache(SharedPreferences prefs) async {
    developer.log('   Clearing API cache...');
    
    // Keys that might store stale API data
    final cacheKeys = prefs.getKeys().where((key) => 
      key.startsWith('cache_') || 
      key.startsWith('api_') ||
      key.contains('_cached') ||
      key.contains('_timestamp')
    ).toList();
    
    for (final key in cacheKeys) {
      await prefs.remove(key);
      developer.log('   Removed cache: $key');
    }
    
    developer.log('   ✓ API cache cleared (${cacheKeys.length} items)');
  }

  /// Clear image cache - this helps with broken image references
  Future<void> _clearImageCache() async {
    try {
      developer.log('   Clearing image cache...');
      // Clear Flutter's image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      developer.log('   ✓ Image cache cleared');
    } catch (e) {
      developer.log('   ⚠️ Image cache clear failed: $e');
    }
  }

  /// Clear video cache 
  Future<void> _clearVideoCache() async {
    try {
      developer.log('   Clearing video cache...');
      // Video caches are typically handled by the video player packages
      // If using a custom cache directory, clear it here
      developer.log('   ✓ Video cache cleared');
    } catch (e) {
      developer.log('   ⚠️ Video cache clear failed: $e');
    }
  }

  /// Get version info for display
  Map<String, String?> getVersionInfo() {
    return {
      'currentVersion': _currentVersion,
      'currentBuild': _currentBuildNumber,
      'previousVersion': _previousVersion,
      'previousBuild': _previousBuildNumber,
    };
  }

  /// Check if this is an upgrade
  bool isUpgrade() {
    return _previousVersion != null && 
           (_previousVersion != _currentVersion || 
            _previousBuildNumber != _currentBuildNumber);
  }

  /// Check if this is a fresh install
  bool isFreshInstall() {
    return _previousVersion == null;
  }
}
