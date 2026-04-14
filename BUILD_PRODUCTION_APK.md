# Building Production APK - Step by Step Guide

This guide provides complete instructions for building a production-ready APK for the SKS mobile app.

---

## 📋 Prerequisites

### 1. Install Required Tools
```bash
# Verify Flutter installation
flutter --version

# Verify Java/JDK installation
java -version

# Should show Java 11 or higher
```

### 2. Update Flutter
```bash
# Update Flutter to latest stable version
flutter upgrade

# Clean previous builds
flutter clean
```

---

## 🔐 Step 1: Configure App Signing

### Create Keystore (First Time Only)

```bash
# Navigate to android directory
cd SKS-mobile-V2/android

# Generate keystore
keytool -genkey -v -keystore ~/sks-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sks-key-alias

# You'll be prompted for:
# - Keystore password (remember this!)
# - Key password (remember this!)
# - Your name
# - Organization unit
# - Organization name
# - City
# - State
# - Country code
```

**⚠️ IMPORTANT:** 
- Save the keystore file (`sks-release-key.jks`) in a secure location
- **NEVER** commit the keystore to Git
- Keep passwords in a secure password manager
- You'll need this keystore for all future app updates

---

## 🔧 Step 2: Configure Gradle for Signing

### Create key.properties file

```bash
# Create key.properties in android directory
cd SKS-mobile-V2/android
touch key.properties
```

### Edit key.properties

```bash
# Open with your editor
nano key.properties
```

Add the following content:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=sks-key-alias
storeFile=/Users/YOUR_USERNAME/sks-release-key.jks
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password
- `/Users/YOUR_USERNAME/sks-release-key.jks` with actual path to your keystore

**⚠️ IMPORTANT:** Add `key.properties` to `.gitignore`

```bash
# Add to .gitignore
echo "android/key.properties" >> .gitignore
```

---

## 📝 Step 3: Update android/app/build.gradle

### Edit build.gradle

```bash
cd SKS-mobile-V2/android/app
nano build.gradle
```

### Add signing configuration

Find the `android {` block and add this **before** the `buildTypes` section:

```gradle
// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing configuration ...

    // Add signing configs
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            // Add signing config
            signingConfig signingConfigs.release
            
            // Enable minification and obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 🎯 Step 4: Configure App Details

### Update android/app/build.gradle

```gradle
android {
    defaultConfig {
        // Application ID (must be unique)
        applicationId "org.sks.app"
        
        // Minimum Android version (Android 5.0)
        minSdkVersion 21
        
        // Target latest Android version
        targetSdkVersion 34
        
        // Version code (increment for each release)
        versionCode 1
        
        // Version name (user-facing version)
        versionName "1.0.0"
    }
}
```

**Version Guidelines:**
- `versionCode`: Integer that increases with each release (1, 2, 3, ...)
- `versionName`: User-facing version string (1.0.0, 1.0.1, 1.1.0, ...)

---

## 🔒 Step 5: Configure ProGuard (Optional but Recommended)

### Create proguard-rules.pro

```bash
cd SKS-mobile-V2/android/app
nano proguard-rules.pro
```

Add the following rules:

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Video player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

---

## ✅ Step 6: Verify Environment Configuration

### Check .env file

```bash
cd SKS-mobile-V2
cat .env
```

Ensure production values are set:
```env
# Backend API
API_BASE_URL=https://your-production-api.com

# OneSignal
ONESIGNAL_APP_ID=your_production_onesignal_app_id

# Google Sign-In (if using)
GOOGLE_CLIENT_ID=your_production_google_client_id
```

**⚠️ IMPORTANT:** Use production credentials, not development!

---

## 🏗️ Step 7: Build the APK

### Option A: Build Release APK (Recommended)

```bash
cd SKS-mobile-V2

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Or build split APKs (smaller file size)
flutter build apk --split-per-abi --release
```

### Option B: Build App Bundle (For Google Play Store)

```bash
# Build app bundle (recommended for Play Store)
flutter build appbundle --release
```

---

## 📦 Step 8: Locate Built Files

### APK Location:
```bash
# Single APK (universal)
SKS-mobile-V2/build/app/outputs/flutter-apk/app-release.apk

# Split APKs (if using --split-per-abi)
SKS-mobile-V2/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
SKS-mobile-V2/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
SKS-mobile-V2/build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### App Bundle Location:
```bash
SKS-mobile-V2/build/app/outputs/bundle/release/app-release.aab
```

---

## 🧪 Step 9: Test the APK

### Install on Device

```bash
# Connect Android device via USB
# Enable USB debugging on device

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or use Flutter
flutter install --release
```

### Test Checklist:
- [ ] App launches successfully
- [ ] Login works (phone OTP and Google)
- [ ] OneSignal notifications work
- [ ] Videos play correctly
- [ ] All features functional
- [ ] No crashes or errors
- [ ] Performance is good

---

## 📊 Step 10: Analyze APK Size

```bash
# Analyze APK size
flutter build apk --analyze-size --release

# View detailed size breakdown
flutter build apk --analyze-size --target-platform android-arm64 --release
```

---

## 🚀 Step 11: Optimize APK (Optional)

### Reduce APK Size:

1. **Use Split APKs:**
```bash
flutter build apk --split-per-abi --release
```

2. **Remove Unused Resources:**
```gradle
// In android/app/build.gradle
android {
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
        }
    }
}
```

3. **Compress Images:**
```bash
# Use tools like TinyPNG or ImageOptim
# Compress all images in assets/images/
```

4. **Remove Debug Symbols:**
```bash
flutter build apk --release --no-tree-shake-icons
```

---

## 📱 Step 12: Prepare for Distribution

### For Direct Distribution (APK):

1. **Rename APK:**
```bash
cd build/app/outputs/flutter-apk/
mv app-release.apk sks-app-v1.0.0.apk
```

2. **Create Checksum:**
```bash
shasum -a 256 sks-app-v1.0.0.apk > sks-app-v1.0.0.apk.sha256
```

3. **Test on Multiple Devices:**
- Test on different Android versions
- Test on different screen sizes
- Test on different manufacturers

### For Google Play Store (AAB):

1. **Build App Bundle:**
```bash
flutter build appbundle --release
```

2. **Upload to Play Console:**
- Go to Google Play Console
- Create new release
- Upload `app-release.aab`
- Fill in release notes
- Submit for review

---

## 🔍 Troubleshooting

### Issue: "Keystore not found"
```bash
# Verify keystore path in key.properties
ls -la ~/sks-release-key.jks

# Update storeFile path if needed
```

### Issue: "Signing config not found"
```bash
# Verify key.properties exists
cat android/key.properties

# Verify build.gradle has signing config
cat android/app/build.gradle | grep signingConfig
```

### Issue: "Build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release --verbose
```

### Issue: "APK too large"
```bash
# Use split APKs
flutter build apk --split-per-abi --release

# Enable shrinkResources
# Add to android/app/build.gradle:
# shrinkResources true
# minifyEnabled true
```

### Issue: "App crashes on launch"
```bash
# Check logs
adb logcat | grep flutter

# Build debug APK to see errors
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📋 Complete Build Script

Create a build script for easy building:

```bash
# Create build script
cd SKS-mobile-V2
nano build-release.sh
```

Add the following:

```bash
#!/bin/bash

echo "🏗️  Building SKS Production APK..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build release APK
echo "🔨 Building release APK..."
flutter build apk --release --split-per-abi

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📦 APK files:"
    ls -lh build/app/outputs/flutter-apk/*.apk
    echo ""
    echo "📍 Location: build/app/outputs/flutter-apk/"
else
    echo "❌ Build failed!"
    exit 1
fi
```

Make it executable:
```bash
chmod +x build-release.sh
```

Run it:
```bash
./build-release.sh
```

---

## 🎯 Quick Reference

### Build Commands:

```bash
# Universal APK (works on all devices)
flutter build apk --release

# Split APKs (smaller size, one per architecture)
flutter build apk --split-per-abi --release

# App Bundle (for Play Store)
flutter build appbundle --release

# Debug APK (for testing)
flutter build apk --debug
```

### File Locations:

```bash
# Universal APK
build/app/outputs/flutter-apk/app-release.apk

# Split APKs
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk

# App Bundle
build/app/outputs/bundle/release/app-release.aab
```

### Version Update:

```gradle
// android/app/build.gradle
defaultConfig {
    versionCode 2        // Increment this
    versionName "1.0.1"  // Update this
}
```

---

## ✅ Pre-Release Checklist

Before distributing your APK:

- [ ] Keystore created and secured
- [ ] key.properties configured
- [ ] build.gradle updated with signing config
- [ ] App version updated (versionCode and versionName)
- [ ] Production environment variables set
- [ ] ProGuard rules configured
- [ ] APK built successfully
- [ ] APK tested on real device
- [ ] All features working
- [ ] No crashes or errors
- [ ] Performance acceptable
- [ ] APK size reasonable
- [ ] Checksum created
- [ ] Release notes prepared

---

## 🎉 Summary

You now have a production-ready APK! The file is located at:
```
SKS-mobile-V2/build/app/outputs/flutter-apk/app-release.apk
```

**Next Steps:**
1. Test thoroughly on multiple devices
2. Distribute to users or upload to Play Store
3. Monitor for crashes and issues
4. Prepare for updates (increment versionCode)

**Remember:**
- Keep your keystore safe!
- Never commit key.properties or keystore to Git
- Test on real devices before distribution
- Monitor app performance and crashes

---

**Build Date:** April 14, 2026
**Status:** ✅ READY FOR PRODUCTION
