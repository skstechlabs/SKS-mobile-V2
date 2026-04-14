# 📱 Build Production APK - Summary

## 🎯 Goal
Build a production-ready APK file for the SKS mobile app that can be distributed to users.

---

## 📋 Three Simple Steps

### 1️⃣ First Time Setup (One-time only)
```bash
cd SKS-mobile-V2
./setup-signing.sh
```
**What it does:** Creates keystore and configures app signing

**Time:** 5 minutes

---

### 2️⃣ Configure Environment
```bash
nano .env
```
**Update these values:**
- `API_BASE_URL` → Your production API URL
- `ONESIGNAL_APP_ID` → Your OneSignal App ID
- `GOOGLE_CLIENT_ID` → Your Google Client ID (if using)

**Time:** 2 minutes

---

### 3️⃣ Build APK
```bash
./build-release.sh
```
**Select option 2** (Split APKs - Recommended)

**Time:** 3-5 minutes

---

## 📦 Output

Your APK files will be in:
```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk  (for older devices)
├── app-arm64-v8a-release.apk    (for most devices) ⭐
└── app-x86_64-release.apk       (for emulators)
```

**Most users need:** `app-arm64-v8a-release.apk`

---

## 📱 Install on Device

```bash
# Connect device via USB
# Enable USB debugging

# Install
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 🔄 For Each New Release

1. **Update version** in `android/app/build.gradle`:
   ```gradle
   versionCode 2        // Increment: 1 → 2 → 3
   versionName "1.0.1"  // Update: 1.0.0 → 1.0.1 → 1.1.0
   ```

2. **Build APK:**
   ```bash
   ./build-release.sh
   ```

3. **Test on device**

4. **Distribute to users**

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `QUICK_START_BUILD.md` | Quick reference guide |
| `BUILD_PRODUCTION_APK.md` | Complete detailed guide |
| `setup-signing.sh` | Setup script (run once) |
| `build-release.sh` | Build script (run for each release) |

---

## ⚠️ Important Notes

### DO:
- ✅ Keep keystore file safe
- ✅ Save passwords securely
- ✅ Test on real device before distributing
- ✅ Update version for each release
- ✅ Use production environment variables

### DON'T:
- ❌ Commit keystore to Git
- ❌ Commit key.properties to Git
- ❌ Share keystore password
- ❌ Lose keystore file (you can't update app without it!)
- ❌ Use development credentials in production

---

## 🆘 Common Issues

### "Keystore not found"
**Solution:** Run `./setup-signing.sh` again

### "Build failed"
**Solution:** 
```bash
flutter clean
flutter pub get
./build-release.sh
```

### "APK too large"
**Solution:** Use option 2 (Split APKs) in build script

### "App crashes"
**Solution:** Check logs with `adb logcat | grep flutter`

---

## 🎉 Success!

When build completes successfully, you'll see:
```
✅ Build successful!

📦 Output files:
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (45M)

📍 Location: build/app/outputs/flutter-apk/
```

Your APK is ready to distribute! 🚀

---

## 📞 Need More Help?

1. **Quick Reference:** `QUICK_START_BUILD.md`
2. **Detailed Guide:** `BUILD_PRODUCTION_APK.md`
3. **Flutter Docs:** https://docs.flutter.dev/deployment/android

---

## 🔗 Quick Links

```bash
# Setup (first time)
./setup-signing.sh

# Build (every release)
./build-release.sh

# Install on device
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Check version
grep "versionCode\|versionName" android/app/build.gradle
```

---

**Total Time:** 10-15 minutes (first time), 5 minutes (subsequent builds)

**Difficulty:** Easy (scripts automate everything!)

**Status:** ✅ Ready to use
