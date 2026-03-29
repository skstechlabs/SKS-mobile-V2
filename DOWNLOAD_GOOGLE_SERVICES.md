# Download Fresh google-services.json from Firebase

## The Issue

The google-services.json you provided has the WRONG mobilesdk_app_id for package `com.spiritual.app`.

Your Firebase Console shows:
- Package name: `com.spiritual.app` ✅

But the google-services.json you sent has:
- Package name: `com.spiritual.spiritual_app` ❌
- App ID: `1:294856785598:android:6cfa4330cd8002019da8ef`

This is for a DIFFERENT Android app in your Firebase project.

## Download Correct File

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **sks-login-mobile**
3. Click gear icon → **Project Settings**
4. Scroll to "Your apps"
5. Find the Android app with package name: **com.spiritual.app**
6. Click the **google-services.json** download button
7. Save the file

## Replace File

```bash
# Copy downloaded file to project
cp ~/Downloads/google-services.json android/app/google-services.json

# Verify it has correct package name
grep "package_name" android/app/google-services.json
# Should show: "package_name": "com.spiritual.app"
```

## Then Rebuild

```bash
flutter clean
flutter pub get
flutter build apk --release
./install-apk.sh
```

## Why This Matters

The google-services.json file maps your app's package name to Firebase configuration. If you use the wrong file (for a different package name), Firebase can't initialize properly.

Your Firebase project might have multiple Android apps registered:
- `com.spiritual.app` ✅ (the one you want)
- `com.spiritual.spiritual_app` ❌ (old/wrong one)

You need the google-services.json for the FIRST one.
