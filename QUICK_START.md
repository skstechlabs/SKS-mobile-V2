# Quick Start Guide - SKS Mobile App

## 🚀 Install Flutter (Choose One Method)

### Method 1: Automated Script (Recommended)

```powershell
# Run as Administrator
cd s:\SKS-mobile-V2
.\install-flutter.ps1
```

### Method 2: Using Winget

```powershell
# Run as Administrator
winget install --id=Google.Flutter -e
```

### Method 3: Manual Installation

1. Download Flutter: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`

## ✅ Verify Installation

```powershell
flutter --version
flutter doctor
```

## 📦 Setup Project

```powershell
cd s:\SKS-mobile-V2
flutter pub get
```

## ▶️ Run the App

### With Local Backend (Development)

```powershell
flutter run --dart-define-from-file=.env.local.json
```

### With Production Backend

```powershell
flutter run --dart-define-from-file=.env.classes-service.json
```

## 🔧 Backend Services

Make sure these are running:

```powershell
pm2 list

# Should show:
# ✅ api-gateway (Port 3012)
# ✅ classes-service (Port 3014)
# ✅ mobile-backend-service (Port 3015)
```

## 📱 Connect Device

### Option 1: Android Emulator

```powershell
# List emulators
flutter emulators

# Start emulator
flutter emulators --launch <emulator_id>
```

### Option 2: Physical Device

1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter devices`

## 🎯 Test Features

1. **Authentication** - Google Sign-In / Phone OTP
2. **Classes** - View and enroll in classes
3. **Video Streaming** - HLS video playback
4. **Redis Caching** - Fast data loading

## 🐛 Troubleshooting

### Flutter not found

```powershell
$env:Path += ";C:\src\flutter\bin"
```

### Build errors

```powershell
flutter clean
flutter pub get
flutter run
```

### Device not detected

```powershell
adb kill-server
adb start-server
flutter devices
```

## 📚 Documentation

- **FLUTTER_SETUP_GUIDE.md** - Complete installation guide
- **CACHE_VALUE_EXPLANATION.md** - Redis caching explained
- **HLS_FOLDER_STRUCTURE.md** - Video streaming structure

## ✨ Quick Commands

```powershell
# Run app
flutter run --dart-define-from-file=.env.local.json

# Hot reload (press 'r' in terminal)
# Hot restart (press 'R' in terminal)
# Quit (press 'q' in terminal)

# Build APK
flutter build apk --release

# Check devices
flutter devices

# Analyze code
flutter analyze
```

## 🎉 Success!

You're ready when:
- ✅ Flutter doctor shows no errors
- ✅ App builds successfully
- ✅ Backend services are running
- ✅ Device is connected
- ✅ App launches and connects to API

Happy coding! 🚀
