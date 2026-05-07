# Push Notifications Not Received - Troubleshooting

## Current Status

✅ Package names match in configuration
✅ OneSignal App ID configured
✅ New permissions screen created (notifications + camera + microphone)
✅ Fresh APK built (132.2 MB)

## Why Notifications Might Not Be Received

### 1. Firebase Server Key Not Configured in OneSignal

OneSignal needs your Firebase Server Key to send notifications via FCM.

**Check in OneSignal Dashboard:**
1. Go to https://onesignal.com/
2. Select your app
3. Settings → Platforms → Google Android (FCM)
4. Verify "Firebase Server Key" is entered
5. Verify "Firebase Sender ID" is entered

**Get Firebase Server Key:**
1. Go to Firebase Console: https://console.firebase.google.com/
2. Project: sks-login-mobile
3. Settings → Cloud Messaging
4. Copy "Server Key" (legacy)
5. Paste into OneSignal dashboard

### 2. Device Not Subscribed to OneSignal

The device needs to be registered with OneSignal to receive notifications.

**Check Subscription:**
1. Install fresh APK: `./install-apk.sh`
2. Complete login/profile
3. Grant all permissions
4. Check logs: `adb logcat | grep -i onesignal`
5. Look for: "Push subscription state changed" with a player ID

**Verify in OneSignal Dashboard:**
1. Go to Audience → Subscriptions
2. Check if your device appears
3. Look for subscription with your Firebase UID as external ID

### 3. Google Play Services Issue

OneSignal requires Google Play Services on Android.

**Check on Device:**
1. Settings → Apps → Google Play Services
2. Verify it's installed and updated
3. If not, update from Play Store

### 4. Internet Connection

Device needs active internet to receive push notifications.

### 5. App Must Be Running or in Background

For testing, keep the app open or in background (not force-closed).

## Testing Steps

### Step 1: Fresh Install

```bash
./install-apk.sh
```

### Step 2: Complete Setup

1. Open app
2. Login (or skip as guest)
3. Complete profile (or skip)
4. Grant ALL permissions (notifications, camera, microphone)

### Step 3: Verify Subscription

```bash
adb logcat | grep -E "(OneSignal|subscription|player)"
```

Look for:
```
✅ OneSignal initialized successfully
📊 Push subscription state changed
   - ID: [player-id]
   - Token: [fcm-token]
   - Opted In: true
```

### Step 4: Send Test Notification

1. Go to OneSignal Dashboard
2. Messages → New Push
3. Select "Send to Test Device" or "Send to All Subscribed Users"
4. Enter message
5. Send immediately
6. Check device

### Step 5: Check Logs

```bash
adb logcat | grep -i "notification"
```

You should see notification received logs.

## Common Issues

### Issue: No Player ID in Logs

**Cause**: OneSignal not initialized properly or Firebase not working

**Fix**:
1. Download correct google-services.json from Firebase Console
2. Verify Firebase Server Key in OneSignal dashboard
3. Rebuild and reinstall

### Issue: Player ID Exists But No Notifications

**Cause**: Firebase Server Key not configured in OneSignal

**Fix**:
1. Go to OneSignal Dashboard → Settings → Platforms
2. Configure Google Android (FCM)
3. Enter Firebase Server Key and Sender ID

### Issue: Notifications Received But Not Stored

**Cause**: Notification handlers not set up

**Fix**: Already handled in code - notifications are automatically stored

## Diagnostic Commands

```bash
# Check if app is installed
adb shell pm list packages | grep spiritual

# Check app permissions
adb shell dumpsys package com.spiritual.app | grep permission

# View all logs
adb logcat | grep -E "(spiritual|OneSignal|Firebase)"

# Clear app data (to test fresh)
adb shell pm clear com.spiritual.app
```

## Next Steps

1. Install fresh APK: `./install-apk.sh`
2. Grant all permissions
3. Check logs for player ID
4. Verify device appears in OneSignal dashboard
5. Send test notification
6. If still not working, check Firebase Server Key in OneSignal

---

**Fresh APK**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)
**Includes**: All permissions screen + better logging
