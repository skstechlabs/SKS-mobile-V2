import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'localization_service.dart';

/// Service to manage quotes with caching and language support
class QuotesService {
  static final QuotesService _instance = QuotesService._internal();
  factory QuotesService() => _instance;
  QuotesService._internal();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _cachedQuotes = [];
  String _cachedLanguage = '';
  static const String _quotesKey = 'cached_quotes';
  static const String _quotesFetchTimeKey = 'quotes_last_fetch';
  static const String _quotesLanguageKey = 'quotes_language';
  static const int _cacheExpiryHours = 24;

  /// Get quotes for current language with caching
  /// - Loads from cache if available and not expired
  /// - Fetches from API on language change or cache miss
  /// - Auto-refreshes in background if cache is stale
  Future<List<Map<String, dynamic>>> getQuotes({bool forceRefresh = false}) async {
    try {
      // Get current language
      final currentLocale = LocalizationService().currentLocale;
      final languageCode = currentLocale.languageCode;
      
      // Map language code to database language
      final languageMap = {
        'en': 'english',
        'hi': 'hindi',
        'te': 'telugu',
        'kn': 'kannada',
      };
      
      final dbLanguage = languageMap[languageCode] ?? 'english';
      
      debugPrint('[QuotesService] Getting quotes for language: $dbLanguage (code: $languageCode)');
      
      // Check if language changed
      final languageChanged = _cachedLanguage != dbLanguage;
      
      if (languageChanged) {
        debugPrint('[QuotesService] Language changed from $_cachedLanguage to $dbLanguage, fetching new quotes');
        forceRefresh = true;
      }
      
      // Try to load from cache first (if not force refresh and language hasn't changed)
      if (!forceRefresh && !languageChanged && _cachedQuotes.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastFetch = prefs.getInt(_quotesFetchTimeKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final hoursSinceLastFetch = (now - lastFetch) / (1000 * 60 * 60);
        
        if (hoursSinceLastFetch < _cacheExpiryHours) {
          debugPrint('[QuotesService] Using cached quotes (${hoursSinceLastFetch.toStringAsFixed(1)} hours old)');
          return _cachedQuotes;
        } else {
          debugPrint('[QuotesService] Cache expired (${hoursSinceLastFetch.toStringAsFixed(1)} hours old), fetching fresh quotes');
        }
      }
      
      // Fetch from API
      debugPrint('[QuotesService] Fetching quotes from API for language: $dbLanguage');
      final response = await _apiService.get(
        '/api/quotes',
        queryParameters: {'language': dbLanguage},
      );
      
      if (response['success'] == true && response['quotes'] != null) {
        final quotes = List<Map<String, dynamic>>.from(response['quotes']);
        
        if (quotes.isNotEmpty) {
          // Update memory cache
          _cachedQuotes = quotes;
          _cachedLanguage = dbLanguage;
          
          // Save to persistent storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_quotesKey, json.encode(quotes));
          await prefs.setInt(_quotesFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
          await prefs.setString(_quotesLanguageKey, dbLanguage);
          
          debugPrint('[QuotesService] ✅ Cached ${quotes.length} quotes for $dbLanguage');
          return quotes;
        }
      }
      
      // If API fails, try to load from persistent cache
      debugPrint('[QuotesService] API failed or returned no quotes, checking persistent cache');
      return await _loadFromPersistentCache(dbLanguage);
      
    } catch (e, stackTrace) {
      debugPrint('[QuotesService] Error fetching quotes: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Try to load from persistent cache
      final currentLocale = LocalizationService().currentLocale;
      final languageCode = currentLocale.languageCode;
      final languageMap = {
        'en': 'english',
        'hi': 'hindi',
        'te': 'telugu',
        'kn': 'kannada',
      };
      final dbLanguage = languageMap[languageCode] ?? 'english';
      
      return await _loadFromPersistentCache(dbLanguage);
    }
  }
  
  /// Load quotes from persistent storage
  Future<List<Map<String, dynamic>>> _loadFromPersistentCache(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLanguage = prefs.getString(_quotesLanguageKey) ?? '';
      
      // Only use cache if language matches
      if (cachedLanguage == language) {
        final cachedData = prefs.getString(_quotesKey);
        if (cachedData != null) {
          final quotes = List<Map<String, dynamic>>.from(json.decode(cachedData));
          debugPrint('[QuotesService] ✅ Loaded ${quotes.length} quotes from persistent cache');
          _cachedQuotes = quotes;
          _cachedLanguage = language;
          return quotes;
        }
      } else {
        debugPrint('[QuotesService] ⚠️ Cached language ($cachedLanguage) != requested language ($language)');
      }
    } catch (e) {
      debugPrint('[QuotesService] Error loading from persistent cache: $e');
    }
    
    debugPrint('[QuotesService] ⚠️ No cached quotes available');
    return [];
  }
  
  /// Get a random quote for current language
  Future<Map<String, dynamic>?> getRandomQuote() async {
    try {
      final quotes = await getQuotes();
      if (quotes.isEmpty) return null;
      
      final randomIndex = DateTime.now().millisecondsSinceEpoch % quotes.length;
      return quotes[randomIndex];
    } catch (e) {
      debugPrint('[QuotesService] Error getting random quote: $e');
      return null;
    }
  }
  
  /// Clear quotes cache (useful when language changes or for manual refresh)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quotesKey);
      await prefs.remove(_quotesFetchTimeKey);
      await prefs.remove(_quotesLanguageKey);
      _cachedQuotes = [];
      _cachedLanguage = '';
      debugPrint('[QuotesService] ✅ Cache cleared');
    } catch (e) {
      debugPrint('[QuotesService] Error clearing cache: $e');
    }
  }
  
  /// Refresh quotes from API (bypasses cache)
  Future<List<Map<String, dynamic>>> refreshQuotes() async {
    debugPrint('[QuotesService] Force refreshing quotes');
    return await getQuotes(forceRefresh: true);
  }
}
