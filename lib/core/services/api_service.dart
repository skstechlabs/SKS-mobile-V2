import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import '../constants/app_env.dart';

// Type alias for MediaType to avoid conflicts
typedef DioMediaType = MediaType;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    // Use base URL as-is, don't modify it
    String baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
        ? AppEnv.apiBaseUrl 
        : 'https://app.sivakundalini.org'; // Default to production server
    
    debugPrint('🔧 API Service Initializing...');
    debugPrint('📍 Base URL: $baseUrl');
    debugPrint('🌐 Environment API_BASE_URL: ${AppEnv.apiBaseUrl}');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 45), // Increased to 45s for slow networks
      receiveTimeout: const Duration(seconds: 45), // Increased to 45s
      sendTimeout: const Duration(seconds: 45), // Increased to 45s
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

    // Add retry interceptor for network failures with exponential backoff
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Check if we should retry
          if (_shouldRetry(error)) {
            // Get retry count from request options
            final retryCount = error.requestOptions.extra['retryCount'] as int? ?? 0;
            
            // Max 2 retries
            if (retryCount < 2) {
              try {
                // Exponential backoff: 1s, 2s
                final delaySeconds = (retryCount + 1);
                debugPrint('🔄 Retrying request (attempt ${retryCount + 1}/2): ${error.requestOptions.path}');
                debugPrint('⏳ Waiting ${delaySeconds}s before retry...');
                
                await Future.delayed(Duration(seconds: delaySeconds));
                
                // Increment retry count
                error.requestOptions.extra['retryCount'] = retryCount + 1;
                
                // Retry the request
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                debugPrint('❌ Retry failed: $e');
                return handler.next(error);
              }
            } else {
              debugPrint('❌ Max retries reached for: ${error.requestOptions.path}');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    // Retry on connection timeout, send timeout, receive timeout, or connection error
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError;
  }

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    try {
      // First try cached token
      final cachedToken = await user.getIdToken(false);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        return cachedToken;
      }
    } catch (e) {
      debugPrint('⚠️ Cached token failed: $e, trying force refresh');
    }
    
    // If cached token fails, force refresh
    try {
      final freshToken = await user.getIdToken(true);
      if (freshToken != null && freshToken.isNotEmpty) {
        return freshToken;
      }
    } catch (e) {
      debugPrint('❌ getIdToken force refresh failed: $e');
    }
    
    return null;
  }

  /// Force-refresh the Firebase ID token. Use ONLY for the login call where
  /// we need a guaranteed-fresh token for the backend to verify.
  Future<String?> _getFreshIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      // forceRefresh=true — hits Firebase network to get a brand-new token.
      // Safe to call once per login; not on every API request.
      return await user.getIdToken(true);
    } catch (e) {
      debugPrint('⚠️ getIdToken(forceRefresh=true) failed, trying cached: $e');
      try {
        return await user.getIdToken(false);
      } catch (e2) {
        debugPrint('❌ getIdToken failed entirely: $e2');
        return null;
      }
    }
  }

  // ── 1a. POST /api/auth/login/google ───────────────────────────────────────
  // Google Sign-In: sends Firebase ID token for server-side verification.
  // [idToken] can be passed directly from signInWithGoogle to avoid a second
  // getIdToken() call. If null, a fresh token is fetched automatically.
  Future<Map<String, dynamic>> loginWithGoogle({
    required String mobile,
    String? email,
    String? name,
    String? photo,
    String? idToken, // pre-fetched fresh token from signInWithGoogle
  }) async {
    try {
      // Use the provided token, or fetch a fresh one
      final token = idToken ?? await _getFreshIdToken();
      if (token == null) {
        return {'success': false, 'message': 'Firebase authentication failed. Please try again.'};
      }

      final response = await _dio.post(
        '/api/auth/login/google',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
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

  // ── 1b. POST /api/auth/login/phone ────────────────────────────────────────
  // MSG91 OTP: sends the MSG91 access_token — no Firebase token needed.
  // Backend verifies with MSG91 and creates/returns the user.
  Future<Map<String, dynamic>> loginWithPhone(String msg91AccessToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/login/phone',
        data: {'access_token': msg91AccessToken},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 1c. login() — legacy wrapper kept so other callers don't break ─────────
  Future<Map<String, dynamic>> login({
    required String authProvider,
    required String mobile,
    String? email,
    String? name,
    String? photo,
  }) async {
    if (authProvider == 'google') {
      return loginWithGoogle(mobile: mobile, email: email, name: name, photo: photo);
    }
    // For phone, this path shouldn't normally be called — use loginWithPhone() directly.
    return {'success': false, 'message': 'Use loginWithPhone() for phone auth'};
  }

  // ── 2. POST /api/user/profile ──────────────────────────────────────────────
  Future<Map<String, dynamic>> completeProfile({
    required String name,
    required String gender,
    required int age,
    required String city,
    required String profession,
    required String preferredLanguage,
    required String country,
    String? dateOfBirth,
    String? address,
    String? state,
    String? pincode,
    String? howDidYouKnow,
    String? howDidYouKnowOther,
    String? referrerName,
    String? referrerMobile,
    String? fullAddress,
    String? comments,
    String? mobile, // For Google users adding their phone number
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
          'age': age,
          'city': city,
          'profession': profession,
          'preferred_language': preferredLanguage,
          'country': country,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          if (address != null) 'address': address,
          if (state != null) 'state': state,
          if (pincode != null) 'pincode': pincode,
          if (howDidYouKnow != null) 'how_did_you_know': howDidYouKnow,
          if (howDidYouKnowOther != null) 'how_did_you_know_other': howDidYouKnowOther,
          if (referrerName != null) 'referrer_name': referrerName,
          if (referrerMobile != null) 'referrer_mobile': referrerMobile,
          if (fullAddress != null) 'full_address': fullAddress,
          if (comments != null) 'comments': comments,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
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

  // ══════════════════════════════════════════════════════════════════════════
  // MULTI-PROFILE SYSTEM APIs
  // ══════════════════════════════════════════════════════════════════════════

  // ── 21. GET /api/profiles/config - Get system configuration ───────────────
  Future<Map<String, dynamic>> getProfilesConfig() async {
    try {
      final response = await _dio.get('/api/profiles/config');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 22. GET /api/profiles - Get all profiles for current account ──────────
  Future<Map<String, dynamic>> getProfiles() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/profiles',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 23. POST /api/profiles - Create new profile ───────────────────────────
  Future<Map<String, dynamic>> createProfile({
    required String profileName,
    String? profileAvatar,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/profiles',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          'profileName': profileName,
          if (profileAvatar != null) 'profileAvatar': profileAvatar,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (gender != null) 'gender': gender,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 24. PUT /api/profiles/:profileUid - Update profile ────────────────────
  Future<Map<String, dynamic>> updateProfileById({
    required String profileUid,
    String? profileName,
    String? profileAvatar,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.put(
        '/api/profiles/$profileUid',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {
          if (profileName != null) 'profileName': profileName,
          if (profileAvatar != null) 'profileAvatar': profileAvatar,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (gender != null) 'gender': gender,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 25. DELETE /api/profiles/:profileUid - Delete profile ─────────────────
  Future<Map<String, dynamic>> deleteProfile(String profileUid) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.delete(
        '/api/profiles/$profileUid',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 26. POST /api/profiles/:profileUid/switch - Switch profile ────────────
  Future<Map<String, dynamic>> switchProfile(String profileUid) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/profiles/$profileUid/switch',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 27. GET /api/profiles/sessions - Get active sessions ──────────────────
  Future<Map<String, dynamic>> getProfileSessions() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/profiles/sessions',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 28. DELETE /api/profiles/sessions/:sessionId - Logout session ─────────
  Future<Map<String, dynamic>> logoutSession(int sessionId) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.delete(
        '/api/profiles/sessions/$sessionId',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 29. POST /api/user/upload-profile-photo - Upload profile photo ────────
  Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;

      // Create form data
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType('image', filename.split('.').last),
        ),
      });

      final response = await _dio.post(
        '/api/user/upload-profile-photo',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 30. DELETE /api/user/profile-photo - Delete profile photo ─────────────
  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.delete(
        '/api/user/profile-photo',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 31. GET /api/quotes - Get all quotes ──────────────────────────────────
  Future<Map<String, dynamic>> getQuotes() async {
    try {
      final response = await _dio.get('/api/quotes');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 32. POST /api/otp/verify - Verify MSG91 access token ──────────────────
  // Called after the MSG91 OTP widget returns an access_token.
  // Backend verifies with MSG91 and returns { success, mobile }.
  Future<Map<String, dynamic>> verifyMsg91Token(String accessToken) async {
    try {
      final response = await _dio.post(
        '/api/otp/verify',
        data: {'access_token': accessToken},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 33. GET /api/notifications/push-status - Check push subscription ───────
  // Call this after login to verify the device is properly registered in OneSignal.
  Future<Map<String, dynamic>> checkPushStatus() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      final response = await _dio.get(
        '/api/notifications/push-status',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MULTI-LANGUAGE VIDEO SYSTEM APIs (V2)
  // ══════════════════════════════════════════════════════════════════════════

  // ── 34. POST /api/classes-v2/user/language - Set user's language preference ─
  Future<Map<String, dynamic>> setUserLanguage(String languageCode) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.post(
        '/api/classes-v2/user/language',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        data: {'language': languageCode},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── 35. GET /api/classes-v2/user/language - Get user's language preference ─
  Future<Map<String, dynamic>> getUserLanguage() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _dio.get(
        '/api/classes-v2/user/language',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
}
