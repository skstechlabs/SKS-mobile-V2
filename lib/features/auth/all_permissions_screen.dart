import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/api_service.dart';
import 'auth_state.dart';

class AllPermissionsScreen extends StatefulWidget {
  const AllPermissionsScreen({super.key});

  @override
  State<AllPermissionsScreen> createState() => _AllPermissionsScreenState();
}

class _AllPermissionsScreenState extends State<AllPermissionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  final OneSignalService _oneSignal = OneSignalService();
  final ApiService _apiService = ApiService();
  final AuthState _authState = AuthState();
  
  bool _notificationGranted = false;
  bool _cameraGranted = false;
  bool _microphoneGranted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
    
    _checkPermissions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermissions() async {
    if (kIsWeb) return;
    
    final notification = await _oneSignal.hasPermission();
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    
    setState(() {
      _notificationGranted = notification;
      _cameraGranted = camera;
      _microphoneGranted = microphone;
    });
    
    debugPrint('📊 Permission status:');
    debugPrint('   Notifications: $notification');
    debugPrint('   Camera: $camera');
    debugPrint('   Microphone: $microphone');
    
    // If notification permission already granted, set up OneSignal user
    if (notification) {
      debugPrint('✅ Notification permission already granted - setting up OneSignal user');
      await _setupOneSignalUser();
    }
  }

  Future<void> _setupOneSignalUser() async {
    try {
      await _oneSignal.optIn();
      
      final user = _authState.user;
      if (user != null) {
        debugPrint('👤 Setting OneSignal external user ID: ${user.uid}');
        await _oneSignal.setExternalUserId(user.uid);
        
        await _oneSignal.setTags({
          'auth_provider': user.authProvider,
          'has_camera': _cameraGranted.toString(),
          'has_microphone': _microphoneGranted.toString(),
        });
        debugPrint('✅ OneSignal user identified and tagged');
      } else {
        debugPrint('👤 User is guest, setting guest tags');
        await _oneSignal.setTags({
          'user_type': 'guest',
          'has_camera': _cameraGranted.toString(),
          'has_microphone': _microphoneGranted.toString(),
        });
      }
      
      // Save to backend
      if (user != null) {
        try {
          await _apiService.savePermissions(
            camera: _cameraGranted,
            microphone: _microphoneGranted,
            notifications: _notificationGranted,
          );
          debugPrint('✅ Permissions saved to backend');
        } catch (e) {
          debugPrint('⚠️ Failed to save permissions: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to setup OneSignal user: $e');
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        context.go('/');
        return;
      }
      
      // Request notifications first (only if not already granted)
      if (!_notificationGranted) {
        debugPrint('🔔 Requesting notification permission...');
        final notifGranted = await _oneSignal.requestPermission();
        debugPrint('🔔 Notification result: $notifGranted');
        
        if (notifGranted) {
          setState(() => _notificationGranted = true);
          await _setupOneSignalUser();
        }
      } else {
        debugPrint('✅ Notification permission already granted');
      }
      
      // Request camera (only if not already granted)
      if (!_cameraGranted) {
        debugPrint('📷 Requesting camera permission...');
        final cameraStatus = await Permission.camera.request();
        debugPrint('📷 Camera result: $cameraStatus');
        setState(() => _cameraGranted = cameraStatus.isGranted);
      }
      
      // Request microphone (only if not already granted)
      if (!_microphoneGranted) {
        debugPrint('🎤 Requesting microphone permission...');
        final micStatus = await Permission.microphone.request();
        debugPrint('🎤 Microphone result: $micStatus');
        setState(() => _microphoneGranted = micStatus.isGranted);
      }
      
      // Check if all critical permissions granted
      if (_notificationGranted) {
        // Navigate to home
        if (mounted) {
          context.go('/');
        }
      } else {
        _showMandatoryDialog();
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error requesting permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMandatoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Notifications Required'),
          ],
        ),
        content: const Text(
          'To connect with Guruji, you must allow notifications. '
          'Camera and microphone are optional but recommended for full experience.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestAllPermissions();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Error'),
        content: Text('Failed to request permissions.\n\nError: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestAllPermissions();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.white, AppTheme.beige.withValues(alpha: 0.2)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.security_outlined,
                        size: 60,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'App Permissions',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'We need a few permissions to provide you the best experience',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Permission items
                    _buildPermissionItem(
                      Icons.notifications_active_outlined,
                      'Notifications',
                      'Receive updates from Guruji',
                      true,
                      _notificationGranted,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionItem(
                      Icons.camera_alt_outlined,
                      'Camera',
                      'Share photos and videos',
                      false,
                      _cameraGranted,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionItem(
                      Icons.mic_outlined,
                      'Microphone',
                      'Record audio messages',
                      false,
                      _microphoneGranted,
                    ),

                    const SizedBox(height: 40),

                    // Mandatory notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Notifications are mandatory. Camera and microphone are optional.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Allow button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Grant Permissions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    IconData icon,
    String title,
    String description,
    bool required,
    bool granted,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
        border: granted 
            ? Border.all(color: Colors.green.shade300, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: granted 
                  ? Colors.green.shade100 
                  : AppTheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              granted ? Icons.check_circle : icon,
              color: granted ? Colors.green.shade700 : AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'REQUIRED',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (granted)
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
        ],
      ),
    );
  }
}
