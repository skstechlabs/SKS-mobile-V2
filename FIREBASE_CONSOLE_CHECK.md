# Firebase Console Verification

## IMPORTANT: Check Your Firebase Console

The google-services.json file in your project now has package name `com.spiritual.app`.

You need to verify this matches your Firebase Console configuration.

## Steps to Verify

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **sks-login-mobile**
3. Click gear icon → Project Settings
4. Scroll to "Your apps" section
5. Find your Android app

### Check Package Name

Your Android app in Firebase should show:
```
Package name: com.spiritual.app
```

### If Package Name is Wrong

If Firebase shows `com.spiritual.spiritual_app` instead:

**Option A: Add New App (Recommended)**
1. Click "Add app" → Android
2. Enter package name: `com.spiritual.app`
3. Download the new google-services.json
4. Replace `android/app/google-services.json`
5. Rebuild APK: `flutter build apk --release`

**Option B: Update Existing App**
- You cannot change package name of existing Firebase app
- You must delete the old app and add a new one
- Or create a new Firebase project

## Current Configuration

Your project currently has:
- **google-services.json**: `com.spiritual.app` ✅
- **build.gradle**: `com.spiritual.app` ✅
- **MainActivity**: `com.spiritual.app` ✅

If Firebase Console also has `com.spiritual.app`, you're good to go!

## If You Need to Download Fresh google-services.json

1. Firebase Console → Project Settings
2. Scroll to "Your apps" → Android app
3. Click "google-services.json" download button
4. Replace `android/app/google-services.json`
5. Rebuild: `flutter build apk --release`

## Why This Matters

The google-services.json file contains:
- Firebase project configuration
- API keys
- App identifiers
- **Package name mapping**

If the package name in this file doesn't match your app's actual package name, Firebase can't initialize, and all Firebase-dependent features (Auth, FCM, OneSignal) will fail.

## Quick Check Command

```bash
# Check what package name is in your google-services.json
grep "package_name" android/app/google-services.json
```

Should output:
```json
"package_name": "com.spiritual.app"
```

If it shows anything else, you need to fix it in Firebase Console and download fresh file.
