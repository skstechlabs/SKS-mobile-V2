import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_storage_service.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/localization_service.dart';
import '../auth/auth_state.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationStorageService _storageService = NotificationStorageService();
  final OneSignalService _oneSignalService = OneSignalService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _cleanupExpiredNotifications();
    _checkNotificationPermission();
    
    // Listen for notification changes
    _storageService.addListener(_onNotificationsChanged);
  }
  
  Future<void> _cleanupExpiredNotifications() async {
    // Trigger cleanup of expired notifications
    final allNotifications = _storageService.getAll();
    debugPrint('🗑️ Checking for expired notifications (showing ${allNotifications.length} active)');
  }

  Future<void> _checkNotificationPermission() async {
    final hasPermission = await _oneSignalService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
      _isCheckingPermission = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    // Check current permission status
    final currentPermission = await _oneSignalService.getPermissionStatus();
    
    if (currentPermission == OSNotificationPermission.denied) {
      // Permission was permanently denied, need to open settings
      _showOpenSettingsDialog();
      return;
    }
    
    // Request permission
    final granted = await _oneSignalService.requestPermission();
    
    if (granted) {
      // Link user to OneSignal
      final authState = AuthState();
      if (authState.user != null) {
        await _oneSignalService.setExternalUserId(authState.user!.uid);
        await _oneSignalService.optIn();
      }
      
      setState(() {
        _hasPermission = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(context.tr('notifications_enabled_success'))),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Permission denied
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.notifications_active, color: AppTheme.primary),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(context.tr('enable_notifications'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('notifications_settings_guide'),
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('settings_path_guide'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Open app settings
              // Note: Requires permission_handler package
            },
            icon: Icon(Icons.settings),
            label: Text(context.tr('open_settings')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text(context.tr('notifications_disabled'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('notification_benefits_message'),
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 16),
            _buildBenefitItem(Icons.event, context.tr('benefit_events')),
            SizedBox(height: 8),
            _buildBenefitItem(Icons.auto_awesome, context.tr('benefit_new_content')),
            SizedBox(height: 8),
            _buildBenefitItem(Icons.celebration, context.tr('benefit_achievements')),
            SizedBox(height: 8),
            _buildBenefitItem(Icons.schedule, context.tr('benefit_reminders')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('maybe_later')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestNotificationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('enable_now')),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _storageService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged(List<NotificationModel> notifications) {
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _unreadCount = _storageService.getUnreadCount();
      });
    }
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _storageService.getAll();
      _unreadCount = _storageService.getUnreadCount();
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    await _storageService.markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    await _storageService.markAllAsRead();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await _storageService.deleteNotification(notificationId);
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('clear_all_notifications')),
        content: Text(context.tr('delete_all_notifications_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('clear_all'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearAll();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return context.tr('just_now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}${context.tr('minutes_ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${context.tr('hours_ago')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${context.tr('days_ago')}';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotifications = _notifications.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(
              context.tr('notifications'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: hasNotifications
            ? [
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: Text(context.tr('mark_all_read')),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'clear') {
                      _clearAll();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(context.tr('clear_all')),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Permission Banner
          if (!_isCheckingPermission && !_hasPermission)
            _buildPermissionBanner(),
          
          // Main Content
          Expanded(
            child: hasNotifications
                ? RefreshIndicator(
                    onRefresh: () async {
                      _loadNotifications();
                      await _checkNotificationPermission();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('stay_updated_spiritual'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 60),
                          _buildEmptyState(context),
                          const SizedBox(height: 40),
                          _buildNotificationPreferences(context),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade200],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('stay_connected'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('enable_notifications_message'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showNotificationBenefitsDialog(),
                  icon: Icon(Icons.info_outline, size: 18),
                  label: Text(context.tr('learn_more')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _requestNotificationPermission,
                  icon: Icon(Icons.notifications_active, size: 18),
                  label: Text(context.tr('enable_now')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationBenefitsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.saffron],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('why_enable_notifications'),
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('notification_benefits_intro'),
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              SizedBox(height: 20),
              _buildDetailedBenefit(
                Icons.event,
                context.tr('benefit_events_title'),
                context.tr('benefit_events_desc'),
                Colors.blue,
              ),
              SizedBox(height: 16),
              _buildDetailedBenefit(
                Icons.auto_awesome,
                context.tr('benefit_content_title'),
                context.tr('benefit_content_desc'),
                Colors.purple,
              ),
              SizedBox(height: 16),
              _buildDetailedBenefit(
                Icons.celebration,
                context.tr('benefit_achievements_title'),
                context.tr('benefit_achievements_desc'),
                Colors.orange,
              ),
              SizedBox(height: 16),
              _buildDetailedBenefit(
                Icons.schedule,
                context.tr('benefit_reminders_title'),
                context.tr('benefit_reminders_desc'),
                Colors.green,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('privacy_message'),
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('maybe_later')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _requestNotificationPermission();
            },
            icon: Icon(Icons.notifications_active),
            label: Text(context.tr('enable_notifications')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBenefit(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('notification_deleted'))),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          // Navigate to notification detail screen
          context.push('/notifications/${notification.id}');
        },
        child: Container(
          color: notification.isRead ? Colors.white : AppTheme.primary.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.receivedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppTheme.softGray,
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('no_notifications_yet'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              context.tr('notifications_description'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Show enable button if permission not granted
          if (!_hasPermission) ...[
            const SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.saffron.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    context.tr('enable_notifications_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.tr('enable_notifications_subtitle'),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _requestNotificationPermission,
                    icon: Icon(Icons.notifications_active),
                    label: Text(context.tr('enable_notifications')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showNotificationBenefitsDialog,
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text(context.tr('why_enable')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationPreferences(BuildContext context) {
    return Column(
      children: [
        _buildPreferenceCard(
          context,
          icon: Icons.notifications_active,
          title: context.tr('events'),
          description: context.tr('get_notified_gatherings'),
        ),
        const SizedBox(height: 16),
        _buildPreferenceCard(
          context,
          icon: Icons.notifications_active,
          title: context.tr('new_content'),
          description: context.tr('stay_updated_new_content'),
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
