import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_storage_service.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  String? _playerId;
  final bool _isWebPlatform = kIsWeb;
  
  // Callback for navigation (set from main.dart after router is available)
  Function(String)? onNavigateToNotification;

  /// Set up notification event handlers (call this after OneSignal.initialize in main.dart)
  void setupNotificationHandlers() {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web platform - skipping handlers');
      return;
    }

    try {
      _setupNotificationHandlers();
      debugPrint('✅ OneSignal notification handlers configured');
    } catch (e) {
      debugPrint('❌ Failed to setup notification handlers: $e');
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    // Notification opened handler
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('📱 Notification clicked: ${event.notification.notificationId}');
      debugPrint('📱 Title: ${event.notification.title}');
      debugPrint('📱 Body: ${event.notification.body}');
      debugPrint('📱 Additional Data: ${event.notification.additionalData}');
      
      // Store notification
      _storeNotification(event.notification);
      
      // Handle notification click
      _handleNotificationOpened(event);
    });

    // Notification received handler (foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('📬 Notification received in foreground: ${event.notification.notificationId}');
      
      // Store notification
      _storeNotification(event.notification);
      
      // Display the notification even when app is in foreground
      event.notification.display();
    });

    // Permission observer
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint('🔔 Notification permission state changed: $state');
    });

    // Subscription observer
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint('📊 Push subscription state changed');
      debugPrint('   - ID: ${state.current.id}');
      debugPrint('   - Token: ${state.current.token}');
      debugPrint('   - Opted In: ${state.current.optedIn}');
      
      _playerId = state.current.id;
    });
  }

  /// Store notification in local storage
  void _storeNotification(OSNotification notification) {
    try {
      // OneSignal SDK guarantees notificationId is never null, but we add fallback for safety
      final finalNotificationId = notification.notificationId.isEmpty
          ? 'notif_${DateTime.now().millisecondsSinceEpoch}'
          : notification.notificationId;
      
      // Get TTL from notification additional data (default 30 days if not specified)
      int ttlDays = 30;
      final additionalData = notification.additionalData;
      if (additionalData != null) {
        // Check for ttl_days, ttl, or expiry_days in additional data
        final ttlValue = additionalData['ttl_days'] ?? 
                        additionalData['ttl'] ??
                        additionalData['expiry_days'];
        if (ttlValue != null) {
          ttlDays = int.tryParse(ttlValue.toString()) ?? 30;
        }
      }
      
      final notificationModel = NotificationModel(
        id: finalNotificationId,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        receivedAt: DateTime.now(),
        additionalData: notification.additionalData,
        isRead: false,
        ttlDays: ttlDays,
      );

      NotificationStorageService().addNotification(notificationModel);
      debugPrint('✅ Notification stored: ${notificationModel.title} (TTL: $ttlDays days)');
    } catch (e) {
      debugPrint('❌ Error storing notification: $e');
    }
  }

  /// Handle notification opened/clicked
  void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notification = event.notification;
    final additionalData = notification.additionalData;
    
    debugPrint('🔗 Handling notification click');
    
    // Navigate to notification detail screen
    final notificationId = notification.notificationId;
    if (notificationId.isNotEmpty && onNavigateToNotification != null) {
      onNavigateToNotification!(notificationId);
      debugPrint('✅ Navigated to notification detail: $notificationId');
    }
    
    // Handle additional actions from notification data
    if (additionalData != null) {
      // Handle direct URL opening (if specified to open immediately)
      if (additionalData.containsKey('open_url_immediately')) {
        final url = additionalData['url'] as String?;
        if (url != null) {
          _openUrl(url);
        }
      }
      
      // Handle screen navigation (custom deep linking)
      if (additionalData.containsKey('screen')) {
        final screen = additionalData['screen'];
        debugPrint('🔗 Custom screen navigation: $screen');
        // Can be extended for specific screen routing
      }
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
      } else {
        debugPrint('❌ Cannot launch URL: $finalUrl');
      }
    } catch (e) {
      debugPrint('❌ Error opening URL: $e');
    }
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - returning false');
      return false;
    }
    return OneSignal.Notifications.permission;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - simulating permission granted');
      return true; // Simulate success on web
    }
    return await OneSignal.Notifications.requestPermission(true);
  }

  /// Get OneSignal Player ID (External User ID)
  String? get playerId {
    if (_isWebPlatform) return null;
    return _playerId ?? OneSignal.User.pushSubscription.id;
  }

  /// Set external user ID (your backend user ID)
  Future<void> setExternalUserId(String userId) async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - skipping setExternalUserId');
      return;
    }
    try {
      OneSignal.login(userId);
      debugPrint('✅ OneSignal external user ID set: $userId');
    } catch (e) {
      debugPrint('❌ Failed to set external user ID: $e');
    }
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - skipping removeExternalUserId');
      return;
    }
    try {
      OneSignal.logout();
      debugPrint('✅ OneSignal external user ID removed');
    } catch (e) {
      debugPrint('❌ Failed to remove external user ID: $e');
    }
  }

  /// Set user tags for targeting
  Future<void> setTags(Map<String, String> tags) async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - skipping setTags');
      return;
    }
    try {
      OneSignal.User.addTags(tags);
      debugPrint('✅ OneSignal tags set: $tags');
    } catch (e) {
      debugPrint('❌ Failed to set tags: $e');
    }
  }

  /// Remove user tags
  Future<void> removeTags(List<String> keys) async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - skipping removeTags');
      return;
    }
    try {
      OneSignal.User.removeTags(keys);
      debugPrint('✅ OneSignal tags removed: $keys');
    } catch (e) {
      debugPrint('❌ Failed to remove tags: $e');
    }
  }

  /// Opt in to push notifications
  Future<void> optIn() async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - skipping optIn');
      return;
    }
    try {
      OneSignal.User.pushSubscription.optIn();
      debugPrint('✅ Opted in to push notifications');
    } catch (e) {
      debugPrint('❌ Failed to opt in: $e');
    }
  }

  /// Opt out of push notifications
  Future<void> optOut() async {
    if (_isWebPlatform) {
      debugPrint('⚠️ OneSignal not supported on web - skipping optOut');
      return;
    }
    try {
      OneSignal.User.pushSubscription.optOut();
      debugPrint('✅ Opted out of push notifications');
    } catch (e) {
      debugPrint('❌ Failed to opt out: $e');
    }
  }

  /// Check if user is subscribed to push notifications
  bool get isSubscribed {
    if (_isWebPlatform) return false;
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }

  /// Get notification permission status
  Future<OSNotificationPermission> getPermissionStatus() async {
    if (_isWebPlatform) {
      return OSNotificationPermission.notDetermined;
    }
    return OneSignal.Notifications.permissionNative();
  }
}
