# Fix: App Stuck on Loader When Running Locally
**Date**: 2026-06-09  
**Issue**: Continuous loader, network errors `10.0.2.2`

---

## 🎯 Problem

When running:
```bash
flutter run --dart-define-from-file=.env.prod.json
```

The app shows continuous loader and errors:
```
Error probing ip=10.0.2.2%16: ENOENT (No such file or directory)
```

**Root Cause:** You're using **production config** (`.env.prod.json`) which tries to connect to `https://app.sivakundalini.org`, but for local testing you should use **development config** (`.env.dev.json`) which connects to `http://localhost:3000`.

---

## ✅ Solution

### Option 1: Use Development Config (Recommended for Local Testing)

**Run this instead:**
```bash
flutter run --dart-define-from-file=.env.dev.json
```

This will:
- Connect to `http://localhost:3000` (your local API Gateway)
- Use Android emulator's special IP `10.0.2.2` to reach your Windows host
- Work with your local backend services

---

### Option 2: Fix Development Config for Android Emulator

The dev config has `http://localhost:3000` which doesn't work in Android emulator. You need `10.0.2.2`.

**Update `.env.dev.json`:**

```json
{
  "API_BASE_URL": "http://10.0.2.2:3000",
  "MSG91_WIDGET_ID": "366379717055333935353237",
  "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
  "GOOGLE_CLIENT_ID": "107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9"
}
```

**Change:** `http://localhost:3000` → `http://10.0.2.2:3000`

Then run:
```bash
flutter run --dart-define-from-file=.env.dev.json
```

---

### Option 3: Test Production Config with Real Server

If you want to test with production config, you need to ensure:

1. **Production server is accessible:**
   ```bash
   curl https://app.sivakundalini.org/api/health
   ```
   Should return server status.

2. **No SSL certificate issues:**
   Production server must have valid SSL certificate.

3. **Internet connection available:**
   Emulator must have internet access.

---

## 🔍 Understanding the Configs

### Development Config (`.env.dev.json`)
```json
{
  "API_BASE_URL": "http://10.0.2.2:3000"  ← Local backend
}
```
**Use for:**
- Local testing during development
- Testing backend changes before deploying
- Debugging API issues

**Connects to:**
- Your Windows PC's local services
- API Gateway on port 3000
- All backend services (3013, 3010, etc.)

---

### Production Config (`.env.prod.json`)
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org"  ← Live server
}
```
**Use for:**
- Testing production environment
- Building release APK
- Publishing to Play Store

**Connects to:**
- Production server over internet
- Requires valid SSL certificate
- Requires internet connection

---

## 🧪 Testing Local Backend

### Step 1: Verify Local Services Running

```powershell
pm2 status
```

**Should show:**
```
┌─────┬──────────────────────────────┬─────────┬─────────┐
│ id  │ name                         │ status  │ port    │
├─────┼──────────────────────────────┼─────────┼─────────┤
│ 0   │ api-gateway                  │ online  │ 3000    │
│ 1   │ sks-mobile-backend-service   │ online  │ 3013    │
│ 2   │ google-login-service         │ online  │ 3010    │
│ 3   │ sks-otp-login-service        │ online  │ 4001    │
│ ...  │ ...                          │ ...     │ ...     │
└─────┴──────────────────────────────┴─────────┴─────────┘
```

All services should be **online** ✅

### Step 2: Test API Gateway from Windows

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/health"
```

**Expected output:**
```json
{
  "status": "ok",
  "timestamp": "2026-06-09T..."
}
```

### Step 3: Update Dev Config

Edit `s:\SKS-mobile-V2\.env.dev.json`:
```json
{
  "API_BASE_URL": "http://10.0.2.2:3000"
}
```

### Step 4: Run App with Dev Config

```bash
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.dev.json
```

### Step 5: Check App Logs

**Should see successful API calls:**
```
✅ GET /api/audios → 200
✅ GET /api/quotes → 200
✅ GET /api/classes → 200
```

**NOT:**
```
❌ Connection timeout
❌ ENOENT (No such file or directory)
```

---

## 🚨 Common Issues

### Issue 1: API Gateway Not Running

**Error:**
```
Connection refused to 10.0.2.2:3000
```

**Fix:**
```powershell
pm2 restart api-gateway
pm2 logs api-gateway --lines 20
```

Ensure API Gateway is **online** on port **3000**.

---

### Issue 2: Firewall Blocking Connection

**Error:**
```
Connection timeout
```

**Fix:**
1. Open **Windows Defender Firewall**
2. Go to **Advanced Settings**
3. **Inbound Rules** → **New Rule**
4. Allow **Port 3000** for Node.js
5. Restart services

---

### Issue 3: Wrong IP in Dev Config

**Error:**
```
Connection refused to localhost:3000
```

**Fix:**
For **Android Emulator**, must use `10.0.2.2` not `localhost`.

```json
"API_BASE_URL": "http://10.0.2.2:3000"  ← Correct
"API_BASE_URL": "http://localhost:3000"  ← Wrong for emulator
```

---

### Issue 4: Services Running on Wrong Ports

**Check ports:**
```powershell
netstat -ano | findstr "3000"
netstat -ano | findstr "3013"
```

**Expected:**
```
TCP    0.0.0.0:3000    LISTENING    12345
TCP    0.0.0.0:3013    LISTENING    67890
```

If ports are different, update service configs.

---

## 📋 Quick Decision Guide

**Local development/testing:**
```bash
flutter run --dart-define-from-file=.env.dev.json
```
✅ Fast, easy debugging  
✅ No internet required  
✅ Test backend changes immediately  

**Testing production environment:**
```bash
flutter run --dart-define-from-file=.env.prod.json
```
✅ Test real server  
✅ Verify SSL works  
⚠️ Requires internet  

**Building for release:**
```bash
flutter build apk --dart-define-from-file=.env.prod.json
```
✅ Production-ready APK  
✅ Uses live server  

---

## ✅ Summary

**Your Issue:** Using production config for local testing.

**Quick Fix:**
```bash
# 1. Update dev config
# Change API_BASE_URL to: http://10.0.2.2:3000

# 2. Run with dev config
flutter run --dart-define-from-file=.env.dev.json
```

**Expected Result:**
- App loads successfully ✅
- No continuous loader ✅
- API calls work ✅
- Can test features locally ✅

---

**Time to Fix:** 2-3 minutes  
**Difficulty:** Easy

---

**Last Updated:** 2026-06-09 21:00 IST
