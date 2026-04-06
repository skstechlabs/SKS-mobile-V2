import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/onesignal_service.dart';
import 'profile_model.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final ApiService _apiService = ApiService();
  final OneSignalService _oneSignal = OneSignalService();
  
  bool _isLoading = true;
  List<ProfileModel> _profiles = [];
  int _maxProfiles = 5;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    try {
      // Load config
      final configResult = await _apiService.getProfilesConfig();
      debugPrint('📊 Config result: $configResult');
      
      if (configResult['success'] == true) {
        final config = configResult['config'] as Map<String, dynamic>;
        _maxProfiles = config['max_profiles_per_account'] as int? ?? 5;
        debugPrint('✅ Max profiles: $_maxProfiles');
      }

      // Load profiles
      final result = await _apiService.getProfiles();
      debugPrint('📊 Profiles result: $result');
      
      if (result['success'] == true && mounted) {
        final profilesList = result['profiles'] as List;
        debugPrint('📊 Profiles list length: ${profilesList.length}');
        
        try {
          final profiles = profilesList.map((p) {
            debugPrint('📊 Parsing profile: $p');
            return ProfileModel.fromJson(p as Map<String, dynamic>);
          }).toList();
          
          setState(() {
            _profiles = profiles;
          });
          debugPrint('✅ Loaded ${_profiles.length} profiles');
        } catch (parseError, stackTrace) {
          debugPrint('❌ Error parsing profiles: $parseError');
          debugPrint('Stack trace: $stackTrace');
          if (mounted) {
            _showError('Error parsing profile data: $parseError');
          }
        }
      } else if (mounted) {
        debugPrint('❌ API returned error: ${result['message']}');
        _showError(result['message'] ?? 'Failed to load profiles');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading profiles: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showError('Error loading profiles: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectProfile(ProfileModel profile) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Switch profile
      final result = await _apiService.switchProfile(profile.profileUid);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      
      if (result['success'] == true && mounted) {
        // Profile switched successfully
        debugPrint('✅ Profile switched to: ${profile.profileName}');
        
        // Check if we need to show permissions screen
        await _checkAndNavigate();
      } else if (mounted) {
        _showError(result['message'] ?? 'Failed to switch profile');
      }
    } catch (e) {
      debugPrint('❌ Error switching profile: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError('Error switching profile');
      }
    }
  }

  Future<void> _checkAndNavigate() async {
    if (kIsWeb) {
      // Web doesn't need permissions
      if (mounted) {
        context.go('/');
      }
      return;
    }

    // Check if any permission is missing
    final notification = await _oneSignal.hasPermission();
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final location = await Permission.location.isGranted;

    // If any permission is missing, go to permissions screen
    if (!notification || !camera || !microphone || !location) {
      if (mounted) {
        context.go('/notification-permission');
      }
    } else {
      // All permissions granted, go to home
      if (mounted) {
        context.go('/');
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

  void _showAddProfileDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a profile name')),
                );
                return;
              }
              
              Navigator.pop(dialogContext);
              
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
                if (mounted) {
                  _showError('Error creating profile');
                }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.white,
              AppTheme.beige.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Title
                    Text(
                      'Who\'s Meditating?',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 28,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Select your profile to continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Profiles Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
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
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ProfileModel profile) {
    return GestureDetector(
      onTap: () => _selectProfile(profile),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: profile.isPrimary 
                ? AppTheme.saffron 
                : AppTheme.softGray,
            width: profile.isPrimary ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.saffron.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.saffron,
                    AppTheme.saffron.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.saffron.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  profile.avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                profile.profileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Badge
            if (profile.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Primary',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.saffron,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.saffron,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.saffron.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.saffron.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.saffron.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                size: 45,
                color: AppTheme.saffron,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Add Profile',
              style: TextStyle(
                fontSize: 18,
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
