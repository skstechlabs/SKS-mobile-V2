import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/audio_player_service.dart';
import '../services/notification_storage_service.dart';
import '../services/localization_service.dart';
import 'spiritual_background.dart';
import 'mini_audio_player.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final NotificationStorageService _notificationService = NotificationStorageService();
  int _unreadCount = 0;

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
    if (mounted) {
      try {
        setState(() {});
      } catch (e) {
        debugPrint('Error updating audio state: $e');
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: false,
        title: Text(
          context.tr('app_full_name'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD84315),
            letterSpacing: 0.3,
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
      body: Column(
        children: [
          Expanded(child: SpiritualBackground(child: widget.child)),
          // Mini Audio Player
          GestureDetector(
            onTap: () {
              try {
                if (_audioService.currentSong != null) {
                  // Navigate to audio player when implemented
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio player will open here')),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error handling audio player tap: $e');
              }
            },
            child: const MiniAudioPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
                  icon: SizedBox(height: 24), // Placeholder for center button
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.connect_without_contact_outlined),
                  activeIcon: const Icon(Icons.connect_without_contact),
                  label: context.tr('contact'),
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
                        onTap: () => context.go('/notifications'),
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
                    // Notification badge
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
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
    );
  }

  void _onItemTapped(BuildContext context, int index) {
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
        context.go('/guruji-connect');
        break;
      case 4:
        context.go('/events');
        break;
    }
  }
}
