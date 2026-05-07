import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/cached_image.dart';
import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../auth/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final AuthState _authState = AuthState();
  final ApiService _apiService = ApiService();
  final OneSignalService _oneSignal = OneSignalService();

  bool _isLoading = false;
  UserModel? _user;
  String? _lastLoadedProfileUid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't reload on every widget update — only reload when explicitly needed
    // (e.g. after editing profile, call _loadProfile() directly)
  }

  Future<void> _loadProfile() async {
    // Prevent duplicate loads
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getProfile();
      
      if (result['success'] == true && result['user'] != null) {
        final user = UserModel.fromJson(result['user']);
        
        // Check if profile actually changed
        final profileUid = result['user']['profile_uid'] as String?;
        if (_lastLoadedProfileUid != profileUid) {
          debugPrint('🔄 Profile changed from $_lastLoadedProfileUid to $profileUid');
          _lastLoadedProfileUid = profileUid;
        }
        
        setState(() {
          _user = user;
        });
        
        // Update auth state with cache
        await _authState.setUser(user);
      } else {
        // Check if it's an authentication error
        final message = result['message'] ?? '';
        if (message.toLowerCase().contains('not authenticated') || 
            message.toLowerCase().contains('unauthorized') ||
            message.toLowerCase().contains('token')) {
          setState(() { _user = null; });
        } else {
          _showError(message.isNotEmpty ? message : 'Failed to load profile');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      setState(() { _user = null; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('logout')),
        content: Text(context.tr('logout_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Call backend logout
      await _apiService.logout();

      // Remove OneSignal external user ID
      await _oneSignal.removeExternalUserId();

      // Sign out from Firebase
      await _authService.signOut();

      // Clear auth state and cache
      await _authState.logout();

      // Navigate to login
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      _showError('Failed to logout. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          context.tr('profile'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 80,
                color: AppTheme.saffron,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('not_logged_in'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('please_login'),
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: Text(context.tr('login')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = _user!;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Profile Picture
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: user.photo.isNotEmpty
                        ? CachedImage(
                            imageUrl: user.photo,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primary,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            user.name.isNotEmpty ? user.name : context.tr('profile'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Auth Provider Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.authProvider == 'google'
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.authProvider == 'google'
                      ? Icons.g_mobiledata
                      : Icons.phone,
                  size: 16,
                  color: user.authProvider == 'google'
                      ? Colors.red.shade700
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  user.authProvider == 'google' ? context.tr('google') : context.tr('phone'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.authProvider == 'google'
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Profile Information
          _buildSection(
            title: context.tr('personal_information'),
            children: [
              _buildInfoTile(
                icon: Icons.phone,
                label: context.tr('mobile'),
                value: user.mobile,
              ),
              if (user.email.isNotEmpty)
                _buildInfoTile(
                  icon: Icons.email,
                  label: context.tr('email'),
                  value: user.email,
                ),
              if (user.gender != null)
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: context.tr('gender'),
                  value: user.gender!,
                ),
              if (user.dateOfBirth != null)
                _buildInfoTile(
                  icon: Icons.cake,
                  label: context.tr('date_of_birth'),
                  value: user.dateOfBirth!,
                ),
            ],
          ),

          if (user.address != null || user.state != null || user.pincode != null)
            _buildSection(
              title: context.tr('address_info'),
              children: [
                if (user.address != null)
                  _buildInfoTile(
                    icon: Icons.home,
                    label: context.tr('address'),
                    value: user.address!,
                  ),
                if (user.state != null)
                  _buildInfoTile(
                    icon: Icons.location_on,
                    label: context.tr('state'),
                    value: user.state!,
                  ),
                if (user.pincode != null)
                  _buildInfoTile(
                    icon: Icons.pin_drop,
                    label: context.tr('pincode'),
                    value: user.pincode!,
                  ),
              ],
            ),

          // Account Actions
          _buildSection(
            title: context.tr('account'),
            children: [
              _buildActionTile(
                icon: Icons.edit,
                label: context.tr('edit_profile'),
                onTap: () => context.push('/edit-profile'),
              ),
              _buildActionTile(
                icon: Icons.people,
                label: context.tr('manage_profiles'),
                onTap: () => context.push('/profile/list'),
              ),
              _buildActionTile(
                icon: Icons.language,
                label: context.tr('change_language'),
                onTap: () => context.push('/settings/language'),
              ),
              _buildActionTile(
                icon: Icons.help_outline,
                label: context.tr('help_support'),
                onTap: () {
                  _showError(context.tr('feature_coming_soon'));
                },
              ),
              _buildActionTile(
                icon: Icons.logout,
                label: context.tr('logout'),
                onTap: _handleLogout,
                isDestructive: true,
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red.shade700 : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red.shade700 : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
