import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  final OneSignalService _oneSignal = OneSignalService();
  final ApiService _apiService = ApiService();
  final AuthState _authState = AuthState();

  bool _notificationGranted = false;
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  bool _locationGranted = false;

  // Track if user previously denied and we need to open settings
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

  // Re-check permissions when user returns from app settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      if (mounted) context.go('/');
      return;
    }

    final notification = await _oneSignal.hasPermission();
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final location = await Permission.location.isGranted;

    // Check if notification was permanently denied (user tapped "Don't allow" before)
    final notifStatus = await _oneSignal.getPermissionStatus();
    final permanentlyDenied = notifStatus == OSNotificationPermission.denied;

    if (mounted) {
      setState(() {
        _notificationGranted = notification;
        _cameraGranted = camera;
        _microphoneGranted = microphone;
        _locationGranted = location;
        _notificationPermanentlyDenied = permanentlyDenied && !notification;
      });
    }

    // If notification permission is already granted, set up OneSignal and proceed
    if (notification) {
      await _setupOneSignalUser();
      // If all permissions granted, go home
      if (camera && microphone && location && mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _setupOneSignalUser() async {
    try {
      debugPrint('🔧 Setting up OneSignal user...');

      final user = _authState.user;
      if (user != null) {
        // Correct order: login(uid) THEN optIn()
        // login() links this device's push token to the user's external_id
        OneSignal.login(user.uid);
        // optIn() ensures the subscription is active
        OneSignal.User.pushSubscription.optIn();

        // Set targeting tags
        await _oneSignal.setTags({
          'auth_provider': user.authProvider,
          'has_notifications': 'true',
          'has_camera': _cameraGranted.toString(),
          'has_microphone': _microphoneGranted.toString(),
          'has_location': _locationGranted.toString(),
        });

        debugPrint('✅ OneSignal.login(${user.uid}) called');
        debugPrint('   Player ID: ${_oneSignal.playerId}');
        debugPrint('   Subscribed: ${_oneSignal.isSubscribed}');
      }

      // Save permissions to backend
      if (user != null) {
        await _apiService.savePermissions(
          camera: _cameraGranted,
          microphone: _microphoneGranted,
          notifications: _notificationGranted,
        ).catchError((_) => <String, dynamic>{'success': false});
      }
    } catch (e) {
      debugPrint('❌ OneSignal setup error: $e');
    }
  }

  Future<void> _requestAllPermissions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ── Step 1: Notifications (MANDATORY) ───────────────────────────────────
      if (!_notificationGranted) {
        if (_notificationPermanentlyDenied) {
          setState(() => _isLoading = false);
          _showOpenSettingsDialog();
          return;
        }

        debugPrint('🔔 Requesting notification permission...');
        // Uses the native OS permission dialog — same as camera/location
        final granted = await _oneSignal.requestPermission();
        debugPrint('🔔 Notification permission: $granted');

        if (mounted) setState(() => _notificationGranted = granted);

        if (!granted) {
          final status = await _oneSignal.getPermissionStatus();
          if (mounted) {
            setState(() {
              _notificationPermanentlyDenied = status == OSNotificationPermission.denied;
              _isLoading = false;
            });
          }
          _showNotificationRequiredDialog();
          return;
        }
      }

      // Permission granted — set up OneSignal subscription + user identity
      await _setupOneSignalUser();

      // ── Step 2: Camera (optional) ────────────────────────────────────────────
      if (!_cameraGranted) {
        final status = await Permission.camera.request();
        if (mounted) setState(() => _cameraGranted = status.isGranted);
      }

      // ── Step 3: Microphone (optional) ────────────────────────────────────────
      if (!_microphoneGranted) {
        final status = await Permission.microphone.request();
        if (mounted) setState(() => _microphoneGranted = status.isGranted);
      }

      // ── Step 4: Location (optional) ──────────────────────────────────────────
      if (!_locationGranted) {
        final status = await Permission.location.request();
        if (mounted) setState(() => _locationGranted = status.isGranted);
      }

      if (mounted) context.go('/');
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Shown when notification permission is denied but not permanently
  void _showNotificationRequiredDialog() {
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
              _requestAllPermissions();
            },
            child: const Text('Allow Notifications'),
          ),
        ],
      ),
    );
  }

  // Shown when notification permission is permanently denied — must go to settings
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
              openAppSettings(); // Opens system app settings
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    if (!mounted) return;
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
      canPop: false, // Cannot go back — notification permission is mandatory
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

                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.security_outlined, size: 60, color: AppTheme.primary),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'App Permissions',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'We need a few permissions to provide you the best experience',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    _buildPermissionItem(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      description: 'Receive updates and blessings from Guruji',
                      required: true,
                      granted: _notificationGranted,
                      permanentlyDenied: _notificationPermanentlyDenied,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionItem(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      description: 'Share photos and videos',
                      required: false,
                      granted: _cameraGranted,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionItem(
                      icon: Icons.mic_outlined,
                      title: 'Microphone',
                      description: 'Record audio messages',
                      required: false,
                      granted: _microphoneGranted,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionItem(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      description: 'Find nearby events and centers',
                      required: false,
                      granted: _locationGranted,
                    ),

                    const SizedBox(height: 24),

                    // Warning if notification permanently denied
                    if (_notificationPermanentlyDenied)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Notifications are blocked. Please enable them in your device Settings to continue.',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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
                                'Notifications are required. Camera, microphone, and location are optional.',
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

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _notificationPermanentlyDenied
                                    ? 'Open Settings'
                                    : _notificationGranted
                                        ? 'Continue'
                                        : 'Grant Permissions',
                                style: const TextStyle(
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

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool required,
    required bool granted,
    bool permanentlyDenied = false,
  }) {
    Color borderColor = Colors.transparent;
    Color bgColor = Colors.white;
    if (granted) {
      borderColor = Colors.green.shade300;
    } else if (permanentlyDenied && required) {
      borderColor = Colors.red.shade300;
      bgColor = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
        border: Border.all(color: borderColor, width: granted || permanentlyDenied ? 2 : 0),
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
                  : permanentlyDenied && required
                      ? Colors.red.shade100
                      : AppTheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              granted
                  ? Icons.check_circle
                  : permanentlyDenied && required
                      ? Icons.block
                      : icon,
              color: granted
                  ? Colors.green.shade700
                  : permanentlyDenied && required
                      ? Colors.red.shade700
                      : AppTheme.primary,
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
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (granted) Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
        ],
      ),
    );
  }
}
