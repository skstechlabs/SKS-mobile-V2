# Testing Checklist - OneSignal Fix Verification

## Pre-Installation

- [ ] Device has Google Play Services installed
- [ ] Device is running Android 7.0+ (API 24+)
- [ ] Device has internet connection
- [ ] ADB is installed and device is connected (`adb devices`)

## Installation

- [ ] Completely uninstalled old app: `adb uninstall com.spiritual.app`
- [ ] Installed fresh APK: `adb install build/app/outputs/flutter-apk/app-release.apk`
- [ ] Installation completed without errors

## App Launch

- [ ] App opens successfully
- [ ] No immediate crashes
- [ ] Splash screen appears

## Login Flow

- [ ] Login screen appears
- [ ] Can login with Google (or skip as guest)
- [ ] No redirect loop to login screen
- [ ] Profile setup screen appears (or skip)

## Notification Permission (CRITICAL TEST)

- [ ] Notification permission screen appears
- [ ] Screen shows "Stay Connected with Guruji" title
- [ ] "Allow Notifications" button is visible
- [ ] Click "Allow Notifications" button
- [ ] **NO "Missing Plugin Exception" error appears** ✅
- [ ] Native Android permission dialog appears
- [ ] Grant permission in dialog
- [ ] App navigates to home screen
- [ ] No crashes or errors

## Post-Permission

- [ ] Home screen loads successfully
- [ ] Can navigate to different tabs
- [ ] Bell icon shows in app bar
- [ ] Can open notifications page

## Logs Verification

Run: `adb logcat | grep -i onesignal`

Expected logs:
```
✅ OneSignal initialized successfully
✅ OneSignal notification handlers configured
🔔 Notification permission state changed: true
📊 Push subscription state changed
```

## Send Test Notification

1. Go to OneSignal Dashboard
2. Messages → New Push
3. Send to "Test Users" or "All Users"
4. Check if notification appears on device
5. Tap notification
6. Check if it appears in app's notifications page

## Success Criteria

✅ No "Missing Plugin Exception" at any point
✅ Permission dialog appears when requested
✅ App navigates correctly after permission grant
✅ Device is registered in OneSignal dashboard
✅ Test notifications are received

## If Any Step Fails

1. Check logs: `adb logcat | grep -E "(OneSignal|Firebase|spiritual)"`
2. Verify complete uninstall was done
3. Verify Google Play Services is updated
4. Try on a different device
5. Check Firebase Console package name matches `com.spiritual.app`

## Expected vs Previous Behavior

| Action | Previous (Broken) | Now (Fixed) |
|--------|------------------|-------------|
| Click "Allow Notifications" | ❌ Missing Plugin Exception | ✅ Permission dialog appears |
| Firebase initialization | ❌ Failed silently | ✅ Succeeds |
| OneSignal plugin loading | ❌ Never loaded | ✅ Loads correctly |
| Permission request | ❌ Method not found | ✅ Method available |

## Confidence

🟢 **VERY HIGH** - The root cause (package name mismatch) has been fixed.

This is a configuration error with a known solution, not a code bug.
