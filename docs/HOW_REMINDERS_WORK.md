# How Reminders Work in SKS Mobile App

## Current Status: ⚠️ LOCAL NOTIFICATIONS DISABLED

### Important Note
Local notifications are **temporarily disabled** due to build issues with the `flutter_local_notifications` package. The reminder system is fully functional for storing and managing reminders, but **notifications do not ring/alert** on the device.

## How It Currently Works

### 1. Reminder Storage (✅ Working)
- Reminders are stored in the backend MySQL database
- Users can create, edit, delete, and toggle reminders
- Each reminder has:
  - Title (e.g., "Morning Meditation")
  - Optional message
  - Time (HH:MM format, e.g., "06:00")
  - Days of week (0=Sunday, 6=Saturday)
  - Active/Inactive status

### 2. Reminder Management (✅ Working)
Users can manage reminders through:
- **Home Screen**: Quick toggle for 3 preset reminders
  - Morning Meditation (6:00 AM)
  - Evening Meditation (7:00 PM)
  - Daily Practice (12:00 PM)
- **Reminders Screen** (`/reminders`): Full management
  - View all reminders
  - Create custom reminders
  - Edit existing reminders
  - Delete reminders
  - Toggle active/inactive status

### 3. Local Notifications (❌ Currently Disabled)
The notification service is a **stub implementation** that:
- Does NOT schedule actual device notifications
- Does NOT ring alarms or show alerts
- Logs warnings: "Local notifications disabled (stub implementation)"
- Always returns success to prevent app crashes

## What Should Happen (When Notifications Are Enabled)

When local notifications are properly enabled, the app would:

1. **Schedule Notifications**: When a reminder is activated, schedule local device notifications
2. **Ring/Alert**: At the specified time, the device would:
   - Show a notification banner
   - Play a notification sound
   - Vibrate (if enabled)
   - Display the reminder title and message
3. **Repeat**: Notifications would repeat on selected days of the week
4. **Cancel**: When a reminder is deactivated or deleted, cancel scheduled notifications

## Technical Implementation

### Backend (✅ Fully Working)
**File**: `sks-backend/routes/reminders.js`

API Endpoints:
- `GET /api/reminders` - Get user's reminders
- `POST /api/reminders` - Create new reminder
- `PUT /api/reminders/:id` - Update reminder
- `DELETE /api/reminders/:id` - Delete reminder
- `PATCH /api/reminders/:id/toggle` - Toggle active status

Database Table: `reminders`
```sql
CREATE TABLE reminders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_uid VARCHAR(255) NOT NULL,
  title VARCHAR(200) NOT NULL,
  message VARCHAR(500),
  reminder_time TIME NOT NULL,
  days_of_week JSON NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Frontend (⚠️ Notifications Disabled)
**Files**:
- `lib/core/services/reminder_notification_service.dart` - Stub implementation
- `lib/features/reminders/reminders_screen.dart` - Reminder management UI
- `lib/features/home/home_page.dart` - Quick toggle for preset reminders

## Why Notifications Are Disabled

From the service file comments:
```dart
/// NOTE: Local notifications are temporarily disabled due to build issues.
/// This is a stub implementation that allows the app to build and run.
/// Reminders are still stored in the backend and can be managed through the app.
```

The `flutter_local_notifications` package was causing build errors, so it was:
1. Commented out in `pubspec.yaml`
2. Replaced with a stub implementation
3. Core library desugaring disabled in `build.gradle`

## How to Re-Enable Notifications

To restore full notification functionality:

### Step 1: Update `pubspec.yaml`
Uncomment the flutter_local_notifications dependency:
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
```

### Step 2: Enable Desugaring in `android/app/build.gradle`
Add core library desugaring support:
```gradle
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

### Step 3: Replace Stub Implementation
Replace `lib/core/services/reminder_notification_service.dart` with full implementation that:
- Initializes `FlutterLocalNotificationsPlugin`
- Schedules notifications using `zonedSchedule`
- Handles Android notification channels
- Manages notification permissions
- Cancels notifications when reminders are disabled

### Step 4: Configure Android Permissions
Ensure `android/app/src/main/AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Step 5: Test
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## User Experience

### Current Experience (Notifications Disabled)
1. User creates/enables a reminder ✅
2. Reminder is saved to backend ✅
3. User sees reminder in the app ✅
4. **At reminder time: Nothing happens** ❌
5. No notification, no sound, no alert ❌

### Expected Experience (When Enabled)
1. User creates/enables a reminder ✅
2. Reminder is saved to backend ✅
3. Local notification is scheduled ✅
4. **At reminder time: Device alerts** ✅
   - Notification banner appears
   - Sound plays
   - Device vibrates
   - User can tap to open app
5. Notification repeats on selected days ✅

## Workarounds

Until notifications are re-enabled, users can:
1. Use device's built-in alarm/reminder app
2. Set calendar events for meditation times
3. Use third-party reminder apps
4. Check the app manually at scheduled times

## Summary

**What Works**:
- ✅ Creating reminders
- ✅ Editing reminders
- ✅ Deleting reminders
- ✅ Toggling reminders on/off
- ✅ Viewing all reminders
- ✅ Backend storage and API

**What Doesn't Work**:
- ❌ Device notifications/alerts
- ❌ Notification sounds
- ❌ Alarm ringing
- ❌ Scheduled notifications

**Bottom Line**: Reminders are stored and managed perfectly, but the app won't alert users at the scheduled time. This is a temporary limitation until local notifications are re-enabled.
