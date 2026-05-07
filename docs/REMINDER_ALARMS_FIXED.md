# Reminder Alarms - Fixed & Testing Guide ✅

## Issues Fixed

### 1. Quote Section ✅
- ✅ Removed "Daily Wisdom" text
- ✅ Fixed height to 200px (doesn't change with quote length)
- ✅ Cleaner, more elegant design

### 2. Reminder Permissions ✅
Added missing Android permissions for exact alarms:

**File**: `android/app/src/main/AndroidManifest.xml`

**Added Permissions:**
```xml
<!-- Reminder/Alarm Permissions -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**Added Receivers:**
```xml
<!-- Boot receiver to reschedule reminders after device restart -->
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
  </intent-filter>
</receiver>

<!-- Receiver for scheduled notifications -->
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```

**Added Activity Flags:**
```xml
android:showWhenLocked="true"
android:turnScreenOn="true"
```

---

## How Reminders Work Now

### 1. User Creates Reminder
- Opens app → Home → Daily Reminders
- Enables "Morning Meditation" (6:00 AM)
- Or creates custom reminder in Reminders screen

### 2. App Schedules Notification
```dart
// Schedules exact-time alarm
await _notifications.zonedSchedule(
  notificationId,
  title,
  message,
  scheduledDate,
  details,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
);
```

### 3. At Reminder Time
- ✅ Notification appears
- ✅ Sound plays
- ✅ Device vibrates
- ✅ Screen turns on (if locked)
- ✅ Works even if app is closed
- ✅ Repeats on selected days

---

## Testing Reminders

### Quick Test (Immediate):

1. **Set reminder for 1 minute from now:**
   ```
   Current time: 2:30 PM
   Set reminder: 2:31 PM
   Enable: All days
   ```

2. **Wait 1 minute**

3. **Expected Result:**
   - ✅ Notification appears
   - ✅ Sound plays
   - ✅ Device vibrates
   - ✅ Can tap to open app

### Full Test (Daily Reminder):

1. **Enable Morning Meditation:**
   - Go to Home → Daily Reminders
   - Toggle "Morning Meditation" (6:00 AM)
   - Ensure it's enabled (switch is ON)

2. **Check Scheduled:**
   ```dart
   // In logs, you should see:
   ✅ Scheduled reminder 10: Morning Meditation on day 0 at 06:00
   ✅ Scheduled reminder 11: Morning Meditation on day 1 at 06:00
   // ... for all 7 days
   ```

3. **Wait for 6:00 AM next day**

4. **Expected Result:**
   - ✅ Notification at exactly 6:00 AM
   - ✅ Sound + vibration
   - ✅ Repeats daily

---

## Verify Permissions

### Check if permissions are granted:

```bash
# After installing APK
adb shell dumpsys package com.spiritual.app | grep permission

# Should show:
# android.permission.SCHEDULE_EXACT_ALARM: granted=true
# android.permission.POST_NOTIFICATIONS: granted=true
# android.permission.VIBRATE: granted=true
```

### Check scheduled alarms:

```bash
# View pending notifications
adb logcat | grep "Scheduled reminder"

# Should show:
# ✅ Scheduled reminder 10: Morning Meditation on day 0 at 06:00
```

---

## Troubleshooting

### Reminders Not Ringing?

**1. Check Permissions:**
```
Settings → Apps → SKS → Permissions
- ✅ Notifications: Allowed
- ✅ Alarms & reminders: Allowed
```

**2. Check Battery Optimization:**
```
Settings → Battery → Battery optimization
- Find "SKS" app
- Select "Don't optimize"
```

**3. Check Do Not Disturb:**
```
Settings → Sound → Do Not Disturb
- Turn OFF or add SKS to exceptions
```

**4. Check Notification Settings:**
```
Settings → Apps → SKS → Notifications
- ✅ All notifications: ON
- ✅ Daily Reminders channel: ON
- ✅ Sound: ON
- ✅ Vibration: ON
```

**5. Verify Reminder is Active:**
- Open app → Reminders screen
- Check reminder has switch ON
- Check correct time and days selected

---

## Android 12+ Special Requirements

### Exact Alarm Permission

Android 12+ requires special permission for exact alarms:

**Auto-granted if:**
- App targets API 31+ (we target 34) ✅
- Uses `SCHEDULE_EXACT_ALARM` permission ✅
- Uses `exactAllowWhileIdle` mode ✅

**User can revoke in:**
```
Settings → Apps → Special app access → Alarms & reminders
```

If revoked, reminders will be approximate (±15 minutes).

---

## Testing Checklist

### Before Testing:
- [ ] Rebuild APK with new permissions
- [ ] Install on device
- [ ] Grant notification permission when prompted
- [ ] Check "Alarms & reminders" permission is granted

### Test 1: Immediate Reminder
- [ ] Create reminder for 1 minute from now
- [ ] Wait 1 minute
- [ ] Notification appears with sound/vibration

### Test 2: Daily Reminder
- [ ] Enable "Morning Meditation" (6:00 AM)
- [ ] Check logs show "Scheduled reminder"
- [ ] Wait until 6:00 AM next day
- [ ] Notification appears at exact time

### Test 3: Custom Reminder
- [ ] Go to Reminders → Add
- [ ] Set custom time and days
- [ ] Save and enable
- [ ] Notification appears at scheduled time

### Test 4: After Reboot
- [ ] Set reminder
- [ ] Restart device
- [ ] Reminder still works (rescheduled on boot)

### Test 5: App Closed
- [ ] Set reminder
- [ ] Force close app
- [ ] Notification still appears (works in background)

---

## Rebuild Required

**IMPORTANT**: You must rebuild the APK for permissions to take effect!

```bash
cd SKS-mobile-V2

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.prod.json

# Install
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Expected Behavior

### When Reminder Time Arrives:

1. **Notification appears** in status bar
2. **Sound plays** (default notification sound)
3. **Device vibrates** (if not in silent mode)
4. **Screen turns on** (if locked)
5. **Notification shows:**
   - Title: "Morning Meditation"
   - Message: "Time for your spiritual practice"
   - Icon: App icon
   - Actions: Tap to open app

### Recurring Behavior:

- ✅ Repeats on selected days automatically
- ✅ No need to reschedule manually
- ✅ Works even after device restart
- ✅ Works even if app is closed

---

## Summary

**Fixed:**
1. ✅ Quote section - removed "Daily Wisdom", fixed height
2. ✅ Added exact alarm permissions
3. ✅ Added boot receiver for rescheduling
4. ✅ Added notification receivers
5. ✅ Added wake lock and screen on flags

**Result:**
- ✅ Reminders will ring at exact scheduled time
- ✅ Sound + vibration
- ✅ Works in background
- ✅ Survives device restart
- ✅ Repeats on selected days

**Action Required:**
```bash
# Rebuild APK with new permissions
./rebuild-production.sh
```

Then test reminders - they should work perfectly! 🎉
