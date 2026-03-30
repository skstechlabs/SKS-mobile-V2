# Why Continuous Loading? The Real Answer

## TL;DR

**You built the APK without the `--dart-define-from-file` flag!**

Without this flag, the app doesn't know the API URL and defaults to `localhost:3012`, which doesn't exist on mobile devices.

---

## The Technical Explanation

### How Environment Variables Work in Flutter

```dart
// In app_env.dart
static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
```

This reads from **compile-time** constants, NOT runtime files!

### Build Command Comparison

#### ❌ WRONG (What You Did):
```bash
flutter build apk --release
```

**Result:**
- `AppEnv.apiBaseUrl` = `""` (empty string)
- App defaults to: `http://localhost:3012`
- Mobile device has no localhost:3012
- All API calls timeout after 30 seconds
- **Continuous loading!**

#### ✅ CORRECT (What You Need):
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

**Result:**
- `AppEnv.apiBaseUrl` = `"https://sivakundalini.org"`
- App connects to: `https://sivakundalini.org`
- API calls succeed
- **App works!**

---

## Why It Worked Before

You probably used the correct command before:
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

But the most recent build was done without the flag, so the environment variables weren't injected.

---

## The Code That Proves It

**File:** `lib/core/services/api_service.dart`

```dart
void initialize() {
  _dio = Dio(BaseOptions(
    baseUrl: AppEnv.apiBaseUrl.isNotEmpty 
        ? AppEnv.apiBaseUrl           // ← Uses this if flag was used
        : 'http://localhost:3012',    // ← Defaults to this if flag missing!
    // ...
  ));
}
```

**File:** `lib/core/constants/app_env.dart`

```dart
class AppEnv {
  // This is EMPTY if --dart-define-from-file wasn't used!
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
```

---

## How to Verify

### After building correctly, check logs:

```bash
# Open app on device
adb logcat | grep "API"
```

**If built correctly:**
```
✅ API Service initialized successfully
🌐 Connecting to: https://sivakundalini.org
```

**If built incorrectly:**
```
✅ API Service initialized successfully
🌐 Connecting to: http://localhost:3012
❌ Connection failed: Connection refused
```

---

## The Fix (Right Now)

```bash
cd SKS-mobile-V2

# Use the script (easiest)
./rebuild-production.sh

# Or manual command
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.prod.json
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Why This Design?

Flutter uses compile-time constants for security and performance:

1. **Security**: API keys baked into binary, not readable in plain text
2. **Performance**: No runtime file reading
3. **Flexibility**: Different configs for dev/staging/prod

But it requires the correct build command!

---

## Prevention

### Always Use One of These:

**Option 1: Script (Recommended)**
```bash
./rebuild-production.sh
```

**Option 2: Full Command**
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

### Never Use Just:
```bash
flutter build apk --release  # ❌ MISSING ENV VARS!
```

---

## Summary

| Build Command | API URL | Result |
|--------------|---------|--------|
| `flutter build apk --release` | `localhost:3012` | ❌ Continuous loading |
| `flutter build apk --release --dart-define-from-file=.env.prod.json` | `https://sivakundalini.org` | ✅ Works! |

**The backend is fine. The config is fine. You just need to rebuild with the correct command!**

---

## Quick Fix

```bash
cd SKS-mobile-V2
./rebuild-production.sh
```

That's it! 🎯
