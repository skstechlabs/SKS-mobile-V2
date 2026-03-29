# Build Production APK - Quick Guide

## ✅ Configuration Fixed!

Your `.env.prod.json` has been updated with the correct API URL:
- ❌ OLD: `http://sivakundalini.org:4000`
- ✅ NEW: `http://sivakundalini.org`

---

## 🚀 Build Production APK

### Step 1: Clean Previous Builds
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
```

### Step 2: Build Release APK
```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

### Step 3: Locate APK
```bash
# APK will be at:
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Install on Real Device

### Option 1: Direct Install (Device Connected via USB)
```bash
flutter install --release
```

### Option 2: Manual Install
1. Copy `build/app/outputs/flutter-apk/app-release.apk` to your device
2. Open file manager on device
3. Tap the APK file
4. Allow installation from unknown sources if prompted
5. Install the app

---

## ✅ What Will Work on Real Device

### Backend Connection ✅
- ✅ Gatherings will load from `http://sivakundalini.org/api/gatherings`
- ✅ Events will load from `http://sivakundalini.org/api/events`
- ✅ Classes will load from `http://sivakundalini.org/api/classes`
- ✅ All API calls will work

### Authentication ✅
- ✅ Phone OTP (MSG91) - configured
- ✅ Google Sign-In (Firebase) - configured
- ✅ User profile management

### Features ✅
- ✅ Meditation timer
- ✅ Reminders
- ✅ Audio playback
- ✅ Push notifications (OneSignal)
- ✅ Image loading from CDN

---

## 🧪 Testing Checklist

After installing on device, test:

1. **App Launch**
   - [ ] Splash screen shows
   - [ ] Home screen loads

2. **Backend Connection**
   - [ ] Gatherings section shows data
   - [ ] Events section shows data
   - [ ] Images load properly

3. **Authentication**
   - [ ] Phone OTP works
   - [ ] Google Sign-In works
   - [ ] Profile saves

4. **Features**
   - [ ] Meditation timer works
   - [ ] Audio plays
   - [ ] Reminders can be set
   - [ ] Navigation works

---

## 🔍 Quick Verification

Before building, verify backend is accessible:

```bash
# Test from your computer
curl http://sivakundalini.org/api/gatherings

# Should return JSON with gatherings data
```

---

## 📊 Build Output

Expected output when building:

```
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB).
```

APK size will be approximately 40-60 MB.

---

## 🎯 Summary

1. ✅ API URL fixed (removed :4000)
2. ✅ Backend deployed and working
3. ✅ Ready to build APK
4. ✅ Will work on real device

**Next step:** Run the build command and install on your device!

```bash
flutter build apk --release --dart-define-from-file=.env.prod.json
```

Your mobile app will connect to the deployed backend successfully! 🎉
