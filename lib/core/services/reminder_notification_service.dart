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

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String? message,
    required String reminderTime, // Format: "HH:MM" (24-hour)
    required List<int> daysOfWeek, // 0=Sunday, 6=Saturday
  }) async {
    // Web: Skip scheduling
    if (kIsWeb) {
      debugPrint('ℹ️ ReminderNotificationService: Scheduling skipped on web');
      return;
    }

    if (!_initialized) await initialize();

    try {
      // Validate and parse time
      if (reminderTime.isEmpty || !reminderTime.contains(':')) {
        debugPrint('❌ Invalid reminderTime format: "$reminderTime" (expected HH:MM)');
        throw FormatException('Invalid time format: "$reminderTime". Expected HH:MM format.');
      }

      // Parse time - handle both "HH:MM" and "HH:MM:SS" formats
      final timeParts = reminderTime.split(':');
      if (timeParts.length < 2) {
        debugPrint('❌ Invalid reminderTime format: "$reminderTime" (not enough parts)');
        throw FormatException('Invalid time format: "$reminderTime". Expected HH:MM format.');
      }

      // Try to parse hour and minute
      int hour;
      int minute;
      try {
        hour = int.parse(timeParts[0].trim());
        minute = int.parse(timeParts[1].trim());
      } catch (e) {
        debugPrint('❌ Error parsing time parts from "$reminderTime": $e');
        throw FormatException('Unable to parse time "$reminderTime". Hour: "${timeParts[0]}", Minute: "${timeParts[1]}"');
      }

      // Validate time ranges
      if (hour < 0 || hour > 23) {
        throw FormatException('Invalid hour: $hour (must be 0-23)');
      }
      if (minute < 0 || minute > 59) {
        throw FormatException('Invalid minute: $minute (must be 0-59)');
      }

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

        // Android notification details with custom sound
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

        debugPrint('✅ Scheduled reminder $notificationId: $title on day $dayOfWeek at $reminderTime');
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
