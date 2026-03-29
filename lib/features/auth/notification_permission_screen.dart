import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/api_service.dart';
import 'auth_state.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _isLoading = false;
  bool _permissionAlreadyGranted = false;
  final OneSignalService _oneSignal = OneSignalService();
  final ApiService _apiService = ApiService();
  final AuthState _authState = AuthState();

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
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
    
    // Check permission status on load
    _checkPermissionStatus();
  }
  
  Future<void> _checkPermissionStatus() async {
    if (kIsWeb) return;
    
    try {
      final hasPermission = await _oneSignal.hasPermission();
      debugPrint('📊 Initial permission check: $hasPermission');
      
      if (hasPermission) {
        setState(() => _permissionAlreadyGranted = true);
      }
    } catch (e) {
      debugPrint('⚠️ Error checking permission status: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔔 Requesting notification permission...');
      
      // Check if running on web
      if (kIsWeb) {
        debugPrint('🌐 Running on web - OneSignal not supported, skipping to home');
        
        // Save permission to backend (only if user is logged in)
        final user = _authState.user;
        if (user != null) {
          try {
            debugPrint('💾 Saving permissions to backend...');
            await _apiService.savePermissions(
              camera: false,
              microphone: false,
              notifications: true,
            );
            debugPrint('✅ Permissions saved to backend');
          } catch (e) {
            debugPrint('⚠️ Failed to save permissions to backend: $e');
          }
        }
        
        if (mounted) {
          debugPrint('🏠 Navigating to home screen (web)');
          context.go('/');
        }
        return;
      }
      
      // Check current permission status first
      final currentPermission = await _oneSignal.hasPermission();
      debugPrint('📊 Current permission status: $currentPermission');
      
      if (currentPermission) {
        debugPrint('ℹ️ Permission already granted - showing info dialog');
        _showAlreadyGrantedDialog();
        return;
      }
      
      // Request OneSignal notification permission (mobile only)
      debugPrint('📱 Calling OneSignal.Notifications.requestPermission(true)...');
      final granted = await _oneSignal.requestPermission();
      
      debugPrint('🔔 Permission request result: $granted');

      if (granted) {
        debugPrint('✅ Notification permission granted');
        
        // Opt in to notifications
        await _oneSignal.optIn();
        debugPrint('✅ Opted in to push notifications');

        // Save permission to backend (only if user is logged in)
        final user = _authState.user;
        if (user != null) {
          try {
            debugPrint('💾 Saving permissions to backend...');
            await _apiService.savePermissions(
              camera: false,
              microphone: false,
              notifications: true,
            );
            debugPrint('✅ Permissions saved to backend');
          } catch (e) {
            // If backend call fails, continue anyway
            debugPrint('⚠️ Failed to save permissions to backend: $e');
          }
        } else {
          // Set guest tag if user skipped login
          debugPrint('👤 User is guest, setting guest tags...');
          await _oneSignal.setTags({
            'user_type': 'guest',
            'permission_granted': 'true',
          });
          debugPrint('✅ Guest tags set');
        }

        // Small delay to ensure everything is registered
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          debugPrint('🏠 Navigating to home screen');
          context.go('/');
        }
      } else {
        debugPrint('❌ Notification permission denied');
        // Show strict message
        _showDeniedDialog();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error requesting notification permission: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAlreadyGrantedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Already Enabled'),
          ],
        ),
        content: const Text(
          'Notification permissions are already enabled for this app. '
          'You\'re all set to receive updates from Guruji!',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: Text('Continue', 
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              )),
          ),
        ],
      ),
    );
  }

  void _showDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Permission Required'),
          ],
        ),
        content: const Text(
          'To connect with Guruji and receive spiritual guidance, you must allow notifications. '
          'This is essential for staying connected with the community and receiving important updates.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: Text('Allow Notifications', 
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              )),
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
        content: Text(
          'Failed to request notification permission.\n\nError: $error\n\nPlease make sure:\n'
          '1. OneSignal App ID is configured\n'
          '2. Internet connection is active\n'
          '3. Google Play Services is installed (Android)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission(); // Retry
            },
            child: Text('Retry', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Spacer(),

                              // Animated Icon
                              ScaleTransition(
                                scale: _scaleAnim,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.2),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_outlined,
                                    size: 60,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Title
                              Text(
                                'Stay Connected with Guruji',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              // Description
                              Text(
                                'To receive spiritual guidance, event updates, and connect with the community, '
                                'you must enable notifications.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.6,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 40),

                              // Benefits
                              _buildBenefitItem(
                                Icons.event_outlined,
                                'Event Reminders',
                                'Never miss important spiritual gatherings',
                              ),
                              const SizedBox(height: 16),
                              _buildBenefitItem(
                                Icons.auto_awesome_outlined,
                                'Daily Wisdom',
                                'Receive daily spiritual messages from Guruji',
                              ),
                              const SizedBox(height: 16),
                              _buildBenefitItem(
                                Icons.people_outline,
                                'Community Updates',
                                'Stay connected with fellow seekers',
                              ),

                              const Spacer(),

                              // Strict Message
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
                                        'Notifications are mandatory to use this app',
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Allow Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _requestPermission,
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
                                      : Text(
                                          _permissionAlreadyGranted 
                                              ? 'Continue (Already Enabled)' 
                                              : 'Allow Notifications',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              
                              // Show status if already granted
                              if (_permissionAlreadyGranted)
                                Text(
                                  'Notifications are already enabled',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              
                              if (_permissionAlreadyGranted)
                                const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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
        ],
      ),
    );
  }
}
