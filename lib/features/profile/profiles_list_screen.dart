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
  int _maxProfiles = 5;
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
    // Prevent duplicate loads
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      // Load config
      final configResult = await _apiService.getProfilesConfig();
      if (configResult['success'] == true) {
        final config = configResult['config'] as Map<String, dynamic>;
        _maxProfiles = config['max_profiles_per_account'] as int? ?? 5;
      }

      // Load profiles
      final result = await _apiService.getProfiles();
      
      if (result['success'] == true && mounted) {
        final profilesList = result['profiles'] as List;
        setState(() {
          _profiles = profilesList.map((p) => ProfileModel.fromJson(p as Map<String, dynamic>)).toList();
          _accountPhone = result['accountPhone'] as String?;
          _hasLoadedOnce = true;
        });
      } else if (mounted) {
        _showError(result['message'] ?? 'Failed to load profiles');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error loading profiles');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchProfile(ProfileModel profile) async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      final result = await _apiService.switchProfile(profile.profileUid);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${profile.profileName}'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home and force reload
        context.go('/');
      } else if (mounted) {
        _showError(result['message'] ?? 'Failed to switch profile');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        _showError('Error switching profile');
      }
    }
  }

  Future<void> _deleteProfile(ProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile.profileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.deleteProfile(profile.profileUid);
      
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfiles();
      } else if (mounted) {
        _showError(result['message'] ?? 'Failed to delete profile');
      }
    } catch (e) {
      _showError('Error deleting profile');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddProfileDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Profile Name',
            hintText: 'Enter profile name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a profile name')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              try {
                final result = await _apiService.createProfile(profileName: name);
                
                if (result['success'] == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadProfiles();
                } else if (mounted) {
                  _showError(result['message'] ?? 'Failed to create profile');
                }
              } catch (e) {
                _showError('Error creating profile');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Manage Profiles',
          style: TextStyle(
            color: Colors.black,
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
                    'Profiles (${_profiles.length}/$_maxProfiles)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Profiles Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _profiles.length + (_profiles.length < _maxProfiles ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _profiles.length) {
                        // Add Profile Card
                        return _buildAddProfileCard();
                      }
                      
                      final profile = _profiles[index];
                      return _buildProfileCard(profile);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(ProfileModel profile) {
    return GestureDetector(
      onTap: () => _switchProfile(profile),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: profile.isPrimary 
                ? AppTheme.saffron 
                : AppTheme.softGray,
            width: profile.isPrimary ? 2 : 1,
          ),
          boxShadow: [AppTheme.softShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                profile.profileName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Badge
            if (profile.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Primary',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.saffron,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Delete button (only for non-primary profiles)
            if (!profile.isPrimary)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: () => _deleteProfile(profile),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard() {
    return GestureDetector(
      onTap: _showAddProfileDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.saffron,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [AppTheme.softShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.saffron.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.add,
                size: 40,
                color: AppTheme.saffron,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Add Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.saffron,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
