# Wallpaper Feature - Fix Instructions

## Error Explanation

The error `MissingPluginException` occurs because new native plugins were added:
- `path_provider` - For file management
- `workmanager` - For background tasks
- `flutter_wallpaper_manager` - For setting wallpapers

These plugins require native Android/iOS code that needs to be compiled into the app.

## Solution: Full Rebuild Required

**Hot reload/restart will NOT work!** You must do a full rebuild.

### Step 1: Stop the App
Stop the currently running app completely.

### Step 2: Clean Build
```bash
cd SKS-mobile-V2
flutter clean
```

### Step 3: Get Dependencies
```bash
flutter pub get
```

### Step 4: Full Rebuild
```bash
# For Android
flutter run

# Or if you have multiple devices
flutter run -d <device-id>
```

### Step 5: Test the Feature
1. Open the app (freshly built)
2. Navigate to Home page
3. Tap "Wisdom Wallpapers" card
4. Toggle "Auto-Rotate" ON
5. ✅ Should work without errors

## Why This Happens

### Native Plugins
When you add packages that have native code (Android/iOS):
- `path_provider` → Native file system access
- `workmanager` → Native background task scheduling
- `flutter_wallpaper_manager` → Native wallpaper API

These require:
1. Native code compilation
2. Platform channel registration
3. Gradle/CocoaPods integration

### Hot Reload Limitations
- Hot reload: Updates Dart code only
- Hot restart: Restarts Dart code only
- **Full rebuild**: Compiles native code ✅

## Quick Commands

### Option 1: Clean and Run
```bash
cd SKS-mobile-V2
flutter clean && flutter pub get && flutter run
```

### Option 2: Uninstall and Reinstall
```bash
# Uninstall from device
adb uninstall com.spiritual.app

# Then run
flutter run
```

### Option 3: Build APK
```bash
flutter build apk --release
# Then install the APK manually
```

## Verification

After rebuild, check if plugins are working:

### Test 1: Path Provider
```dart
// Should work without error
final directory = await getTemporaryDirectory();
print('Temp dir: ${directory.path}');
```

### Test 2: WorkManager
```dart
// Should work without error
await Workmanager().initialize(callbackDispatcher);
```

### Test 3: Wallpaper Manager
```dart
// Should work without error
await WallpaperManager.setWallpaperFromFile(path, WallpaperManager.HOME_SCREEN);
```

## Common Issues

### Issue 1: Still Getting Error After Rebuild
**Solution**: Make sure you did a FULL rebuild, not hot restart
```bash
# Stop app completely
# Then:
flutter clean
flutter pub get
flutter run
```

### Issue 2: Gradle Build Fails
**Solution**: Check Android SDK and Gradle versions
```bash
# Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version=8.0
cd ..
flutter run
```

### Issue 3: Plugin Not Found
**Solution**: Verify pubspec.yaml has the packages
```yaml
dependencies:
  path_provider: ^2.1.1
  workmanager: ^0.5.2
  flutter_wallpaper_manager: ^0.0.3
```

## Expected Behavior After Fix

### Enable Auto-Rotation
1. Tap toggle switch
2. ✅ First wallpaper sets immediately
3. ✅ Success message appears
4. ✅ No errors in console

### Manual Selection
1. Tap any image in grid
2. ✅ Wallpaper changes
3. ✅ Success message appears
4. ✅ "Current" badge updates

### Change Now
1. Tap "Change Now" button
2. ✅ Next wallpaper sets
3. ✅ Last update time updates
4. ✅ No errors

## Debug Mode

If you want to see detailed logs:

```bash
# Run with verbose logging
flutter run -v

# Or check Android logs
adb logcat | grep -i wallpaper
```

## Summary

**The fix is simple:**
1. Stop the app
2. Run: `flutter clean && flutter pub get && flutter run`
3. Test the feature

**Do NOT use:**
- ❌ Hot reload (r)
- ❌ Hot restart (R)

**DO use:**
- ✅ Full rebuild (stop app → flutter run)

After a full rebuild, all the wallpaper features will work perfectly!
