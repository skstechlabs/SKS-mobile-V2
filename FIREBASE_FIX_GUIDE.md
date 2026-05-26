# Firebase Initialization Fix Guide

## Error
```
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
```

## Root Cause
Firebase initialization is failing silently in the app, causing Google Sign-In to fail.

## Solution Steps

### Step 1: Clean and Rebuild the App

```bash
# Navigate to mobile app directory
cd s:\SKS-mobile-V2

# Clean Flutter build cache
flutter clean

# Get dependencies
flutter pub get

# Rebuild the app
flutter build apk --debug
# OR for running on device
flutter run
```

### Step 2: Verify Firebase Configuration Files

#### Check google-services.json (Android)
Location: `s:\SKS-mobile-V2\android\app\google-services.json`

Verify:
- ✅ File exists
- ✅ `project_id`: "sks-login-mobile"
- ✅ `mobilesdk_app_id`: "1:294856785598:android:c5a6e5f6685abcef9da8ef"
- ✅ `package_name`: "com.spiritual.app"

#### Check firebase_options.dart
Location: `s:\SKS-mobile-V2\lib\firebase_options.dart`

Verify:
- ✅ File exists
- ✅ Android configuration present
- ✅ API key matches google-services.json

### Step 3: Verify Android Build Configuration

#### Check android/app/build.gradle.kts
Ensure these lines are present:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Must be present
}
```

#### Check android/build.gradle.kts
Ensure Google Services plugin is in dependencies:

```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")  // ← Must be present
}
```

### Step 4: Check Package Name Consistency

All these must match: **com.spiritual.app**

1. `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest package="com.spiritual.app">
   ```

2. `android/app/google-services.json`:
   ```json
   "package_name": "com.spiritual.app"
   ```

3. `android/app/build.gradle.kts`:
   ```kotlin
   namespace = "com.spiritual.app"
   applicationId = "com.spiritual.app"
   ```

### Step 5: Verify SHA-1 Certificate

The google-services.json has these certificate hashes:
- `ffe75b3eee2c36546c8e4037788af066ba1e4e7d`
- `e86a515c68af408a6148871ef70b4b48ab5fc78a`

Check your debug keystore SHA-1:

```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Look for SHA1 fingerprint
```

If SHA-1 doesn't match, add it to Firebase Console:
1. Go to Firebase Console → Project Settings
2. Select your Android app
3. Add the SHA-1 fingerprint
4. Download new google-services.json
5. Replace the old file
6. Rebuild the app

### Step 6: Test Firebase Initialization

Add this test code to verify Firebase is working:

```dart
// In main.dart, after Firebase.initializeApp()
try {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log('✅ Firebase initialized successfully');
  
  // Test Firebase Auth
  final auth = FirebaseAuth.instance;
  developer.log('✅ FirebaseAuth instance: ${auth.app.name}');
  developer.log('✅ Firebase App name: ${Firebase.app().name}');
  
} catch (e, stackTrace) {
  developer.log('❌ CRITICAL: Firebase initialization failed: $e');
  developer.log('Stack trace: $stackTrace');
  rethrow;
}
```

### Step 7: Common Issues and Fixes

#### Issue 1: Multidex Error
If you see "Cannot fit requested classes in a single dex file":

Add to `android/app/build.gradle.kts`:
```kotlin
android {
    defaultConfig {
        multiDexEnabled = true
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
```

#### Issue 2: Gradle Sync Failed
```bash
cd android
./gradlew clean
./gradlew build
cd ..
flutter clean
flutter pub get
```

#### Issue 3: Firebase Core Version Mismatch
Check `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  google_sign_in: ^7.2.0
```

Run:
```bash
flutter pub upgrade firebase_core firebase_auth google_sign_in
```

#### Issue 4: Google Services Plugin Not Applied
Verify `android/app/build.gradle.kts` has at the **bottom**:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### Step 8: Rebuild and Test

```bash
# Full clean rebuild
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run

# Watch logs
adb logcat | grep -i firebase
```

## Expected Output (Success)

When Firebase initializes correctly, you should see:

```
I/flutter: ========================================
I/flutter: 🔍 CHECKING ENVIRONMENT CONFIGURATION
I/flutter: ========================================
I/flutter: ✅ Firebase initialized successfully
I/flutter: ✅ FirebaseAuth instance: [DEFAULT]
I/flutter: ✅ Firebase App name: [DEFAULT]
I/flutter: ✅ API Service initialized
I/flutter: ✅ Notification Storage initialized
I/flutter: ✅ Localization initialized
I/flutter: ✅ AuthState initialized
I/flutter: ✅ ConnectivityService initialized
I/flutter: ✅ AudioService initialized
I/flutter: 🚀 Starting app...
```

## Testing Google Sign-In

After Firebase is initialized:

1. Open the app
2. Click "Login with Google"
3. Select Google account
4. Should see success message

Expected flow:
```
I/flutter: 🔑 GoogleSignIn.initialize() with serverClientId: 294856785598-qivhqf2ehn5p0rs1830dt9mt030ort9p.apps.googleusercontent.com
I/flutter: ✅ GoogleSignIn.instance initialized
I/flutter: ✅ GoogleSignIn account: user@example.com
I/flutter: ✅ idToken: present
I/flutter: ✅ Firebase sign-in success: user@example.com
```

## Quick Diagnostic Commands

```bash
# Check if google-services.json is being included in build
cd s:\SKS-mobile-V2\android
./gradlew :app:dependencies | grep google-services

# Check Firebase dependencies
flutter pub deps | grep firebase

# Check for build errors
flutter analyze

# Verbose build to see Firebase initialization
flutter run -v
```

## Still Not Working?

### Check Android Logs
```bash
# Filter for Firebase errors
adb logcat | grep -E "Firebase|GoogleSignIn|auth"

# Check for initialization errors
adb logcat | grep -i "no-app"
```

### Verify Firebase Project
1. Go to Firebase Console: https://console.firebase.google.com
2. Select project: sks-login-mobile
3. Check Authentication → Sign-in method → Google is enabled
4. Check Project Settings → Your apps → Android app is configured

### Re-download Configuration
1. Firebase Console → Project Settings
2. Select Android app
3. Download google-services.json
4. Replace `s:\SKS-mobile-V2\android\app\google-services.json`
5. Run `flutter clean && flutter pub get`
6. Rebuild app

## Summary

The error `[core/no-app] No Firebase App '[DEFAULT]' has been created` means:
1. Firebase.initializeApp() was never called successfully
2. OR Firebase.initializeApp() was called but failed silently
3. OR google-services.json is not being processed during build

**Most Common Fix**: Clean rebuild
```bash
flutter clean
flutter pub get
flutter run
```

**If that doesn't work**: Check SHA-1 certificate and re-download google-services.json from Firebase Console.
