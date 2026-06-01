# 🚀 START HERE - Quick Fix for Localhost Connection

## ❌ Your Current Problem

App is still connecting to `https://app.sivakundalini.org` instead of `http://localhost:3000`

## ✅ Quick Fix (2 Steps)

### Step 1: Stop Your Current Flutter App

Press `Ctrl+C` in the terminal where Flutter is running.

### Step 2: Run This Command

**Choose ONE of these options:**

#### Option A: PowerShell Script (Easiest)
```powershell
cd s:\SKS-mobile-V2
.\run-web-dev.ps1
```

#### Option B: Batch File
```cmd
cd s:\SKS-mobile-V2
run-web-dev.bat
```

#### Option C: Manual Command
```powershell
cd s:\SKS-mobile-V2
flutter clean
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
```

---

## ✅ How to Verify It's Working

Open Chrome DevTools (F12) → Console tab

**You should see:**
```
🔧 API Service Initializing...
📍 Base URL: http://localhost:3000  ← THIS IS CORRECT!
```

**Network tab should show:**
```
✓ http://localhost:3000/api/events
✓ http://localhost:3000/api/gatherings
✓ http://localhost:3000/api/quotes
```

---

## 🎯 Why This Fixes It

Flutter web doesn't load `.env.json` automatically. You MUST pass environment variables explicitly using `--dart-define` flags.

The scripts do this for you automatically!

---

## 📚 More Information

- **FIX_LOCALHOST_URL.md** - Detailed explanation
- **CORS_COMPLETE_FIX.md** - CORS configuration details
- **DEVELOPMENT_SETUP.md** - Full development setup

---

**That's it! Just run the script and you're done!** 🎉
