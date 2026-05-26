# Mobile App Testing Guide - Fix 502 Errors

## ❌ Problem: 502 Bad Gateway Errors

You were getting these errors because the mobile app was configured to use the **production URL** (`https://app.sivakundalini.org`) which is not accessible/running.

```
502 Bad Gateway errors on:
- https://app.sivakundalini.org/api/reminders
- https://app.sivakundalini.org/api/level-progression/access
- https://app.sivakundalini.org/api/auth/login/google
```

## ✅ Solution: Use Local Development Configuration

For local testing, you MUST use `.env.local.json` which points to your local API Gateway.

### Step 1: Use the Correct Environment File

**❌ WRONG (Production - causes 502 errors):**
```powershell
flutter run --dart-define-from-file=.env.classes-service.json
```

**✅ CORRECT (Local Development):**
```powershell
flutter run --dart-define-from-file=.env.local.json
```

### Step 2: Understand the URL Differences

**For Android Emulator:**
- `localhost` doesn't work (refers to emulator itself)
- Use `10.0.2.2` instead (special IP that refers to host machine)

**For Physical Device:**
- Use your computer's IP address (e.g., `192.168.1.100:3012`)
- Make sure device and computer are on same WiFi network

### Step 3: Configuration Files

**`.env.local.json` (Local Development) - UPDATED:**
```json
{
  "API_BASE_URL": "http://10.0.2.2:3012"
}
```

**`.env.classes-service.json` (Production):**
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org"
}
```

## 🔧 What Was Fixed

### 1. Updated `.env.local.json`
Changed from `http://localhost:3012` to `http://10.0.2.2:3012` for Android emulator compatibility.

### 2. Improved CORS Configuration in API Gateway
Added proper handling for:
- ✅ Preflight OPTIONS requests
- ✅ Multiple allowed origins
- ✅ Mobile app requests (no origin header)
- ✅ Proper CORS headers

### 3. Restarted API Gateway
Applied the new CORS configuration.

## 📱 How to Run the App Correctly

### For Android Emulator

```powershell
# Navigate to project
cd s:\SKS-mobile-V2

# Run with local configuration
flutter run --dart-define-from-file=.env.local.json
```

The app will connect to: `http://10.0.2.2:3012` (your local API Gateway)

### For Physical Android Device

1. **Find your computer's IP address:**
   ```powershell
   ipconfig
   # Look for "IPv4 Address" under your WiFi adapter
   # Example: 192.168.1.100
   ```

2. **Create `.env.device.json`:**
   ```json
   {
     "MSG91_WIDGET_ID": "366379717055333935353237",
     "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
     "API_BASE_URL": "http://192.168.1.100:3012",
     "FIREBASE_API_KEY": "AIzaSyBXUN42KBq3eGoMgib4ZWDbYYFFc0Ft458",
     "FIREBASE_AUTH_DOMAIN": "sks-login-mobile.firebaseapp.com",
     "FIREBASE_PROJECT_ID": "sks-login-mobile",
     "FIREBASE_STORAGE_BUCKET": "sks-login-mobile.firebasestorage.app",
     "FIREBASE_MESSAGING_SENDER_ID": "294856785598",
     "FIREBASE_WEB_APP_ID": "1:294856785598:web:placeholder",
     "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9",
     "GOOGLE_CLIENT_ID": "294856785598-qivhqf2ehn5p0rs1830dt9mt030ort9p.apps.googleusercontent.com"
   }
   ```

3. **Run the app:**
   ```powershell
   flutter run --dart-define-from-file=.env.device.json
   ```

## 🧪 Test the Configuration

### 1. Verify Backend Services are Running

```powershell
pm2 list
```

Should show all services as "online":
- ✅ api-gateway (Port 3012)
- ✅ google-login-service (Port 3010)
- ✅ classes-service (Port 3014)
- ✅ mobile-backend-service (Port 3015)
- ✅ notification-service (Port 3016)
- ✅ otp-login-service (Port 3011)

### 2. Test API Gateway from Computer

```powershell
curl http://localhost:3012/health
```

Should return 200 OK.

### 3. Test from Android Emulator Perspective

```powershell
curl http://10.0.2.2:3012/health
```

Should return 200 OK.

## 🐛 Troubleshooting

### Still Getting 502 Errors?

**Check 1: Are you using the correct environment file?**
```powershell
# ❌ WRONG
flutter run --dart-define-from-file=.env.classes-service.json

# ✅ CORRECT
flutter run --dart-define-from-file=.env.local.json
```

**Check 2: Is API Gateway running?**
```powershell
pm2 list
curl http://localhost:3012/health
```

**Check 3: Can emulator reach host?**
```powershell
# From your computer
curl http://10.0.2.2:3012/health
```

### Google Login Not Working?

**Check 1: Firebase token is valid**
- Make sure you're signed in with Google in the app
- Check Firebase console for authentication status

**Check 2: Google Login Service is running**
```powershell
pm2 logs google-login-service --lines 20
curl http://localhost:3010/health
```

**Check 3: API Gateway can reach Google Login Service**
```powershell
curl http://localhost:3012/health
# Check the "googleLogin" service status in response
```

### CORS Errors?

**Check 1: API Gateway CORS configuration**
```powershell
pm2 logs api-gateway --lines 20
```

**Check 2: Restart API Gateway**
```powershell
pm2 restart api-gateway --update-env
```

## 📊 Expected Behavior

### Successful Google Login Flow

1. **User taps "Sign in with Google"**
2. **Firebase authentication** (handled by Firebase SDK)
3. **App gets Firebase ID token**
4. **App sends request to:**
   ```
   POST http://10.0.2.2:3012/api/auth/login/google
   Headers: Authorization: Bearer <firebase_token>
   Body: { mobile, email, name }
   ```
5. **API Gateway forwards to Google Login Service**
6. **Google Login Service verifies token and creates/updates user**
7. **Response sent back to app**
8. **User is logged in!**

### What You Should See in Logs

**API Gateway logs:**
```
Proxying POST /api/auth/login/google to Google Login Service
Received response from Google Login Service: 200
```

**Google Login Service logs:**
```
Request started: POST /api/auth/login/google
Firebase token verified successfully
User created/updated
Request completed: 200
```

## ✅ Quick Start Checklist

- [ ] All PM2 services running (`pm2 list`)
- [ ] API Gateway responding (`curl http://localhost:3012/health`)
- [ ] Using `.env.local.json` for local testing
- [ ] API_BASE_URL is `http://10.0.2.2:3012` (for emulator)
- [ ] Run app: `flutter run --dart-define-from-file=.env.local.json`
- [ ] Test Google Sign-In in app
- [ ] Check logs if issues: `pm2 logs api-gateway google-login-service`

## 🎯 Summary

**The Problem:**
- ❌ App was using production URL (`https://app.sivakundalini.org`)
- ❌ Production server not accessible (502 errors)
- ❌ CORS not configured for OPTIONS requests

**The Solution:**
- ✅ Use `.env.local.json` for local testing
- ✅ Use `http://10.0.2.2:3012` for Android emulator
- ✅ Fixed CORS configuration in API Gateway
- ✅ All services running on correct ports

**Now Run:**
```powershell
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.local.json
```

**Google login should now work!** 🎉
