import '../../core/services/api_service.dart';
import 'auth_state.dart';
import 'user_model.dart';

/// Service for managing user profile operations
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ApiService _apiService = ApiService();
  final AuthState _authState = AuthState();

  /// Fetch user profile from backend and update local state
  Future<Map<String, dynamic>> fetchAndUpdateProfile() async {
    final result = await _apiService.getProfile();
    
    if (result['success'] == true) {
      final userData = result['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);
      _authState.setUser(user);
    }
    
    return result;
  }

  /// Update specific profile fields
  Future<Map<String, dynamic>> updateProfileFields(Map<String, dynamic> updates) async {
    final result = await _apiService.updateProfile(updates);
    
    if (result['success'] == true) {
      final userData = result['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);
      _authState.updateProfile(user);
    }
    
    return result;
  }

  /// Get current user from local state
  UserModel? get currentUser => _authState.user;
}
