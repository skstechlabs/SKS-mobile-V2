import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_storage_service.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final NotificationStorageService _storageService = NotificationStorageService();
  NotificationModel? _notification;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadNotification();
  }

  void _loadNotification() {
    final notification = _storageService.getById(widget.notificationId);
    setState(() {
      _notification = notification;
    });

    // Mark as read
    if (notification != null && !notification.isRead) {
      _storageService.markAsRead(widget.notificationId);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      debugPrint('🔗 Attempting to open URL: $url');
      
      // Ensure URL has proper scheme
      String finalUrl = url.trim();
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }
      
      final uri = Uri.parse(finalUrl);
      debugPrint('🔗 Parsed URI: $uri');
      
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('🔗 Can launch URL: $canLaunch');
      
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ URL launched: $launched');
        
        if (!launched) {
          _showError('Failed to open link');
        }
      } else {
        debugPrint('❌ Cannot launch URL: $finalUrl');
        _showError('Cannot open this link');
      }
    } catch (e) {
      debugPrint('❌ Error opening URL: $e');
      _showError('Failed to open link: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  List<String> _extractUrls(String text) {
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    final matches = urlPattern.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_notification == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Notification not found'),
        ),
      );
    }

    final notification = _notification!;
    final urlsInBody = _extractUrls(notification.body);
    final additionalUrl = notification.additionalData?['url'] as String?;
    final actionUrl = notification.additionalData?['action_url'] as String?;
    final buttonText = notification.additionalData?['button_text'] as String?;

    // Deep link data from class/day notifications
    final screen = notification.additionalData?['screen'] as String?;
    final classId = notification.additionalData?['classId'] as String?;
    final dayId = notification.additionalData?['dayId'] as String?;
    final dayNumber = notification.additionalData?['dayNumber'] as String?;
    final level = notification.additionalData?['level'] as String?;

    // Build deep link action if this is a class notification
    Widget? deepLinkButton;
    if (screen == 'DayVideoScreen' && classId != null && dayId != null) {
      deepLinkButton = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton.icon(
          onPressed: () {
            final dayNum = int.tryParse(dayNumber ?? '1') ?? 1;
            context.push(
              '/classes/days/$dayId/video?title=${Uri.encodeComponent(notification.title)}&dayNumber=$dayNum',
            );
          },
          icon: const Icon(Icons.play_circle_outline, size: 22),
          label: Text(
            dayNumber != null
                ? 'Watch Day $dayNumber${level != null ? ' · $level' : ''}'
                : 'Watch Video',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.saffron,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (screen == 'ClassDaysListScreen' && classId != null) {
      deepLinkButton = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton.icon(
          onPressed: () {
            context.push(
              '/classes/$classId/days',
              extra: {
                'classTitle': level ?? 'Class',
                'level': level ?? 'Level',
              },
            );
          },
          icon: const Icon(Icons.school_outlined, size: 22),
          label: Text(
            level != null ? 'Go to $level' : 'Go to Classes',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.saffron,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black),
            onPressed: () async {
              await _storageService.deleteNotification(widget.notificationId);
              if (mounted) {
                context.pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and timestamp
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
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
                      Icons.notifications_active,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(notification.receivedAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expires: ${_formatDateTime(notification.receivedAt.add(Duration(days: notification.ttlDays)))}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),

            // Body with expand/collapse
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCrossFade(
                    firstChild: Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        height: 1.6,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  if (notification.body.length > 150)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                      label: Text(_isExpanded ? 'Show less' : 'Read more'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Deep link action (Go to Class / Watch Day) ─────────────────
            if (deepLinkButton != null) ...[
              deepLinkButton,
              const SizedBox(height: 16),
            ],

            // Action buttons from additionalData
            if (actionUrl != null || additionalUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (actionUrl != null)
                      ElevatedButton.icon(
                        onPressed: () => _openUrl(actionUrl),
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: Text(buttonText ?? 'Open Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (additionalUrl != null && additionalUrl != actionUrl)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () => _openUrl(additionalUrl),
                          icon: const Icon(Icons.link, size: 20),
                          label: const Text('Open Additional Link'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // URLs found in body text
            if (urlsInBody.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Links in message:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...urlsInBody.map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _openUrl(url),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      url,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade700,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),

            // Additional data (for debugging/advanced users)
            if (notification.additionalData != null &&
                notification.additionalData!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: ExpansionTile(
                  title: Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: notification.additionalData!.entries
                            .where((e) => e.key != 'url' && e.key != 'action_url' && e.key != 'button_text')
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.key}: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${entry.value}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
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
}
