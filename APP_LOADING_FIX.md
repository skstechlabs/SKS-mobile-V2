# Fix: App Continuous Loading on Startup
**Date**: 2026-06-09 21:05 IST  
**Issue**: App shows continuous loader when running with production config

---

## 🎯 Root Cause

The app's splash screen does several checks on startup:

1. **Language selection check** (fast)
2. **Cached user check** (fast)
3. **Firebase Auth check** (fast)
4. **Silent Google Sign-In** ← **THIS IS WHERE IT HANGS** (10-second timeout)
5. **Backend login API call** (depends on step 4)

When running locally with `--dart-define-from-file=.env.prod.json`, the **silent Google sign-in** is likely timing out or failing, causing the 10-second delay before it falls back to the login screen.

---

## 🔍 What to Check

### Step 1: See the REAL Flutter Logs

The logs you showed are **Android system logs** (Netlink, Wallet, etc.) - not your app logs!

**Filter for YOUR app logs:**

When running `flutter run`, look for lines starting with:
```
🚀 Splash: initializing...
📱 First launch — language selection
✅ Cached user found → home
⚠️ Firebase not ready
🔄 Attempting lightweight Google sign-in...
❌ Silent login error
```

These are the logs from `splash_screen.dart` that tell you **exactly** where it's stuck.

### Step 2: Check What's Happening

In your terminal running `flutter run`, you should see:

**If working normally:**
```
🚀 Splash: initializing...
✅ Cached user found → home
```
*Goes to home in 1-2 seconds* ✅

**If stuck (your issue):**
```
🚀 Splash: initializing...
🔄 Attempting lightweight Google sign-in...
[10 SECONDS OF SILENCE]
⚠️ Lightweight sign-in failed: timeout
👤 No session → login screen
```
*Takes 10+ seconds to show login screen* ❌

---

## ✅ Solutions

### Solution 1: Clear App Data & Cache (Quick Fix)

The app might have cached Firebase session that's now invalid.

**In Android Emulator:**
1. Long-press the app icon
2. Tap **App info**
3. Tap **Storage & cache**
4. Tap **Clear storage** and **Clear cache**
5. Run the app again:
   ```bash
   flutter run --dart-define-from-file=.env.prod.json
   ```

Should go straight to login screen now ✅

---

### Solution 2: Force Clean Start (More Thorough)

**Uninstall and reinstall:**

```bash
# Uninstall from emulator
flutter clean

# Rebuild and run
flutter run --dart-define-from-file=.env.prod.json
```

---

### Solution 3: Skip Silent Sign-In (Temporary)

If you want to test other features without the sign-in delay, you can temporarily disable silent sign-in.

**Edit `lib/features/splash/splash_screen.dart`:**

Find this section (around line 109):
```dart
if (firebaseUser == null) {
  // No Firebase session — try lightweight Google sign-in
  if (!kIsWeb) {
    try {
      developer.log('🔄 Attempting lightweight Google sign-in...');
      firebaseUser = await AuthService()
          .attemptSilentSignIn()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
```

**Comment it out:**
```dart
if (firebaseUser == null) {
  // TEMPORARY: Skip silent sign-in for testing
  // if (!kIsWeb) {
  //   try {
  //     developer.log('🔄 Attempting lightweight Google sign-in...');
  //     firebaseUser = await AuthService()
  //         .attemptSilentSignIn()
  //         .timeout(const Duration(seconds: 10), onTimeout: () => null);
  //     if (firebaseUser != null) {
  //       developer.log('✅ Lightweight sign-in restored: ${firebaseUser.email}');
  //     }
  //   } catch (e) {
  //     developer.log('⚠️ Lightweight sign-in failed: $e');
  //   }
  // }
}
```

**Hot restart:**
```bash
# In flutter run terminal, press 'R'
R
```

Now it will skip the 10-second timeout and go straight to login ✅

---

### Solution 4: Reduce Timeout (Faster Fallback)

Instead of waiting 10 seconds, make it timeout faster:

**Edit `lib/features/splash/splash_screen.dart` (line ~110):**

Change:
```dart
.timeout(const Duration(seconds: 10), onTimeout: () => null);
```

To:
```dart
.timeout(const Duration(seconds: 2), onTimeout: () => null);
```

Now it will only wait 2 seconds before showing login screen.

---

## 🎯 Understanding the Flow

### Normal Flow (Working)
```
App Start
    ↓
Splash Screen
    ↓
Check Language Selected? → YES
    ↓
Check Cached User? → YES ✅
    ↓
→ HOME SCREEN (1 second)
```

### Your Flow (Stuck)
```
App Start
    ↓
Splash Screen
    ↓
Check Language Selected? → YES
    ↓
Check Cached User? → NO
    ↓
Check Firebase User? → NO
    ↓
Try Silent Google Sign-In → TIMEOUT ⏳ (10 seconds)
    ↓
→ LOGIN SCREEN (after 10 seconds)
```

---

## 🧪 Testing

### Test 1: Check Flutter Logs

When you run the app, watch the **console output** in your terminal.

**Look for these specific log messages:**

```bash
flutter run --dart-define-from-file=.env.prod.json
```

**Expected logs:**
```
🚀 Splash: initializing...
📱 First launch — language selection
   OR
✅ Cached user found → home
   OR
👤 No session → login screen
```

**If you see:**
```
🔄 Attempting lightweight Google sign-in...
[LONG PAUSE]
⚠️ Lightweight sign-in failed: timeout
```

This confirms the issue is the silent sign-in timeout.

---

### Test 2: Time the Loading

**Open stopwatch:**
1. Start timer when app launches
2. Stop when you see login screen or home screen

**If it takes:**
- **1-2 seconds** → Working normally ✅
- **10+ seconds** → Silent sign-in is timing out ❌

---

### Test 3: Try After Clearing Data

**After clearing app data:**
```bash
# Should see this log:
📱 First launch — language selection
```

App should show language selection screen **immediately** (1 second).

**After selecting language:**
```bash
# Should see this log:
👤 No session → login screen
```

App should show login screen **immediately** (1 second).

---

## 📝 Why This Happens

### Scenario 1: Cached Firebase Session (Most Likely)
- You previously logged in with Google
- Firebase cached the session
- Session is now expired/invalid
- App tries to restore it silently
- Times out after 10 seconds
- Then shows login screen

**Fix:** Clear app data

---

### Scenario 2: Google Play Services Issue
- Silent sign-in requires Google Play Services
- If not available or not responding
- Times out after 10 seconds

**Fix:** Ensure emulator has Google Play Services

---

### Scenario 3: Network Issue
- Silent sign-in makes network calls
- If network is slow or firewalled
- Times out after 10 seconds

**Fix:** Check emulator has internet access

---

## ✅ Recommended Fix

**Do this:**

1. **Clear app data** (Solution 1)
2. **Run app again**
3. **Should go straight to login screen** (1-2 seconds)
4. **Login normally**
5. **Test features**

**If still stuck:**

1. **Reduce timeout** to 2 seconds (Solution 4)
2. **Hot restart** (press 'R' in flutter terminal)
3. **Should show login after 2 seconds instead of 10**

---

## 🎯 Quick Commands

**See full Flutter logs:**
```bash
# Add verbose flag
flutter run --dart-define-from-file=.env.prod.json --verbose
```

**Filter for your app logs only:**
```bash
# In Android Studio Logcat, filter by:
tag:flutter
```

**Hot restart after code changes:**
```
# In flutter run terminal, press:
R
```

**Stop and rebuild:**
```
# Press:
q

# Then run again:
flutter run --dart-define-from-file=.env.prod.json
```

---

## 📊 Expected Timeline

**With fixes:**
- Clear app data: **1 minute**
- Run app: **1-2 seconds to login screen** ✅
- Login: **3-5 seconds**
- Total: **2-3 minutes**

**Without fixes:**
- Run app: **10+ seconds to login screen** ❌
- Very frustrating for testing

---

## 🆘 Still Having Issues?

### Check These:

1. **Are you seeing Flutter logs?**
   - Look for `🚀`, `✅`, `❌` emoji in console
   - If not visible, add `--verbose` flag

2. **What's the last log message?**
   - If it shows `🔄 Attempting lightweight Google sign-in...` and stops
   - That's where it's stuck

3. **Does emulator have Google Play?**
   - Open **Play Store** in emulator
   - If it works, Google Play Services is available ✅
   - If error, use an emulator with Google Play

4. **Is production server accessible?**
   ```bash
   curl https://app.sivakundalini.org/
   ```
   Should return JSON response

---

## 💡 Pro Tips

**For faster local testing:**
```bash
# Use dev config instead
flutter run --dart-define-from-file=.env.dev.json
```
- Connects to local backend
- No network delays
- Faster iteration

**For production testing:**
```bash
# Only test production when you need to verify:
# - Real server behavior
# - SSL certificates
# - Production data
flutter run --dart-define-from-file=.env.prod.json
```

**For release builds:**
```bash
flutter build apk --dart-define-from-file=.env.prod.json
```

---

**Last Updated:** 2026-06-09 21:10 IST  
**Time to Fix:** 2-5 minutes  
**Recommended:** Clear app data + reduce timeout
