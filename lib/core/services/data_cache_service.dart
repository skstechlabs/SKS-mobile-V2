import 'package:flutter/foundation.dart';
import 'persistent_cache_service.dart';

/// Two-layer smart cache.
///
/// L1  In-memory  — fast, 5-min TTL, lost on restart
/// L2  Disk       — SharedPreferences, 24-h TTL, survives restarts
///
/// Read order: L1 hit → return immediately.
///             L1 miss → L2 hit → return immediately (even if stale).
///             Both miss → caller must fetch from network.
///
/// The stale-while-revalidate pattern is used for all GET endpoints:
///   1. Return L2 data immediately (user sees content at once)
///   2. Caller fetches fresh data in background
///   3. L1 + L2 updated silently; UI rebuilt via setState/notifyListeners
///
/// This means the user ALWAYS sees content as long as they've opened the
/// app at least once with internet. Spinners only appear on first-ever load.
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  // L1: in-memory (fast, volatile)
  final Map<String, _CacheEntry> _mem = {};
  static const Duration _memTtl  = Duration(minutes: 5);
  static const Duration _diskTtl = Duration(hours: 24);

  final PersistentCacheService _disk = PersistentCacheService();

  // ── Synchronous L1 read ───────────────────────────────────────────────────

  /// Read from memory only. Returns null if absent or expired.
  T? get<T>(String key) {
    final entry = _mem[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _mem.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  // ── Async two-layer read ──────────────────────────────────────────────────

  /// Read from memory first, then disk. Always returns the best available
  /// data — even if stale. Never returns null when data exists anywhere.
  ///
  /// [checkFreshness] — if true, skip stale disk entries (use for flows
  /// that must not show very old data, e.g. user profile).
  Future<Map<String, dynamic>?> getWithDiskFallback(
    String key, {
    bool checkFreshness = false,
  }) async {
    // L1 hit
    final mem = get<Map<String, dynamic>>(key);
    if (mem != null) {
      debugPrint('✅ L1 cache hit: $key');
      return mem;
    }

    // L2 hit
    final disk = checkFreshness
        ? await _disk.getFresh(key)
        : await _disk.get(key);

    if (disk != null) {
      final age = await _disk.age(key);
      debugPrint('✅ L2 disk cache hit: $key (age: ${age?.inMinutes}m)');
      // Warm L1 from disk
      _mem[key] = _CacheEntry(data: disk, expiresAt: DateTime.now().add(_memTtl));
      return disk;
    }

    debugPrint('📭 Cache miss (L1+L2): $key');
    return null;
  }

  /// True if disk has ANY data for [key] (even stale).
  Future<bool> hasDisk(String key) => _disk.has(key);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Write to both L1 (memory) and L2 (disk).
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? _memTtl);
    _mem[key] = _CacheEntry(data: data, expiresAt: expiresAt);

    // Persist to disk asynchronously (fire and forget — never blocks the UI)
    if (data is Map<String, dynamic>) {
      _disk.set(key, data, ttl: _diskTtl).catchError((e) {
        debugPrint('⚠️ Disk cache write error: $e');
      });
    }
  }

  // ── Invalidate ────────────────────────────────────────────────────────────

  void invalidate(String key) {
    _mem.remove(key);
    _disk.remove(key); // async, fire and forget
    debugPrint('🗑️ Cache invalidated: $key');
  }

  void invalidateMultiple(List<String> keys) {
    for (final key in keys) {
      _mem.remove(key);
      _disk.remove(key);
    }
    debugPrint('🗑️ Cache invalidated: ${keys.join(', ')}');
  }

  void clear() {
    _mem.clear();
    _disk.clearAll();
    debugPrint('🧹 Cache cleared (L1 + L2)');
  }

  bool has(String key) {
    final entry = _mem[key];
    return entry != null && !entry.isExpired;
  }

  Map<String, dynamic> getStats() {
    final total   = _mem.length;
    final expired = _mem.values.where((e) => e.isExpired).length;
    return {'total': total, 'valid': total - expired, 'expired': expired};
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime createdAt;

  _CacheEntry({required this.data, required this.expiresAt})
      : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get age => DateTime.now().difference(createdAt);
}

/// Cache keys for different endpoints
class CacheKeys {
  static const String reminders         = 'reminders';
  static const String events            = 'events';
  static const String gatherings        = 'gatherings';
  static const String audios            = 'audios';
  static const String quotes            = 'quotes';
  static const String profile           = 'profile';
  static const String presetReminders   = 'preset_reminders';
  static const String levelAccess       = 'level_access';
  static const String meditationSounds  = 'meditation_sounds';

  static String classesDay(String language, int day) =>
      'classes_${language}_day_$day';
  static String classesAll(String language) => 'classes_$language';
}
