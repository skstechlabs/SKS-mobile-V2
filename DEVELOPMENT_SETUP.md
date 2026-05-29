# Development Setup Guide - Web Testing with Chrome

## Issue: CORS Errors When Testing Mobile App on Chrome

When running the Flutter mobile app on Chrome for web testing, you may encounter CORS errors because the app is trying to connect to the production API instead of your local development server.

---

## ✅ Complete Fix (Step-by-Step)

### Step 1: Configure Mobile App Environment

**File**: `s:\SKS-mobile-V2\.env.json`

Update the API_BASE_URL to point to localhost:

```json
{
  "API_BASE_URL": "http://localhost:3000",
  "MSG91_WIDGET_ID": "366379717055333935353237",
  "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
  "GOOGLE_CLIENT_ID": "107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9"
}
```

### Step 2: Configure API Gateway

**File**: `s:\Backup\api-gateway\.env`

Ensure these settings:

```env
# API Gateway runs on port 3000
PORT=3000
NODE_ENV=development

# Microservices URLs (correct ports)
GOOGLE_LOGIN_SERVICE_URL=http://localhost:4000
OTP_LOGIN_SERVICE_URL=http://localhost:4001
NOTIFICATION_SERVICE_URL=http://localhost:3007
CLASSES_SERVICE_URL=http://localhost:3014
MOBILE_BACKEND_SERVICE_URL=http://localhost:3008

# CORS - Allow all origins in development
CORS_ORIGINS=*,http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000,http://127.0.0.1:8080
```

### Step 3: Verify All Services Are Running

Make sure all backend services are running on the correct ports:

```bash
# Terminal 1 - API Gateway
cd s:\Backup\api-gateway
npm start
# Should show: Server running on port 3000

# Terminal 2 - Mobile Backend Service
cd s:\Backup\sks-mobile-backend-service
npm start
# Should show: Server running on port 3008

# Terminal 3 - Classes Service
cd s:\Backup\sks-classes-service
npm start
# Should show: Server running on port 3014

# Terminal 4 - Notification Service
cd s:\Backup\sks-notification-service
npm start
# Should show: Server running on port 3007

# Terminal 5 - Google Login Service
cd s:\Backup\sks-google-login-service
npm start
# Should show: Server running on port 4000

# Terminal 6 - OTP Login Service
cd s:\Backup\sks-otp-login-service
npm start
# Should show: Server running on port 4001
```

### Step 4: Run Flutter App for Web

```bash
cd s:\SKS-mobile-V2

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Run on Chrome with environment variables
flutter run -d chrome --dart-define-from-file=.env.json
```

---

## 🔍 Verification Checklist

### 1. Check API Gateway is Running
Open browser: http://localhost:3000/health

Expected response:
```json
{
  "status": "ok",
  "service": "api-gateway",
  "timestamp": "2024-01-15T10:00:00.000Z"
}
```

### 2. Check CORS Headers
Open Chrome DevTools → Network tab → Check response headers:

Should include:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
```

### 3. Check Mobile App Console
In Chrome DevTools → Console, you should see:
```
✅ API Service initialized
✅ Base URL: http://localhost:3000
```

NOT:
```
❌ Base URL: https://app.sivakundalini.org
```

---

## 🐛 Troubleshooting

### Issue 1: Still Getting CORS Errors

**Solution**: Clear browser cache and restart

```bash
# Stop Flutter app (Ctrl+C)
# Clear Chrome cache: Ctrl+Shift+Delete → Clear all
# Restart Flutter app
flutter run -d chrome --dart-define-from-file=.env.json
```

### Issue 2: Connection Refused

**Symptom**: `ERR_CONNECTION_REFUSED`

**Solution**: Verify API Gateway is running on port 3000

```bash
# Check if port 3000 is in use
netstat -ano | findstr :3000

# If nothing shows, API Gateway is not running
# Start it:
cd s:\Backup\api-gateway
npm start
```

### Issue 3: 404 Not Found

**Symptom**: API returns 404 for all endpoints

**Solution**: Check service URLs in API Gateway .env

```bash
# Verify these are correct:
MOBILE_BACKEND_SERVICE_URL=http://localhost:3008
CLASSES_SERVICE_URL=http://localhost:3014
NOTIFICATION_SERVICE_URL=http://localhost:3007
```

### Issue 4: Unauthorized (401)

**Symptom**: All API calls return 401

**Solution**: Check Firebase authentication

1. Make sure you're logged in
2. Check Firebase ID token is being sent
3. Verify Firebase Admin SDK is configured in backend services

### Issue 5: Wrong Base URL Still Being Used

**Symptom**: App still tries to connect to `https://app.sivakundalini.org`

**Solution**: 

1. Stop the app
2. Run `flutter clean`
3. Delete `.dart_tool` folder
4. Run `flutter pub get`
5. Run with explicit env file:
```bash
flutter run -d chrome --dart-define-from-file=.env.json
```

---

## 📝 Quick Reference: Service Ports

| Service | Port | URL |
|---------|------|-----|
| API Gateway | 3000 | http://localhost:3000 |
| Mobile Backend | 3008 | http://localhost:3008 |
| Notification Service | 3007 | http://localhost:3007 |
| Classes Service | 3014 | http://localhost:3014 |
| Google Login | 4000 | http://localhost:4000 |
| OTP Login | 4001 | http://localhost:4001 |

---

## 🚀 One-Command Startup (PowerShell)

Create a file `start-all-services.ps1`:

```powershell
# Start all services in separate windows

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\api-gateway; npm start"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-mobile-backend-service; npm start"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-classes-service; npm start"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-notification-service; npm start"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-google-login-service; npm start"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-otp-login-service; npm start"

Write-Host "All services started! Wait 10 seconds for initialization..."
Start-Sleep -Seconds 10

Write-Host "Starting Flutter app..."
cd s:\SKS-mobile-V2
flutter run -d chrome --dart-define-from-file=.env.json
```

Run it:
```powershell
.\start-all-services.ps1
```

---

## 🔒 Security Note

**IMPORTANT**: The `CORS_ORIGINS=*` setting allows ALL origins. This is ONLY for development!

For production, use specific domains:
```env
CORS_ORIGINS=https://app.sivakundalini.org,https://www.sivakundalini.org
```

---

## ✅ Success Indicators

When everything is working correctly, you should see:

1. **Chrome Console**:
   ```
   ✅ Firebase initialized successfully
   ✅ API Service initialized
   ✅ Base URL: http://localhost:3000
   ```

2. **Network Tab** (no errors):
   ```
   GET http://localhost:3000/api/gatherings → 200 OK
   GET http://localhost:3000/api/events → 200 OK
   GET http://localhost:3000/api/quotes → 200 OK
   GET http://localhost:3000/api/reminders → 200 OK
   ```

3. **No CORS Errors**:
   - No "Access-Control-Allow-Origin" errors
   - No "XMLHttpRequest onError" errors
   - No connection refused errors

---

## 📞 Still Having Issues?

1. Check all services are running: `netstat -ano | findstr "3000 3007 3008 3014 4000 4001"`
2. Check API Gateway logs for errors
3. Check Chrome DevTools → Network tab for failed requests
4. Verify `.env.json` is being loaded: Add `debugPrint(AppEnv.apiBaseUrl);` in `api_service.dart`

---

**Last Updated**: January 2024
