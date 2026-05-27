# 🚨 URGENT: Mobile App Configuration Issue

## Problem Identified

The mobile app is calling the **PRODUCTION server** (`https://app.sivakundalini.org`), NOT your local server!

### Evidence from Logs
```
uri: https://app.sivakundalini.org/api/classes-v2/days/4/video-config
statusCode: 404
Response: {"success":false,"message":"Day not found for this language","error_code":"DAY_NOT_FOUND"}
```

### Why This Is Happening

1. **Mobile App Configuration**:
   - File: `lib/core/utils/environment_checker.dart`
   - Fallback URL: `https://app.sivakundalini.org`
   - The app was built WITHOUT environment configuration
   - So it defaults to production server

2. **Local Server**:
   - We fixed the local server (changed `HLS_DEFAULT_LANGUAGE=te`)
   - Local server is working correctly
   - But mobile app is NOT calling local server!

3. **Production Server**:
   - Still has `HLS_DEFAULT_LANGUAGE=en`
   - Needs the same fix we applied locally

---

## 🔧 Solution Options

### Option 1: Rebuild Mobile App to Use Local Server (RECOMMENDED FOR TESTING)

**Step 1**: Create `.env.json` file (already created)
```json
{
  "API_BASE_URL": "http://YOUR_LOCAL_IP:3012",
  "MSG91_WIDGET_ID": "366379717055333935353237",
  "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
  "GOOGLE_CLIENT_ID": "...",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9"
}
```

**Step 2**: Find your local IP address
```bash
# Windows
ipconfig
# Look for IPv4 Address (e.g., 192.168.1.100)
```

**Step 3**: Update `.env.json` with your IP
```json
{
  "API_BASE_URL": "http://192.168.1.100:3012",
  ...
}
```

**Step 4**: Rebuild and install the app
```bash
cd s:\SKS-mobile-V2
flutter build apk --release --dart-define-from-file=.env.json
```

**Step 5**: Install on your phone
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

### Option 2: Fix Production Server (RECOMMENDED FOR PRODUCTION)

**If you have SSH access to production server**:

1. SSH into production server
2. Navigate to classes-service directory
3. Edit `.env` file:
   ```bash
   nano .env
   # Change: HLS_DEFAULT_LANGUAGE=en
   # To:     HLS_DEFAULT_LANGUAGE=te
   ```
4. Restart service:
   ```bash
   pm2 restart classes-service --update-env
   ```

**If you don't have SSH access**:
- Contact your server administrator
- Or deploy the fixed code to production

---

### Option 3: Quick Test with ADB Port Forwarding

**If you just want to test quickly**:

```bash
# Forward production domain to local server
adb reverse tcp:3012 tcp:3012

# This makes the phone think app.sivakundalini.org is your local server
# But this only works if the app uses HTTP, not HTTPS
```

**Note**: This won't work if the app enforces HTTPS!

---

## 🎯 Recommended Approach

### For Testing (Now):
1. Find your local IP address (e.g., `192.168.1.100`)
2. Update `.env.json`:
   ```json
   {
     "API_BASE_URL": "http://192.168.1.100:3012",
     ...
   }
   ```
3. Rebuild app:
   ```bash
   flutter build apk --release --dart-define-from-file=.env.json
   ```
4. Install on phone:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### For Production (Later):
1. Fix production server `.env` file
2. Restart production classes-service
3. Test with production app

---

## 📝 Quick Commands

### Find Your Local IP
```bash
# Windows
ipconfig | findstr IPv4

# You'll see something like:
# IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

### Update .env.json
```bash
# Edit the file and replace localhost with your IP
notepad s:\SKS-mobile-V2\.env.json
```

### Rebuild App
```bash
cd s:\SKS-mobile-V2
flutter build apk --release --dart-define-from-file=.env.json
```

### Install App
```bash
# Make sure phone is connected via USB
adb devices

# Install the app
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔍 Verify Configuration

After rebuilding, check the app logs when it starts:
```
========================================
ENVIRONMENT CONFIGURATION CHECK
========================================
API_BASE_URL: "http://192.168.1.100:3012"
API_BASE_URL isEmpty: false
✅ API_BASE_URL is configured
========================================
```

If you see this, the app will use your local server!

---

## ⚠️ Important Notes

1. **Local IP vs Localhost**:
   - Use your computer's IP address (e.g., `192.168.1.100`)
   - NOT `localhost` or `127.0.0.1` (these refer to the phone itself)

2. **Same Network**:
   - Phone and computer must be on the same WiFi network
   - Or use USB debugging with port forwarding

3. **Firewall**:
   - Make sure Windows Firewall allows connections on port 3012
   - You may need to add a firewall rule

4. **HTTPS vs HTTP**:
   - Local server uses HTTP
   - Production uses HTTPS
   - Make sure app allows HTTP for local testing

---

## 🚀 Next Steps

1. **Find your local IP address**
2. **Update `.env.json` with your IP**
3. **Rebuild the mobile app**
4. **Install on your phone**
5. **Test video playback**

The video should load and play once the app is configured to use your local server!

---

**Current Status**:
- ✅ Local server fixed (HLS_DEFAULT_LANGUAGE=te)
- ❌ Mobile app calling production server
- ❌ Production server not fixed yet

**Action Required**:
- Rebuild mobile app with local server URL
- OR fix production server
