# ✅ CORS Issue Fixed - Quick Start Guide

## What Was Fixed

Your Flutter web app was trying to connect to `https://app.sivakundalini.org` (production) instead of `http://localhost:3000` (development), causing CORS errors.

### Changes Made:

1. **Mobile App Configuration** (`s:\SKS-mobile-V2\.env.json`)
   - Changed `API_BASE_URL` from `http://192.168.0.3:3012` → `http://localhost:3000`

2. **API Gateway Configuration** (`s:\Backup\api-gateway\.env`)
   - Changed `PORT` from `3012` → `3000`
   - Fixed service URLs to correct ports
   - Added comprehensive CORS origins for localhost testing

---

## 🚀 Quick Start (3 Steps)

### Option 1: Automated Startup (Recommended)

```powershell
# Run the startup script
cd s:\SKS-mobile-V2
.\start-dev-environment.ps1
```

This will:
- Start all 6 backend services
- Check health status
- Optionally start Flutter web app

### Option 2: Manual Startup

**Step 1: Start Backend Services**

Open 6 separate PowerShell terminals and run:

```powershell
# Terminal 1 - API Gateway
cd s:\Backup\api-gateway
npm start

# Terminal 2 - Mobile Backend
cd s:\Backup\sks-mobile-backend-service
npm start

# Terminal 3 - Classes Service
cd s:\Backup\sks-classes-service
npm start

# Terminal 4 - Notification Service
cd s:\Backup\sks-notification-service
npm start

# Terminal 5 - Google Login
cd s:\Backup\sks-google-login-service
npm start

# Terminal 6 - OTP Login
cd s:\Backup\sks-otp-login-service
npm start
```

**Step 2: Verify Services**

Open browser: http://localhost:3000/health

Should return:
```json
{"status":"ok","service":"api-gateway"}
```

**Step 3: Start Flutter App**

```powershell
cd s:\SKS-mobile-V2
flutter clean
flutter pub get
flutter run -d chrome --dart-define-from-file=.env.json
```

---

## ✅ Verification

### 1. Check Console Output

In Chrome DevTools Console, you should see:
```
✅ API Service initialized
Base URL: http://localhost:3000
```

**NOT**:
```
❌ Base URL: https://app.sivakundalini.org
```

### 2. Check Network Tab

All API calls should go to `http://localhost:3000`:
```
✓ GET http://localhost:3000/api/gatherings → 200 OK
✓ GET http://localhost:3000/api/events → 200 OK
✓ GET http://localhost:3000/api/quotes → 200 OK
✓ GET http://localhost:3000/api/reminders → 200 OK
```

### 3. No CORS Errors

You should NOT see:
```
❌ Access-Control-Allow-Origin error
❌ XMLHttpRequest onError callback
❌ Connection errored
```

---

## 🐛 Still Having Issues?

### Issue: Services Won't Start

**Check if ports are already in use:**
```powershell
netstat -ano | findstr "3000 3007 3008 3014 4000 4001"
```

**Kill processes if needed:**
```powershell
# Find PID from netstat output, then:
taskkill /PID <PID> /F
```

### Issue: Flutter Still Uses Production URL

**Solution:**
```powershell
cd s:\SKS-mobile-V2
flutter clean
Remove-Item -Recurse -Force .dart_tool
flutter pub get
flutter run -d chrome --dart-define-from-file=.env.json
```

### Issue: CORS Errors Persist

**Solution:**
1. Clear Chrome cache (Ctrl+Shift+Delete)
2. Restart API Gateway
3. Restart Flutter app

---

## 📝 Service Ports Reference

| Service | Port | Health Check |
|---------|------|--------------|
| API Gateway | 3000 | http://localhost:3000/health |
| Mobile Backend | 3008 | http://localhost:3008/health |
| Classes Service | 3014 | http://localhost:3014/health |
| Notification Service | 3007 | http://localhost:3007/health |
| Google Login | 4000 | http://localhost:4000/health |
| OTP Login | 4001 | http://localhost:4001/health |

---

## 📚 Additional Documentation

- **Complete Setup Guide**: See `DEVELOPMENT_SETUP.md`
- **Architecture Documentation**: See `ARCHITECTURE.md`
- **API Reference**: See `API_REFERENCE.md`
- **Service Map**: See `SERVICE_MAP.md`

---

## 🎯 Expected Behavior

After following these steps:

1. ✅ All backend services running on correct ports
2. ✅ API Gateway accessible at http://localhost:3000
3. ✅ Flutter app connects to localhost (not production)
4. ✅ No CORS errors in Chrome console
5. ✅ All API calls return 200 OK
6. ✅ App loads data successfully

---

## 🔒 Important Notes

### Development vs Production

**Development** (Current Setup):
- API URL: `http://localhost:3000`
- CORS: Allows all origins (`*`)
- All services on localhost

**Production**:
- API URL: `https://app.sivakundalini.org`
- CORS: Specific domains only
- Services on cloud infrastructure

### Switching to Production

To test against production:

1. Update `s:\SKS-mobile-V2\.env.json`:
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org"
}
```

2. Rebuild app:
```powershell
flutter clean
flutter pub get
flutter run -d chrome --dart-define-from-file=.env.json
```

---

## ✨ Success!

If you see the app loading without errors, congratulations! 🎉

Your development environment is now properly configured for web testing.

---

**Need Help?**
- Check `DEVELOPMENT_SETUP.md` for detailed troubleshooting
- Review service logs for specific errors
- Verify all environment variables are set correctly

**Last Updated**: January 2024
