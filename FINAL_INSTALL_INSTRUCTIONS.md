# Final Installation Instructions

## ✅ Everything is Now Correct

- ✅ Correct google-services.json (package: com.spiritual.app)
- ✅ All permissions screen (notifications + camera + microphone)
- ✅ OneSignal properly initialized
- ✅ Fresh APK built (132.2 MB)

## Install Now

```bash
./install-apk.sh
```

## What Will Happen

1. App opens
2. Login/profile setup
3. **Permissions screen** appears showing:
   - 🔔 Notifications (REQUIRED)
   - 📷 Camera (optional)
   - 🎤 Microphone (optional)
4. Click "Grant Permissions"
5. You'll see 3 Android permission dialogs (one for each)
6. Grant at least notifications
7. App goes to home

## Test Push Notifications

### Step 1: Verify Subscription

After granting permissions, run:
```bash
adb logcat | grep -E "(subscription|player|token)"
```

Look for:
```
📊 Push subscription state changed
   - ID: [some-player-id]
   - Token: [some-fcm-token]
   - Opted In: true
```

### Step 2: Check OneSignal Dashboard

1. Go to https://onesignal.com/
2. Your app → Audience → Subscriptions
3. Your device should appear with the player ID

### Step 3: Configure Firebase Server Key (CRITICAL)

**This is probably why notifications aren't being received!**

1. Go to Firebase Console: https://console.firebase.google.com/
2. Project: sks-login-mobile
3. Settings (gear icon) → **Cloud Messaging** tab
4. Copy the **Server Key** (under Cloud Messaging API - Legacy)

Then:
1. Go to OneSignal Dashboard: https://onesignal.com/
2. Your app → Settings → Platforms
3. Click **"Google Android (FCM)"**
4. Enter:
   - **Firebase Server Key**: [paste the key from Firebase]
   - **Firebase Sender ID**: `294856785598`
5. Click **Save**

### Step 4: Send Test Notification

1. OneSignal Dashboard → Messages → New Push
2. Title: "Test"
3. Message: "Testing notifications"
4. Audience: "Send to Test Device" or "All Subscribed Users"
5. Click "Send Message"
6. Check your device

## If Notifications Still Don't Arrive

### Check 1: Firebase Server Key

The most common reason notifications don't arrive is missing Firebase Server Key in OneSignal.

Verify: OneSignal Dashboard → Settings → Platforms → Google Android (FCM) → Server Key is filled

### Check 2: Device Subscription

```bash
adb logcat | grep -i "opted in"
```

Should show: `Opted In: true`

### Check 3: OneSignal Dashboard

Audience → Subscriptions → Your device should be listed

### Check 4: Test from OneSignal

Send a test notification from OneSignal dashboard (not from your backend) to verify the setup works.

## Logs to Monitor

```bash
# Clear logs first
adb logcat -c

# Then monitor while testing
adb logcat | grep -E "(OneSignal|Firebase|notification|spiritual)"
```

---

**APK**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)
**Status**: ✅ Ready with correct Firebase config
**Next**: Install and configure Firebase Server Key in OneSignal
