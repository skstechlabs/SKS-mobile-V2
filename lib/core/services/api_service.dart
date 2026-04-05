import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_env.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    // Use base URL as-is, don't modify it
    String baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
        ? AppEnv.apiBaseUrl 
        : 'https://sivakundalini.org';
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30), // Increased from 10s
      receiveTimeout: const Duration(seconds: 30), // Increased from 10s
      sendTimeout: const Duration(seconds: 30), // Added send timeout
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    // Add retry interceptor for network failures
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              debugPrint('🔄 Retrying request: ${error.requestOptions.path}');
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    // Retry on connection timeout, send timeout, or connection error
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.connectionError;
  }

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // ── 1. POST /api/auth/login ────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String authProvider, // 'phone' | 'google'
    required String mobile,
    String? email,
    String? name,
    String? photo,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/auth/login',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'auth_provider': authProvider,
          'mobile': mobile,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (photo != null) 'photo': photo,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 2. POST /api/user/profile ──────────────────────────────────────────────
  Future<Map<String, dynamic>> completeProfile({
    required String name,
    required String gender,
    required String dateOfBirth,
    required String address,
    required String state,
    required String pincode,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'name': name,
          'gender': gender,
          'date_of_birth': dateOfBirth,
          'address': address,
          'state': state,
          'pincode': pincode,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 3. GET /api/user/profile ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 4. PATCH /api/user/profile ─────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.patch(
        '/api/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: updates,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 5. POST /api/user/permissions ──────────────────────────────────────────
  Future<Map<String, dynamic>> savePermissions({
    required bool camera,
    required bool microphone,
    required bool notifications,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/user/permissions',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'camera': camera,
          'microphone': microphone,
          'notifications': notifications,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 6. POST /api/auth/logout ───────────────────────────────────────────────
  Future<Map<String, dynamic>> logout() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 7. GET /api/auth/verify ────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/auth/verify',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 8. GET /api/reminders ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReminders() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/reminders',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 9. POST /api/reminders ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> createReminder({
    required String title,
    String? message,
    required String reminderTime,
    required List<int> daysOfWeek,
    bool? isActive,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/reminders',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'title': title,
          if (message != null) 'message': message,
          'reminder_time': reminderTime,
          'days_of_week': daysOfWeek,
          if (isActive != null) 'is_active': isActive,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 10. PUT /api/reminders/:id ─────────────────────────────────────────────
  Future<Map<String, dynamic>> updateReminder({
    required int id,
    String? title,
    String? message,
    String? reminderTime,
    List<int>? daysOfWeek,
    bool? isActive,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.put(
        '/api/reminders/$id',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          if (title != null) 'title': title,
          if (message != null) 'message': message,
          if (reminderTime != null) 'reminder_time': reminderTime,
          if (daysOfWeek != null) 'days_of_week': daysOfWeek,
          if (isActive != null) 'is_active': isActive,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 11. DELETE /api/reminders/:id ──────────────────────────────────────────
  Future<Map<String, dynamic>> deleteReminder(int id) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.delete(
        '/api/reminders/$id',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 12. PATCH /api/reminders/:id/toggle ────────────────────────────────────
  Future<Map<String, dynamic>> toggleReminder(int id) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.patch(
        '/api/reminders/$id/toggle',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 13. GET /api/events ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await _dio.get('/api/events');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 14. POST /api/events/:id/register ──────────────────────────────────────
  Future<Map<String, dynamic>> registerForEvent(int eventId) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/events/$eventId/register',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 15. GET /api/gatherings ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getGatherings() async {
    try {
      final response = await _dio.get('/api/gatherings');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 16. POST /api/meditation/sessions - Record meditation session ──────────
  Future<Map<String, dynamic>> recordMeditationSession({
    required String startTime,
    required String endTime,
    required int durationSeconds,
    String? notes,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/meditation/sessions',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'start_time': startTime,
          'end_time': endTime,
          'duration_seconds': durationSeconds,
          if (notes != null) 'notes': notes,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 17. GET /api/meditation/sessions - Get meditation sessions ─────────────
  Future<Map<String, dynamic>> getMeditationSessions({
    int limit = 50,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };

      final response = await _dio.get(
        '/api/meditation/sessions',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 18. GET /api/meditation/stats - Get meditation statistics ──────────────
  Future<Map<String, dynamic>> getMeditationStats({
    String period = 'week', // day, week, month, year, all
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/meditation/stats',
        queryParameters: {'period': period},
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 19. GET /api/meditation/streak - Get meditation streak ─────────────────
  Future<Map<String, dynamic>> getMeditationStreak() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/meditation/streak',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 20. DELETE /api/meditation/sessions/:id - Delete session ───────────────
  Future<Map<String, dynamic>> deleteMeditationSession(int sessionId) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.delete(
        '/api/meditation/sessions/$sessionId',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Generic GET method for authenticated requests ──────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          responseType: ResponseType.json, // Ensure JSON response
        ),
      );

      // Handle response data type
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        // Try to parse string as JSON
        try {
          final decoded = json.decode(response.data as String);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (e) {
          debugPrint('Failed to parse response as JSON: $e');
        }
      }
      
      // Fallback: wrap response in a map
      return {
        'success': false,
        'message': 'Invalid response format',
        'data': response.data,
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Generic POST method for authenticated requests ─────────────────────────
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        path,
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          responseType: ResponseType.json, // Ensure JSON response
        ),
      );

      // Handle response data type
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        // Try to parse string as JSON
        try {
          final decoded = json.decode(response.data as String);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (e) {
          debugPrint('Failed to parse response as JSON: $e');
        }
      }
      
      // Fallback: wrap response in a map
      return {
        'success': false,
        'message': 'Invalid response format',
        'data': response.data,
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed',
          'error_code': data['error_code'],
        };
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return {
          'success': false,
          'message': 'Connection timeout. Please try again.',
          'error_code': 'TIMEOUT'
        };
      case DioExceptionType.connectionError:
        return {
          'success': false,
          'message': 'Network error. Check your connection.',
          'error_code': 'NETWORK_ERROR'
        };
      case DioExceptionType.badResponse:
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
          'error_code': 'SERVER_ERROR'
        };
      default:
        return {
          'success': false,
          'message': 'Something went wrong. Please try again.',
          'error_code': 'UNKNOWN_ERROR'
        };
    }
  }
}
