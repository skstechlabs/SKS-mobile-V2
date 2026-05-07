# ⚠️ ACTION REQUIRED - Download Correct google-services.json

## What I Found

Your Firebase Console has package name: `com.spiritual.app` ✅

But the google-services.json you sent me has: `com.spiritual.spiritual_app` ❌

These don't match! You need to download the correct file from Firebase.

## What You Need to Do

### Step 1: Download Correct File from Firebase

1. Go to https://console.firebase.google.com/
2. Open project: **sks-login-mobile**
3. Click gear icon → **Project Settings**
4. Scroll to "Your apps" section
5. Find Android app with package: **com.spiritual.app**
6. Click download button for **google-services.json**

### Step 2: Replace File

```bash
cp ~/Downloads/google-services.json android/app/google-services.json
```

### Step 3: Rebuild and Install

```bash
flutter clean
flutter pub get
flutter build apk --release
./install-apk.sh
```

## Why This is Critical

The google-services.json file you sent me is for a DIFFERENT Android app in your Firebase project (one with package `com.spiritual.spiritual_app`). 

Your actual app uses `com.spiritual.app`, so you need the google-services.json for THAT app.

## Current Status

I've configured everything in your code to use `com.spiritual.app`:
- ✅ build.gradle.kts: `com.spiritual.app`
- ✅ build.gradle: `com.spiritual.app`
- ✅ MainActivity: `package com.spiritual.app`
- ✅ AndroidManifest: configured correctly
- ✅ OneSignal: initialized correctly

But I need the CORRECT google-services.json from Firebase Console to complete the fix.

## Quick Check

After downloading, verify:
```bash
grep "package_name" android/app/google-services.json
```

Should show: `"package_name": "com.spiritual.app"`

---

**Next**: Download the file, then I'll rebuild the APK.
