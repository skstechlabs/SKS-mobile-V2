import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_storage_service.dart';
import '../../core/services/localization_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationStorageService _storageService = NotificationStorageService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _cleanupExpiredNotifications();
    
    // Listen for notification changes
    _storageService.addListener(_onNotificationsChanged);
  }
  
  Future<void> _cleanupExpiredNotifications() async {
    // Trigger cleanup of expired notifications
    final allNotifications = _storageService.getAll();
    debugPrint('🗑️ Checking for expired notifications (showing ${allNotifications.length} active)');
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
          onPressed: () => context.go('/'),
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
      body: hasNotifications
          ? RefreshIndicator(
              onRefresh: () async {
                _loadNotifications();
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
