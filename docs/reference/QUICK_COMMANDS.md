# ⚡ Quick Commands Reference

## 🏗️ Build APK

### Debug APK (for testing)
```bash
flutter build apk --debug
```
**Location**: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for production)
```bash
flutter build apk --release
```
**Location**: `build/app/outputs/flutter-apk/app-release.apk`

### Split APK (smaller size)
```bash
flutter build apk --split-per-abi
```

## 📱 Install on Real Device

### Install APK
```bash
# Connect phone via USB first
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Check device connected
```bash
adb devices
```

### Uninstall app
```bash
adb uninstall com.spiritual.app
```

## 🖥️ Virtual Device (Emulator)

### Start emulator
```bash
# From Android Studio: Device Manager → Click ▶️
# OR from command line:
emulator -avd Pixel_5_API_33
```

### List available emulators
```bash
emulator -list-avds
```

### Check running devices
```bash
flutter devices
```

## 🚀 Run App

### Run on any available device
```bash
flutter run
```

### Run on specific device
```bash
flutter run -d emulator-5554
```

### Run on web
```bash
flutter run -d chrome
```

## 🔄 Development

### Hot reload (fast)
Press `r` in terminal

### Hot restart (full restart)
Press `R` in terminal

### Clean build
```bash
flutter clean
flutter pub get
flutter run
```

## 🧪 Testing Workflow

### Option 1: Real Device
```bash
# 1. Build APK
flutter build apk --debug

# 2. Connect phone via USB

# 3. Install
adb install build/app/outputs/flutter-apk/app-debug.apk

# 4. Test on phone!
```

### Option 2: Emulator
```bash
# 1. Start emulator (from Android Studio)

# 2. Run app
flutter run

# 3. Test in emulator!
```

## 📊 Useful Commands

### Check Flutter version
```bash
flutter --version
```

### Check for issues
```bash
flutter doctor
```

### Get dependencies
```bash
flutter pub get
```

### Clean project
```bash
flutter clean
```

### Analyze code
```bash
flutter analyze
```

## 🎯 Complete Testing Flow

```bash
# 1. Clean build
flutter clean && flutter pub get

# 2. Build APK
flutter build apk --debug

# 3. Check devices
flutter devices

# 4a. Install on real device
adb install build/app/outputs/flutter-apk/app-debug.apk

# OR

# 4b. Run on emulator
flutter run

# 5. Test notifications!
```

## 📍 File Locations

### APK files
```
build/app/outputs/flutter-apk/
├── app-debug.apk
├── app-release.apk
└── app-arm64-v8a-release.apk (if split)
```

### Android config
```
android/app/build.gradle
android/app/src/main/AndroidManifest.xml
```

### Environment config
```
.env.json
lib/core/constants/app_env.dart
```

## 🐛 Quick Fixes

### Device not detected
```bash
adb kill-server
adb start-server
adb devices
```

### Build failed
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Emulator won't start
- Enable virtualization in BIOS
- Increase RAM allocation
- Use ARM system image

---

**Most Common Commands:**

```bash
# Build APK
flutter build apk --debug

# Install on phone
adb install build/app/outputs/flutter-apk/app-debug.apk

# Run on emulator
flutter run

# Check devices
flutter devices
```
