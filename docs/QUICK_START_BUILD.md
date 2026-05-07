# Quick Start - Build Production APK

This is a quick reference guide for building production APKs. For detailed instructions, see `BUILD_PRODUCTION_APK.md`.

---

## 🚀 First Time Setup (One-time only)

### Step 1: Run Setup Script
```bash
cd SKS-mobile-V2
./setup-signing.sh
```

This will:
- Create a keystore for signing your app
- Create `key.properties` file
- Update `.gitignore`

**⚠️ IMPORTANT:** Save your keystore password! You'll need it for all future builds.

### Step 2: Update build.gradle (if needed)

If the setup script indicates that `build.gradle` needs updating, follow the instructions shown.

### Step 3: Configure Environment

Edit `.env` file with production values:
```bash
nano .env
```

Update:
```env
API_BASE_URL=https://your-production-api.com
ONESIGNAL_APP_ID=your_production_onesignal_app_id
GOOGLE_CLIENT_ID=your_production_google_client_id
```

---

## 🏗️ Building APK (Every Release)

### Option 1: Use Build Script (Recommended)
```bash
cd SKS-mobile-V2
./build-release.sh
```

Select build type:
1. Universal APK (works on all devices)
2. Split APKs (smaller size) - **RECOMMENDED**
3. App Bundle (for Play Store)

### Option 2: Manual Build
```bash
cd SKS-mobile-V2

# Clean
flutter clean

# Get dependencies
flutter pub get

# Build (choose one)
flutter build apk --release                    # Universal APK
flutter build apk --split-per-abi --release    # Split APKs (recommended)
flutter build appbundle --release              # App Bundle
```

---

## 📦 Output Location

### Universal APK:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### App Bundle:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 📱 Install on Device

### Using ADB:
```bash
# Connect device via USB
# Enable USB debugging on device

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Using Flutter:
```bash
flutter install --release
```

---

## 🔄 Update Version (Before Each Release)

Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    versionCode 2        // Increment this (1, 2, 3, ...)
    versionName "1.0.1"  // Update this (1.0.0, 1.0.1, 1.1.0, ...)
}
```

---

## ✅ Pre-Release Checklist

Before distributing:
- [ ] Version updated (versionCode and versionName)
- [ ] Production environment variables set
- [ ] APK built successfully
- [ ] Tested on real device
- [ ] All features working
- [ ] No crashes or errors

---

## 🆘 Troubleshooting

### Build fails with "Keystore not found"
```bash
# Run setup script again
./setup-signing.sh
```

### Build fails with "Signing config not found"
```bash
# Check if key.properties exists
cat android/key.properties

# Verify build.gradle has signing config
cat android/app/build.gradle | grep signingConfig
```

### APK too large
```bash
# Use split APKs instead
flutter build apk --split-per-abi --release
```

### App crashes on launch
```bash
# Check logs
adb logcat | grep flutter

# Build debug version to see errors
flutter build apk --debug
```

---

## 📚 More Information

- **Detailed Guide:** `BUILD_PRODUCTION_APK.md`
- **Flutter Docs:** https://docs.flutter.dev/deployment/android
- **App Signing:** https://developer.android.com/studio/publish/app-signing

---

## 🎯 Quick Commands Reference

```bash
# First time setup
./setup-signing.sh

# Build production APK
./build-release.sh

# Or manually
flutter build apk --split-per-abi --release

# Install on device
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Check APK size
flutter build apk --analyze-size --release

# Clean build
flutter clean && flutter pub get
```

---

## 📞 Need Help?

1. Check `BUILD_PRODUCTION_APK.md` for detailed instructions
2. Check Flutter documentation
3. Check error logs: `adb logcat | grep flutter`

---

**Last Updated:** April 14, 2026
