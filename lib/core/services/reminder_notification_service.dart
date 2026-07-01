import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Reminder Notification Service
/// 
/// Handles local notifications for daily reminders (meditation, practice, etc.)
/// Web: Stubs all notification methods (browser notifications not supported yet)
/// Mobile: Full notification scheduling with timezone support
class ReminderNotificationService {
  static final ReminderNotificationService _instance = ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    // Skip initialization on web
    if (kIsWeb) {
      debugPrint('ℹ️ ReminderNotificationService: Notifications not supported on web');
      _initialized = true;
      return;
    }

    if (_initialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      
      // Set local timezone (default to UTC if detection fails)
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // India timezone
      } catch (e) {
        debugPrint('⚠️ Could not set timezone to Asia/Kolkata, using UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }

      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('✅ ReminderNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ ReminderNotificationService initialization failed: $e');
      rethrow;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Handle notification tap if needed
  }

  Future<bool> requestPermissions() async {
    // Web: No permissions needed
    if (kIsWeb) {
      debugPrint('ℹ️ ReminderNotificationService: Permissions not needed on web');
      return true;
    }

    if (!_initialized) await initialize();

    try {
      // Android 13+ requires runtime permission for POST_NOTIFICATIONS
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('📱 Android notification permission: ${granted ?? false}');

        // Android 12+ (API 31+): Request exact alarm permission.
        // Without this, exactAllowWhileIdle scheduling throws a PlatformException.
        // requestExactAlarmsPermission() opens Settings on Android 12+ so the user
        // can grant it — does nothing on older versions.
        try {
          await androidPlugin.requestExactAlarmsPermission();
          debugPrint('📱 Exact alarm permission requested');
        } catch (e) {
          debugPrint('⚠️ Exact alarm permission request failed (non-critical): $e');
        }

        return granted ?? false;
      }

      // iOS permissions
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('📱 iOS notification permission: ${granted ?? false}');
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Parse any time string the API might return into a `({int hour, int minute})`.
  ///
  /// Handles:
  ///   "06:00"                    → (hour: 6,  minute: 0)
  ///   "06:00:00"                 → (hour: 6,  minute: 0)
  ///   "1970-01-01T06:00:00.000Z" → (hour: 6,  minute: 0)
  ///   "1970-01-01T06:00:00Z"     → (hour: 6,  minute: 0)
  ({int hour, int minute}) _parseTimeString(String raw) {
    final s = raw.trim();
    if (s.isEmpty) throw FormatException('Empty time string');

    // ISO 8601 datetime: contains a 'T' separator between date and time
    if (s.contains('T')) {
      try {
        final dt = DateTime.parse(s).toUtc();
        debugPrint('✅ Parsed ISO 8601 time "$s" → ${dt.hour}:${dt.minute}');
        return (hour: dt.hour, minute: dt.minute);
      } catch (e) {
        throw FormatException('Cannot parse ISO 8601 time "$s": $e');
      }
    }

    // Plain time: "HH:MM" or "HH:MM:SS"
    final parts = s.split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid time format "$s" — expected HH:MM');
    }
    final hour   = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) {
      throw FormatException('Cannot parse hour/minute from "$s"');
    }
    if (hour < 0 || hour > 23) {
      throw FormatException('Hour $hour out of range 0–23 in "$s"');
    }
    if (minute < 0 || minute > 59) {
      throw FormatException('Minute $minute out of range 0–59 in "$s"');
    }
    return (hour: hour, minute: minute);
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String? message,
    required String reminderTime, // "HH:MM", "HH:MM:SS", or ISO 8601
    required List<int> daysOfWeek, // 0=Sunday, 6=Saturday
  }) async {
    // Web: Skip scheduling
    if (kIsWeb) {
      debugPrint('ℹ️ ReminderNotificationService: Scheduling skipped on web');
      return;
    }

    if (!_initialized) await initialize();

    try {
      // Normalize to HH:MM — handles all formats the API may return:
      //   "06:00"                    → hour=6,  minute=0
      //   "06:00:00"                 → hour=6,  minute=0
      //   "1970-01-01T06:00:00.000Z" → hour=6,  minute=0
      //   "1970-01-01T06:00:00Z"     → hour=6,  minute=0
      final parsed = _parseTimeString(reminderTime);
      final hour   = parsed.hour;
      final minute = parsed.minute;

      // Cancel existing notification for this ID
      await cancelReminder(id);

      // Schedule for each day of the week
      for (final dayOfWeek in daysOfWeek) {
        final notificationId = id * 10 + dayOfWeek; // Unique ID per day
        
        // Calculate next occurrence of this day and time
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // Adjust to the correct day of week
        while (scheduledDate.weekday % 7 != dayOfWeek) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        // If the time has passed today, schedule for next week
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }

        // Android notification details with Sivoham ringtone
        // Use inexactAllowWhileIdle to work on all Android versions including
        // Android 12+ which restricts exactAllowWhileIdle without special permission.
        // For daily reminders, ~1 min accuracy is perfectly acceptable.
        const androidDetails = AndroidNotificationDetails(
          'reminders_channel',
          'Daily Reminders',
          channelDescription: 'Notifications for daily spiritual practice reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('sivoham_ringtone'),
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: false,
        );

      // iOS notification details with custom sound
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'sivoham_ringtone.mp3',
      );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Schedule the notification — use exact alarm if available, fall back
        // to inexact on Android 12+ when SCHEDULE_EXACT_ALARM is not granted.
        try {
          await _notifications.zonedSchedule(
            notificationId,
            title,
            message ?? 'Time for your spiritual practice',
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } on PlatformException catch (pe) {
          // On Android 12+ the exact alarm permission may not be granted.
          // Fall back to an inexact (approximate) alarm — still fires, just
          // may be a few minutes off.
          debugPrint('⚠️ Exact alarm denied (${pe.code}), falling back to inexact: $pe');
          await _notifications.zonedSchedule(
            notificationId,
            title,
            message ?? 'Time for your spiritual practice',
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }

        debugPrint('✅ Scheduled reminder $notificationId: $title on day $dayOfWeek at $reminderTime (inexact)');
      }
    } catch (e) {
      debugPrint('❌ Error scheduling reminder: $e');
      rethrow;
    }
  }

  Future<void> cancelReminder(int id) async {
    // Web: Skip cancellation
    if (kIsWeb) {
      debugPrint('ℹ️ ReminderNotificationService: Cancellation skipped on web');
      return;
    }

    try {
      // Cancel all day variations of this reminder
      for (int i = 0; i < 7; i++) {
        final notificationId = id * 10 + i;
        await _notifications.cancel(notificationId);
      }
      debugPrint('✅ Cancelled reminder $id');
    } catch (e) {
      debugPrint('❌ Error cancelling reminder: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    // Web: Skip cancellation
    if (kIsWeb) {
      debugPrint('ℹ️ ReminderNotificationService: Cancel all skipped on web');
      return;
    }

    try {
      await _notifications.cancelAll();
      debugPrint('✅ Cancelled all reminders');
    } catch (e) {
      debugPrint('❌ Error cancelling all reminders: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    // Web: Return empty list
    if (kIsWeb) {
      return [];
    }

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }
}
