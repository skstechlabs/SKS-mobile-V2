# Quick Fix Checklist

## Install Fresh APK

```bash
./install-apk.sh
```

## Test Permissions

1. Open app on Android device
2. Complete login/profile
3. On permissions screen, click "Grant Permissions"
4. You should see 3 permission dialogs:
   - Notifications (mandatory)
   - Camera (optional)
   - Microphone (optional)
5. Grant at least notifications
6. App should go to home

## Test Push Notifications

### Step 1: Verify Device is Subscribed

Run while app is open:
```bash
adb logcat | grep -i "subscription"
```

Look for player ID and FCM token.

### Step 2: Check OneSignal Dashboard

1. Go to https://onesignal.com/
2. Your app → Audience → Subscriptions
3. Verify your device appears

### Step 3: Configure Firebase Server Key

1. Go to OneSignal Dashboard → Settings → Platforms
2. Click "Google Android (FCM)"
3. Enter:
   - **Firebase Server Key**: Get from Firebase Console → Cloud Messaging
   - **Firebase Sender ID**: `294856785598`
4. Save

### Step 4: Send Test Notification

1. OneSignal Dashboard → Messages → New Push
2. Enter title and message
3. Send to "Test Device" or "All Users"
4. Check device

## If Notifications Still Don't Arrive

### Check 1: Firebase Server Key

```
OneSignal Dashboard → Settings → Platforms → Google Android (FCM)
```

Must have Firebase Server Key configured.

### Check 2: Device Subscription

```bash
adb logcat | grep -E "(player|subscription|token)"
```

Should show player ID and FCM token.

### Check 3: Google Play Services

Device Settings → Apps → Google Play Services (must be installed)

### Check 4: Internet Connection

Device must have active internet.

---

**Current APK**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)
**Status**: Includes all permissions screen + logging
