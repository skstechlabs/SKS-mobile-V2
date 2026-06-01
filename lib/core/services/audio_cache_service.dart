import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  Directory? _cacheDir;
  final Map<String, String> _cacheMap = {}; // URL -> Local path
  final Map<String, double> _downloadProgress = {}; // URL -> Progress (0.0 to 1.0)

  // Initialize cache directory
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/audio_cache');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Load existing cache map
      await _loadCacheMap();
      
      debugPrint('Audio cache initialized at: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('Error initializing audio cache: $e');
    }
  }

  // Load cache map from disk
  Future<void> _loadCacheMap() async {
    try {
      if (_cacheDir == null) return;
      
      final files = await _cacheDir!.list().toList();
      for (var file in files) {
        if (file is File && file.path.endsWith('.mp3')) {
          final fileName = file.path.split('/').last;
          // Store in memory map (we'll need to match URLs later)
          debugPrint('Found cached audio: $fileName');
        }
      }
    } catch (e) {
      debugPrint('Error loading cache map: $e');
    }
  }

  // Generate cache key from URL
  String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Get cached file path if exists
  Future<String?> getCachedFilePath(String url) async {
    if (_cacheDir == null) await initialize();
    
    final cacheKey = _getCacheKey(url);
    final cachedPath = '${_cacheDir!.path}/$cacheKey.mp3';
    final file = File(cachedPath);
    
    if (await file.exists()) {
      _cacheMap[url] = cachedPath;
      return cachedPath;
    }
    
    return null;
  }

  // Check if file is cached
  Future<bool> isCached(String url) async {
    final path = await getCachedFilePath(url);
    return path != null;
  }

  // Download and cache audio file
  Future<String?> downloadAndCache(
    String url, {
    Function(double)? onProgress,
  }) async {
    try {
      if (_cacheDir == null) await initialize();

      // Check if already cached
      final cachedPath = await getCachedFilePath(url);
      if (cachedPath != null) {
        debugPrint('Audio already cached: $url');
        return cachedPath;
      }

      debugPrint('Downloading audio: $url');
      
      // Download file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final cacheKey = _getCacheKey(url);
        final filePath = '${_cacheDir!.path}/$cacheKey.mp3';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        _cacheMap[url] = filePath;
        
        debugPrint('Audio cached successfully: $filePath');
        return filePath;
      } else {
        debugPrint('Failed to download audio: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      return null;
    }
  }

  // Download with progress tracking (for large files)
  Future<String?> downloadWithProgress(
    String url, {
    Function(double)? onProgress,
  }) async {
    try {
      if (_cacheDir == null) await initialize();

      // Check if already cached
      final cachedPath = await getCachedFilePath(url);
      if (cachedPath != null) {
        onProgress?.call(1.0);
        return cachedPath;
      }

      debugPrint('Downloading audio with progress: $url');
      
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final cacheKey = _getCacheKey(url);
        final filePath = '${_cacheDir!.path}/$cacheKey.mp3';
        final file = File(filePath);
        
        final contentLength = response.contentLength ?? 0;
        int downloadedBytes = 0;
        
        final sink = file.openWrite();
        
        await for (var chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          
          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            _downloadProgress[url] = progress;
            onProgress?.call(progress);
          }
        }
        
        await sink.close();
        _cacheMap[url] = filePath;
        _downloadProgress.remove(url);
        
        debugPrint('Audio cached successfully: $filePath');
        return filePath;
      } else {
        debugPrint('Failed to download audio: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading audio with progress: $e');
      _downloadProgress.remove(url);
      return null;
    }
  }

  // Get download progress for a URL
  double? getDownloadProgress(String url) {
    return _downloadProgress[url];
  }

  // Clear specific cached file
  Future<bool> clearCache(String url) async {
    try {
      final cachedPath = await getCachedFilePath(url);
      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
          _cacheMap.remove(url);
          debugPrint('Cleared cache for: $url');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
  }

  // Clear all cached audio files
  Future<void> clearAllCache() async {
    try {
      if (_cacheDir == null) await initialize();
      
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        _cacheMap.clear();
        debugPrint('All audio cache cleared');
      }
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  // Get total cache size
  Future<int> getCacheSize() async {
    try {
      if (_cacheDir == null) await initialize();
      
      int totalSize = 0;
      final files = await _cacheDir!.list().toList();
      
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  // Format cache size for display
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // Preload audio files in background (for better UX)
  Future<void> preloadAudios(List<String> urls) async {
    for (var url in urls) {
      final isCached = await this.isCached(url);
      if (!isCached) {
        // Download in background without blocking
        downloadAndCache(url).then((path) {
          if (path != null) {
            debugPrint('Preloaded audio: $url');
          }
        }).catchError((e) {
          debugPrint('Error preloading audio: $e');
        });
      }
    }
  }
}
