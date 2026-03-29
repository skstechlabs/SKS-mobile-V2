# Firebase + OneSignal Complete Setup Guide

## 🎯 Overview

This guide will help you:
1. Create a new Firebase project for notifications
2. Add Android and iOS apps
3. Get Firebase Server Key
4. Configure OneSignal
5. Connect everything to your Flutter app

**Time Required:** 20-25 minutes

---

## 📋 Prerequisites

- Google account (for Firebase)
- OneSignal account (free)
- Flutter project ready
- Android Studio or Xcode installed

---

## PART 1: Firebase Setup

### STEP 1: Create Firebase Project

1. **Go to Firebase Console**
   ```
   URL: https://console.firebase.google.com/
   ```

2. **Create New Project**
   - Click "Add project"
   - Project name: `sks-mobile-notifications`
   - Click "Continue"

3. **Google Analytics**
   - Toggle OFF (not needed for push notifications)
   - Click "Create project"
   - Wait 30-60 seconds
   - Click "Continue"

✅ **Checkpoint:** You should see the Firebase project dashboard

---

### STEP 2: Add Android App

1. **Click "Add app"**
   - Click the Android icon (robot)

2. **Register Android App**
   ```
   Android package name: com.spiritual.app
   App nickname: SKS Android (optional)
   Debug SHA-1: Leave blank
   ```
   - Click "Register app"

3. **Download google-services.json**
   - Click "Download google-services.json"
   - Save to your Downloads folder
   - Click "Next"

4. **Skip SDK Setup**
   - Click "Next" (we'll configure manually)
   - Click "Next" again
   - Click "Continue to console"

✅ **Checkpoint:** You should have `google-services.json` file downloaded

---

### STEP 3: Add iOS App

1. **Click "Add app" again**
   - Click the iOS icon (Apple)

2. **Register iOS App**
   ```
   iOS bundle ID: com.spiritual.app
   App nickname: SKS iOS (optional)
   App Store ID: Leave blank
   ```
   - Click "Register app"

3. **Download GoogleService-Info.plist**
   - Click "Download GoogleService-Info.plist"
   - Save to your Downloads folder
   - Click "Next"

4. **Skip SDK Setup**
   - Click "Next"
   - Click "Next" again
   - Click "Continue to console"

✅ **Checkpoint:** You should have `GoogleService-Info.plist` file downloaded

---

### STEP 4: Get Firebase Server Key

1. **Go to Project Settings**
   - Click Settings icon (⚙️) in left sidebar
   - Click "Project settings"

2. **Go to Cloud Messaging Tab**
   - Click "Cloud Messaging" tab

3. **Enable Cloud Messaging API**
   - Find "Cloud Messaging API (V1)"
   - Click the three dots (...) menu
   - Click "Manage API in Google Cloud Console"
   - Click "ENABLE" button
   - Wait for it to enable (10-20 seconds)
   - Go back to Firebase Console tab

4. **Get Server Key (Legacy)**
   - Scroll down to "Cloud Messaging API (Legacy)"
   - Find "Server key"
   - Copy the key (starts with "AAAA...")
   - **SAVE THIS KEY!** You'll need it for OneSignal

✅ **Checkpoint:** You should have copied the Firebase Server Key

---

## PART 2: Flutter Project Configuration

### STEP 5: Add google-services.json to Android

1. **Open Terminal/Command Prompt**
   ```bash
   cd your_flutter_project
   ```

2. **Copy google-services.json**
   ```bash
   # Copy from Downloads to android/app/
   cp ~/Downloads/google-services.json android/app/
   
   # Or on Windows:
   # copy %USERPROFILE%\Downloads\google-services.json android\app\
   ```

3. **Verify File Location**
   ```
   your_flutter_project/
   └── android/
       └── app/
           └── google-services.json  ← Should be here
   ```

✅ **Checkpoint:** File should be at `android/app/google-services.json`

---

### STEP 6: Configure Android Build Files

1. **Open android/build.gradle**
   
   Find the `dependencies` section inside `buildscript` and add:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.android.tools.build:gradle:7.3.0'
           classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
           classpath 'com.google.gms:google-services:4.4.0'  // Add this line
       }
   }
   ```

2. **Open android/app/build.gradle**
   
   Add at the very bottom of the file:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

✅ **Checkpoint:** Android configuration complete

---

### STEP 7: Add GoogleService-Info.plist to iOS

1. **Copy GoogleService-Info.plist**
   ```bash
   # Copy from Downloads to ios/Runner/
   cp ~/Downloads/GoogleService-Info.plist ios/Runner/
   
   # Or on Windows:
   # copy %USERPROFILE%\Downloads\GoogleService-Info.plist ios\Runner\
   ```

2. **Add to Xcode (IMPORTANT!)**
   ```bash
   # Open Xcode workspace
   open ios/Runner.xcworkspace
   ```
   
   In Xcode:
   - Right-click on "Runner" folder in left sidebar
   - Select "Add Files to Runner..."
   - Navigate to `ios/Runner/GoogleService-Info.plist`
   - Check "Copy items if needed"
   - Click "Add"

3. **Verify in Xcode**
   - You should see `GoogleService-Info.plist` in Runner folder
   - It should have a checkmark next to "Runner" target

✅ **Checkpoint:** iOS configuration complete

---

## PART 3: OneSignal Configuration

### STEP 8: Configure OneSignal

1. **Go to OneSignal Dashboard**
   ```
   URL: https://onesignal.com/
   ```

2. **Select Your App**
   - Click on your app (or create new one)

3. **Go to Settings**
   - Click Settings (⚙️) icon
   - Click "Platforms"

4. **Configure Google Android (FCM)**
   - Click "Google Android (FCM)"
   - Click "Configuration" button
   - Paste your **Firebase Server Key** (from Step 4)
   - Click "Save & Continue"

5. **Get OneSignal App ID**
   - Go to Settings > Keys & IDs
   - Copy "OneSignal App ID"
   - Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

✅ **Checkpoint:** OneSignal configured with Firebase

---

### STEP 9: Update Flutter App Configuration

1. **Open .env.json**
   ```json
   {
     "ONESIGNAL_APP_ID": "paste_your_onesignal_app_id_here"
   }
   ```

2. **Replace with your actual App ID**
   ```json
   {
     "ONESIGNAL_APP_ID": "12345678-1234-1234-1234-123456789abc"
   }
   ```

3. **Save the file**

✅ **Checkpoint:** Configuration complete

---

## PART 4: Testing

### STEP 10: Run the App

1. **Clean and Get Dependencies**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Run on Android**
   ```bash
   flutter run --dart-define-from-file=.env.json
   ```

3. **Complete the Flow**
   - Login with phone or Google
   - Complete profile
   - Grant camera/microphone permissions
   - **MUST** allow notification permission
   - App should open to home screen

✅ **Checkpoint:** App runs without errors

---

### STEP 11: Verify in OneSignal Dashboard

1. **Go to OneSignal Dashboard**
   - Audience > All Users

2. **Check Your Device**
   - You should see 1 user
   - Click on the user

3. **Verify Details**
   - Player ID: Should exist
   - External User ID: Should be your Firebase UID
   - Tags: Should show auth_provider, mobile, etc.
   - Subscription: Should be "Subscribed"

✅ **Checkpoint:** User appears in OneSignal

---

### STEP 12: Send Test Notification

1. **Go to OneSignal Dashboard**
   - Messages > New Push

2. **Create Notification**
   - Audience: "Send to All Subscribers"
   - Title: "Test Notification"
   - Message: "Testing OneSignal integration!"
   - Click "Review"

3. **Send**
   - Click "Send Message"
   - Wait 5-10 seconds

4. **Check Your Device**
   - You should receive the notification
   - Tap it to open the app

✅ **Checkpoint:** Notification received and working!

---

## 🎉 Success Checklist

- [ ] Firebase project created: `sks-mobile-notifications`
- [ ] Android app added to Firebase
- [ ] iOS app added to Firebase
- [ ] Firebase Server Key obtained
- [ ] google-services.json placed in android/app/
- [ ] GoogleService-Info.plist placed in ios/Runner/
- [ ] Android build.gradle files updated
- [ ] iOS file added to Xcode
- [ ] OneSignal configured with Firebase Server Key
- [ ] OneSignal App ID copied
- [ ] .env.json updated with App ID
- [ ] App runs without errors
- [ ] User appears in OneSignal dashboard
- [ ] Test notification received

---

## 📁 File Structure Verification

```
your_flutter_project/
├── android/
│   ├── app/
│   │   ├── google-services.json          ✅ Must be here
│   │   └── build.gradle                  ✅ Updated
│   └── build.gradle                      ✅ Updated
│
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist      ✅ Must be here
│
└── .env.json                             ✅ Updated with App ID
```

---

## 🐛 Troubleshooting

### Issue: "google-services.json not found"
**Solution:**
```bash
# Verify file location
ls android/app/google-services.json

# If not there, copy again
cp ~/Downloads/google-services.json android/app/
```

### Issue: "Firebase Server Key not working"
**Solution:**
1. Go to Firebase Console
2. Project Settings > Cloud Messaging
3. Make sure "Cloud Messaging API (Legacy)" is enabled
4. Copy the Server Key again
5. Update in OneSignal

### Issue: "Notifications not received"
**Solution:**
1. Check OneSignal App ID is correct in .env.json
2. Verify Firebase Server Key in OneSignal
3. Ensure notification permission granted
4. Check device has internet connection
5. Restart the app

### Issue: "User not appearing in OneSignal"
**Solution:**
1. Complete full login flow
2. Allow notification permission
3. Wait 10-15 seconds
4. Refresh OneSignal dashboard

### Issue: "Build errors after adding files"
**Solution:**
```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env.json
```

---

## 📞 Support

- **Firebase Docs**: https://firebase.google.com/docs
- **OneSignal Docs**: https://documentation.onesignal.com/
- **Flutter Firebase**: https://firebase.flutter.dev/

---

## 🚀 Next Steps

1. ✅ Test on multiple Android devices
2. ✅ Configure iOS APNs (when ready)
3. ✅ Send targeted notifications
4. ✅ Set up automation
5. ✅ Monitor analytics

---

## 📝 Important Notes

- **One Firebase project** for both Android and iOS
- **One OneSignal App ID** for both platforms
- **Firebase Server Key** is for Android (FCM)
- **APNs Key** will be needed for iOS later
- **No code changes** needed when adding iOS

---

**Congratulations! Your Firebase + OneSignal integration is complete!** 🎉

You can now send push notifications to all your users!
