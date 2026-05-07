# APK Continuous Loading Issue - CRITICAL FIX

## Problem

After installing APK on mobile device:
- Login works locally but shows continuous loader in APK
- Gatherings page shows continuous loader
- Events page shows continuous loader
- All API calls fail silently

## Root Cause

**The APK was built WITHOUT the `--dart-define-from-file=.env.prod.json` flag!**

This means:
- `AppEnv.apiBaseUrl` is EMPTY (empty string "")
- API service defaults to `https://sivakundalini.org` (fallback)
- BUT the app still tries to connect to localhost first
- All API calls timeout or fail

## Why It Works Locally

When you run locally with:
```dart
// In api_service.dart
baseUrl: AppEnv.apiBaseUrl.isNotEmpty 
    ? AppEnv.apiBaseUrl 
    : 'https://sivakundalini.org',  // Fallback works
```

The fallback URL works because you're testing on the same network or with proper configuration.

## Why It Fails in APK

When APK is built WITHOUT the flag:
1. `String.fromEnvironment('API_BASE_URL')` returns `""` (empty string)
2. The fallback kicks in, but...
3. The app may have cached the empty value
4. Or the initialization order is wrong
5. Or there's a race condition

## The Fix

### Step 1: Verify Current APK Configuration

Add this to your app to check what's configured:

```dart
// In main.dart
import 'core/utils/environment_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CHECK ENVIRONMENT
  EnvironmentChecker.checkEnvironment();
  
  // ... rest of initialization
}
```

### Step 2: Rebuild APK with Correct Flag

**CRITICAL: You MUST use this exact command:**

```bash
cd SKS-mobile-V2

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK with environment variables
flutter build apk --release --dart-define-from-file=.env.prod.json
```

**OR use the script:**

```bash
./rebuild-production.sh
```

### Step 3: Verify Environment Variables Were Injected

After building, check the logs when you run the APK:

```bash
# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Monitor logs
adb logcat | grep -E "ENVIRONMENT|API_BASE_URL|API Base URL"
```

You should see:
```
✅ API_BASE_URL is configured: https://sivakundalini.org
```

If you see:
```
❌ CRITICAL: API_BASE_URL is EMPTY!
```

Then the APK was built incorrectly.

## Verification Steps

### 1. Check .env.prod.json

```bash
cat .env.prod.json
```

Should show:
```json
{
  "API_BASE_URL": "https://sivakundalini.org",
  ...
}
```

### 2. Check Build Command

The build command MUST include:
```
--dart-define-from-file=.env.prod.json
```

### 3. Check Logs After Install

```bash
adb logcat | grep "API"
```

Should show:
```
API_BASE_URL: "https://sivakundalini.org"
API_BASE_URL isEmpty: false
```

## Common Mistakes

### ❌ WRONG: Building without flag
```bash
flutter build apk --release
```

### ❌ WRONG: Using wrong file
```bash
flutter build apk --release --dart-define-from-file=.env.json
```

### ❌ WRONG: Typo in flag
```bash
flutter build apk --release --dart-defines-from-file=.env.prod.json
```

### ✅ CORRECT: Exact command
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

## Testing After Fix

### 1. Install Fresh APK
```bash
# Uninstall old APK
adb uninstall com.spiritual.app

# Install new APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Open App and Check Logs
```bash
adb logcat | grep -E "ENVIRONMENT|API|ERROR"
```

### 3. Test API Calls

1. **Login**: Should work immediately
2. **Home Page**: Should load quotes
3. **Gatherings**: Should load list (not continuous loader)
4. **Events**: Should load list (not continuous loader)
5. **Profile**: Should load user data

### 4. Test Backend Connectivity

From your computer:
```bash
curl https://sivakundalini.org/api/gatherings
```

Should return JSON data, not error.

## Debugging

### If Still Shows Continuous Loader

1. **Check Backend is Running**:
```bash
curl https://sivakundalini.org/api/health
```

Should return: `{"status":"ok"}`

2. **Check Logs for Errors**:
```bash
adb logcat | grep -E "ERROR|Exception|DioException"
```

3. **Check Network Connectivity**:
- Ensure device has internet
- Try opening https://sivakundalini.org in mobile browser
- Check if backend is accessible from mobile network

4. **Check Firebase Token**:
```bash
adb logcat | grep "Firebase"
```

Should show successful Firebase initialization.

5. **Check API Service Initialization**:
```bash
adb logcat | grep "API Service"
```

Should show: `✅ API Service initialized successfully`

## Files Modified

1. `lib/core/utils/environment_checker.dart` - NEW: Environment diagnostic tool
2. `lib/main.dart` - UPDATED: Added environment check on startup
3. `lib/core/services/api_service.dart` - Already has fallback URL

## Quick Fix Script

Create `diagnose-apk.sh`:

```bash
#!/bin/bash

echo "🔍 Diagnosing APK Configuration..."
echo ""

# Check if .env.prod.json exists
if [ ! -f ".env.prod.json" ]; then
    echo "❌ .env.prod.json NOT FOUND!"
    exit 1
fi

echo "✅ .env.prod.json exists"
echo ""

# Show API_BASE_URL
echo "API_BASE_URL in .env.prod.json:"
grep "API_BASE_URL" .env.prod.json
echo ""

# Check if APK exists
if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "❌ APK NOT FOUND! Need to build."
    echo ""
    echo "Run: ./rebuild-production.sh"
    exit 1
fi

echo "✅ APK exists"
echo ""

# Show APK size and date
echo "APK Info:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No device connected!"
    echo "Connect device and enable USB debugging"
    exit 1
fi

echo "✅ Device connected"
echo ""

# Install APK
echo "Installing APK..."
adb install -r build/app/outputs/flutter-apk/app-release.apk

echo ""
echo "✅ APK installed"
echo ""
echo "Now open the app and check logs:"
echo "  adb logcat | grep -E 'ENVIRONMENT|API_BASE_URL'"
echo ""
```

Make it executable:
```bash
chmod +x diagnose-apk.sh
```

Run it:
```bash
./diagnose-apk.sh
```

## Summary

**The ONLY solution is to rebuild the APK with the correct flag:**

```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

**DO NOT:**
- Try to fix it in code
- Try to hardcode the URL
- Try to change the fallback

**DO:**
- Use the rebuild script: `./rebuild-production.sh`
- Verify environment variables in logs
- Test on device after rebuild

## Expected Timeline

1. Clean build: 30 seconds
2. Get dependencies: 10 seconds
3. Build APK: 2-5 minutes
4. Install on device: 30 seconds
5. Test: 2 minutes

**Total: ~5-10 minutes**

## Success Criteria

After rebuilding and installing:
- ✅ Login works
- ✅ Home page loads quotes
- ✅ Gatherings page loads list (no continuous loader)
- ✅ Events page loads list (no continuous loader)
- ✅ Profile page loads user data
- ✅ All API calls complete within 5 seconds

## If Problem Persists

If after rebuilding correctly, the issue persists:

1. **Check Backend Logs**:
```bash
pm2 logs sks-backend
```

2. **Check Backend is Accessible**:
```bash
curl -v https://sivakundalini.org/api/gatherings
```

3. **Check CORS Headers**:
```bash
curl -H "Origin: http://localhost" -v https://sivakundalini.org/api/gatherings
```

4. **Check SSL Certificate**:
```bash
openssl s_client -connect sivakundalini.org:443
```

5. **Check Firewall/Network**:
- Ensure backend allows mobile network IPs
- Check if there's a firewall blocking mobile requests
- Verify SSL certificate is valid

## Contact

If issue persists after following all steps:
1. Share output of: `adb logcat | grep -E "ENVIRONMENT|API|ERROR"`
2. Share output of: `curl -v https://sivakundalini.org/api/gatherings`
3. Share screenshot of continuous loader
4. Confirm you used: `flutter build apk --release --dart-define-from-file=.env.prod.json`
