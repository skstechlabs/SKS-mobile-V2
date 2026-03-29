# Install and Test - Quick Guide

## The Problem Was Fixed

**Root Cause**: Package name mismatch between build.gradle (`com.spiritual.app`) and google-services.json (`com.spiritual.spiritual_app`)

**Result**: Firebase couldn't initialize, which broke OneSignal plugin registration

## What You Need to Do

### Step 1: Complete Uninstall (CRITICAL)

```bash
adb uninstall com.spiritual.app
```

You MUST uninstall the old app completely. A simple reinstall won't work because:
- Firebase configuration is cached
- Plugin registrations are cached
- OneSignal player ID is tied to failed configuration

### Step 2: Install Fresh APK

```bash
# Option A: Use the script
./install-apk.sh

# Option B: Manual install
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Test

1. Open app
2. Login or skip as guest
3. Complete profile or skip
4. On notification permission screen, click "Allow Notifications"
5. **EXPECTED**: Native Android permission dialog appears (NO ERROR)
6. Grant permission
7. **EXPECTED**: App navigates to home screen

## What Was Fixed

✅ Fixed package name in google-services.json
✅ Removed duplicate MainActivity
✅ Fixed OneSignal initialization order
✅ Verified AndroidManifest configuration

## Fresh APK Details

- **Location**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 132.2 MB
- **Build**: Release mode with all fixes

## View Logs

```bash
adb logcat | grep -i onesignal
```

You should see:
- "OneSignal initialized successfully"
- No "Missing Plugin Exception" errors

## If It Still Fails

1. Verify device has Google Play Services
2. Check internet connection
3. Try on a different Android device
4. Check Firebase Console has correct package name
5. Contact me with logcat output
