# Install APK Without ADB

## Fresh APK Ready

**Location**: `build/app/outputs/flutter-apk/app-release.apk`
**Size**: 132.2 MB
**Status**: ✅ All fixes applied

## Installation Methods

### Method 1: USB Transfer (Easiest)

1. Connect Android device to Mac via USB
2. Install **Android File Transfer** if you don't have it:
   - Download from: https://www.android.com/filetransfer/
   - Or: `brew install android-file-transfer`
3. Open Android File Transfer
4. Drag `build/app/outputs/flutter-apk/app-release.apk` to device Downloads folder
5. On device:
   - Open Files app → Downloads
   - Tap `app-release.apk`
   - Tap "Install"
   - If prompted, enable "Install from unknown sources"

### Method 2: Cloud Transfer

1. Upload APK to Google Drive or Dropbox
2. On Android device, open the link
3. Download APK
4. Tap to install

### Method 3: Email

1. Email the APK to yourself
2. Open email on Android device
3. Download attachment
4. Tap to install

### Method 4: Local Web Server

```bash
# Start simple HTTP server
cd build/app/outputs/flutter-apk
python3 -m http.server 8000
```

Then on Android device:
1. Connect to same WiFi as Mac
2. Find Mac's IP: `ifconfig | grep "inet "`
3. Open browser on device: `http://[MAC_IP]:8000`
4. Download app-release.apk
5. Install

## Before Installing

**IMPORTANT**: Uninstall old app first!

On device:
1. Settings → Apps → SKS
2. Tap "Uninstall"
3. Confirm

## After Installing

1. Open app
2. Complete login/profile
3. **Grant all permissions** when prompted:
   - ✅ Notifications (mandatory)
   - ✅ Camera (optional but recommended)
   - ✅ Microphone (optional but recommended)
4. App goes to home

## Verify Notifications Work

### Step 1: Check OneSignal Dashboard

1. Go to https://onesignal.com/
2. Your app → Audience → Subscriptions
3. Your device should appear after granting permissions

### Step 2: Configure Firebase Server Key

**This is CRITICAL for receiving notifications!**

1. Go to Firebase Console: https://console.firebase.google.com/
2. Project: **sks-login-mobile**
3. Settings → **Cloud Messaging** tab
4. Copy **Server Key** (under "Cloud Messaging API (Legacy)")

Then:
1. Go to OneSignal Dashboard: https://onesignal.com/
2. Your app → Settings → Platforms
3. Click **"Configure"** under Google Android (FCM)
4. Enter:
   - **Firebase Server Key**: [paste from Firebase]
   - **Firebase Sender ID**: `294856785598`
5. Click **Save**

### Step 3: Send Test Notification

1. OneSignal Dashboard → Messages → New Push
2. Title: "Test Notification"
3. Message: "Testing from OneSignal"
4. Audience: "Send to All Subscribed Users"
5. Click "Send Message"
6. Check your device - notification should appear

## If Notifications Don't Arrive

### Most Common Issue: Firebase Server Key Not Configured

Check: OneSignal Dashboard → Settings → Platforms → Google Android (FCM)

Must have:
- ✅ Firebase Server Key filled
- ✅ Firebase Sender ID: 294856785598

### Other Checks

- Device has Google Play Services installed
- Device has internet connection
- App is open or in background (not force-closed)
- Permissions were granted

## Install ADB for Better Testing (Optional)

```bash
brew install android-platform-tools
```

Then you can use `./install-apk.sh` and view logs.

---

**APK**: `build/app/outputs/flutter-apk/app-release.apk` (132.2 MB)
**Next**: Install on device and configure Firebase Server Key in OneSignal
