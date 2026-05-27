# 🚀 REBUILD MOBILE APP - STEP BY STEP

## 🎯 Problem
Your mobile app is calling the **production server** (`https://app.sivakundalini.org`), not your local server where we fixed the video issue.

## ✅ Solution
Rebuild the app to use your **local server** at `http://192.168.0.3:3012`

---

## 📋 Step-by-Step Instructions

### Step 1: Verify Configuration File
✅ **DONE** - I've created `.env.json` with your local IP:
```json
{
  "API_BASE_URL": "http://192.168.0.3:3012",
  ...
}
```

### Step 2: Make Sure Phone and Computer Are on Same WiFi
- Your computer IP: `192.168.0.3`
- Your phone must be on the same WiFi network
- Check your phone's WiFi settings

### Step 3: Build the APK
Open PowerShell and run:
```powershell
cd s:\SKS-mobile-V2
flutter build apk --release --dart-define-from-file=.env.json
```

This will take 2-3 minutes. You'll see:
```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.XMB)
```

### Step 4: Connect Your Phone
- Connect phone to computer via USB
- Enable USB debugging on phone
- Verify connection:
```powershell
adb devices
```

You should see your device listed.

### Step 5: Install the APK
```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

If app is already installed, use:
```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### Step 6: Test the App
1. Open the app on your phone
2. Login with Google
3. Go to Classes → Level 1
4. Tap on Day 1
5. **Video should load and play!** 🎬

---

## 🔍 Verify It's Working

When the app starts, check the logs:
```
========================================
ENVIRONMENT CONFIGURATION CHECK
========================================
API_BASE_URL: "http://192.168.0.3:3012"
✅ API_BASE_URL is configured
========================================
```

When you try to play video, you should see:
```
🎥 Loading video config for day 4
uri: http://192.168.0.3:3012/api/classes-v2/days/4/video-config
✅ Video config loaded successfully
```

---

## ⚠️ Troubleshooting

### If Build Fails
```powershell
# Clean and retry
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.json
```

### If Phone Not Detected
```powershell
# Check ADB
adb devices

# If no devices, check:
# 1. USB debugging enabled on phone
# 2. USB cable is data cable (not charge-only)
# 3. Accept "Allow USB debugging" prompt on phone
```

### If Video Still Doesn't Load
1. Check phone is on same WiFi as computer
2. Check Windows Firewall allows port 3012
3. Test API from phone browser: `http://192.168.0.3:3012/health`

### If Firewall Blocks Connection
```powershell
# Add firewall rule (run as Administrator)
netsh advfirewall firewall add rule name="API Gateway" dir=in action=allow protocol=TCP localport=3012
```

---

## 🎯 Quick Commands Summary

```powershell
# 1. Navigate to project
cd s:\SKS-mobile-V2

# 2. Build APK
flutter build apk --release --dart-define-from-file=.env.json

# 3. Check phone connection
adb devices

# 4. Install app
adb install -r build\app\outputs\flutter-apk\app-release.apk

# 5. Watch logs (optional)
adb logcat | Select-String "flutter"
```

---

## ✅ Expected Result

After rebuilding and installing:
- App will call `http://192.168.0.3:3012` (your local server)
- Local server has `HLS_DEFAULT_LANGUAGE=te` (fixed)
- Video config will be found
- Video will load and play! 🎉

---

## 📝 Notes

1. **This is for testing only**
   - Production app should still use `https://app.sivakundalini.org`
   - You'll need to fix production server too

2. **Phone must stay on same WiFi**
   - If phone switches to mobile data, it won't reach local server
   - Keep WiFi enabled during testing

3. **Local IP may change**
   - If your computer restarts, IP might change
   - Check with `ipconfig` and rebuild if needed

---

**Ready to rebuild?** Run the commands above! 🚀
