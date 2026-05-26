# How to Create APK - Complete Guide

## Quick Method (Debug APK)

### Step 1: Open Terminal
In Android Studio, open Terminal (bottom panel)

### Step 2: Build APK
```bash
flutter build apk --debug
```

### Step 3: Find APK
APK will be created at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

**That's it!** You can now install this APK on any Android device.

---

## Production Method (Release APK)

### Step 1: Build Release APK
```bash
flutter build apk --release
```

### Step 2: Find APK
```
build/app/outputs/flutter-apk/app-release.apk
```

**Size:** ~20-50 MB (smaller than debug)
**Performance:** Optimized and faster

---

## Split APKs (Smaller Size)

### Build for Specific Architecture:
```bash
# For most devices (ARM 64-bit)
flutter build apk --target-platform android-arm64 --release

# For older devices (ARM 32-bit)
flutter build apk --target-platform android-arm --release

# For x86 devices (rare)
flutter build apk --target-platform android-x64 --release
```

---

## App Bundle (For Play Store)

### Build App Bundle:
```bash
flutter build appbundle --release
```

### Find Bundle:
```
build/app/outputs/bundle/release/app-release.aab
```

**Use this for Google Play Store submission**

---

## Complete Build Commands

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for distribution)
flutter build apk --release

# Split APKs (smaller size)
flutter build apk --split-per-abi --release

# App Bundle (for Play Store)
flutter build appbundle --release

# Clean build (if issues)
flutter clean
flutter pub get
flutter build apk --release
```

---

## APK Locations

After building, find your APK here:

```
SKS-mobile-V2/
└── build/
    └── app/
        └── outputs/
            ├── flutter-apk/
            │   ├── app-debug.apk          (Debug APK)
            │   ├── app-release.apk        (Release APK)
            │   ├── app-armeabi-v7a-release.apk  (ARM 32-bit)
            │   └── app-arm64-v8a-release.apk    (ARM 64-bit)
            └── bundle/
                └── release/
                    └── app-release.aab    (App Bundle)
```

---

## Install APK on Device

### Method 1: Using ADB
```bash
# Install on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Install on specific device
adb -s <device-id> install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual Transfer
1. Copy APK to phone (USB, email, cloud)
2. Open APK on phone
3. Tap "Install"
4. Allow "Install from unknown sources" if prompted

---

## Build Sizes

| Build Type | Size | Use Case |
|------------|------|----------|
| Debug APK | ~50-80 MB | Testing only |
| Release APK | ~20-50 MB | Distribution |
| Split APK (ARM64) | ~15-30 MB | Specific devices |
| App Bundle | ~20-40 MB | Play Store |

---

## Before Building Release APK

### 1. Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Change to 1.0.1+2, etc.
```

### 2. Update App Name
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Your App Name"
    ...>
```

### 3. Update Package Name (if needed)
Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.spiritual.app"
    ...
}
```

---

## Signing APK (For Production)

### Step 1: Create Keystore
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 2: Create key.properties
Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>/upload-keystore.jks
```

### Step 3: Update build.gradle
Edit `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
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
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 4: Build Signed APK
```bash
flutter build apk --release
```

---

## Troubleshooting

### Issue: "Build failed"
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: "APK too large"
```bash
# Use split APKs
flutter build apk --split-per-abi --release
```

### Issue: "Signing error"
- Check `key.properties` file exists
- Verify keystore path is correct
- Ensure passwords are correct

---

## Quick Reference

| Command | Output | Size | Use |
|---------|--------|------|-----|
| `flutter build apk` | app-release.apk | ~30 MB | Distribution |
| `flutter build apk --debug` | app-debug.apk | ~60 MB | Testing |
| `flutter build apk --split-per-abi` | Multiple APKs | ~20 MB each | Smaller size |
| `flutter build appbundle` | app-release.aab | ~25 MB | Play Store |

---

## Summary

**For Testing:**
```bash
flutter build apk --debug
```
APK: `build/app/outputs/flutter-apk/app-debug.apk`

**For Distribution:**
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

**For Play Store:**
```bash
flutter build appbundle --release
```
Bundle: `build/app/outputs/bundle/release/app-release.aab`

**That's it!** 🚀
