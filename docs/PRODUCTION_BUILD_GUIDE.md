# SKS Mobile App - Production Build Guide

---

## 📋 Pre-Build Checklist

### 1. Verify Environment Configuration

Check `.env.prod.json`:
```json
{
  "API_BASE_URL": "http://sivakundalini.org:4000",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9",
  "FIREBASE_PROJECT_ID": "sks-login-mobile",
  ...
}
```

### 2. Verify Backend is Running
```bash
# Test production backend
curl http://sivakundalini.org:4000/health

# Expected response:
# {"status":"ok","timestamp":"..."}
```

### 3. Clean Build Environment
```bash
cd SKS-mobile-V2

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Verify no errors
flutter doctor
```

---

## 🏗️ Build Production APK

### Standard Build
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

### Split APK by ABI (Smaller file sizes)
```bash
flutter build apk --release --split-per-abi --dart-define-from-file=.env.prod.json
```

This creates 3 APKs:
- `app-armeabi-v7a-release.apk` (32-bit ARM - older devices)
- `app-arm64-v8a-release.apk` (64-bit ARM - most modern devices)
- `app-x86_64-release.apk` (64-bit x86 - emulators/tablets)

**Recommended:** Use `app-arm64-v8a-release.apk` for most users.

### Build Location
```
build/app/outputs/flutter-apk/app-release.apk
```

Or for split builds:
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

## 🧪 Testing Production Build

### 1. Install on Physical Device
```bash
# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or for specific ABI
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# View logs
adb logcat | grep -i flutter
```

### 2. Test Critical Flows

#### Authentication
- [ ] OTP login works
- [ ] Google sign-in works
- [ ] Profile completion works
- [ ] Logout works

#### Permissions
- [ ] Notification permission requested
- [ ] Camera permission requested (optional)
- [ ] Microphone permission requested (optional)
- [ ] Location permission requested (optional)
- [ ] Skip permissions screen if all granted

#### OneSignal Integration
- [ ] User appears in OneSignal dashboard after granting notification permission
- [ ] Push notifications received
- [ ] Notification click opens detail screen
- [ ] External user ID set correctly

#### Core Features
- [ ] Home page loads
- [ ] Events load from database
- [ ] Gatherings load from database
- [ ] Reminders can be created/edited/deleted
- [ ] Preset reminders work
- [ ] Profile screen works
- [ ] Images load from CDN with caching

#### Backend Integration
- [ ] API calls to production server work
- [ ] Authentication tokens work
- [ ] All CRUD operations work
- [ ] Error handling works

---

## 🔍 Debugging Production Issues

### View Logs
```bash
# Real-time logs
adb logcat | grep -E "flutter|OneSignal|Firebase"

# Save logs to file
adb logcat > app_logs.txt

# Filter for errors only
adb logcat *:E | grep flutter
```

### Check OneSignal Subscription
Look for these log messages:
```
📱 OS Permission Status: true
👤 Step 2: Setting OneSignal external user ID: <uid>
📊 OneSignal subscription status:
   Subscribed: true
   Player ID: <valid_id>
```

**Red Flags:**
- `Player ID: null` - Subscription failed
- `Subscribed: false` - User not subscribed
- `⚠️ WARNING: Player ID is null or empty!`

### Common Issues

#### Issue: API calls fail
```
Check:
1. Backend server is running: curl http://sivakundalini.org:4000/health
2. .env.prod.json has correct API_BASE_URL
3. Device has internet connection
4. Firewall allows port 4000
```

#### Issue: OneSignal subscriptions not appearing
```
Check:
1. OneSignal App ID is correct in .env.prod.json
2. Notification permission granted
3. Player ID is not null in logs
4. External user ID is set
5. Device has internet connection
```

#### Issue: Images not loading
```
Check:
1. CDN URLs are correct in cdn_images.dart
2. Device has internet connection
3. Cloudflare CDN is accessible
4. Check logs for image loading errors
```

---

## 📦 Distribution

### Option 1: Direct APK Distribution
1. Upload APK to file hosting (Google Drive, Dropbox, etc.)
2. Share download link with users
3. Users must enable "Install from Unknown Sources"

### Option 2: Google Play Store (Recommended)
1. Create app bundle:
   ```bash
   flutter build appbundle --release --dart-define-from-file=.env.prod.json
   ```
2. Upload to Google Play Console
3. Follow Play Store review process

### Option 3: Firebase App Distribution
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Distribute:
   ```bash
   firebase appdistribution:distribute \
     build/app/outputs/flutter-apk/app-release.apk \
     --app 1:294856785598:android:your_app_id \
     --groups testers
   ```

---

## 🔄 Update Deployment

### Version Update
1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version+build_number
   ```

2. Build new APK:
   ```bash
   flutter build apk --release --dart-define-from-file=.env.prod.json
   ```

3. Test thoroughly before distribution

### Hot Fixes
For critical bugs:
1. Fix the issue
2. Increment build number
3. Build and test
4. Distribute immediately

---

## 📊 Build Optimization

### Reduce APK Size
```bash
# Use split APKs
flutter build apk --release --split-per-abi --dart-define-from-file=.env.prod.json

# Enable code shrinking (already enabled in build.gradle.kts)
# minifyEnabled = true
# shrinkResources = true
```

### Current APK Size
- Full APK: ~133 MB
- Split APK (arm64-v8a): ~50-60 MB

### Size Breakdown
- Flutter engine: ~30 MB
- Dart code: ~10 MB
- Assets (images): ~1 MB (CDN migration saved ~12 MB)
- Dependencies: ~90 MB

---

## 🔒 Security Checklist

- [ ] API keys not hardcoded (using environment variables)
- [ ] ProGuard/R8 enabled for code obfuscation
- [ ] HTTPS used for all API calls (when SSL configured)
- [ ] Firebase security rules configured
- [ ] OneSignal REST API key not in app
- [ ] No sensitive data in logs (production)

---

## 📝 Release Notes Template

```
Version 1.0.0 (Build 1)
Release Date: March 29, 2026

New Features:
- OTP and Google authentication
- Push notifications with OneSignal
- Daily meditation reminders
- Events and gatherings from database
- Profile management
- CDN-based image loading with caching

Bug Fixes:
- Fixed notification permission flow
- Fixed OneSignal subscription issue
- Fixed image loading performance

Known Issues:
- Local notifications temporarily disabled (build issue)

Requirements:
- Android 5.0 (API 21) or higher
- Internet connection required
- Notification permission required
```

---

## 🎯 Quality Assurance

### Test Matrix

| Feature | Test Case | Status |
|---------|-----------|--------|
| Auth | OTP login | ✅ |
| Auth | Google login | ✅ |
| Auth | Logout | ✅ |
| Permissions | Notification | ✅ |
| Permissions | Camera | ✅ |
| Permissions | Microphone | ✅ |
| Permissions | Location | ✅ |
| OneSignal | Subscription | ⚠️ |
| OneSignal | Push notification | ⚠️ |
| API | Events list | ✅ |
| API | Gatherings list | ✅ |
| API | Reminders CRUD | ✅ |
| UI | Home page | ✅ |
| UI | Profile page | ✅ |
| Images | CDN loading | ✅ |
| Images | Caching | ✅ |

---

## 📞 Support Information

- **Firebase Project:** sks-login-mobile (294856785598)
- **OneSignal App ID:** b89d199e-15be-4343-9e04-640c43f355e9
- **Package Name:** com.spiritual.app
- **Production API:** http://sivakundalini.org:4000

---

## ✅ Pre-Release Checklist

- [ ] All tests passing
- [ ] No console errors in production build
- [ ] Backend server running and accessible
- [ ] OneSignal subscriptions working
- [ ] All API endpoints responding
- [ ] Images loading from CDN
- [ ] Authentication flows working
- [ ] Profile management working
- [ ] Reminders working
- [ ] Events and gatherings loading
- [ ] Performance acceptable (no lag)
- [ ] Memory usage acceptable (no leaks)
- [ ] Battery usage acceptable
- [ ] APK size acceptable
- [ ] Release notes prepared
- [ ] Distribution method decided

---

## 🚀 Launch!

Once all checks pass:
1. Build final production APK
2. Test on multiple devices
3. Distribute to users
4. Monitor for issues
5. Be ready for hot fixes

**Good luck with your launch! 🎉**
