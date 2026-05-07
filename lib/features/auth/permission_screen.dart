import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class _PermissionItem {
  final String title;
  final String description;
  final IconData icon;
  final Permission permission;
  PermissionStatus status;

  _PermissionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
    PermissionStatus? initialStatus,
  }) : status = initialStatus ?? PermissionStatus.denied;
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      title: 'Camera',
      description: 'Required for video sessions and profile photo',
      icon: Icons.videocam_outlined,
      permission: Permission.camera,
    ),
    _PermissionItem(
      title: 'Microphone',
      description: 'Required for live sessions and audio features',
      icon: Icons.mic_outlined,
      permission: Permission.microphone,
    ),
    _PermissionItem(
      title: 'Notifications',
      description: 'Stay updated with events, programs and reminders',
      icon: Icons.notifications_outlined,
      permission: Permission.notification,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
    _checkCurrentStatuses();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentStatuses() async {
    if (kIsWeb) return; // permission_handler not supported on web
    for (final item in _permissions) {
      final status = await item.permission.status;
      if (mounted) setState(() => item.status = status);
    }
  }

  Future<void> _requestAll() async {
    if (kIsWeb) {
      // On web skip permissions and go to notification permission
      await _savePermissionsToBackend(true, true, true);
      if (mounted) context.go('/notification-permission');
      return;
    }

    setState(() => _isLoading = true);

    for (final item in _permissions) {
      if (!item.status.isGranted) {
        final result = await item.permission.request();
        if (mounted) setState(() => item.status = result);
      }
    }

    // Save permissions to backend
    final cameraGranted = _permissions[0].status.isGranted;
    final micGranted = _permissions[1].status.isGranted;
    final notifGranted = _permissions[2].status.isGranted;
    
    await _savePermissionsToBackend(cameraGranted, micGranted, notifGranted);

    setState(() => _isLoading = false);

    final allGranted = _permissions.every((p) => p.status.isGranted);
    if (allGranted) {
      // Navigate to mandatory notification permission screen
      if (mounted) context.go('/notification-permission');
    } else {
      _showDeniedDialog();
    }
  }

  Future<void> _savePermissionsToBackend(bool camera, bool microphone, bool notifications) async {
    final result = await _apiService.savePermissions(
      camera: camera,
      microphone: microphone,
      notifications: notifications,
    );

    if (result['success'] != true) {
      // Log error but don't block user flow
      debugPrint('Failed to save permissions: ${result['message']}');
    }
  }

  void _showDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permissions Required'),
        content: const Text(
          'All permissions are required to use the app. Please grant them in Settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: AppTheme.primary)),
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
            colors: [AppTheme.white, AppTheme.beige.withOpacity(0.2)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(Icons.security_outlined, size: 40, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 24),

                  Text('App Permissions',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: AppTheme.primary,
                    )),
                  const SizedBox(height: 8),
                  Text(
                    'We need the following permissions\nto give you the best experience',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Permission cards
                  ..._permissions.map((item) => _buildPermissionCard(item)),

                  const Spacer(),

                  // Grant All button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Grant All Permissions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(_PermissionItem item) {
    final isGranted = item.status.isGranted;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? Colors.green.shade200 : AppTheme.softGray,
          width: 1.5,
        ),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : AppTheme.primary.withOpacity(0.1),
            ),
            child: Icon(item.icon,
              color: isGranted ? Colors.green : AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(item.description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isGranted ? Colors.green : AppTheme.softGray,
            size: 24,
          ),
        ],
      ),
    );
  }
}
