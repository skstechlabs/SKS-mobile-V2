import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure Storage Service for sensitive data (tokens, credentials).
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android).
///
/// Design notes:
/// - The FlutterSecureStorage instance is created lazily via a getter so that
///   calling initialize() multiple times (warm restart) is safe — it is a no-op
///   after the first call and never throws LateInitializationError.
/// - All methods are safe to call even before explicit initialize().
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Nullable, not late final — avoids LateInitializationError on warm restart
  // when initialize() is called again after the singleton already has a value.
  FlutterSecureStorage? _storage;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userUidKey = 'user_uid';

  /// Returns the storage instance, creating it if needed.
  /// This is the single place where FlutterSecureStorage is constructed.
  FlutterSecureStorage get _store {
    _storage ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    return _storage!;
  }

  /// Initialize the service. Safe to call multiple times — subsequent calls
  /// are no-ops. Keeping this method so existing call sites don't need changing.
  void initialize() {
    // Trigger lazy creation of _storage via the getter — idempotent.
    final _ = _store;
    debugPrint('✅ SecureStorageService ready');
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
    // Treat as expired 5 minutes before actual expiry for safety margin
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
      await _store.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Error clearing secure storage: $e');
    }
  }
}
