import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';


class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    if (kIsWeb) {
      // Web: Request browser permissions
      try {
        // Request camera
        await Permission.camera.request();
        // Request microphone  
        await Permission.microphone.request();
        // Request notifications
        await Permission.notification.request();
        
        setState(() => _isLoading = false);
        if (mounted) context.go('/');
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) context.go('/');
      }
    } else {
      // Mobile: Request all permissions
      final permissions = [
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.photos,
        Permission.notification,
        Permission.location,
      ];

      await permissions.request();
      
      setState(() => _isLoading = false);
      if (mounted) context.go('/');
    }
  }

  void _skipPermissions() {
    // Navigate to home without requesting permissions
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spiritualGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                Container(
                  width: MediaQuery.of(context).size.width > 600 ? 100 : 80,
                  height: MediaQuery.of(context).size.width > 600 ? 100 : 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.saffronGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security, 
                    size: MediaQuery.of(context).size.width > 600 ? 50 : 40, 
                    color: Colors.white
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height > 700 ? 24 : 16),
                Text(
                  'Permissions Required',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: MediaQuery.of(context).size.width > 600 ? null : 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height > 700 ? 12 : 8),
                Text(
                  'To provide you with the best experience, we need access to:',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height > 700 ? 16 : 12),
                _buildPermissionItem(Icons.camera_alt, 'Camera', 'For capturing spiritual moments'),
                _buildPermissionItem(Icons.mic, 'Microphone', 'For audio recordings'),
                _buildPermissionItem(Icons.folder, 'Storage', 'For saving content'),
                _buildPermissionItem(Icons.photo_library, 'Photos', 'For accessing media'),
                _buildPermissionItem(Icons.notifications, 'Notifications', 'For spiritual reminders'),
                _buildPermissionItem(Icons.location_on, 'Location', 'For nearby events'),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: Image.asset(
                              'assets/images/SKS_Logo.png',
                              width: 24,
                              height: 24,
                            ),
                          )
                        : Text('Grant Permissions', style: TextStyle(fontSize: 18)),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _skipPermissions,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppTheme.saffron,
                    ),
                    child: Text(
                      'Skip Permissions', 
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height > 700 ? 6 : 4,
      ),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width > 600 ? 48 : 40,
            height: MediaQuery.of(context).size.width > 600 ? 48 : 40,
            decoration: BoxDecoration(
              color: AppTheme.saffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: AppTheme.saffron,
              size: MediaQuery.of(context).size.width > 600 ? 24 : 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
