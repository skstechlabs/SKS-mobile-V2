import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
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

  // Prevents concurrent initialize() calls from double-loading translations.
  Completer<void>? _initCompleter;

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('te'),
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'te': 'తెలుగు (Telugu)',
  };

  /// Initialize localization service.
  /// Safe to call multiple times and from multiple callers concurrently —
  /// only one load is ever performed; subsequent callers await the same future.
  Future<void> initialize() async {
    // Already loaded with non-empty strings → nothing to do.
    if (_isInitialized && _localizedStrings.isNotEmpty) {
      return;
    }

    // Another call is already in progress → await it rather than double-loading.
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    _isInitialized = false;

    try {
      debugPrint('🌐 LocalizationService: loading translations...');
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_languageKey) ?? _defaultLanguage;
      debugPrint('📱 Saved language: $saved');

      await _loadLanguage(saved);
      _currentLocale = Locale(saved);
      _isInitialized = true;
      debugPrint('✅ LocalizationService ready with ${ _localizedStrings.length} keys (lang=$saved)');
      _initCompleter!.complete();
    } catch (e, st) {
      debugPrint('❌ LocalizationService init error: $e\n$st');
      // Hard fallback — try English
      try {
        await _loadLanguage(_defaultLanguage);
        _currentLocale = const Locale(_defaultLanguage);
      } catch (_) {
        // Even fallback failed; _localizedStrings remains empty,
        // translate() will return keys which is visible but not a crash.
      }
      _isInitialized = true;
      _initCompleter!.complete();
    } finally {
      // Allow future calls to re-initialize if strings are still empty.
      // (e.g. rootBundle wasn't ready on first try)
      if (_localizedStrings.isEmpty) {
        _initCompleter = null;
        _isInitialized = false;
      }
    }
  }

  /// Change app language.
  Future<void> changeLanguage(String languageCode,
      {bool savePreference = true}) async {
    if (!supportedLocales.any((l) => l.languageCode == languageCode)) {
      debugPrint('⚠️ Unsupported language: $languageCode, using default');
      languageCode = _defaultLanguage;
    }

    try {
      await _loadLanguage(languageCode);
      _currentLocale = Locale(languageCode);

      if (savePreference) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);

        // Sync with backend — fire and forget, never block UI.
        _apiService.setUserLanguage(languageCode).then((r) {
          debugPrint(r['success'] == true
              ? '✅ Language synced with backend'
              : '⚠️ Language backend sync: ${r['message']}');
        }).catchError((e) {
          debugPrint('⚠️ Language backend sync failed (non-critical): $e');
        });
      }

      notifyListeners();
      debugPrint('✅ Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }

  Future<void> _loadLanguage(String languageCode) async {
    try {
      debugPrint('📂 Loading translation: assets/translations/$languageCode.json');
      final jsonString =
          await rootBundle.loadString('assets/translations/$languageCode.json');
      final Map<String, dynamic> map = json.decode(jsonString);
      _localizedStrings = map.map((k, v) => MapEntry(k, v.toString()));
      debugPrint('✅ Loaded ${_localizedStrings.length} keys for $languageCode');
    } catch (e, st) {
      debugPrint('❌ Failed loading $languageCode.json: $e\n$st');
      if (languageCode != _defaultLanguage) {
        debugPrint('🔄 Falling back to default language');
        await _loadLanguage(_defaultLanguage);
      }
    }
  }

  /// Merge extra key-value pairs into the currently loaded strings.
  /// Use this to inject keys that exist in the JSON but are not yet in the
  /// cached rootBundle (e.g. keys added since the last full build).
  /// Existing keys are NOT overwritten — live bundle values take priority.
  void patchStrings(Map<String, String> extras) {
    for (final entry in extras.entries) {
      _localizedStrings.putIfAbsent(entry.key, () => entry.value);
    }
  }

  String translate(String key) {
    if (!_isInitialized || _localizedStrings.isEmpty) return key;
    final t = _localizedStrings[key];
    if (t == null && kDebugMode) {
      debugPrint('⚠️ Missing translation: $key');
    }
    return t ?? key;
  }

  static Future<String?> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isLanguageSelected() async {
    final lang = await getSavedLanguage();
    return lang != null;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) => LocalizationService().translate(key);
  LocalizationService get localization => LocalizationService();
}
