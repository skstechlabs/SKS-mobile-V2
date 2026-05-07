# Debug White Screen Issue - Action Plan

**Date:** March 29, 2026  
**Status:** 🔍 NEEDS DEVICE LOGS

---

## 🎯 Current Situation

The app shows "Something went wrong, restart app" after splash screen on mobile devices (works fine on web).

### What We Know

1. ✅ Error handling is in place in `main.dart`
2. ✅ All services wrapped in try-catch blocks
3. ✅ Error boundary only shows in debug mode
4. ❌ Don't know which service is failing
5. ❌ Need actual device logs to identify root cause

---

## 🔍 Step 1: Collect Device Logs

### Connect Device and Get Logs

```bash
# Connect your Android device via USB
# Enable USB debugging in Developer Options

# Check device is connected
adb devices

# Clear previous logs
adb logcat -c

# Install the APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Start collecting logs
adb logcat | grep -E "flutter|Firebase|OneSignal|API|Exception|Error|✅|❌|🚀" > app_debug.log

# Open the app on device
# Let it show the error
# Press Ctrl+C to stop log collection

# View the logs
cat app_debug.log
```

### What to Look For

Look for these patterns in the logs:

**Success Messages (should see all of these):**
```
✅ Firebase initialized successfully
✅ API Service initialized successfully
✅ Notification Storage initialized successfully
✅ AudioService initialized successfully
🚀 Starting app...
✅ OneSignal initialized successfully
```

**Error Messages (identify which service fails):**
```
❌ Firebase initialization failed: [error details]
❌ API Service initialization failed: [error details]
❌ Notification Storage initialization failed: [error details]
❌ AudioService initialization failed: [error details]
❌ OneSignal initialization failed: [error details]
❌ CRITICAL: App initialization failed: [error details]
```

**Common Errors:**
```
# Firebase errors
E/FirebaseApp: Firebase initialization failed
E/FirebaseAuth: Authentication failed

# API errors
E/flutter: API Service: Connection refused
E/flutter: API Service: Network unreachable

# Storage errors
E/flutter: Storage permission denied
E/flutter: Failed to initialize shared preferences

# Router errors
E/flutter: No route defined for /splash
E/flutter: Navigation failed
```

---

## 🔧 Step 2: Fix Based on Logs

### Scenario A: Firebase Initialization Failed

**Symptoms:**
```
❌ Firebase initialization failed: [error]
```

**Possible Causes:**
1. google-services.json mismatch
2. Package name mismatch
3. Firebase project not configured

**Fix:**
```bash
# 1. Verify package name in build.gradle.kts
cat android/app/build.gradle.kts | grep applicationId
# Should be: applicationId = "com.spiritual.app"

# 2. Verify google-services.json
cat android/app/google-services.json | grep package_name
# Should be: "package_name": "com.spiritual.app"

# 3. Download fresh google-services.json from Firebase Console
# https://console.firebase.google.com/project/sks-login-mobile/settings/general

# 4. Replace the file
cp ~/Downloads/google-services.json android/app/

# 5. Rebuild
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.json
```

### Scenario B: API Service Failed

**Symptoms:**
```
❌ API Service initialization failed: [error]
```

**Possible Causes:**
1. Backend server not reachable
2. Wrong API URL in .env.json
3. Network permission issue

**Fix:**
```bash
# 1. Check .env.json
cat .env.json | grep API_BASE_URL
# Should be: "API_BASE_URL": "http://sivakundalini.org:4000"

# 2. Test backend connectivity
curl http://sivakundalini.org:4000/health
# Should return 200 OK

# 3. Check AndroidManifest.xml has internet permission
cat android/app/src/main/AndroidManifest.xml | grep INTERNET
# Should have: <uses-permission android:name="android.permission.INTERNET" />

# 4. If missing, add to AndroidManifest.xml
```

### Scenario C: Router/Navigation Failed

**Symptoms:**
```
E/flutter: No route defined for /splash
E/flutter: Navigation failed
```

**Possible Causes:**
1. Router initialization failed
2. Missing route definition
3. Context not available

**Fix:**
Check `lib/core/router.dart` has all routes defined:
- /splash
- /login
- /profile-setup
- /permissions
- /notification-permission
- / (home)

### Scenario D: Storage/Permissions Failed

**Symptoms:**
```
❌ Notification Storage initialization failed: [error]
E/flutter: Storage permission denied
```

**Possible Causes:**
1. Storage permission not granted
2. SharedPreferences initialization failed

**Fix:**
```bash
# Check AndroidManifest.xml has storage permissions
cat android/app/src/main/AndroidManifest.xml | grep storage

# Should have these permissions if needed:
# <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
# <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### Scenario E: OneSignal Failed

**Symptoms:**
```
❌ OneSignal initialization failed: [error]
```

**Note:** OneSignal initializes AFTER app starts, so this shouldn't cause white screen.

**Fix:**
```bash
# Verify OneSignal App ID in .env.json
cat .env.json | grep ONESIGNAL_APP_ID
# Should be: "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9"
```

---

## 🧪 Step 3: Test Specific Scenarios

### Test 1: Fresh Install (No Internet)

```bash
# Enable airplane mode on device
# Uninstall app
adb uninstall com.spiritual.app

# Install fresh
adb install build/app/outputs/flutter-apk/app-release.apk

# Collect logs
adb logcat | grep -E "flutter|Exception|Error|✅|❌"

# Expected: App should load (may show API errors but UI should work)
```

### Test 2: Fresh Install (With Internet)

```bash
# Disable airplane mode
# Uninstall app
adb uninstall com.spiritual.app

# Install fresh
adb install build/app/outputs/flutter-apk/app-release.apk

# Collect logs
adb logcat | grep -E "flutter|Exception|Error|✅|❌"

# Expected: All services should initialize successfully
```

### Test 3: Clear Data and Restart

```bash
# Clear app data
adb shell pm clear com.spiritual.app

# Restart app
adb shell am start -n com.spiritual.app/.MainActivity

# Collect logs
adb logcat | grep -E "flutter|Exception|Error|✅|❌"

# Expected: App should load like fresh install
```

---

## 🔍 Step 4: Enable Verbose Logging

If still unclear, enable verbose logging:

### Modify main.dart temporarily

```dart
void main() async {
  // Add this at the very beginning
  debugPrint('🔍 DEBUG: Starting main()');
  
  try {
    debugPrint('🔍 DEBUG: Initializing Flutter binding');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🔍 DEBUG: Flutter binding initialized');

    // Add debugPrint before and after each initialization
    debugPrint('🔍 DEBUG: Starting Firebase initialization');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
    
    // ... similar for all services
    
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
```

### Rebuild and Test

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.json
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep -E "DEBUG|flutter|Exception|Error"
```

---

## 📊 Step 5: Analyze Logs

### Create Log Analysis Report

```bash
# Save logs to file
adb logcat > full_logs.txt

# Extract Flutter logs
grep "flutter" full_logs.txt > flutter_logs.txt

# Extract errors
grep -E "Exception|Error|FATAL" full_logs.txt > errors.txt

# Extract our debug messages
grep -E "✅|❌|🚀|🔍" full_logs.txt > debug_messages.txt
```

### Look for Patterns

1. **Timing Issues**: Does error happen immediately or after delay?
2. **Consistency**: Does it happen every time or randomly?
3. **Service Order**: Which service fails first?
4. **Stack Traces**: What's the call stack when error occurs?

---

## 🎯 Common Solutions

### Solution 1: Remove Error Boundary in Release Mode

The error boundary might be catching errors that should be handled differently.

**Current code in main.dart:**
```dart
if (kDebugMode) {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Show error widget
  };
}
```

**Try removing error boundary completely:**
```dart
// Comment out the entire ErrorWidget.builder section
// Let Flutter handle errors naturally
```

### Solution 2: Simplify Initialization

Remove non-critical services temporarily to isolate the issue:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize Firebase (most critical)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    developer.log('Firebase failed: $e');
  }
  
  // Start app immediately
  runApp(const SpiritualApp());
  
  // Initialize other services after app starts
  Future.delayed(const Duration(seconds: 1), () {
    // Initialize API, Storage, Audio, OneSignal here
  });
}
```

### Solution 3: Add Fallback UI

If error persists, show a better error screen:

```dart
// In MaterialApp.router builder
builder: (context, child) {
  if (child == null) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
  return child;
}
```

---

## 📞 Next Steps

1. **Collect logs** using the commands above
2. **Identify failing service** from log messages
3. **Apply specific fix** based on the error
4. **Test thoroughly** on multiple devices
5. **Report findings** with log excerpts

---

## 🚨 Emergency Rollback

If issue persists and blocking production:

```bash
# Revert to last working version
git log --oneline  # Find last working commit
git checkout <commit-hash>

# Rebuild
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.json
```

---

## ✅ Success Criteria

Issue is resolved when:

- ✅ App loads immediately on first install
- ✅ No "Something went wrong" message
- ✅ All services initialize successfully (check logs)
- ✅ Works with and without internet
- ✅ Works on multiple devices
- ✅ Survives app restart
- ✅ Survives device restart

---

**IMPORTANT:** Without device logs, we can only guess. The logs will tell us exactly what's failing and why.
