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

/// Whether this screen was opened for first-time setup (from profile-setup)
/// or later from the bell icon tap.
///
/// `isFirstTime = true`  → replaces entire stack with home after granting
/// `isFirstTime = false` → pops back to where user came from (bell icon scenario)
class AllPermissionsScreen extends StatefulWidget {
  final bool isFirstTime;
  const AllPermissionsScreen({super.key, this.isFirstTime = true});

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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();

    _checkCurrentPermission();
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
      _checkCurrentPermission();
    }
  }

  Future<void> _checkCurrentPermission() async {
    if (kIsWeb) {
      _goHome();
      return;
    }

    final granted = await _oneSignal.hasPermission();
    final status = await _oneSignal.getPermissionStatus();

    if (!mounted) return;

    setState(() {
      _notificationGranted = granted;
      _notificationPermanentlyDenied =
          status == OSNotificationPermission.denied && !granted;
    });

    // Already granted — set up OneSignal, persist, and proceed
    if (granted) {
      await _onPermissionGranted();
    }
  }

  Future<void> _onPermissionGranted() async {
    // Persist so splash never redirects here again
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_granted', true);
    } catch (_) {}

    // Link OneSignal identity
    try {
      final user = _authState.user;
      if (user != null) {
        OneSignal.login(user.uid);
        OneSignal.User.pushSubscription.optIn();
        await _oneSignal.setTags({
          'auth_provider': user.authProvider,
          'has_notifications': 'true',
        });
      }
      if (_authState.user != null) {
        await _apiService.savePermissions(
          camera: false,
          microphone: false,
          notifications: true,
        ).catchError((_) => <String, dynamic>{'success': false});
      }
    } catch (e) {
      debugPrint('❌ OneSignal setup error: $e');
    }

    if (!mounted) return;
    _goHome();
  }

  /// Navigate correctly depending on whether we're in first-time setup
  /// or arrived from bell icon tap.
  void _goHome() {
    if (widget.isFirstTime) {
      // Replace entire stack — user should not be able to go back to this screen
      context.go('/');
    } else {
      // Go to notifications list (came from bell icon)
      if (context.canPop()) {
        context.pop();
        context.push('/notifications');
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;

    if (_notificationGranted) {
      await _onPermissionGranted();
      return;
    }

    if (_notificationPermanentlyDenied) {
      _showOpenSettingsDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔔 Requesting notification permission...');
      final granted = await _oneSignal.requestPermission();
      debugPrint('🔔 Result: $granted');

      if (!mounted) return;
      setState(() {
        _notificationGranted = granted;
        _isLoading = false;
      });

      if (granted) {
        await _onPermissionGranted();
      } else {
        // Check if now permanently denied
        final status = await _oneSignal.getPermissionStatus();
        final permanentlyDenied = status == OSNotificationPermission.denied;
        if (mounted) {
          setState(() => _notificationPermanentlyDenied = permanentlyDenied);
        }
        // Do NOT block the user — just show info, allow them to skip
      }
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skipAndContinue() {
    // User chose to skip — go home without notifications
    // They can always grant later by tapping the bell icon
    if (widget.isFirstTime) {
      context.go('/');
    } else {
      if (context.canPop()) context.pop();
    }
  }

  void _showOpenSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppTheme.primary, size: 26),
            SizedBox(width: 12),
            Expanded(child: Text('Enable Notifications')),
          ],
        ),
        content: const Text(
          'Notifications are blocked. Go to Settings → App → Notifications and enable them.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Skip', style: TextStyle(color: AppTheme.textSecondary)),
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
      // Allow back navigation — don't block the app
      canPop: !widget.isFirstTime,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.isFirstTime) {
          // First-time: back goes to home (can't go back to login)
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: !widget.isFirstTime
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  onPressed: _skipAndContinue,
                ),
              )
            : null,
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
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(),

                    // Bell icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _notificationGranted
                            ? Colors.green.shade50
                            : AppTheme.primary.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        _notificationGranted
                            ? Icons.notifications_active
                            : Icons.notifications_outlined,
                        size: 52,
                        color: _notificationGranted
                            ? Colors.green.shade600
                            : AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      _notificationGranted
                          ? 'Notifications Enabled!'
                          : 'Stay Connected',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _notificationGranted
                                ? Colors.green.shade700
                                : AppTheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _notificationGranted
                          ? 'You will receive blessings and updates from Guruji.'
                          : _notificationPermanentlyDenied
                              ? 'Notifications are blocked in your device settings. Tap "Open Settings" to enable them.'
                              : 'Allow notifications to receive updates, reminders, and blessings from Guruji.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Status card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [AppTheme.softShadow],
                        border: Border.all(
                          color: _notificationGranted
                              ? Colors.green.shade200
                              : _notificationPermanentlyDenied
                                  ? Colors.orange.shade200
                                  : AppTheme.softGray,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _notificationGranted
                                  ? Colors.green.shade50
                                  : _notificationPermanentlyDenied
                                      ? Colors.orange.shade50
                                      : AppTheme.primary.withValues(alpha: 0.08),
                            ),
                            child: Icon(
                              _notificationGranted
                                  ? Icons.check_circle
                                  : _notificationPermanentlyDenied
                                      ? Icons.settings_outlined
                                      : Icons.notifications_outlined,
                              color: _notificationGranted
                                  ? Colors.green.shade600
                                  : _notificationPermanentlyDenied
                                      ? Colors.orange.shade700
                                      : AppTheme.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Push Notifications',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  _notificationGranted
                                      ? 'Allowed ✓'
                                      : _notificationPermanentlyDenied
                                          ? 'Blocked — open Settings to enable'
                                          : 'Not yet allowed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _notificationGranted
                                        ? Colors.green.shade700
                                        : _notificationPermanentlyDenied
                                            ? Colors.orange.shade700
                                            : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Primary action button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _notificationPermanentlyDenied
                                ? _showOpenSettingsDialog
                                : _notificationGranted
                                    ? _goHome
                                    : _requestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _notificationGranted
                              ? Colors.green.shade600
                              : AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _notificationPermanentlyDenied
                                    ? 'Open Settings'
                                    : _notificationGranted
                                        ? 'Continue →'
                                        : 'Allow Notifications',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Skip link — always visible, never blocks
                    if (!_notificationGranted)
                      TextButton(
                        onPressed: _skipAndContinue,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
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
