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
      // On Home tab — double-back-press to exit
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
    // On any other tab — back always goes to Home, never exits app
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
      // Always intercept — we fully control back behavior
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: OfflineBanner(child: widget.child),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniAudioPlayer(),
                  _buildBottomNav(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth / 20).clamp(16.0, 22.0);
    // Show a back-to-home button on non-home tabs
    final bool showBackButton = widget.currentIndex != 0;

    return AppBar(
      backgroundColor: AppTheme.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: showBackButton ? 0 : 16,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.primary, size: 20),
              onPressed: () => context.go('/'),
            )
          : null,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        context.tr('app_full_name'),
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Notification icon — small tight circle, icon clearly visible
        GestureDetector(
          onTap: () => _onNotificationTap(context),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tagBg,
                    border: Border.all(color: AppTheme.tagBorder, width: 1.5),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/notification-icon.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Profile icon — same tight circle
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tagBg,
                border: Border.all(color: AppTheme.tagBorder, width: 1.5),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/icons/profile-icon.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
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
    const double barHeight = 82;
    // Responsive icon size — scales with screen width, clamped between 90–120px
    final double medIconSize =
        (MediaQuery.of(context).size.width * 0.26).clamp(90.0, 120.0);
    // How far the icon rises above the bar top
    final double riseAbove = (medIconSize - barHeight) / 2 + 4;

    return Container(
      color: AppTheme.cream,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Bar background ──────────────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.gold.withValues(alpha: 0.40),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textPrimary.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                ),
              ),
              // ── 4 regular items + 1 placeholder for meditation ──────────
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavImageItem(
                      iconPath: 'assets/images/icons/home-icon.png',
                      label: context.tr('home'),
                      isActive: widget.currentIndex == 0,
                      onTap: () => context.go('/'),
                    ),
                    _NavImageItem(
                      iconPath: 'assets/images/icons/classes-icon.png',
                      label: context.tr('classes'),
                      isActive: widget.currentIndex == 1,
                      onTap: () => context.go('/learnings'),
                    ),
                    // Centre placeholder — same width keeps spacing symmetric
                    SizedBox(width: MediaQuery.of(context).size.width / 5),
                    _NavImageItem(
                      iconPath: 'assets/images/icons/songs-icon.png',
                      label: context.tr('songs'),
                      isActive: widget.currentIndex == 3,
                      onTap: () => context.go('/all-songs'),
                    ),
                    _NavImageItem(
                      iconPath: 'assets/images/icons/events-icon.png',
                      label: context.tr('events'),
                      isActive: widget.currentIndex == 4,
                      onTap: () => context.go('/events'),
                      iconSize: 46,
                    ),
                  ],
                ),
              ),
              // ── Meditation icon — rises above bar, no circle ─────────────
              Positioned(
                top: -riseAbove,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.go('/meditation/timer'),
                    behavior: HitTestBehavior.opaque,
                    child: Image.asset(
                      'assets/images/icons/meditation-icon.png',
                      width: medIconSize,
                      height: medIconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Individual bottom nav item — fixed icon box + label + active dot.
class _NavImageItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double iconSize;

  const _NavImageItem({
    required this.iconPath,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.iconSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Image.asset(iconPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nav item using a Material IconData — for items without a custom PNG.
class _NavIconItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconItem({
    required this.icon,
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
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 28,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
