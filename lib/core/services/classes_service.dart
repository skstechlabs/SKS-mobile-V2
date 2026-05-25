import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for interacting with the SKS Classes Service backend
/// Backend: sks-classes-service (Port 3013)
/// API Docs: http://localhost:3013/api-docs
class ClassesService {
  static final ClassesService _instance = ClassesService._internal();
  factory ClassesService() => _instance;
  ClassesService._internal();

  final ApiService _apiService = ApiService();

  // ══════════════════════════════════════════════════════════════════════════
  // CLASSES MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/classes - Get all classes (public - no auth required)
  /// Returns list of all active classes
  Future<Map<String, dynamic>> getAllClasses() async {
    try {
      debugPrint('📚 Fetching all classes...');
      final response = await _apiService.get('/api/classes');
      
      if (response['success'] == true) {
        debugPrint('✅ Loaded ${response['classes']?.length ?? 0} classes');
      } else {
        debugPrint('❌ Failed to load classes: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching classes: $e');
      return {
        'success': false,
        'message': 'Failed to fetch classes',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// GET /api/classes/:id - Get single class details (requires auth)
  /// Returns detailed information about a specific class
  Future<Map<String, dynamic>> getClassDetails(int classId) async {
    try {
      debugPrint('📚 Fetching class details for ID: $classId');
      final response = await _apiService.get('/api/classes/$classId');
      
      if (response['success'] == true) {
        debugPrint('✅ Loaded class: ${response['class']?['title']}');
      } else {
        debugPrint('❌ Failed to load class: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching class details: $e');
      return {
        'success': false,
        'message': 'Failed to fetch class details',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// POST /api/classes/:id/enroll - Enroll in class (requires auth)
  /// Enrolls the current user in a class and unlocks Day 1
  Future<Map<String, dynamic>> enrollInClass(int classId) async {
    try {
      debugPrint('📝 Enrolling in class ID: $classId');
      final response = await _apiService.post(
        '/api/classes/$classId/enroll',
        {},
      );
      
      if (response['success'] == true) {
        debugPrint('✅ Successfully enrolled in class');
      } else {
        debugPrint('❌ Failed to enroll: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error enrolling in class: $e');
      return {
        'success': false,
        'message': 'Failed to enroll in class',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// GET /api/classes/my/enrollments - Get user's enrolled classes (requires auth)
  /// Returns list of classes the user is enrolled in
  Future<Map<String, dynamic>> getMyEnrollments() async {
    try {
      debugPrint('📚 Fetching my enrollments...');
      final response = await _apiService.get('/api/classes/my/enrollments');
      
      if (response['success'] == true) {
        debugPrint('✅ Loaded ${response['enrollments']?.length ?? 0} enrollments');
      } else {
        debugPrint('❌ Failed to load enrollments: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching enrollments: $e');
      return {
        'success': false,
        'message': 'Failed to fetch enrollments',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLASS DAYS & VIDEO STREAMING
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/classes/:classId/days - Get class days with progress (requires auth)
  /// Returns list of days for a class with user's progress
  Future<Map<String, dynamic>> getClassDays(int classId) async {
    try {
      debugPrint('📅 Fetching days for class ID: $classId');
      final response = await _apiService.get('/api/classes/$classId/days');
      
      if (response['success'] == true) {
        debugPrint('✅ Loaded ${response['days']?.length ?? 0} days');
      } else {
        debugPrint('❌ Failed to load days: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching class days: $e');
      return {
        'success': false,
        'message': 'Failed to fetch class days',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// GET /api/classes/:classId/progress - Get class progress (requires auth)
  /// Returns overall progress for a class
  Future<Map<String, dynamic>> getClassProgress(int classId) async {
    try {
      debugPrint('📊 Fetching progress for class ID: $classId');
      final response = await _apiService.get('/api/classes/$classId/progress');
      
      if (response['success'] == true) {
        debugPrint('✅ Progress: ${response['progress']?['completionPercentage']}%');
      } else {
        debugPrint('❌ Failed to load progress: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching class progress: $e');
      return {
        'success': false,
        'message': 'Failed to fetch class progress',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// POST /api/classes/days/:dayId/start - Start a day (requires auth)
  /// Marks a day as started and records the start time
  Future<Map<String, dynamic>> startDay(int dayId) async {
    try {
      debugPrint('▶️ Starting day ID: $dayId');
      final response = await _apiService.post(
        '/api/classes/days/$dayId/start',
        {},
      );
      
      if (response['success'] == true) {
        debugPrint('✅ Day started successfully');
      } else {
        debugPrint('❌ Failed to start day: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error starting day: $e');
      return {
        'success': false,
        'message': 'Failed to start day',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// POST /api/classes/days/:dayId/track - Track video progress (requires auth)
  /// Records video playback events (start, progress, pause, resume, complete)
  Future<Map<String, dynamic>> trackVideoProgress({
    required int dayId,
    required String eventType, // start, progress, pause, resume, complete
    required int positionSeconds,
    required int durationSeconds,
    required String sessionId,
  }) async {
    try {
      debugPrint('📹 Tracking video: $eventType at ${positionSeconds}s');
      final response = await _apiService.post(
        '/api/classes/days/$dayId/track',
        {
          'eventType': eventType,
          'positionSeconds': positionSeconds,
          'durationSeconds': durationSeconds,
          'sessionId': sessionId,
        },
      );
      
      if (response['success'] == true) {
        debugPrint('✅ Video progress tracked');
      } else {
        debugPrint('❌ Failed to track progress: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error tracking video progress: $e');
      return {
        'success': false,
        'message': 'Failed to track video progress',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// GET /api/classes/days/:dayId/video-config - Get video configuration (requires auth)
  /// Returns Cloudflare Stream video configuration and playback URL
  Future<Map<String, dynamic>> getVideoConfig(int dayId) async {
    try {
      debugPrint('🎥 Fetching video config for day ID: $dayId');
      final response = await _apiService.get('/api/classes/days/$dayId/video-config');
      
      if (response['success'] == true) {
        debugPrint('✅ Video config loaded');
      } else {
        debugPrint('❌ Failed to load video config: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching video config: $e');
      return {
        'success': false,
        'message': 'Failed to fetch video configuration',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// POST /api/classes/days/:dayId/security-event - Log security event (requires auth)
  /// Records security events like screen recording attempts, download attempts, etc.
  Future<Map<String, dynamic>> logSecurityEvent({
    required int dayId,
    required String eventType, // screen_recording, download_attempt, skip_attempt, etc.
    String? details,
  }) async {
    try {
      debugPrint('🔒 Logging security event: $eventType for day $dayId');
      final response = await _apiService.post(
        '/api/classes/days/$dayId/security-event',
        {
          'eventType': eventType,
          if (details != null) 'details': details,
        },
      );
      
      if (response['success'] == true) {
        debugPrint('✅ Security event logged');
      } else {
        debugPrint('❌ Failed to log security event: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error logging security event: $e');
      return {
        'success': false,
        'message': 'Failed to log security event',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEVEL PROGRESSION
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/level-progression/access - Get level access status (requires auth)
  /// Returns which levels are unlocked and their unlock times
  Future<Map<String, dynamic>> getLevelAccess() async {
    try {
      debugPrint('🔓 Fetching level access...');
      final response = await _apiService.get('/api/level-progression/access');
      
      if (response['success'] == true) {
        debugPrint('✅ Level access loaded');
      } else {
        debugPrint('❌ Failed to load level access: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching level access: $e');
      return {
        'success': false,
        'message': 'Failed to fetch level access',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  /// POST /api/level-progression/meditation-test - Submit meditation test (requires auth)
  /// Submits meditation test results to unlock Level 3
  Future<Map<String, dynamic>> submitMeditationTest({
    required int score,
    required int totalQuestions,
    required Map<String, dynamic> answers,
  }) async {
    try {
      debugPrint('📝 Submitting meditation test: $score/$totalQuestions');
      final response = await _apiService.post(
        '/api/level-progression/meditation-test',
        {
          'score': score,
          'total_questions': totalQuestions,
          'answers': answers,
        },
      );
      
      if (response['success'] == true) {
        debugPrint('✅ Meditation test submitted');
      } else {
        debugPrint('❌ Failed to submit test: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error submitting meditation test: $e');
      return {
        'success': false,
        'message': 'Failed to submit meditation test',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/classes/analytics/summary - Get analytics summary (requires auth)
  /// Returns analytics data for classes and video viewing
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      debugPrint('📊 Fetching analytics summary...');
      final response = await _apiService.get('/api/classes/analytics/summary');
      
      if (response['success'] == true) {
        debugPrint('✅ Analytics loaded');
      } else {
        debugPrint('❌ Failed to load analytics: ${response['message']}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching analytics: $e');
      return {
        'success': false,
        'message': 'Failed to fetch analytics',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /health - Health check (public - no auth required)
  /// Checks if the classes service is running
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      debugPrint('🏥 Checking classes service health...');
      final response = await _apiService.get('/health');
      
      if (response['success'] == true) {
        debugPrint('✅ Classes service is healthy');
      } else {
        debugPrint('❌ Classes service health check failed');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Error checking health: $e');
      return {
        'success': false,
        'message': 'Failed to check service health',
        'error_code': 'CLIENT_ERROR',
      };
    }
  }
}
