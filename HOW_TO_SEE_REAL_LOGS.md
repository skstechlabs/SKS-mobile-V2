# How to See REAL App Logs (Not Android System Logs)

## ❌ What You're Looking At (WRONG)

You're reading **Android system logs** (logcat) which shows:
- Google Play Store errors
- Network system messages
- Wallet errors
- Task persister errors

**These are NOT your app's logs!** ❌

---

## ✅ Where Your REAL App Logs Are

### Option 1: Flutter Console (MAIN SOURCE)

When you run:
```bash
flutter run --dart-define-from-file=.env.prod.json
```

**Look at THAT terminal window** - that's where your app logs appear!

**You should see logs like:**
```
Launching lib\main.dart on sdk gphone64 x86 64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing build\app\outputs\flutter-apk\app.apk...
Debug service listening on ws://127.0.0.1:xxxxx

🚀 Splash: initializing...               ← YOUR APP LOGS START HERE
📱 First launch — language selection      ← THESE TELL YOU WHAT'S HAPPENING
✅ Cached user found → home               ← LOOK FOR EMOJI INDICATORS
🔄 Attempting lightweight Google sign-in... ← THIS IS WHERE IT MIGHT HANG
⚠️ Lightweight sign-in failed: timeout    ← ERROR MESSAGES
👤 No session → login screen              ← NAVIGATION DECISIONS
```

---

### Option 2: Add Print Statements

If you don't see the logs above, add explicit print statements.

**Edit `lib/features/splash/splash_screen.dart`:**

At the very start of `_initializeApp()` method (line ~60), add:
```dart
Future<void> _initializeApp() async {
  try {
    print('═══════════════════════════════════════');
    print('🚀 SPLASH SCREEN STARTING');
    print('═══════════════════════════════════════');
    
    developer.log('🚀 Splash: initializing...');
    // ... rest of code
```

And at every important step, add:
```dart
print('✅ Step 1: Waiting for first frame...');
// code
print('✅ Step 2: Waiting for localization...');
// code
print('✅ Step 3: Checking language selected...');
// code
```

---

### Option 3: Android Studio Logcat (Filtered)

If using Android Studio:

1. **Open Logcat tab** (bottom of screen)
2. **Filter by package:** Enter `com.spiritual.app` (your app package)
3. **Filter by tag:** Enter `flutter`
4. **Look for lines with emoji:** 🚀 ✅ ❌ 🔄 ⚠️

**You should see:**
```
2026-06-09 20:52:55.000  12345-12345  flutter  com.spiritual.app  I  🚀 Splash: initializing...
2026-06-09 20:52:56.000  12345-12345  flutter  com.spiritual.app  I  ✅ Step 1 complete
2026-06-09 20:52:57.000  12345-12345  flutter  com.spiritual.app  I  🔄 Attempting sign-in...
```

**NOT:**
```
2026-06-09 20:52:55.000  1927-1927   Finsky   com.android.vending    W  Failed to get storage stats
```
This is Google Play Store, not your app!

---

## 🔍 Debugging Steps

### Step 1: Check Flutter Console Output

**In the terminal where you ran `flutter run`, scroll up and look for:**

```
🚀 Splash: initializing...
```

**If you see this**, keep reading to find where it stops.

**If you DON'T see this**, the logs might be disabled or hidden.

---

### Step 2: Enable Verbose Logging

**Run with verbose flag:**
```bash
flutter run --dart-define-from-file=.env.prod.json --verbose
```

This shows EVERYTHING, including:
- Network requests
- API calls
- Error stack traces
- Timing information

---

### Step 3: Look for These Specific Messages

**Search in your Flutter console for:**

#### Success Case (app loads quickly):
```
🚀 Splash: initializing...
✅ Cached user found → home
```
*Takes 1-2 seconds*

#### Timeout Case (10-second delay):
```
🚀 Splash: initializing...
🔄 Attempting lightweight Google sign-in...
[10 SECONDS OF SILENCE HERE]
⚠️ Lightweight sign-in failed
👤 No session → login screen
```
*Takes 10+ seconds*

#### Error Case (immediate failure):
```
🚀 Splash: initializing...
❌ Splash error: [error message]
👤 No session → login screen
```
*Takes 1-2 seconds but with error*

---

### Step 4: Check for Network Errors

**Look for:**
```
❌ Error: Failed to connect
❌ Error: Connection timeout
❌ Error: Network unreachable
❌ Error: SSL handshake failed
```

These indicate network/connectivity issues.

---

### Step 5: Check API Calls

**Look for:**
```
🔑 POST /api/auth/google
✅ Login success
```
or
```
❌ Login failed: [reason]
```

---

## 🎯 What to Do Based on Logs

### If You See: "🔄 Attempting lightweight Google sign-in..." (Then Silence)

**Problem:** Silent sign-in is timing out (10 seconds)

**Fix:**
```dart
// Edit lib/features/splash/splash_screen.dart line ~110
// Change timeout from 10 to 2 seconds:
.timeout(const Duration(seconds: 2), onTimeout: () => null);
```

---

### If You See: "❌ Splash error: SocketException"

**Problem:** Can't connect to server

**Check:**
1. Is production server up?
   ```bash
   curl https://app.sivakundalini.org/
   ```
2. Does emulator have internet?
   - Open Chrome in emulator
   - Try loading google.com

---

### If You See: "❌ Error: SSL handshake failed"

**Problem:** SSL certificate issue

**Fix:**
Use dev config for local testing:
```bash
flutter run --dart-define-from-file=.env.dev.json
```

---

### If You Don't See ANY App Logs

**Problem:** Logs not showing

**Fix:**
1. Add print statements (see Option 2 above)
2. Restart with `--verbose` flag
3. Check Android Studio Logcat with filter

---

## 📋 Complete Debugging Command

**Run this to get maximum information:**

```bash
flutter run --dart-define-from-file=.env.prod.json --verbose | findstr "Splash flutter ERROR"
```

This filters for:
- "Splash" - your splash screen logs
- "flutter" - Flutter framework logs
- "ERROR" - any errors

---

## 🎯 Expected Output

### Normal Startup (Working):
```
flutter: 🚀 Splash: initializing...
flutter: ✅ Cached user found → home
Application finished.
```
**Time:** 1-2 seconds

### First Launch (Working):
```
flutter: 🚀 Splash: initializing...
flutter: 📱 First launch — language selection
Application finished.
```
**Time:** 1-2 seconds

### Your Issue (Timeout):
```
flutter: 🚀 Splash: initializing...
flutter: 🔄 Attempting lightweight Google sign-in...
[10 SECONDS OF NOTHING]
flutter: ⚠️ Lightweight sign-in failed: null
flutter: 👤 No session → login screen
Application finished.
```
**Time:** 10+ seconds

---

## ✅ Quick Test

**Add this at the VERY START of `_initializeApp()` in splash_screen.dart:**

```dart
Future<void> _initializeApp() async {
  // ADD THESE LINES:
  print('');
  print('╔═══════════════════════════════════════════╗');
  print('║  SPLASH SCREEN DEBUG - STARTING NOW      ║');
  print('╔═══════════════════════════════════════════╗');
  print('');
  
  try {
    developer.log('🚀 Splash: initializing...');
    // ... rest of your code
```

**Run app again:**
```bash
flutter run --dart-define-from-file=.env.prod.json
```

**You MUST see this box in your Flutter console:**
```
╔═══════════════════════════════════════════╗
║  SPLASH SCREEN DEBUG - STARTING NOW      ║
╔═══════════════════════════════════════════╗
```

**If you DON'T see it:**
- App is not reaching splash screen
- Look for errors BEFORE this
- App might be crashing earlier

**If you DO see it:**
- Follow the logs after this
- See where it stops or waits
- That's your issue

---

## 🆘 Still Can't Find Logs?

**Screenshot your ENTIRE Flutter terminal output and share:**
1. The command you ran
2. ALL the output from start to current
3. Any errors or warnings

**The logs you're sharing (TaskPersister, Finsky, etc.) are NOT helpful** - they're Android system logs, not your app.

---

**Last Updated:** 2026-06-09 21:20 IST
