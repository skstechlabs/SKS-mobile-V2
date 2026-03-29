# 🚀 Install APK & Complete OneSignal Setup

## ✅ WHAT'S FIXED
- Compilation error fixed (removed invalid `providerData` reference)
- All permissions screen now requests: Notifications (required), Camera (optional), Microphone (optional)
- Fresh APK built: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)

---

## 📱 STEP 1: Install the APK on Your Android Device

### Option A: Transfer via USB Cable
1. Connect your Android device to Mac via USB
2. Copy APK to device:
   ```bash
   # Find your device in Finder, then drag the APK file to it
   # Or use Android File Transfer app
   ```
3. On your device, open "Files" or "Downloads" app
4. Tap the APK file and install

### Option B: Transfer via Cloud/Email
1. Upload `build/app/outputs/flutter-apk/app-release.apk` to Google Drive/Dropbox
2. Open the link on your Android device
3. Download and install

### Option C: Direct Transfer
1. Use any file transfer app (Snapdrop, Send Anywhere, etc.)
2. Transfer APK from Mac to Android
3. Install on device

---

## 🔔 STEP 2: Test Permissions

1. Open the app on your device
2. You should see the "App Permissions" screen
3. Tap "Grant Permissions"
4. You'll see 3 permission dialogs:
   - **Notifications** (mandatory) - MUST grant
   - **Camera** (optional) - can skip
   - **Microphone** (optional) - can skip
5. After granting notifications, app will navigate to home

---

## 🔥 STEP 3: Fix OneSignal Firebase Configuration

**PROBLEM**: You uploaded the wrong Firebase project to OneSignal Dashboard.

**SOLUTION**: Replace it with the correct Service Account JSON.

### A. Enable Firebase Cloud Messaging API (v1)
1. Go to: https://console.cloud.google.com/apis/library/fcm.googleapis.com
2. Select project: **sks-login-mobile**
3. Click "ENABLE" button

### B. Download Service Account JSON
1. Go to: https://console.firebase.google.com/project/sks-login-mobile/settings/serviceaccounts/adminsdk
2. Click "Generate new private key"
3. Click "Generate key" in the popup
4. Save the JSON file (e.g., `sks-login-mobile-firebase-adminsdk.json`)

### C. Upload to OneSignal Dashboard
1. Go to: https://dashboard.onesignal.com/apps/3586ffae-bd5f-4475-91c0-6dd24a129a05/settings/platforms
2. Find "Google Android (FCM)" section
3. Click on the **"FCM v1"** tab (NOT Legacy API)
4. Click "Upload Service Account JSON"
5. Select the JSON file you downloaded in step B
6. Click "Save"

This will REPLACE the wrong Firebase configuration with the correct one.

---

## ✅ STEP 4: Verify Device Registration

1. **Uninstall** the old app from your device (important!)
2. **Reinstall** the new APK from Step 1
3. Grant notification permission
4. Wait 10-20 seconds
5. Check OneSignal Dashboard:
   - Go to: https://dashboard.onesignal.com/apps/3586ffae-bd5f-4475-91c0-6dd24a129a05/audience/subscriptions
   - You should see your device listed with:
     - Subscription ID
     - Device type (Android)
     - Last active timestamp

---

## 🧪 STEP 5: Send Test Notification

1. In OneSignal Dashboard, go to "Messages" → "New Push"
2. Select "Send to Test Device"
3. Enter your Subscription ID (from Step 4)
4. Write a test message
5. Click "Send Message"
6. Check your Android device - you should receive the notification!

---

## 🔍 TROUBLESHOOTING

### Device not appearing in OneSignal subscriptions?
- Verify FCM v1 API is enabled in Google Cloud Console
- Verify Service Account JSON is uploaded to OneSignal
- Check app logs for OneSignal initialization errors
- Ensure internet connection is active
- Wait 30-60 seconds after granting permission

### Notifications not received?
- Check device is in subscriptions list
- Verify notification permission is granted in device settings
- Check OneSignal message delivery status in Dashboard
- Ensure app is not in battery optimization mode

---

## 📋 QUICK CHECKLIST

- [ ] Install fresh APK on device
- [ ] Grant notification permission (mandatory)
- [ ] Enable FCM v1 API in Google Cloud Console
- [ ] Download Service Account JSON from Firebase Console
- [ ] Upload Service Account JSON to OneSignal Dashboard (FCM v1 tab)
- [ ] Uninstall and reinstall app
- [ ] Verify device appears in OneSignal subscriptions
- [ ] Send test notification from OneSignal Dashboard

---

**Your OneSignal App ID**: `3586ffae-bd5f-4475-91c0-6dd24a129a05`  
**Firebase Project**: `sks-login-mobile` (Project #: 294856785598)  
**Package Name**: `com.spiritual.app`
