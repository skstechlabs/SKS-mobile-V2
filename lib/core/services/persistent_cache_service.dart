import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent disk cache using SharedPreferences.
///
/// Unlike [DataCacheService] (in-memory, lost on restart), this cache
/// survives app restarts and works offline. It is the foundation of the
/// "always show content" strategy:
///
///   1. Return disk cache immediately (zero latency, works offline)
///   2. Fetch fresh data from network in background
///   3. Update UI and disk cache silently when fresh data arrives
///
/// TTL default is 24 hours — stale content is better than a spinner.
/// For critical content (quotes, events) even older data is fine.
class PersistentCacheService {
  static final PersistentCacheService _instance =
      PersistentCacheService._internal();
  factory PersistentCacheService() => _instance;
  PersistentCacheService._internal();

  static const String _keyPrefix = 'pcache_v1_';
  static const String _metaPrefix = 'pcache_meta_v1_';
  static const Duration _defaultTtl = Duration(hours: 24);

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Write ────────────────────────────────────────────────────────────────

  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = _defaultTtl,
  }) async {
    try {
      final store = await _store;
      final encoded = jsonEncode(data);
      final expiresAt =
          DateTime.now().add(ttl).millisecondsSinceEpoch;
      await store.setString(_keyPrefix + key, encoded);
      await store.setInt(_metaPrefix + key, expiresAt);
    } catch (e) {
      debugPrint('⚠️ PersistentCache set error for "$key": $e');
    }
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Returns cached data if present, regardless of TTL (stale-ok read).
  /// Caller decides whether to also trigger a background refresh.
  Future<Map<String, dynamic>?> get(String key) async {
    try {
      final store = await _store;
      final raw = store.getString(_keyPrefix + key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ PersistentCache get error for "$key": $e');
      return null;
    }
  }

  /// Returns cached data only if it's still within TTL (fresh read).
  Future<Map<String, dynamic>?> getFresh(String key) async {
    try {
      final store = await _store;
      final expiresAt = store.getInt(_metaPrefix + key);
      if (expiresAt == null) return null;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return null; // stale
      }
      final raw = store.getString(_keyPrefix + key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ PersistentCache getFresh error for "$key": $e');
      return null;
    }
  }

  /// True if key exists (even if stale).
  Future<bool> has(String key) async {
    final store = await _store;
    return store.containsKey(_keyPrefix + key);
  }

  /// True if key exists AND is within TTL.
  Future<bool> isFresh(String key) async {
    final store = await _store;
    final expiresAt = store.getInt(_metaPrefix + key);
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch <= expiresAt;
  }

  /// How old is the cached entry (null if not present).
  Future<Duration?> age(String key) async {
    try {
      final store = await _store;
      final expiresAt = store.getInt(_metaPrefix + key);
      if (expiresAt == null) return null;
      // We stored expiresAt, not createdAt — approximate age from TTL
      // (good enough for logging / UI decisions)
      final defaultTtlMs = _defaultTtl.inMilliseconds;
      final createdAt = expiresAt - defaultTtlMs;
      return Duration(
          milliseconds: DateTime.now().millisecondsSinceEpoch - createdAt);
    } catch (_) {
      return null;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> remove(String key) async {
    try {
      final store = await _store;
      await store.remove(_keyPrefix + key);
      await store.remove(_metaPrefix + key);
    } catch (e) {
      debugPrint('⚠️ PersistentCache remove error for "$key": $e');
    }
  }

  /// Remove all persistent cache entries (keeps other SharedPreferences).
  Future<void> clearAll() async {
    try {
      final store = await _store;
      final keys = store.getKeys()
          .where((k) => k.startsWith(_keyPrefix) || k.startsWith(_metaPrefix))
          .toList();
      for (final k in keys) {
        await store.remove(k);
      }
      debugPrint('🧹 PersistentCache cleared (${keys.length} entries)');
    } catch (e) {
      debugPrint('⚠️ PersistentCache clearAll error: $e');
    }
  }
}
