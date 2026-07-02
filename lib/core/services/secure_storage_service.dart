import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure Storage Service for sensitive data (tokens, credentials).
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android).
///
/// Android fallback: Some devices (especially after a factory-reset of the
/// secure enclave or on older Android versions) have a broken KeyStore that
/// silently returns null for reads even though writes appeared to succeed.
/// We detect this with a round-trip probe and fall back to unencrypted
/// SharedPreferences in that case. Tokens are still transmitted over TLS,
/// so the security posture is the same as every other mobile app that uses
/// SharedPreferences for session tokens.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  FlutterSecureStorage? _storage;
  bool _encryptedStorageWorking = true; // assume working until proven otherwise

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userUidKey = 'user_uid';

  // Probe key used to verify the encrypted storage is functional
  static const String _probeKey = '_probe_check';
  static const String _probeValue = 'ok';

  FlutterSecureStorage get _encryptedStore {
    _storage ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    return _storage!;
  }

  /// Fallback: plain FlutterSecureStorage without encrypted SharedPreferences.
  /// Used when the encrypted variant is broken on the device.
  static const FlutterSecureStorage _plainStore = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  FlutterSecureStorage get _store =>
      _encryptedStorageWorking ? _encryptedStore : _plainStore;

  void initialize() {
    final _ = _encryptedStore;
    _verifyStorageWorks();
    debugPrint('✅ SecureStorageService ready');
  }

  /// Write a probe value and read it back. If the round-trip fails, mark
  /// encrypted storage as broken and switch to the plain fallback.
  Future<void> _verifyStorageWorks() async {
    if (!_encryptedStorageWorking) return;
    try {
      await _encryptedStore.write(key: _probeKey, value: _probeValue);
      final readBack = await _encryptedStore.read(key: _probeKey);
      if (readBack != _probeValue) {
        debugPrint('⚠️ SecureStorage encrypted round-trip failed — using plain fallback');
        _encryptedStorageWorking = false;
        // Migrate any existing tokens to plain store
        await _migrateToPlainStore();
      } else {
        debugPrint('✅ SecureStorage encrypted round-trip OK');
      }
    } catch (e) {
      debugPrint('⚠️ SecureStorage probe error ($e) — using plain fallback');
      _encryptedStorageWorking = false;
      try {
        await _migrateToPlainStore();
      } catch (_) {}
    }
  }

  Future<void> _migrateToPlainStore() async {
    try {
      // Try to copy tokens from encrypted to plain store before encrypted breaks
      final keys = [_accessTokenKey, _refreshTokenKey, _tokenExpiryKey, _userUidKey];
      for (final key in keys) {
        try {
          final val = await _encryptedStore.read(key: key);
          if (val != null && val.isNotEmpty) {
            await _plainStore.write(key: key, value: val);
            debugPrint('  ↳ Migrated $key to plain store');
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ Migration to plain store failed: $e');
    }
  }

  // ── Access Token ──────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    try {
      await _store.write(key: _accessTokenKey, value: token);
    } catch (e) {
      debugPrint('❌ Error saving access token: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _store.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading access token: $e');
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    try {
      await _store.delete(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Error deleting access token: $e');
    }
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    try {
      await _store.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      debugPrint('❌ Error saving refresh token: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _store.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading refresh token: $e');
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _store.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error deleting refresh token: $e');
    }
  }

  // ── Token Expiry ──────────────────────────────────────────────────────────

  Future<void> saveTokenExpiry(DateTime expiry) async {
    try {
      await _store.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
    } catch (e) {
      debugPrint('❌ Error saving token expiry: $e');
    }
  }

  Future<DateTime?> getTokenExpiry() async {
    try {
      final s = await _store.read(key: _tokenExpiryKey);
      return s != null ? DateTime.parse(s) : null;
    } catch (e) {
      debugPrint('❌ Error reading token expiry: $e');
      return null;
    }
  }

  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    // 5-minute safety margin before actual expiry
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  // ── User UID ──────────────────────────────────────────────────────────────

  Future<void> saveUserUid(String uid) async {
    try {
      await _store.write(key: _userUidKey, value: uid);
    } catch (e) {
      debugPrint('❌ Error saving user UID: $e');
    }
  }

  Future<String?> getUserUid() async {
    try {
      return await _store.read(key: _userUidKey);
    } catch (e) {
      debugPrint('❌ Error reading user UID: $e');
      return null;
    }
  }

  // ── Token Pair ────────────────────────────────────────────────────────────

  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));
    await saveTokenExpiry(expiry);
    debugPrint('✅ JWT token pair saved (expires in ${expiresIn}s)');
  }

  Future<Map<String, String?>> getTokenPair() async {
    return {
      'accessToken': await getAccessToken(),
      'refreshToken': await getRefreshToken(),
    };
  }

  // ── Clear All ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    try {
      // Clear from both stores to be safe
      await _encryptedStore.deleteAll();
    } catch (e) {
      debugPrint('⚠️ Encrypted store clear error: $e');
    }
    try {
      await _plainStore.deleteAll();
    } catch (e) {
      debugPrint('⚠️ Plain store clear error: $e');
    }
    debugPrint('✅ All secure storage cleared');
  }
}
