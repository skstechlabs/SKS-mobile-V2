# Do This Now - Fix OneSignal

## The Issue

Device not appearing in OneSignal because **Firebase credentials are missing in OneSignal Dashboard**.

## The Fix (3 Steps - 5 Minutes)

### 1. Enable FCM API

https://console.cloud.google.com/ → Project: sks-login-mobile → Search "Firebase Cloud Messaging API" → Enable

### 2. Download Service Account JSON

https://console.firebase.google.com/ → sks-login-mobile → Settings → Service Accounts → "Generate new private key"

### 3. Upload to OneSignal

https://onesignal.com/ → Your App → Settings → Platforms → Google Android (FCM) → Configure → Upload JSON

## Then Test

1. Reinstall app on device
2. Grant permissions
3. Check OneSignal Dashboard → Audience → Subscriptions
4. Device should appear
5. Send test notification

---

**Detailed guide**: See `STEP_BY_STEP_ONESIGNAL_SETUP.md`
**APK**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)
