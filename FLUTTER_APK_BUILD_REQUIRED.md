# Flutter APK Build Required

## ⚠️ CRITICAL: APK Must Be Rebuilt

The Android APK **MUST** be rebuilt on a machine with Android SDK to deploy the SSL certificate trust fix.

---

## What Was Fixed

### 1. ✅ Backend - Secure Video Proxy (DEPLOYED)
**Service:** `sks-classes-service`
**Status:** ✅ LIVE - Committed and PM2 restarted
**Commit:** `d3e9dbd`

- Created authenticated video proxy at `/api/video-proxy/:path*`
- Requires Firebase authentication
- Verifies day unlock status before serving videos
- Auto-unlocks Day 1 for all users
- Hides R2 URLs from public
- Rewrites m3u8 URLs to use proxy
- Access logging enabled

### 2. ✅ Database URLs Updated (DEPLOYED)
**Status:** ✅ COMPLETE - 8 rows updated

All video URLs changed from:
```
https://pub-9129a0cdf4ad4862bcc4c1a92c619c17.r2.dev/classes/videos/...
```

To:
```
https://app.sivakundalini.org/api/video-proxy/classes/videos/...
```

### 3. ✅ Network Security Config (COMMITTED - Needs APK Rebuild)
**File:** `android/app/src/main/res/xml/network_security_config.xml`
**Status:** ✅ Committed - Waiting for APK build
**Commit:** `05affc1`

- Added SSL trust for `app.sivakundalini.org`
- Trusts system CA certificates (includes Let's Encrypt)
- Added user-installed certificate trust for testing

### 4. ✅ Wallpaper Service Fix (COMMITTED - Needs APK Rebuild)
**File:** `lib/core/services/wallpaper_service.dart`
**Status:** ✅ Committed - Waiting for APK build
**Commit:** `4d46448`

- Fixed `LateInitializationError` with `_dio` field
- Changed to lazy initialization pattern

---

## 🚨 APK Build Instructions

**IMPORTANT:** This server does NOT have Android SDK installed. You must build on a machine with Android development tools.

### Prerequisites
1. Machine with Android Studio and SDK installed
2. Flutter SDK installed
3. Git access to repository

### Build Commands

```cmd
# On a machine with Android SDK

cd s:\SKS-mobile-V2

# Pull latest changes (includes SSL fix)
git pull

# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# APK will be at:
# s:\SKS-mobile-V2\build\app\outputs\flutter-apk\app-release.apk
```

### Install on Device

```cmd
# Option 1: Install via ADB
adb install -r build\app\outputs\flutter-apk\app-release.apk

# Option 2: Transfer APK to device and install manually
# Copy app-release.apk to phone and tap to install
```

---

## 🧪 Testing Checklist

After installing the new APK:

### 1. Video Playback Test
- [ ] Login with valid user
- [ ] Navigate to Classes (Learnings)
- [ ] Select Level 1, Day 1 (Auto-unlocked)
- [ ] Verify video plays without SSL errors
- [ ] Check console logs - should NOT see:
  - `Trust anchor for certification path not found`
  - `handshake failed; returned -1, SSL error code 1`
  - `net::ERR_BLOCKED_BY_ORB`

### 2. Multi-Language Test
- [ ] Level 1, Day 1 - Telugu (te)
- [ ] Level 1, Day 1 - Hindi (hi)
- [ ] Level 2, Day 1 - Telugu
- [ ] Verify all play smoothly

### 3. Quality Switching Test
- [ ] Start video playback
- [ ] Click Quality button
- [ ] Switch between Auto, 1080p, 720p, 480p
- [ ] Verify seamless transitions (no flicker, no pause)

### 4. Access Control Test
- [ ] Try to access Day 2+ without completing Day 1
- [ ] Should show "Day X is locked" message
- [ ] Complete Day 1
- [ ] Verify Day 2 unlocks

### 5. Wallpaper Test
- [ ] Navigate to Wallpapers section
- [ ] Verify wallpapers load without `LateInitializationError`
- [ ] Download and set a wallpaper

### 6. Meditation Stats Test
- [ ] Navigate to Meditation section
- [ ] Start a meditation session
- [ ] Complete session
- [ ] Verify stats are recorded without 500 errors

---

## 📊 Backend Status (All Live)

| Service | Status | Port | PM2 Status |
|---------|--------|------|------------|
| api-gateway | ✅ LIVE | 3000 | online |
| sks-mobile-backend-service | ✅ LIVE | 3012 | online |
| sks-classes-service | ✅ LIVE | 3014 | online |
| google-login-service | ✅ LIVE | 3015 | online |
| otp-login-service | ✅ LIVE | 3016 | online |
| notification-service | ✅ LIVE | 3013 | online |

---

## 🔍 Verification Commands

### Check Backend Services
```cmd
pm2 status
pm2 logs sks-classes-service --lines 50
pm2 logs sks-mobile-backend-service --lines 50
```

### Test Video Proxy Endpoint
```bash
# With valid Firebase token
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://app.sivakundalini.org/api/video-proxy/classes/videos/1/1/te/master.m3u8
```

### Check Database URLs
```sql
USE sivoham_classes;
SELECT TOP 5 class_id, day_number, language, video_url 
FROM class_days 
WHERE is_active = 1;
```

---

## 📁 Changed Files

### Backend (Deployed)
- ✅ `s:\Backup\sks-classes-service\routes\video-proxy.js` - NEW
- ✅ `s:\Backup\sks-classes-service\server.js` - MODIFIED
- ✅ `s:\Backup\sks-mobile-backend-service\routes\meditation.js` - MODIFIED

### Frontend (Needs APK Rebuild)
- ✅ `s:\SKS-mobile-V2\android\app\src\main\res\xml\network_security_config.xml` - MODIFIED
- ✅ `s:\SKS-mobile-V2\lib\core\services\wallpaper_service.dart` - MODIFIED

### Database (Deployed)
- ✅ 8 video URLs updated to proxy format

---

## 🎯 Success Criteria

✅ **BACKEND:** All fixes deployed and services running
⏳ **FRONTEND:** Waiting for APK rebuild
⏳ **TESTING:** Pending APK installation

### When APK is rebuilt and installed:
- Videos play without SSL certificate errors
- All levels and languages work smoothly
- Quality switching is seamless
- Access control enforced (locked days blocked)
- Wallpapers load without errors
- Meditation stats save correctly

---

## 🆘 Troubleshooting

### If videos still don't play after APK install:

1. **Check network security config is included:**
   ```cmd
   # Extract APK and verify
   unzip -l app-release.apk | grep network_security_config.xml
   ```

2. **Check server SSL certificate:**
   ```bash
   openssl s_client -connect app.sivakundalini.org:443 -showcerts
   ```

3. **Check proxy logs:**
   ```cmd
   pm2 logs sks-classes-service --lines 100
   ```

4. **Verify user authentication:**
   - Token must be valid
   - User must be logged in
   - Check Firebase auth status

---

## 📝 Notes

- Android SDK is NOT installed on this server (Server 2022 Standard)
- APK must be built on a development machine
- All backend changes are LIVE and working
- Frontend changes are committed but not deployed (need APK build)
- Database is updated and ready

**Next Step:** Build APK on Android development machine and install on device.
