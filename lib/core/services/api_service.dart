import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_env.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppEnv.apiBaseUrl.isNotEmpty 
          ? AppEnv.apiBaseUrl 
          : 'http://localhost:3011',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
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

  Map<String, dynamic> _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed',
        };
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return {'success': false, 'message': 'Connection timeout. Please try again.'};
      case DioExceptionType.connectionError:
        return {'success': false, 'message': 'Network error. Check your connection.'};
      case DioExceptionType.badResponse:
        return {'success': false, 'message': 'Server error. Please try again later.'};
      default:
        return {'success': false, 'message': 'Something went wrong. Please try again.'};
    }
  }
}
