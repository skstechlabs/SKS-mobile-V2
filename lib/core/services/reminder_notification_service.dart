import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Reminder Notification Service
/// 
/// Handles local notifications for daily reminders (meditation, practice, etc.)
class ReminderNotificationService {
  static final ReminderNotificationService _instance = ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
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
    if (!_initialized) await initialize();

    try {
      // Android 13+ requires runtime permission
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('📱 Android notification permission: ${granted ?? false}');
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
    if (!_initialized) await initialize();

    try {
      // Parse time
      final timeParts = reminderTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

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

        // Android notification details
        const androidDetails = AndroidNotificationDetails(
          'reminders_channel',
          'Daily Reminders',
          channelDescription: 'Notifications for daily spiritual practice reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );

        // iOS notification details
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Schedule the notification
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

        debugPrint('✅ Scheduled reminder $notificationId: $title on day $dayOfWeek at $reminderTime');
      }
    } catch (e) {
      debugPrint('❌ Error scheduling reminder: $e');
      rethrow;
    }
  }

  Future<void> cancelReminder(int id) async {
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
    try {
      await _notifications.cancelAll();
      debugPrint('✅ Cancelled all reminders');
    } catch (e) {
      debugPrint('❌ Error cancelling all reminders: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }
}
