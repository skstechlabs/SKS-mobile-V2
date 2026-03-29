# Step-by-Step OneSignal Setup Guide

## Current Status

✅ Flutter SDK integrated correctly
✅ OneSignal initialized in app
✅ Permissions screen working
✅ APK installed on device
❌ Device NOT appearing in OneSignal (Firebase credentials missing)

## The Problem

OneSignal can't register your device because it doesn't have Firebase credentials to communicate with FCM.

## The Solution (3 Steps)

### STEP 1: Enable Firebase Cloud Messaging API v1

1. Open: https://console.cloud.google.com/
2. Select project: **sks-login-mobile** (top dropdown)
3. In search bar, type: **"Firebase Cloud Messaging API"**
4. Click on the API result
5. Click **"ENABLE"** button
6. Wait for confirmation (10-20 seconds)

**Why**: OneSignal uses FCM v1 API which must be explicitly enabled

---

### STEP 2: Generate Service Account JSON

1. Open: https://console.firebase.google.com/
2. Select project: **sks-login-mobile**
3. Click **gear icon** (⚙️) → **Project Settings**
4. Click **"Service Accounts"** tab (top menu)
5. Scroll down to **"Firebase Admin SDK"** section
6. Click **"Generate new private key"** button
7. Dialog appears → Click **"Generate key"**
8. JSON file downloads automatically
9. **Save this file** - name it something like `firebase-service-account.json`

**File will look like**:
```json
{
  "type": "service_account",
  "project_id": "sks-login-mobile",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-xxxxx@sks-login-mobile.iam.gserviceaccount.com",
  ...
}
```

**Why**: This file allows OneSignal to authenticate with Firebase and send notifications

---

### STEP 3: Upload to OneSignal

1. Open: https://onesignal.com/
2. Click on your app (or select from dropdown)
3. Click **"Settings"** in left sidebar (⚙️ icon)
4. Click **"Platforms"** in left menu
5. Find **"Google Android (FCM)"** section
6. Click **"Configure"** button (or "Edit Configuration" if already configured)
7. You'll see two tabs:
   - **"FCM v1"** ← Select this tab
   - "Legacy Server Key"
8. Click **"Upload Service Account JSON"** button
9. Select the JSON file you downloaded in Step 2
10. Click **"Upload"** or **"Save"**
11. You should see:
    - ✅ Green checkmark
    - ✅ "Configuration saved successfully"
    - ✅ Sender ID: 294856785598

**Why**: OneSignal needs these credentials to send notifications via Firebase

---

## STEP 4: Test the Setup

### A. Reinstall App

1. Uninstall old app from device
2. Install fresh APK: `build/app/outputs/flutter-apk/app-release.apk`
3. Open app
4. Complete login/profile
5. Grant ALL permissions (notifications, camera, microphone)
6. Wait 30 seconds

### B. Check OneSignal Dashboard

1. Go to OneSignal Dashboard
2. Click **"Audience"** in left sidebar
3. Click **"Subscriptions"** tab
4. **Your device should now appear!**

You should see:
- Subscription ID (player ID)
- Platform: Android
- Status: Subscribed
- Last Active: Just now

### C. Send Test Notification

1. OneSignal Dashboard → **"Messages"** (left sidebar)
2. Click **"New Push"** button
3. Fill in:
   - **Title**: "Test from OneSignal"
   - **Message**: "If you see this, it works!"
4. **Audience**: Select "Send to All Subscribed Users"
5. Click **"Review & Send"**
6. Click **"Send Message"**
7. **Check your device** - notification should appear within seconds

### D. Verify in App

1. Notification appears on device
2. Tap notification
3. App opens
4. Go to Notifications page (bell icon)
5. Notification should be listed there

---

## Troubleshooting

### Device Still Not Appearing

**Check 1**: Firebase Cloud Messaging API v1 enabled?
- Google Cloud Console → APIs & Services → Enabled APIs
- Should see "Firebase Cloud Messaging API"

**Check 2**: Service Account JSON uploaded to OneSignal?
- OneSignal → Settings → Platforms → Google Android (FCM)
- Should show green checkmark and "Configured"

**Check 3**: App has correct OneSignal App ID?
```bash
grep "ONESIGNAL_APP_ID" .env.json
grep "onesignal_app_id" android/app/src/main/AndroidManifest.xml
```
Both should show: `3586ffae-bd5f-4475-91c0-6dd24a129a05`

**Check 4**: Google Play Services on device?
- Device Settings → Apps → Google Play Services
- Must be installed and updated

**Check 5**: Internet connection?
- Device must have active internet

### Notifications Not Received

**Most Common**: Firebase credentials not configured in OneSignal
- Follow Step 3 above

**Other**: Device not subscribed
- Check OneSignal Dashboard → Audience → Subscriptions
- If device not listed, reinstall app and grant permissions

---

## Quick Reference

### Firebase Console URLs
- Main: https://console.firebase.google.com/
- Cloud Console: https://console.cloud.google.com/

### OneSignal Dashboard
- Main: https://onesignal.com/
- Your App ID: `3586ffae-bd5f-4475-91c0-6dd24a129a05`

### Firebase Project
- Name: sks-login-mobile
- Project Number: 294856785598
- Sender ID: 294856785598

### Package Name
- com.spiritual.app

---

## Summary

The app code is 100% correct. The only missing piece is **Firebase Service Account JSON in OneSignal Dashboard**.

Once you complete Steps 1-3 above, notifications will work immediately.

**Time required**: 5-10 minutes
**Difficulty**: Easy (just following steps in dashboards)
**Result**: Full push notification functionality
