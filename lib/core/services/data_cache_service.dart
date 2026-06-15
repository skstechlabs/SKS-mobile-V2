import 'package:flutter/foundation.dart';

/// Data Cache Service - Smart caching to reduce server load
/// 
/// Strategy:
/// - Cache GET responses with TTL (time-to-live)
/// - Invalidate cache on mutations (create/update/delete)
/// - Support manual refresh
/// - Lazy load tab-specific data
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // Cache storage
  final Map<String, _CacheEntry> _cache = {};

  // Default TTL: 5 minutes (adjust per endpoint if needed)
  static const Duration _defaultTTL = Duration(minutes: 5);

  /// Get cached data if available and not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      debugPrint('📦 Cache MISS: $key');
      return null;
    }

    if (entry.isExpired) {
      debugPrint('⏰ Cache EXPIRED: $key');
      _cache.remove(key);
      return null;
    }

    debugPrint('✅ Cache HIT: $key (age: ${entry.age})');
    return entry.data as T;
  }

  /// Store data in cache
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? _defaultTTL);
    _cache[key] = _CacheEntry(data: data, expiresAt: expiresAt);
    debugPrint('💾 Cache SET: $key (TTL: ${ttl ?? _defaultTTL})');
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    debugPrint('🗑️ Cache INVALIDATE: $key');
  }

  /// Invalidate multiple cache entries (e.g., after mutation)
  void invalidateMultiple(List<String> keys) {
    for (final key in keys) {
      _cache.remove(key);
    }
    debugPrint('🗑️ Cache INVALIDATE: ${keys.join(', ')}');
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    debugPrint('🧹 Cache CLEARED');
  }

  /// Check if cache has valid entry
  bool has(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// Get cache stats
  Map<String, dynamic> getStats() {
    final total = _cache.length;
    final expired = _cache.values.where((e) => e.isExpired).length;
    final valid = total - expired;

    return {
      'total': total,
      'valid': valid,
      'expired': expired,
      'keys': _cache.keys.toList(),
    };
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime createdAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  }) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get age => DateTime.now().difference(createdAt);
}

/// Cache keys for different endpoints
class CacheKeys {
  static const String reminders = 'reminders';
  static const String events = 'events';
  static const String gatherings = 'gatherings';
  static const String audios = 'audios';
  static const String quotes = 'quotes';
  static const String profile = 'profile';
  static const String presetReminders = 'preset_reminders';
  
  // Classes/videos (per language and day)
  static String classesDay(String language, int day) => 'classes_${language}_day_$day';
  static String classesAll(String language) => 'classes_$language';
}
