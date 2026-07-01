import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/enhanced_audio_player_service.dart';
import '../services/notification_storage_service.dart';
import '../services/localization_service.dart';
import '../services/onesignal_service.dart';
import 'spiritual_background.dart';
import 'mini_audio_player.dart';
import 'offline_banner.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
  final NotificationStorageService _notificationService = NotificationStorageService();
  final OneSignalService _oneSignal = OneSignalService();
  int _unreadCount = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _audioService.addListener(_onAudioStateChanged);
    _notificationService.addListener(_onNotificationsChanged);
    _updateUnreadCount();
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    // Only rebuild if the audio playback visibility actually changed
    // (song started or stopped) to avoid rebuilding the entire scaffold
    // on every audio position update.
    if (!mounted) return;
    final hasAudio = _audioService.currentSong != null;
    if (hasAudio != _hadAudio) {
      _hadAudio = hasAudio;
      setState(() {});
    }
  }

  bool _hadAudio = false;

  void _onNotificationsChanged(List<NotificationModel> notifications) {
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    if (mounted) {
      setState(() {
        _unreadCount = _notificationService.getUnreadCount();
      });
    }
  }

  /// Handle Android back button press
  Future<bool> _onWillPop() async {
    // If we're on the home tab, show exit confirmation
    if (widget.currentIndex == 0) {
      final now = DateTime.now();
      if (_lastBackPressTime == null || 
          now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false; // Don't exit
      }
      return true; // Exit app
    }
    
    // If we're on other tabs, go to home
    if (mounted) {
      context.go('/');
    }
    return false; // Don't exit, navigate to home instead
  }

  /// Tap on notification bell — check permission first, re-prompt if not granted
  Future<void> _onNotificationTap(BuildContext context) async {
    final hasPermission = await _oneSignal.hasPermission();
    if (!mounted) return;

    if (hasPermission) {
      context.push('/notifications');
    } else {
      // Permission not granted — send to permissions screen to get it
      context.push('/notification-permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // We handle pop manually
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop(); // Exit the app
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          centerTitle: false,
          automaticallyImplyLeading: false, // Don't show back button on main tabs
          title: Text(
            context.tr('app_full_name'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD84315),
              letterSpacing: 0.8,
              height: 1.3,
              fontFamily: 'serif',
              shadows: [
                Shadow(
                  color: AppTheme.saffron.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  size: 26,
                ),
                tooltip: context.tr('profile_tooltip'),
                onPressed: () => context.push('/profile'),
              ),
            ),
          ],
        ),
        body: OfflineBanner(
          child: SpiritualBackground(child: widget.child),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini Audio Player — sits above the nav bar
            const MiniAudioPlayer(),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkBrown.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  BottomNavigationBar(
                    currentIndex: widget.currentIndex,
                    onTap: (index) => _onItemTapped(context, index),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: AppTheme.white,
                    selectedItemColor: AppTheme.saffron,
                    unselectedItemColor: AppTheme.darkBrown.withValues(alpha: 0.6),
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    iconSize: 24,
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.home_outlined),
                        activeIcon: const Icon(Icons.home),
                        label: context.tr('home'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.school_outlined),
                        activeIcon: const Icon(Icons.school),
                        label: context.tr('classes'),
                      ),
                      const BottomNavigationBarItem(
                        icon: SizedBox(height: 24),
                        label: '',
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.park_outlined),
                        activeIcon: const Icon(Icons.park),
                        label: context.tr('kalpataru'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.event_outlined),
                        activeIcon: const Icon(Icons.event),
                        label: context.tr('events'),
                      ),
                    ],
                  ),
                  // Floating center notification button
                  Positioned(
                    top: -28,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            color: AppTheme.saffron,
                            shape: const CircleBorder(),
                            elevation: 8,
                            child: InkWell(
                              onTap: () => _onNotificationTap(context),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    // Use go() for bottom nav tabs - this is the expected behavior
    // as tabs should replace each other, not stack
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/learnings');
        break;
      case 2:
        // Center button (notifications) - handled by floating button
        break;
      case 3:
        context.go('/kalpataru');
        break;
      case 4:
        context.go('/events');
        break;
    }
  }
}
