import 'package:flutter/foundation.dart';

/// Reminder Notification Service
/// 
/// NOTE: Local notifications are temporarily disabled due to build issues.
/// This is a stub implementation that allows the app to build and run.
/// Reminders are still stored in the backend and can be managed through the app.
/// 
/// To re-enable local notifications:
/// 1. Uncomment flutter_local_notifications in pubspec.yaml
/// 2. Enable core library desugaring in android/app/build.gradle.kts
/// 3. Replace this file with the full implementation
class ReminderNotificationService {
  static final ReminderNotificationService _instance = ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('⚠️ ReminderNotificationService: Local notifications disabled (stub implementation)');
    _initialized = true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String? message,
    required String reminderTime,
    required List<int> daysOfWeek,
  }) async {
    if (!_initialized) await initialize();
    debugPrint('⚠️ ReminderNotificationService: scheduleReminder called but local notifications are disabled');
    // Stub: Does nothing
  }

  Future<void> cancelReminder(int id) async {
    debugPrint('⚠️ ReminderNotificationService: cancelReminder called but local notifications are disabled');
    // Stub: Does nothing
  }

  Future<void> cancelAllReminders() async {
    debugPrint('⚠️ ReminderNotificationService: cancelAllReminders called but local notifications are disabled');
    // Stub: Does nothing
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    debugPrint('⚠️ ReminderNotificationService: requestPermissions called but local notifications are disabled');
    // Stub: Always returns true
    return true;
  }
}
