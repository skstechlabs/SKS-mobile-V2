# OneSignal Firebase Setup Required

## Why Device Isn't Appearing in OneSignal

Your device isn't showing in OneSignal Dashboard → Audience → Subscriptions because **OneSignal can't send notifications without Firebase credentials**.

OneSignal requires **FCM v1 Service Account JSON** to communicate with Firebase Cloud Messaging.

## Complete Setup Steps

### Step 1: Enable Firebase Cloud Messaging API v1

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **sks-login-mobile**
3. Search for "Firebase Cloud Messaging API" in the search bar
4. Click on "Firebase Cloud Messaging API"
5. Click **"Enable"** button
6. Wait for it to enable (takes a few seconds)

### Step 2: Generate Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **sks-login-mobile**
3. Click gear icon → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **"Generate new private key"** button
6. Click **"Generate key"** in the confirmation dialog
7. A JSON file will download (e.g., `sks-login-mobile-firebase-adminsdk-xxxxx.json`)
8. **Save this file securely** - you'll need it for OneSignal

### Step 3: Upload to OneSignal Dashboard

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Select your app
3. Click **Settings** (gear icon)
4. Click **Platforms** in left sidebar
5. Find **"Google Android (FCM)"**
6. Click **"Configure"** or **"Edit Configuration"**
7. You'll see two options:
   - **FCM v1 (Recommended)** ← Choose this
   - Legacy Server Key
8. Click **"Upload Service Account JSON"**
9. Select the JSON file you downloaded in Step 2
10. Click **"Save & Continue"**

### Step 4: Verify Configuration

After uploading, you should see:
- ✅ Green checkmark next to "Google Android (FCM)"
- ✅ Sender ID displayed: `294856785598`
- ✅ Status: "Configured"

## After Configuration

### Reinstall App and Test

1. Uninstall app from device
2. Install fresh APK
3. Open app
4. Grant all permissions
5. Wait 10-30 seconds
6. Check OneSignal Dashboard → Audience → Subscriptions
7. Your device should now appear!

### Send Test Notification

1. OneSignal Dashboard → **Messages** → **New Push**
2. Enter:
   - Title: "Test"
   - Message: "Testing notifications"
3. Audience: **"Send to All Subscribed Users"**
4. Click **"Send Message"**
5. Notification should appear on your device

## Why This is Required

OneSignal doesn't send notifications directly. The flow is:

```
OneSignal → Firebase Cloud Messaging → Your Device
```

Without Firebase credentials in OneSignal:
- ❌ OneSignal can't connect to FCM
- ❌ Device can't register with OneSignal
- ❌ Device won't appear in subscriptions
- ❌ Notifications can't be sent

With Firebase credentials:
- ✅ OneSignal connects to FCM
- ✅ Device registers successfully
- ✅ Device appears in subscriptions
- ✅ Notifications are delivered

## Verification Checklist

- [ ] Firebase Cloud Messaging API v1 enabled in Google Cloud Console
- [ ] Service Account JSON generated from Firebase Console
- [ ] JSON uploaded to OneSignal Dashboard
- [ ] OneSignal shows "Configured" for Google Android (FCM)
- [ ] App reinstalled on device
- [ ] Permissions granted
- [ ] Device appears in OneSignal → Audience → Subscriptions
- [ ] Test notification sent and received

## Common Issues

### Issue: Can't Find "Generate Private Key"

**Location**: Firebase Console → Project Settings → **Service Accounts** tab (not Cloud Messaging tab)

### Issue: Upload Fails in OneSignal

**Cause**: Wrong JSON file or file corrupted

**Fix**: Re-download from Firebase and try again

### Issue: Device Still Not Appearing

**Causes**:
1. Firebase credentials not configured in OneSignal
2. App not properly initialized
3. Permissions not granted
4. Google Play Services not installed on device

**Fix**: Follow all steps above, then reinstall app

## Next Steps

1. **Enable FCM API v1** in Google Cloud Console
2. **Generate Service Account JSON** from Firebase Console
3. **Upload to OneSignal** Dashboard
4. **Reinstall app** on device
5. **Grant permissions**
6. **Verify device** appears in OneSignal subscriptions
7. **Send test notification**

---

**Critical**: Without Service Account JSON in OneSignal, notifications will NEVER work, even if everything else is configured correctly.
