import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure Storage Service for sensitive data (tokens, credentials)
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  late final FlutterSecureStorage _storage;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userUidKey = 'user_uid';

  void initialize() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  // ── Access Token Management ────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      debugPrint('✅ Access token saved securely');
    } catch (e) {
      debugPrint('❌ Error saving access token: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading access token: $e');
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Error deleting access token: $e');
    }
  }

  // ── Refresh Token Management (90-day session) ──────────────────────────────

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      debugPrint('✅ Refresh token saved securely');
    } catch (e) {
      debugPrint('❌ Error saving refresh token: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error reading refresh token: $e');
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error deleting refresh token: $e');
    }
  }

  // ── Token Expiry Management ────────────────────────────────────────────────

  Future<void> saveTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
    } catch (e) {
      debugPrint('❌ Error saving token expiry: $e');
    }
  }

  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        return DateTime.parse(expiryStr);
      }
    } catch (e) {
      debugPrint('❌ Error reading token expiry: $e');
    }
    return null;
  }

  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    
    // Consider token expired if less than 5 minutes remaining
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  // ── User UID Management ────────────────────────────────────────────────────

  Future<void> saveUserUid(String uid) async {
    try {
      await _storage.write(key: _userUidKey, value: uid);
    } catch (e) {
      debugPrint('❌ Error saving user UID: $e');
    }
  }

  Future<String?> getUserUid() async {
    try {
      return await _storage.read(key: _userUidKey);
    } catch (e) {
      debugPrint('❌ Error reading user UID: $e');
      return null;
    }
  }

  // ── Clear All Secure Data ──────────────────────────────────────────────────

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Error clearing secure storage: $e');
    }
  }

  // ── Token Pair Management ──────────────────────────────────────────────────

  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));
    await saveTokenExpiry(expiry);
  }

  Future<Map<String, String?>> getTokenPair() async {
    return {
      'accessToken': await getAccessToken(),
      'refreshToken': await getRefreshToken(),
    };
  }
}
