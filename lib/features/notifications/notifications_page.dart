import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'New Meditation Session',
        'message': 'Join us for a special meditation session this evening',
        'time': '2 hours ago',
        'type': 'event',
        'read': false,
      },
      {
        'title': 'Daily Quote',
        'message': 'Your daily wisdom has been updated',
        'time': '5 hours ago',
        'type': 'content',
        'read': false,
      },
      {
        'title': 'Event Reminder',
        'message': 'Meditation Retreat starts in 3 days',
        'time': '1 day ago',
        'type': 'reminder',
        'read': true,
      },
      {
        'title': 'New Bhajan Released',
        'message': 'Listen to the latest devotional song',
        'time': '2 days ago',
        'type': 'content',
        'read': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(context, notifications[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppTheme.softGray,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'We\'ll notify you about important updates',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkBrown.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notification) {
    final isUnread = !(notification['read'] as bool);
    
    return Container(
      color: isUnread ? AppTheme.beige.withValues(alpha: 0.3) : Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification['type'] as String).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification['type'] as String),
            color: _getNotificationColor(notification['type'] as String),
          ),
        ),
        title: Text(
          notification['title'] as String,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(notification['message'] as String),
            SizedBox(height: 4),
            Text(
              notification['time'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.darkBrown.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.saffron,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {},
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'content':
        return Icons.auto_awesome;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'event':
        return AppTheme.saffron;
      case 'content':
        return AppTheme.gold;
      case 'reminder':
        return Colors.blue;
      default:
        return AppTheme.darkBrown;
    }
  }
}
