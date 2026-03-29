# Mobile App Deployment Checklist - Production Ready

## ⚠️ CRITICAL ISSUE FOUND

Your backend is deployed at: `http://sivakundalini.org/api/gatherings` (port 80)
But your mobile app is configured for: `http://sivakundalini.org:4000/api/gatherings` (port 4000)

**Result:** Mobile app will NOT be able to connect to backend!

---

## 🔧 FIX REQUIRED

### Option 1: Update Mobile App Configuration (Recommended)

Update `.env.prod.json` to match your deployed backend:

**Current (WRONG):**
```json
{
  "API_BASE_URL": "http://sivakundalini.org:4000"
}
```

**Should be (CORRECT):**
```json
{
  "API_BASE_URL": "http://sivakundalini.org"
}
```

### Option 2: Update Backend to Run on Port 4000

If you want to keep port 4000, configure your server:
- Update IIS/Nginx to proxy port 4000
- Or run backend directly on port 4000
- Open firewall for port 4000

**Recommendation:** Use Option 1 (update mobile app config)

---

## ✅ Complete Pre-Deployment Checklist

### 1. Backend Configuration ✅

- [x] Backend deployed at `http://sivakundalini.org`
- [x] API endpoints working (tested `/api/gatherings`)
- [x] Database connected
- [x] Firebase Admin SDK configured
- [x] OneSignal configured
- [x] CORS allows mobile app origin

### 2. Mobile App Configuration ⚠️

**File: `SKS-mobile-V2/.env.prod.json`**

Check and update:

```json
{
  "MSG91_WIDGET_ID": "366379717055333935353237",
  "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
  "API_BASE_URL": "http://sivakundalini.org",  ⚠️ REMOVE :4000
  "FIREBASE_API_KEY": "AIzaSyBXUN42KBq3eGoMgib4ZWDbYYFFc0Ft458",
  "FIREBASE_AUTH_DOMAIN": "sks-login-mobile.firebaseapp.com",
  "FIREBASE_PROJECT_ID": "sks-login-mobile",
  "FIREBASE_STORAGE_BUCKET": "sks-login-mobile.firebasestorage.app",
  "FIREBASE_MESSAGING_SENDER_ID": "294856785598",
  "FIREBASE_WEB_APP_ID": "1:294856785598:web:placeholder",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9"
}
```

**Changes needed:**
- [ ] Change `"API_BASE_URL": "http://sivakundalini.org:4000"` 
- [ ] To: `"API_BASE_URL": "http://sivakundalini.org"`

### 3. Firebase Configuration ✅

- [x] Firebase project: `sks-login-mobile`
- [x] Android app registered
- [x] `google-services.json` in place
- [x] SHA-1 fingerprint added (for Google Sign-In)

### 4. OneSignal Configuration ✅

- [x] OneSignal App ID: `b89d199e-15be-4343-9e04-640c43f355e9`
- [x] Android configuration complete
- [x] Push notification permissions in AndroidManifest.xml

### 5. Build Configuration

**Before building APK, verify:**

- [ ] `.env.prod.json` has correct `API_BASE_URL` (without :4000)
- [ ] `google-services.json` is present
- [ ] App version updated in `pubspec.yaml`
- [ ] App signing configured (for release build)

---

## 🚀 Building Production APK

### Step 1: Fix API URL

```bash
cd SKS-mobile-V2

# Edit .env.prod.json
# Change API_BASE_URL from "http://sivakundalini.org:4000"
# To: "http://sivakundalini.org"
```

### Step 2: Clean Build

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get
```

### Step 3: Build Release APK

```bash
# Build APK with production config
flutter build apk --release --dart-define-from-file=.env.prod.json

# Or build App Bundle (recommended for Play Store)
flutter build appbundle --release --dart-define-from-file=.env.prod.json
```

### Step 4: Locate APK

```bash
# APK location:
build/app/outputs/flutter-apk/app-release.apk

# App Bundle location:
build/app/outputs/bundle/release/app-release.aab
```

---

## 📱 Testing on Real Device

### Before Installing

1. **Enable USB Debugging** on your Android device
2. **Allow installation from unknown sources**
3. **Connect device to computer**

### Install APK

**Option 1: Via USB**
```bash
# Install APK
flutter install --release

# Or using adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Option 2: Transfer APK**
1. Copy `app-release.apk` to device
2. Open file manager on device
3. Tap APK file
4. Allow installation
5. Install app

### Test Checklist

After installing on real device, test:

#### Basic Functionality
- [ ] App launches successfully
- [ ] Splash screen shows
- [ ] Home screen loads

#### Backend Connection
- [ ] Gatherings load from API
- [ ] Events load from API
- [ ] Classes load from API
- [ ] Images load from CDN

#### Authentication
- [ ] Phone number OTP works (MSG91)
- [ ] Google Sign-In works (Firebase)
- [ ] User profile saves
- [ ] Login persists after app restart

#### Push Notifications
- [ ] OneSignal subscription works
- [ ] Test notification received
- [ ] Notification opens app

#### Features
- [ ] Meditation timer works
- [ ] Reminders can be set
- [ ] Audio playback works
- [ ] All navigation works

---

## 🔍 Troubleshooting

### Issue: "Network Error" or "Failed to connect"

**Cause:** Wrong API URL (port 4000 issue)

**Solution:**
1. Check `.env.prod.json` has `"API_BASE_URL": "http://sivakundalini.org"`
2. Rebuild APK with correct config
3. Reinstall on device

**Verify:**
```bash
# On device, check if this works in browser:
http://sivakundalini.org/api/gatherings

# Should return JSON with gatherings data
```

### Issue: "Firebase authentication failed"

**Cause:** SHA-1 fingerprint not added or wrong google-services.json

**Solution:**
1. Get SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
2. Add to Firebase Console → Project Settings → Your apps → SHA certificate fingerprints
3. Download new `google-services.json`
4. Replace in `android/app/google-services.json`
5. Rebuild APK

### Issue: "Push notifications not working"

**Cause:** OneSignal not initialized or wrong App ID

**Solution:**
1. Verify `ONESIGNAL_APP_ID` in `.env.prod.json`
2. Check OneSignal dashboard shows device subscribed
3. Send test notification from OneSignal dashboard
4. Check device notification settings allow app notifications

### Issue: "Images not loading"

**Cause:** CDN URLs or network permissions

**Solution:**
1. Check `AndroidManifest.xml` has internet permission
2. Verify CDN URLs are accessible
3. Check if using HTTP (not HTTPS) - may need cleartext traffic config

---

## 🌐 Network Configuration

### AndroidManifest.xml

Verify these permissions exist:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Network Security Config (if using HTTP)

If your backend uses HTTP (not HTTPS), add:

**File: `android/app/src/main/res/xml/network_security_config.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">sivakundalini.org</domain>
    </domain-config>
</network-security-config>
```

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

---

## 📊 Backend Verification

Before building APK, verify backend endpoints:

```bash
# Test gatherings
curl http://sivakundalini.org/api/gatherings

# Test events
curl http://sivakundalini.org/api/events

# Test classes
curl http://sivakundalini.org/api/classes

# Test health
curl http://sivakundalini.org/health
```

All should return JSON responses with `"success": true`

---

## ✅ Final Checklist Before Building

- [ ] Backend deployed and working at `http://sivakundalini.org`
- [ ] `.env.prod.json` updated with correct API_BASE_URL (no :4000)
- [ ] Firebase `google-services.json` in place
- [ ] OneSignal App ID correct
- [ ] App version updated
- [ ] All dependencies installed (`flutter pub get`)
- [ ] Previous builds cleaned (`flutter clean`)

---

## 🎯 Build Commands

### For Testing (Debug APK)
```bash
flutter build apk --debug --dart-define-from-file=.env.prod.json
```

### For Production (Release APK)
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

### For Play Store (App Bundle)
```bash
flutter build appbundle --release --dart-define-from-file=.env.prod.json
```

---

## 📱 Expected Behavior on Real Device

After installing and opening the app:

1. **Splash Screen** (2-3 seconds)
   - Shows Guruji logo
   - Preloads images

2. **Login Screen**
   - Phone number input
   - Google Sign-In button
   - OTP verification works

3. **Home Screen**
   - Loads gatherings from backend
   - Shows daily quotes
   - All images load from CDN
   - Navigation works

4. **Features Work**
   - Meditation timer
   - Audio playback
   - Reminders
   - Profile management
   - Push notifications

---

## 🚨 Critical Fix Summary

**MUST DO BEFORE BUILDING APK:**

1. Open `SKS-mobile-V2/.env.prod.json`
2. Change line 3 from:
   ```json
   "API_BASE_URL": "http://sivakundalini.org:4000",
   ```
   To:
   ```json
   "API_BASE_URL": "http://sivakundalini.org",
   ```
3. Save file
4. Run `flutter clean`
5. Run `flutter pub get`
6. Build APK: `flutter build apk --release --dart-define-from-file=.env.prod.json`
7. Install on device and test

**Without this fix, the mobile app will NOT connect to your backend!**

---

## 📞 Support

If you encounter issues:
1. Check backend is accessible: `curl http://sivakundalini.org/api/gatherings`
2. Verify APK built with correct config
3. Check device logs: `adb logcat | grep Flutter`
4. Test individual features one by one

Your backend is deployed and working! Just fix the API URL and build the APK. 🚀
