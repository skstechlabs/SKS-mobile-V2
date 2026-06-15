import 'package:flutter/foundation.dart';
import '../models/audio_model.dart';
import '../repositories/audio_repository.dart';
import '../services/enhanced_audio_player_service.dart';

/// Provider for managing audio data fetched from API
/// Replaces static AppConstants.bhajans and AppConstants.meditationMusic
class AudioProvider extends ChangeNotifier {
  final AudioRepository _repository = AudioRepository();
  final EnhancedAudioPlayerService _playerService = EnhancedAudioPlayerService();
  
  List<AudioModel> _allAudios = [];
  List<AudioModel> _bhajans = [];
  List<AudioModel> _meditations = [];
  List<AudioModel> _ringtones = [];
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  DateTime? _lastFetchTime;
  
  // Getters
  List<AudioModel> get allAudios => _allAudios;
  List<AudioModel> get bhajans => _bhajans;
  List<AudioModel> get meditations => _meditations;
  List<AudioModel> get ringtones => _ringtones;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  
  /// Initialize provider and fetch audio data
  Future<void> initialize() async {
    if (_isInitialized) {
      // Check if we need to refresh (e.g., every 6 hours)
      if (_lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!).inHours < 6) {
        debugPrint('[AudioProvider] Using cached data');
        return;
      }
    }
    
    await fetchAllAudios();
  }
  
  /// Fetch all audios from API
  Future<void> fetchAllAudios({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('[AudioProvider] Fetching audios from API...');
      
      final audios = await _repository.fetchAllAudios(forceRefresh: forceRefresh);
      
      if (audios.isNotEmpty) {
        _allAudios = audios;
        
        // Categorize audios
        _bhajans = audios.where((a) => a.category == 'bhajan').toList();
        _meditations = audios.where((a) => a.category == 'meditation').toList();
        _ringtones = audios.where((a) => a.category == 'ringtone').toList();
        
        _isInitialized = true;
        _lastFetchTime = DateTime.now();
        
        debugPrint('[AudioProvider] Fetched ${audios.length} audios');
        debugPrint('[AudioProvider] - Bhajans: ${_bhajans.length}');
        debugPrint('[AudioProvider] - Meditations: ${_meditations.length}');
        debugPrint('[AudioProvider] - Ringtones: ${_ringtones.length}');
      } else {
        _error = 'No audio files found. Please check your connection.';
        debugPrint('[AudioProvider] No audios found');
      }
    } catch (e) {
      _error = 'Failed to load audio files: ${e.toString()}';
      debugPrint('[AudioProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch audios by category
  Future<List<AudioModel>> fetchByCategory(String category) async {
    try {
      debugPrint('[AudioProvider] Fetching category: $category');
      return await _repository.fetchAudiosByCategory(category);
    } catch (e) {
      debugPrint('[AudioProvider] Error fetching category: $e');
      return [];
    }
  }
  
  /// Fetch audios by language
  Future<List<AudioModel>> fetchByLanguage(String language) async {
    try {
      debugPrint('[AudioProvider] Fetching language: $language');
      return await _repository.fetchAudiosByLanguage(language);
    } catch (e) {
      debugPrint('[AudioProvider] Error fetching language: $e');
      return [];
    }
  }
  
  /// Search audios
  Future<List<AudioModel>> search(String query) async {
    try {
      debugPrint('[AudioProvider] Searching: $query');
      return await _repository.searchAudios(query);
    } catch (e) {
      debugPrint('[AudioProvider] Error searching: $e');
      return [];
    }
  }
  
  /// Get popular audios
  Future<List<AudioModel>> getPopular({int limit = 10}) async {
    try {
      debugPrint('[AudioProvider] Fetching popular audios');
      return await _repository.fetchPopularAudios(limit: limit);
    } catch (e) {
      debugPrint('[AudioProvider] Error fetching popular: $e');
      return [];
    }
  }
  
  /// Play audio with enhanced player
  Future<void> playAudio(List<AudioModel> playlist, int index) async {
    try {
      await _playerService.playSong(playlist, index);
      
      // Track play count
      if (index >= 0 && index < playlist.length) {
        final audio = playlist[index];
        _repository.incrementPlayCount(audio.id).catchError((e) {
          debugPrint('[AudioProvider] Error tracking play count: $e');
        });
      }
    } catch (e) {
      debugPrint('[AudioProvider] Error playing audio: $e');
      rethrow;
    }
  }
  
  /// Get audio by ID
  Future<AudioModel?> getAudioById(int id) async {
    try {
      return await _repository.fetchAudioById(id);
    } catch (e) {
      debugPrint('[AudioProvider] Error fetching audio by ID: $e');
      return null;
    }
  }
  
  /// Clear cache and force refresh
  Future<void> refreshAudios() async {
    _isInitialized = false;
    _lastFetchTime = null;
    await fetchAllAudios(forceRefresh: true);
  }
  
  /// Preload playlist for offline access
  Future<void> preloadPlaylist(List<AudioModel> playlist) async {
    try {
      debugPrint('[AudioProvider] Preloading ${playlist.length} audios...');
      // Set playlist first, then preload
      await _playerService.playSong(playlist, 0);
      await _playerService.pause();
      await _playerService.preloadPlaylist();
      debugPrint('[AudioProvider] Preload completed');
    } catch (e) {
      debugPrint('[AudioProvider] Error preloading: $e');
    }
  }
  
  /// Get cache status
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final cacheSize = await _playerService.getCacheSize();
      // Count cached files - note: this is an approximation
      final cachedCount = 0; // Would need to implement proper cache checking
      
      return {
        'size': cacheSize,
        'count': cachedCount,
        'total': _allAudios.length,
      };
    } catch (e) {
      debugPrint('[AudioProvider] Error getting cache info: $e');
      return {'size': '0 B', 'count': 0, 'total': _allAudios.length};
    }
  }
  
  /// Clear audio cache
  Future<void> clearCache() async {
    try {
      await _playerService.clearAllCache();
      debugPrint('[AudioProvider] Cache cleared');
    } catch (e) {
      debugPrint('[AudioProvider] Error clearing cache: $e');
    }
  }
}
