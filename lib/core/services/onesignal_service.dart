import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_storage_service.dart';
import '../router.dart';

/// OneSignal push notification service.
///
/// Initialization order (enforced in main.dart):
///   1. OneSignal.Debug.setLogLevel(verbose)
///   2. OneSignal.initialize(appId)          ← BEFORE runApp
///   3. setupNotificationHandlers()
///   4. markInitialized()
///   5. runApp(...)
///   6. setExternalUserId(uid)               ← after runApp, for ALL logged-in users
///                                              (safe to call without notification permission)
///   7. optIn()                              ← only after user grants notification permission
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  String? _playerId;
  final bool _isWebPlatform = kIsWeb;
  bool _initialized = false;

  Function(String)? onNavigateToNotification;

  // ── Init tracking ────────────────────────────────────────────────────────────

  void markInitialized() {
    _initialized = true;
    debugPrint('✅ OneSignalService: initialized');
  }

  Future<void> _waitForInit() async {
    if (_initialized || _isWebPlatform) return;
    int waited = 0;
    while (!_initialized && waited < 8000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    if (!_initialized) debugPrint('⚠️ OneSignal: not initialized after 8s, proceeding anyway');
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  void setupNotificationHandlers() {
    if (_isWebPlatform) return;
    try {
      // Foreground: display and store
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('📬 Foreground notification: ${event.notification.notificationId}');
        _storeNotification(event.notification);
        event.notification.display(); // Always show even when app is open
      });

      // Click: store + navigate
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('📱 Notification tapped: ${event.notification.notificationId}');
        _storeNotification(event.notification);
        _handleNotificationOpened(event);
      });

      // Permission changes
      OneSignal.Notifications.addPermissionObserver((granted) {
        debugPrint('🔔 Notification permission changed: $granted');
      });

      // Subscription changes — capture player ID
      OneSignal.User.pushSubscription.addObserver((state) {
        _playerId = state.current.id;
        debugPrint('📊 Push subscription: id=${state.current.id}, optedIn=${state.current.optedIn}');
      });

      debugPrint('✅ OneSignal handlers registered');
    } catch (e) {
      debugPrint('❌ OneSignal handler setup failed: $e');
    }
  }

  // ── Notification storage ─────────────────────────────────────────────────────

  void _storeNotification(OSNotification notification) {
    try {
      final id = notification.notificationId.isEmpty
          ? 'notif_${DateTime.now().millisecondsSinceEpoch}'
          : notification.notificationId;

      int ttlDays = 30;
      final extra = notification.additionalData;
      if (extra != null) {
        final v = extra['ttl_days'] ?? extra['ttl'] ?? extra['expiry_days'];
        if (v != null) ttlDays = int.tryParse(v.toString()) ?? 30;
      }

      NotificationStorageService().addNotification(NotificationModel(
        id: id,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        receivedAt: DateTime.now(),
        additionalData: notification.additionalData,
        isRead: false,
        ttlDays: ttlDays,
      ));
    } catch (e) {
      debugPrint('❌ Error storing notification: $e');
    }
  }

  void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notifId = event.notification.notificationId;
    final extra = event.notification.additionalData;

    // Deep link: navigate directly to the relevant screen based on notification data
    if (extra != null) {
      final screen = extra['screen'] as String?;
      final classId = extra['classId'] as String?;
      final dayId = extra['dayId'] as String?;
      final dayNumber = extra['dayNumber'] as String?;

      if (screen == 'DayVideoScreen' && classId != null && dayId != null) {
        // Navigate directly to the specific day video
        final title = event.notification.title ?? 'Day $dayNumber';
        final dayNum = int.tryParse(dayNumber ?? '1') ?? 1;
        Future.microtask(() {
          appRouter.push(
            '/classes/days/$dayId/video?title=${Uri.encodeComponent(title)}&dayNumber=$dayNum',
          );
        });
        _storeNotification(event.notification);
        return;
      }

      if (screen == 'ClassDaysListScreen' && classId != null) {
        // Navigate to the class days list
        Future.microtask(() {
          appRouter.push(
            '/classes/$classId/days',
            extra: {
              'classTitle': event.notification.title ?? 'Class',
              'level': extra['level'] ?? 'Level',
            },
          );
        });
        _storeNotification(event.notification);
        return;
      }

      // URL-based navigation
      if (extra.containsKey('open_url_immediately')) {
        final url = extra['url'] as String?;
        if (url != null) _openUrl(url);
        _storeNotification(event.notification);
        return;
      }
    }

    // Default: go to notification detail screen
    _storeNotification(event.notification);
    if (notifId.isNotEmpty && onNavigateToNotification != null) {
      onNavigateToNotification!(notifId);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      String u = url.trim();
      if (!u.startsWith('http')) u = 'https://$u';
      final uri = Uri.parse(u);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('❌ Error opening URL: $e');
    }
  }

  // ── Permission ───────────────────────────────────────────────────────────────

  Future<bool> hasPermission() async {
    if (_isWebPlatform) return false;
    return OneSignal.Notifications.permission;
  }

  /// Request OS-level notification permission.
  /// Pass fallbackToSettings=true to open settings if permanently denied.
  Future<bool> requestPermission() async {
    if (_isWebPlatform) return true;
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      debugPrint('🔔 requestPermission result: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ requestPermission error: $e');
      return false;
    }
  }

  Future<OSNotificationPermission> getPermissionStatus() async {
    if (_isWebPlatform) return OSNotificationPermission.notDetermined;
    return OneSignal.Notifications.permissionNative();
  }

  // ── Subscription ─────────────────────────────────────────────────────────────

  String? get playerId {
    if (_isWebPlatform) return null;
    return _playerId ?? OneSignal.User.pushSubscription.id;
  }

  bool get isSubscribed {
    if (_isWebPlatform) return false;
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }

  /// Opt in to push notifications (call after permission is granted).
  Future<void> optIn() async {
    if (_isWebPlatform) return;
    try {
      await _waitForInit();
      OneSignal.User.pushSubscription.optIn();
      debugPrint('✅ OneSignal: opted in');
    } catch (e) {
      debugPrint('❌ optIn error: $e');
    }
  }

  Future<void> optOut() async {
    if (_isWebPlatform) return;
    try {
      OneSignal.User.pushSubscription.optOut();
      debugPrint('✅ OneSignal: opted out');
    } catch (e) {
      debugPrint('❌ optOut error: $e');
    }
  }

  // ── User identity ─────────────────────────────────────────────────────────────

  /// Link this device to a user account.
  /// Safe to call even before notification permission is granted (OneSignal SDK v5).
  /// The identity is stored and automatically associated with the push token
  /// once the user grants notification permission.
  Future<void> setExternalUserId(String userId) async {
    if (_isWebPlatform || userId.isEmpty) return;
    try {
      await _waitForInit();
      // OneSignal.login links the device subscription to this external_id.
      // This MUST be called regardless of notification permission status.
      OneSignal.login(userId);
      // Only opt in if permission is already granted — do not force opt-in
      // before the user has made a permission decision.
      if (OneSignal.Notifications.permission) {
        OneSignal.User.pushSubscription.optIn();
      }
      debugPrint('✅ OneSignal.login($userId) called');
    } catch (e) {
      debugPrint('❌ setExternalUserId error: $e');
    }
  }

  Future<void> removeExternalUserId() async {
    if (_isWebPlatform) return;
    try {
      OneSignal.logout();
      debugPrint('✅ OneSignal: logged out');
    } catch (e) {
      debugPrint('❌ removeExternalUserId error: $e');
    }
  }

  // ── Tags ─────────────────────────────────────────────────────────────────────

  Future<void> setTags(Map<String, String> tags) async {
    if (_isWebPlatform) return;
    try {
      await _waitForInit();
      OneSignal.User.addTags(tags);
      debugPrint('✅ OneSignal tags: $tags');
    } catch (e) {
      debugPrint('❌ setTags error: $e');
    }
  }

  Future<void> removeTags(List<String> keys) async {
    if (_isWebPlatform) return;
    try {
      OneSignal.User.removeTags(keys);
    } catch (e) {
      debugPrint('❌ removeTags error: $e');
    }
  }
}
