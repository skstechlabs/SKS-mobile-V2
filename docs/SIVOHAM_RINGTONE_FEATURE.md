# Sivoham Ringtone Feature - Complete Implementation

## Overview

The Sivoham Ringtone feature allows users to:
1. Use Sivoham_ringtone.mp3 as the default notification sound for the app
2. Set Sivoham ringtone as their device ringtone
3. Set Sivoham ringtone as their notification sound
4. Set Sivoham ringtone as their alarm sound

## Features Implemented

### 1. ✅ Default App Notification Sound
- Sivoham_ringtone.mp3 is now the default sound for all app notifications
- Used for daily reminders and meditation notifications
- Automatically plays when notifications are triggered

### 2. ✅ Ringtone Settings Page
Beautiful dedicated page with:
- Preview button to listen to the ringtone
- Three options to set as:
  - Phone Ringtone
  - Notification Sound
  - Alarm Sound
- Permission handling
- Success/error feedback

### 3. ✅ Easy Access from Home Page
- New "Sivoham Ringtone" card on home page
- Located right after Meditation Timer
- Orange/red gradient design
- Direct navigation to settings

## File Locations

### Audio File
- **Asset**: `assets/audio/Sivoham_ringtone.mp3`
- **Android Raw**: `android/app/src/main/res/raw/sivoham_ringtone.mp3`

### Code Files
1. **Ringtone Settings Page**: `lib/features/settings/ringtone_settings_page.dart`
2. **Notification Service**: `lib/core/services/reminder_notification_service.dart`
3. **Android Platform Code**: `android/app/src/main/kotlin/com/spiritual/app/MainActivity.kt`
4. **Router**: `lib/core/router.dart`
5. **Home Page**: `lib/features/home/home_page.dart`

## How It Works

### App Notifications
```dart
// In reminder_notification_service.dart
const androidDetails = AndroidNotificationDetails(
  'reminders_channel',
  'Daily Reminders',
  sound: RawResourceAndroidNotificationSound('sivoham_ringtone'),
  // ... other settings
);
```

### Setting Device Ringtone
1. User taps "Set as Ringtone" button
2. App copies asset to external storage
3. Platform channel calls Android native code
4. Android inserts audio into MediaStore
5. Sets as default ringtone using RingtoneManager
6. Shows success message

### Platform Channel Communication
```dart
// Flutter side
static const platform = MethodChannel('com.spiritual.app/ringtone');
await platform.invokeMethod('setRingtone', {
  'path': file.path,
  'title': 'Sivoham',
});

// Android side (Kotlin)
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL)
  .setMethodCallHandler { call, result ->
    when (call.method) {
      "setRingtone" -> setRingtone(path, title, TYPE_RINGTONE)
      // ...
    }
  }
```

## User Flow

### Accessing Ringtone Settings
1. Open app home page
2. Scroll to "Sivoham Ringtone" card (orange/red gradient)
3. Tap the card
4. Opens Ringtone Settings page

### Setting as Ringtone
1. On Ringtone Settings page
2. Tap "Play Preview" to listen (optional)
3. Tap "Phone Ringtone" option
4. If permission needed, dialog appears
5. Tap "Open Settings" to grant permission
6. Return to app and try again
7. Success message appears
8. Ringtone is now set!

### Setting as Notification/Alarm
- Same flow as ringtone
- Choose "Notification Sound" or "Alarm Sound" instead

## Permissions

### Android Permissions Required
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.WRITE_SETTINGS" />
```

### Runtime Permission
- Android 6.0+ requires "Modify system settings" permission
- App automatically requests when user tries to set ringtone
- If denied, shows dialog with "Open Settings" button

## UI Design

### Home Page Card
```
┌─────────────────────────────────┐
│  🎵  Sivoham Ringtone          │
│      Set as your device         │
│      ringtone              →    │
└─────────────────────────────────┘
Orange/Red Gradient
```

### Settings Page Layout
```
┌─────────────────────────────────┐
│  App Bar: Sivoham Ringtone      │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │  🎵  Sivoham Ringtone     │  │
│  │  Sacred mantra for device │  │
│  │  [Play Preview Button]    │  │
│  └───────────────────────────┘  │
├─────────────────────────────────┤
│  Set as Device Sound            │
├─────────────────────────────────┤
│  📞 Phone Ringtone          →   │
│  🔔 Notification Sound      →   │
│  ⏰ Alarm Sound             →   │
├─────────────────────────────────┤
│  ℹ️  Permission Note            │
└─────────────────────────────────┘
```

## Technical Implementation

### 1. Notification Sound Setup
```dart
// Copy audio to Android raw resources
android/app/src/main/res/raw/sivoham_ringtone.mp3

// Use in notifications
sound: RawResourceAndroidNotificationSound('sivoham_ringtone')
```

### 2. Ringtone Setting (Android)
```kotlin
private fun setRingtone(filePath: String, title: String, type: Int): Boolean {
    // 1. Check WRITE_SETTINGS permission
    if (!Settings.System.canWrite(this)) {
        // Request permission
        return false
    }
    
    // 2. Insert into MediaStore
    val values = ContentValues().apply {
        put(MediaStore.MediaColumns.DATA, file.absolutePath)
        put(MediaStore.MediaColumns.TITLE, title)
        put(MediaStore.Audio.Media.IS_RINGTONE, true)
        // ...
    }
    val newUri = contentResolver.insert(uri, values)
    
    // 3. Set as default
    RingtoneManager.setActualDefaultRingtoneUri(this, type, newUri)
    
    return true
}
```

### 3. File Management
```dart
Future<File> _copyAssetToFile() async {
    // Load from assets
    final byteData = await rootBundle.load('assets/audio/Sivoham_ringtone.mp3');
    
    // Get external storage
    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/Sivoham_ringtone.mp3';
    
    // Write file
    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    
    return file;
}
```

## Testing

### Test App Notifications
1. Create a reminder
2. Wait for notification time
3. ✅ Should hear Sivoham ringtone

### Test Ringtone Setting
1. Go to home page
2. Tap "Sivoham Ringtone" card
3. Tap "Play Preview"
4. ✅ Should hear the ringtone
5. Tap "Phone Ringtone"
6. Grant permission if asked
7. ✅ Success message appears
8. Make a test call
9. ✅ Should hear Sivoham ringtone

### Test Notification Sound
1. On Ringtone Settings page
2. Tap "Notification Sound"
3. Grant permission if needed
4. ✅ Success message appears
5. Send a test notification
6. ✅ Should hear Sivoham sound

### Test Alarm Sound
1. On Ringtone Settings page
2. Tap "Alarm Sound"
3. Grant permission if needed
4. ✅ Success message appears
5. Set a test alarm
6. ✅ Should hear Sivoham sound

## Troubleshooting

### Issue: Permission Denied
**Cause**: WRITE_SETTINGS permission not granted
**Solution**:
1. Tap "Open Settings" in dialog
2. Enable "Modify system settings"
3. Return to app and try again

### Issue: Ringtone Not Playing
**Cause**: File not copied correctly
**Solution**:
1. Check external storage permission
2. Verify file exists in storage
3. Check Android logs for errors

### Issue: Preview Not Working
**Cause**: Audio player issue
**Solution**:
1. Check device volume
2. Restart app
3. Check asset path is correct

## Installation

### Step 1: Install Dependencies
```bash
cd SKS-mobile-V2
flutter pub get
```

### Step 2: Build and Run
```bash
flutter run
```

### Step 3: Test Features
1. Navigate to home page
2. Find "Sivoham Ringtone" card
3. Tap to open settings
4. Test all features

## Dependencies Added

```yaml
# pubspec.yaml
dependencies:
  path_provider: ^2.1.1  # For file management
  just_audio: ^0.9.36    # For audio preview (already existed)
```

## Routes Added

```dart
// lib/core/router.dart
GoRoute(
  path: '/settings/ringtone',
  builder: (context, state) => const RingtoneSettingsPage(),
),
```

## Success Criteria

✅ Sivoham ringtone plays for app notifications
✅ Users can preview the ringtone
✅ Users can set as phone ringtone
✅ Users can set as notification sound
✅ Users can set as alarm sound
✅ Permission handling works correctly
✅ Success/error messages display properly
✅ Easy access from home page
✅ Beautiful UI with gradient design

## Future Enhancements (Optional)

1. **Multiple Ringtones**: Add more spiritual ringtones
2. **Custom Duration**: Let users trim ringtone length
3. **Favorites**: Mark favorite ringtones
4. **Share**: Share ringtone with friends
5. **Download**: Download more ringtones from server
6. **Categories**: Organize by mantra, bhajan, etc.

## Notes

- Feature is Android-only (iOS has restrictions on setting ringtones)
- Requires Android 6.0+ for runtime permissions
- Audio file should be under 30 seconds for best ringtone experience
- Sivoham_ringtone.mp3 is a sacred mantra, perfect for spiritual reminders

## Conclusion

The Sivoham Ringtone feature is now fully implemented and provides users with a beautiful way to integrate spiritual sounds into their daily device usage. The feature includes both app notifications and device-wide ringtone setting capabilities.
