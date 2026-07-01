import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/api_service.dart';
import 'auth_state.dart';

/// Key stored in SharedPreferences once the user grants notification permission.
/// This lets us skip the permission screen on subsequent app launches
/// without relying on OneSignal's synchronous .permission getter.
const String _kNotificationPermissionGrantedKey = 'notification_permission_granted';

class AllPermissionsScreen extends StatefulWidget {
  const AllPermissionsScreen({super.key});

  @override
  State<AllPermissionsScreen> createState() => _AllPermissionsScreenState();
}

class _AllPermissionsScreenState extends State<AllPermissionsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  final OneSignalService _oneSignal = OneSignalService();
  final ApiService _apiService = ApiService();
  final AuthState _authState = AuthState();

  bool _notificationGranted = false;
  bool _notificationPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  // Re-check when user returns from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Short delay for OS to sync permission state after returning from Settings
      Future.delayed(const Duration(milliseconds: 500), _checkPermissions);
    }
  }

  Future<void> _checkPermissions() async {
    // Web: skip permission screen
    if (kIsWeb) {
      if (mounted) context.go('/');
      return;
    }

    // Query the OS directly via permission_handler — this is always accurate
    // regardless of OneSignal SDK initialization state.
    // No delay needed: permission_handler calls the OS synchronously.
    final status = await Permission.notification.status;
    final bool granted = status.isGranted;

    if (mounted) {
      setState(() {
        _notificationGranted = granted;
        _notificationPermanentlyDenied = false; // reset; update below if needed
      });
    }

    if (granted) {
      await _persistPermissionGranted();
      await _setupOneSignalUser();
      if (mounted) context.go('/');
      return;
    }

    // Not granted — check if permanently denied (user tapped "Don't ask again")
    if (mounted) {
      setState(() {
        _notificationPermanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  /// Persist that notification permission was granted.
  /// This is the source of truth used by the splash screen to skip this screen.
  Future<void> _persistPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotificationPermissionGrantedKey, true);
      debugPrint('✅ Notification permission flag persisted');
    } catch (e) {
      debugPrint('⚠️ Could not persist permission flag: $e');
    }
  }

  Future<void> _setupOneSignalUser() async {
    try {
      final user = _authState.user;
      if (user != null) {
        // login() links identity; optIn() enables push delivery now that permission is granted
        OneSignal.login(user.uid);
        OneSignal.User.pushSubscription.optIn();
        await _oneSignal.setTags({
          'auth_provider': user.authProvider,
          'has_notifications': 'true',
        });
        debugPrint('✅ OneSignal.login(${user.uid}) + optIn() called after permission granted');
      }
      // Save to backend
      if (user != null) {
        await _apiService.savePermissions(
          camera: false,
          microphone: false,
          notifications: true,
        ).catchError((_) => <String, dynamic>{'success': false});
      }
    } catch (e) {
      debugPrint('❌ OneSignal setup error: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_notificationGranted) {
        // Already granted — just go home
        await _persistPermissionGranted();
        await _setupOneSignalUser();
        if (mounted) context.go('/');
        return;
      }

      if (_notificationPermanentlyDenied) {
        setState(() => _isLoading = false);
        _showOpenSettingsDialog();
        return;
      }

      debugPrint('🔔 Requesting notification permission...');
      final granted = await _oneSignal.requestPermission();
      debugPrint('🔔 Result: $granted');

      if (!mounted) return;
      setState(() => _notificationGranted = granted);

      if (granted) {
        await _persistPermissionGranted();
        await _setupOneSignalUser();
        if (mounted) context.go('/');
      } else {
        // Check OS state to distinguish "denied this time" vs "permanently denied"
        final status = await Permission.notification.status;
        if (mounted) {
          setState(() {
            _notificationPermanentlyDenied = status.isPermanentlyDenied;
            _isLoading = false;
          });
        }
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      if (mounted) setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Notifications Required')),
          ],
        ),
        content: const Text(
          'Push notifications are required to receive updates from Guruji. '
          'Please allow notifications to continue.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: const Text('Allow Notifications'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppTheme.primary, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Enable Notifications')),
          ],
        ),
        content: const Text(
          'Notifications are required to receive updates from Guruji.\n\n'
          'Please go to Settings → App → Notifications and enable them.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),

                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, size: 60, color: AppTheme.primary),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Stay Connected',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Allow notifications to receive blessings and updates from Guruji',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Status card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [AppTheme.softShadow],
                        border: Border.all(
                          color: _notificationGranted
                              ? Colors.green.shade200
                              : _notificationPermanentlyDenied
                                  ? Colors.red.shade200
                                  : AppTheme.softGray,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _notificationGranted
                                  ? Colors.green.shade50
                                  : _notificationPermanentlyDenied
                                      ? Colors.red.shade50
                                      : AppTheme.primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              _notificationGranted
                                  ? Icons.check_circle
                                  : _notificationPermanentlyDenied
                                      ? Icons.block
                                      : Icons.notifications_outlined,
                              color: _notificationGranted
                                  ? Colors.green.shade600
                                  : _notificationPermanentlyDenied
                                      ? Colors.red.shade600
                                      : AppTheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 3),
                                Text(
                                  _notificationGranted
                                      ? 'Allowed'
                                      : _notificationPermanentlyDenied
                                          ? 'Blocked — open Settings to enable'
                                          : 'Required to receive Guruji updates',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _notificationGranted
                                        ? Colors.green.shade700
                                        : _notificationPermanentlyDenied
                                            ? Colors.red.shade700
                                            : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_notificationGranted)
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _notificationPermanentlyDenied
                                    ? 'Open Settings'
                                    : _notificationGranted
                                        ? 'Continue'
                                        : 'Allow Notifications',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
