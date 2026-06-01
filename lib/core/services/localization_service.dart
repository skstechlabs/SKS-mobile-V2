import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  final ApiService _apiService = ApiService();
  
  Locale _currentLocale = const Locale('en');
  Map<String, String> _localizedStrings = {};
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('te'), // Telugu
  ];

  // Language names for display
  static const Map<String, String> languageNames = {
    'en': 'English',
    'te': 'తెలుగు (Telugu)',
  };

  /// Initialize localization service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️  LocalizationService already initialized');
      return;
    }
    
    try {
      debugPrint('🌐 Initializing LocalizationService...');
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      debugPrint('📱 Saved language from prefs: $savedLanguage');
      
      final languageToLoad = savedLanguage ?? _defaultLanguage;
      debugPrint('🔄 Loading language: $languageToLoad');
      
      await changeLanguage(languageToLoad, savePreference: false);
      _isInitialized = true;
      debugPrint('✅ LocalizationService initialized successfully with language: $languageToLoad');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing localization: $e');
      debugPrint('Stack trace: $stackTrace');
      // Load default language
      try {
        await _loadLanguage(_defaultLanguage);
        _currentLocale = Locale(_defaultLanguage);
        _isInitialized = true;
        debugPrint('✅ Fallback to default language: $_defaultLanguage');
      } catch (fallbackError) {
        debugPrint('❌ Even fallback failed: $fallbackError');
        _isInitialized = true; // Mark as initialized anyway to not block app
      }
    }
  }

  /// Change app language
  Future<void> changeLanguage(String languageCode, {bool savePreference = true}) async {
    try {
      // Validate language code
      if (!supportedLocales.any((locale) => locale.languageCode == languageCode)) {
        debugPrint('⚠️  Unsupported language: $languageCode, using default');
        languageCode = _defaultLanguage;
      }

      await _loadLanguage(languageCode);
      _currentLocale = Locale(languageCode);

      if (savePreference) {
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
        
        // Sync with backend API
        try {
          debugPrint('🌐 Syncing language preference with backend: $languageCode');
          final response = await _apiService.setUserLanguage(languageCode);
          if (response['success'] == true) {
            debugPrint('✅ Language preference synced with backend');
          } else {
            debugPrint('⚠️ Failed to sync language with backend: ${response['message']}');
          }
        } catch (e) {
          debugPrint('⚠️ Error syncing language with backend (non-critical): $e');
          // Don't fail the language change if backend sync fails
        }
      }

      notifyListeners();
      debugPrint('✅ Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }

  /// Load language translations from JSON file
  Future<void> _loadLanguage(String languageCode) async {
    try {
      debugPrint('📂 Loading translation file: assets/translations/$languageCode.json');
      final jsonString = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      debugPrint('✅ Translation file loaded, parsing JSON...');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      debugPrint('✅ Loaded ${_localizedStrings.length} translation keys for $languageCode');
      
      // Debug: Print first few keys
      if (_localizedStrings.isNotEmpty) {
        final firstKeys = _localizedStrings.keys.take(5).toList();
        debugPrint('📝 Sample keys: $firstKeys');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading language file for $languageCode: $e');
      debugPrint('Stack trace: $stackTrace');
      // If loading fails, try to load default language
      if (languageCode != _defaultLanguage) {
        debugPrint('🔄 Attempting to load default language: $_defaultLanguage');
        await _loadLanguage(_defaultLanguage);
      } else {
        debugPrint('❌ Failed to load even default language!');
      }
    }
  }

  /// Get translated string by key
  String translate(String key) {
    final translation = _localizedStrings[key];
    if (translation == null) {
      debugPrint('⚠️  Missing translation for key: $key');
      return key; // Return key if translation not found
    }
    return translation;
  }

  /// Get saved language code
  static Future<String?> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      debugPrint('❌ Error getting saved language: $e');
      return null;
    }
  }

  /// Check if language is selected (for first-time setup)
  static Future<bool> isLanguageSelected() async {
    final savedLanguage = await getSavedLanguage();
    return savedLanguage != null;
  }
}

/// Extension for easy access to translations
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return LocalizationService().translate(key);
  }
  
  LocalizationService get localization => LocalizationService();
}
