import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/enhanced_audio_player_service.dart';
import '../services/notification_storage_service.dart';
import '../services/localization_service.dart';
import '../services/onesignal_service.dart';
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
  final EnhancedAudioPlayerService _audioService =
      EnhancedAudioPlayerService();
  final NotificationStorageService _notificationService =
      NotificationStorageService();
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
    if (mounted) setState(() => _unreadCount = _notificationService.getUnreadCount());
  }

  Future<bool> _onWillPop() async {
    if (widget.currentIndex == 0) {
      final now = DateTime.now();
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return false;
      }
      return true;
    }
    if (mounted) context.go('/');
    return false;
  }

  Future<void> _onNotificationTap(BuildContext context) async {
    final hasPermission = await _oneSignal.hasPermission();
    if (!mounted) return;
    if (hasPermission) {
      context.push('/notifications');
    } else {
      context.push('/notification-permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: _buildAppBar(context),
        body: OfflineBanner(child: widget.child),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniAudioPlayer(),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      centerTitle: false,
      automaticallyImplyLeading: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        context.tr('app_full_name'),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.tagBg,
              border: Border.all(color: AppTheme.tagBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.softGray.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        border: Border(
          top: BorderSide(
            color: AppTheme.tagBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.cottage_outlined,
                activeIcon: Icons.cottage_rounded,
                label: context.tr('home'),
                isActive: widget.currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.auto_stories_outlined,
                activeIcon: Icons.auto_stories,
                label: context.tr('classes'),
                isActive: widget.currentIndex == 1,
                onTap: () => context.go('/learnings'),
              ),
              // Centre notification button — sits inline like all other items
              GestureDetector(
                onTap: () => _onNotificationTap(context),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active dot indicator (matches _NavItem pattern)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: widget.currentIndex == 2 ? 20 : 4,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: widget.currentIndex == 2
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Bell icon with gradient circle
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF3B30),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('notifications'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.self_improvement_outlined,
                activeIcon: Icons.self_improvement,
                label: context.tr('kalpataru'),
                isActive: widget.currentIndex == 3,
                onTap: () => context.go('/kalpataru'),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: context.tr('events'),
                isActive: widget.currentIndex == 4,
                onTap: () => context.go('/events'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Individual bottom nav item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 20 : 4,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon with warm pill background when active
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                letterSpacing: isActive ? 0.2 : 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
