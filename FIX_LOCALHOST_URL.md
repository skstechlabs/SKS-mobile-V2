# 🔧 Fix: App Still Using Production URL Instead of Localhost

## ❌ Problem

Even after updating `.env.json`, the Flutter web app is still trying to connect to `https://app.sivakundalini.org` instead of `http://localhost:3000`.

**Error in Console:**
```
uri: https://app.sivakundalini.org/api/events
DioException [connection error]: The connection errored
```

## 🎯 Root Cause

Flutter web doesn't automatically load `.env.json` file. The `--dart-define-from-file` flag doesn't work properly on web platform. Environment variables must be passed explicitly via `--dart-define` flags.

## ✅ Solution

### Option 1: Use the Automated Script (Easiest)

**Windows PowerShell:**
```powershell
cd s:\SKS-mobile-V2
.\run-web-dev.ps1
```

**Windows Command Prompt:**
```cmd
cd s:\SKS-mobile-V2
run-web-dev.bat
```

### Option 2: Manual Command

Stop your current Flutter app (Ctrl+C) and run:

```powershell
cd s:\SKS-mobile-V2

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Run with explicit environment variables
flutter run -d chrome `
    --dart-define=API_BASE_URL=http://localhost:3000 `
    --dart-define=MSG91_WIDGET_ID=366379717055333935353237 `
    --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 `
    --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com `
    --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

**For Command Prompt (use `^` instead of backtick):**
```cmd
flutter run -d chrome ^
    --dart-define=API_BASE_URL=http://localhost:3000 ^
    --dart-define=MSG91_WIDGET_ID=366379717055333935353237 ^
    --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 ^
    --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com ^
    --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

---

## ✅ Verification

### 1. Check Console Output

When the app starts, you should see in Chrome DevTools Console:

```
🔧 API Service Initializing...
📍 Base URL: http://localhost:3000
🌐 Environment API_BASE_URL: http://localhost:3000
✅ API Service initialized
```

**NOT:**
```
❌ Base URL: https://app.sivakundalini.org
```

### 2. Check Network Tab

Open Chrome DevTools → Network tab. All requests should go to:

```
✓ http://localhost:3000/api/events
✓ http://localhost:3000/api/gatherings
✓ http://localhost:3000/api/quotes
✓ http://localhost:3000/api/reminders
```

**NOT:**
```
❌ https://app.sivakundalini.org/api/events
```

### 3. No Connection Errors

You should NOT see:
```
❌ DioException [connection error]
❌ XMLHttpRequest onError
❌ Max retries reached
```

---

## 🔍 Why This Happens

### The Issue with `--dart-define-from-file`

```dart
// This works on mobile but NOT on web:
flutter run -d chrome --dart-define-from-file=.env.json  ❌

// This works on web:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000  ✅
```

### How Environment Variables Work

```dart
// In app_env.dart:
static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

// If API_BASE_URL is not passed via --dart-define, it returns empty string
// Then api_service.dart falls back to default URL
```

### The Fix Applied

Updated `api_service.dart` to default to localhost:

```dart
String baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
    ? AppEnv.apiBaseUrl 
    : 'http://localhost:3000'; // Changed from production URL
```

---

## 🚀 Complete Workflow

### Step 1: Ensure Backend is Running

```powershell
# Check if API Gateway is running
curl http://localhost:3000/health

# Should return: {"status":"ok"}
```

If not running, start it:
```powershell
cd s:\Backup\api-gateway
npm start
```

### Step 2: Stop Current Flutter App

Press `Ctrl+C` in the terminal where Flutter is running.

### Step 3: Run with Correct Command

Use one of the methods above (automated script or manual command).

### Step 4: Verify in Browser

1. Open Chrome DevTools (F12)
2. Go to Console tab
3. Look for: `📍 Base URL: http://localhost:3000`
4. Go to Network tab
5. Verify all requests go to `localhost:3000`

---

## 🐛 Troubleshooting

### Issue: Still Seeing Production URL

**Solution:**
1. Make sure you stopped the old Flutter process completely
2. Run `flutter clean`
3. Delete `.dart_tool` folder: `Remove-Item -Recurse -Force .dart_tool`
4. Run with explicit `--dart-define` flags

### Issue: "API Gateway is NOT running"

**Solution:**
```powershell
# Start API Gateway
cd s:\Backup\api-gateway
npm start

# Wait for: "Server running on port 3000"
```

### Issue: Environment Variables Not Working

**Solution:**
Don't use `--dart-define-from-file` on web. Use explicit `--dart-define` flags:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

### Issue: Port 3000 Connection Refused

**Solution:**
```powershell
# Check if API Gateway is running
netstat -ano | findstr :3000

# If nothing shows, start API Gateway
cd s:\Backup\api-gateway
npm start
```

---

## 📝 Scripts Created

### 1. `run-web-dev.ps1` (PowerShell)
- Checks if API Gateway is running
- Cleans Flutter build
- Runs with correct environment variables
- Shows helpful messages

**Usage:**
```powershell
.\run-web-dev.ps1
```

### 2. `run-web-dev.bat` (Command Prompt)
- Same functionality as PowerShell script
- Works in Command Prompt

**Usage:**
```cmd
run-web-dev.bat
```

---

## 🎯 Quick Reference

### ✅ Correct Way (Web)
```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

### ❌ Wrong Way (Doesn't work on web)
```powershell
flutter run -d chrome --dart-define-from-file=.env.json
```

### ✅ For Mobile (Android/iOS)
```powershell
flutter run --dart-define-from-file=.env.json
```

---

## 🔒 Security Note

The environment variables are hardcoded in the batch files for development convenience. For production:

1. Use proper environment variable management
2. Don't commit sensitive keys to git
3. Use different configuration for production builds

---

## ✨ Success Indicators

When everything is working:

1. ✅ Console shows: `📍 Base URL: http://localhost:3000`
2. ✅ Network tab shows requests to `localhost:3000`
3. ✅ No connection errors
4. ✅ All API calls return 200 OK
5. ✅ Data loads successfully in the app

---

## 📚 Related Files

- `run-web-dev.ps1` - PowerShell startup script
- `run-web-dev.bat` - Batch file startup script
- `.env.json` - Environment configuration (not used on web)
- `lib/core/services/api_service.dart` - Updated with localhost default
- `lib/core/constants/app_env.dart` - Environment variable definitions

---

**Last Updated**: January 2024

**Remember**: Always use the run scripts or explicit `--dart-define` flags when running Flutter web!
