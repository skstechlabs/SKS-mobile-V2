import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user_model.dart';

class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  static const String _userKey = 'cached_user_data';
  static const String _authTokenKey = 'cached_auth_token';
  
  UserModel? _user;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  String? get uid => _user?.uid;
  String? get mobile => _user?.mobile;
  bool get isProfileComplete => _user?.isProfileComplete ?? false;

  /// Initialize auth state from cache
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔐 Initializing AuthState from cache...');
      final prefs = await SharedPreferences.getInstance();
      
      // Load cached user data
      final userJson = prefs.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userData = json.decode(userJson) as Map<String, dynamic>;
          _user = UserModel.fromJson(userData);
          debugPrint('✅ Loaded cached user: ${_user!.uid}');
        } catch (e) {
          debugPrint('❌ Error parsing cached user data: $e');
          // Clear corrupted cache
          await prefs.remove(_userKey);
        }
      } else {
        debugPrint('ℹ️  No cached user data found');
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing AuthState: $e');
      _isInitialized = true;
    }
  }

  /// Set user and persist to cache
  Future<void> setUser(UserModel user) async {
    _user = user;
    await _persistUser();
    notifyListeners();
  }

  /// Update profile and persist to cache
  Future<void> updateProfile(UserModel updated) async {
    _user = updated;
    await _persistUser();
    notifyListeners();
  }

  /// Persist user data to SharedPreferences
  Future<void> _persistUser() async {
    try {
      if (_user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(_user!.toJson());
      await prefs.setString(_userKey, userJson);
      debugPrint('✅ User data cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching user data: $e');
    }
  }

  /// Keep for backward compat
  void loginWithMobile(String mobile) {
    _user = UserModel(uid: '', mobile: mobile, authProvider: 'phone');
    _persistUser();
    notifyListeners();
  }

  /// Logout and clear cache
  Future<void> logout() async {
    _user = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authTokenKey);
      debugPrint('✅ User cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
    }
    
    notifyListeners();
  }

  /// Clear all cached data (for testing or troubleshooting)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authTokenKey);
      debugPrint('✅ All auth cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
}
