import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/audio_model.dart';
import '../constants/app_env.dart';

class AudioRepository {
  late final Dio _dio;

  AudioRepository() {
    // Initialize Dio for public API calls (no authentication)
    String baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
        ? AppEnv.apiBaseUrl 
        : 'https://app.sivakundalini.org';
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // SSL certificate handling for Let's Encrypt certificates
    // Only for mobile/desktop platforms (not web)
    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Allow Let's Encrypt certificates for our domain
          if (host == 'app.sivakundalini.org') {
            return true;
          }
          return false;
        };
        return client;
      };
    }

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint('[AudioRepository] $obj'),
    ));
  }

  // Fetch all audio files (PUBLIC - no auth required)
  Future<List<AudioModel>> fetchAllAudios() async {
    try {
      debugPrint('[AudioRepository] Fetching all audios from /api/audios');
      final response = await _dio.get('/api/audios');
      
      debugPrint('[AudioRepository] Response status: ${response.statusCode}');
      debugPrint('[AudioRepository] Response data: ${response.data}');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> audioList = response.data['data'] as List<dynamic>;
        debugPrint('[AudioRepository] Found ${audioList.length} audios');
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      debugPrint('[AudioRepository] No audios found or invalid response');
      return [];
    } catch (e) {
      debugPrint('[AudioRepository] Error fetching audios: $e');
      return [];
    }
  }

  // Fetch audios by category (PUBLIC - no auth required)
  Future<List<AudioModel>> fetchAudiosByCategory(String category) async {
    try {
      debugPrint('[AudioRepository] Fetching audios for category: $category');
      final response = await _dio.get('/api/audios/category/$category');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> audioList = response.data['data'] as List<dynamic>;
        debugPrint('[AudioRepository] Found ${audioList.length} audios in category $category');
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('[AudioRepository] Error fetching audios by category: $e');
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

  // Fetch single audio by ID (PUBLIC - no auth required)
  Future<AudioModel?> fetchAudioById(int id) async {
    try {
      final response = await _dio.get('/api/audios/$id');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        return AudioModel.fromJson(response.data['data']);
      }
      
      return null;
    } catch (e) {
      debugPrint('[AudioRepository] Error fetching audio by ID: $e');
      return null;
    }
  }

  // Search audios (PUBLIC - no auth required)
  Future<List<AudioModel>> searchAudios(String query) async {
    try {
      final response = await _dio.get(
        '/api/audios/search',
        queryParameters: {'q': query},
      );
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> audioList = response.data['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('[AudioRepository] Error searching audios: $e');
      return [];
    }
  }

  // Fetch audios by language (PUBLIC - no auth required)
  Future<List<AudioModel>> fetchAudiosByLanguage(String language) async {
    try {
      final response = await _dio.get('/api/audios/language/$language');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> audioList = response.data['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('[AudioRepository] Error fetching audios by language: $e');
      return [];
    }
  }

  // Increment play count (PUBLIC - no auth required)
  Future<void> incrementPlayCount(int audioId) async {
    try {
      await _dio.post('/api/audios/$audioId/play');
    } catch (e) {
      debugPrint('[AudioRepository] Error incrementing play count: $e');
    }
  }

  // Fetch popular audios (PUBLIC - no auth required)
  Future<List<AudioModel>> fetchPopularAudios({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/api/audios/popular',
        queryParameters: {'limit': limit.toString()},
      );
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> audioList = response.data['data'] as List<dynamic>;
        return audioList.map((json) => AudioModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('[AudioRepository] Error fetching popular audios: $e');
      return [];
    }
  }
}
