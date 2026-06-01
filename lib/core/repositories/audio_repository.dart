import 'package:flutter/foundation.dart';
import '../models/audio_model.dart';
import '../services/api_service.dart';

class AudioRepository {
  final ApiService _apiService;

  AudioRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Fetch all audio files
  Future<List<AudioModel>> fetchAllAudios() async {
    try {
      final response = await _apiService.get('/api/audios');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> audioList = response['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching audios: $e');
      return [];
    }
  }

  // Fetch audios by category
  Future<List<AudioModel>> fetchAudiosByCategory(String category) async {
    try {
      final response = await _apiService.get('/api/audios/category/$category');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> audioList = response['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching audios by category: $e');
      return [];
    }
  }

  // Fetch meditation music
  Future<List<AudioModel>> fetchMeditationMusic() async {
    return fetchAudiosByCategory('meditation');
  }

  // Fetch bhajans
  Future<List<AudioModel>> fetchBhajans() async {
    return fetchAudiosByCategory('bhajan');
  }

  // Fetch chants
  Future<List<AudioModel>> fetchChants() async {
    return fetchAudiosByCategory('chant');
  }

  // Fetch single audio by ID
  Future<AudioModel?> fetchAudioById(int id) async {
    try {
      final response = await _apiService.get('/api/audios/$id');
      
      if (response['success'] == true && response['data'] != null) {
        return AudioModel.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching audio by ID: $e');
      return null;
    }
  }

  // Search audios
  Future<List<AudioModel>> searchAudios(String query) async {
    try {
      final response = await _apiService.get(
        '/api/audios/search',
        queryParameters: {'q': query},
      );
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> audioList = response['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error searching audios: $e');
      return [];
    }
  }

  // Fetch audios by language
  Future<List<AudioModel>> fetchAudiosByLanguage(String language) async {
    try {
      final response = await _apiService.get('/api/audios/language/$language');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> audioList = response['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching audios by language: $e');
      return [];
    }
  }

  // Increment play count (analytics) - No authentication required
  Future<void> incrementPlayCount(int audioId) async {
    try {
      await _apiService.post('/api/audios/$audioId/play', {});
    } catch (e) {
      debugPrint('Error incrementing play count: $e');
    }
  }

  // Fetch popular audios
  Future<List<AudioModel>> fetchPopularAudios({int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '/api/audios/popular',
        queryParameters: {'limit': limit.toString()},
      );
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> audioList = response['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching popular audios: $e');
      return [];
    }
  }
}
