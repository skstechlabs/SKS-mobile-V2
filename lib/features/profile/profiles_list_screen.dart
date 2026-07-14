import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import 'profile_model.dart';

class ProfilesListScreen extends StatefulWidget {
  const ProfilesListScreen({super.key});

  @override
  State<ProfilesListScreen> createState() => _ProfilesListScreenState();
}

class _ProfilesListScreenState extends State<ProfilesListScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  List<ProfileModel> _profiles = [];
  String? _accountPhone;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }
  
  @override
  void didUpdateWidget(ProfilesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget is updated (e.g., after navigation)
    if (_hasLoadedOnce) {
      _loadProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📊 Loading profiles...');
      
      // Backend doesn't support multi-profile yet, load single user profile
      final result = await _apiService.getProfile();
      debugPrint('📊 Profile result: $result');
      
      if (result['success'] == true && mounted) {
        // Backend returns single user profile, not a list
        final userData = result['user'] as Map<String, dynamic>;
        debugPrint('📊 User data: $userData');
        
        try {
          // Create a ProfileModel from user data
          final profile = ProfileModel(
            id: 0, // Temporary ID since backend doesn't provide it
            profileUid: userData['uid'] as String,
            profileName: userData['name'] as String? ?? 'User',
            profileAvatar: userData['photo'] as String?,
            isPrimary: true,
            isActive: true,
            dateOfBirth: userData['date_of_birth'] as String?,
            gender: userData['gender'] as String?,
            createdAt: DateTime.parse(userData['created_at'] as String),
          );
          
          setState(() {
            _profiles = [profile];
            _accountPhone = userData['mobile'] as String?;
            _hasLoadedOnce = true;
            _isLoading = false;
          });
          debugPrint('✅ Loaded profile: ${profile.profileName}');
        } catch (parseError, stackTrace) {
          debugPrint('❌ Error parsing profile: $parseError');
          debugPrint('Stack trace: $stackTrace');
          if (mounted) {
            setState(() => _isLoading = false);
            _showError('Error parsing profile data: $parseError');
          }
        }
      } else if (mounted) {
        debugPrint('❌ API returned error: ${result['message']}');
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'Failed to load profile');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading profile: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading profile: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Manage Profiles',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner about multi-profile not available
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.saffron.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.saffron,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Multi-profile feature is coming soon. Currently showing your profile.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_accountPhone != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Account: $_accountPhone',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  
                  Text(
                    'Your Profile',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Show single profile
                  if (_profiles.isNotEmpty)
                    _buildProfileCard(_profiles[0]),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(ProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.saffron,
          width: 2,
        ),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.saffron,
                  AppTheme.saffron.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                profile.avatarInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            profile.profileName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Primary Profile',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.saffron,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
