# Flutter Installation & Mobile App Setup Guide

## 📋 Prerequisites

Before installing Flutter, ensure you have:
- Windows 10 or later (64-bit)
- At least 2.5 GB of free disk space
- Git for Windows
- PowerShell 5.0 or newer

## 🚀 Step 1: Install Flutter

### Option 1: Using Winget (Recommended)

```powershell
# Open PowerShell as Administrator
winget install --id=Google.Flutter -e
```

### Option 2: Manual Installation

1. **Download Flutter SDK:**
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the latest stable release (Flutter SDK)
   - Extract to: `C:\src\flutter`

2. **Add Flutter to PATH:**
   ```powershell
   # Open PowerShell as Administrator
   $env:Path += ";C:\src\flutter\bin"
   [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
   ```

3. **Verify Installation:**
   ```powershell
   flutter --version
   flutter doctor
   ```

## 🔧 Step 2: Install Android Studio

1. **Download Android Studio:**
   - Visit: https://developer.android.com/studio
   - Download and install Android Studio

2. **Install Android SDK:**
   - Open Android Studio
   - Go to: Settings → Appearance & Behavior → System Settings → Android SDK
   - Install:
     - Android SDK Platform (API 34 or latest)
     - Android SDK Build-Tools
     - Android SDK Platform-Tools
     - Android SDK Command-line Tools

3. **Accept Android Licenses:**
   ```powershell
   flutter doctor --android-licenses
   # Press 'y' to accept all licenses
   ```

## 📱 Step 3: Setup Android Emulator (Optional)

1. **Create Virtual Device:**
   - Open Android Studio
   - Tools → Device Manager
   - Create Device → Select Pixel 7 Pro
   - Select System Image: API 34 (Android 14)
   - Finish

2. **Start Emulator:**
   ```powershell
   # List available emulators
   flutter emulators
   
   # Start emulator
   flutter emulators --launch <emulator_id>
   ```

## 🔌 Step 4: Connect Physical Device (Alternative)

1. **Enable Developer Options on Android:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back → Developer Options
   - Enable "USB Debugging"

2. **Connect Device:**
   - Connect phone via USB
   - Allow USB debugging on phone
   - Verify connection:
     ```powershell
     flutter devices
     ```

## 📦 Step 5: Setup Flutter Project

### Navigate to Project Directory

```powershell
cd s:\SKS-mobile-V2
```

### Install Dependencies

```powershell
# Get all Flutter packages
flutter pub get

# Clean build (if needed)
flutter clean
flutter pub get
```

### Verify Project Setup

```powershell
# Check for issues
flutter doctor -v

# Analyze project
flutter analyze
```

## 🔑 Step 6: Configure Environment

The project uses `.env.classes-service.json` for configuration.

**Current Configuration:**
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9",
  "GOOGLE_CLIENT_ID": "294856785598-qivhqf2ehn5p0rs1830dt9mt030ort9p.apps.googleusercontent.com"
}
```

**For Local Development:**

Create `.env.local.json`:
```json
{
  "MSG91_WIDGET_ID": "366379717055333935353237",
  "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
  "API_BASE_URL": "http://localhost:3012",
  "FIREBASE_API_KEY": "AIzaSyBXUN42KBq3eGoMgib4ZWDbYYFFc0Ft458",
  "FIREBASE_AUTH_DOMAIN": "sks-login-mobile.firebaseapp.com",
  "FIREBASE_PROJECT_ID": "sks-login-mobile",
  "FIREBASE_STORAGE_BUCKET": "sks-login-mobile.firebasestorage.app",
  "FIREBASE_MESSAGING_SENDER_ID": "294856785598",
  "FIREBASE_WEB_APP_ID": "1:294856785598:web:placeholder",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9",
  "GOOGLE_CLIENT_ID": "294856785598-qivhqf2ehn5p0rs1830dt9mt030ort9p.apps.googleusercontent.com",
  "IOS_NOTIFICATIONS_API_KEY": "AIzaSyBKh7tIinn5KBcZIzZlFfWMkfh6CR8IwXc",
  "R2_ENDPOINT": "https://dfca0f529df9f308d904bbd559e88b81.r2.cloudflarestorage.com",
  "R2_ACCESS_KEY_ID": "9b9b28d52733816213e08beb193fc415",
  "R2_SECRET_ACCESS_KEY": "655c82825795342f1eb8ce5aa662cac849854e8cc869e7b794a377b451daf7bc",
  "R2_BUCKET_NAME": "sadhaks",
  "R2_PUBLIC_URL": "https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev"
}
```

## ▶️ Step 7: Run the App

### Run with Production API (Default)

```powershell
flutter run --dart-define-from-file=.env.classes-service.json
```

### Run with Local API (Development)

```powershell
flutter run --dart-define-from-file=.env.local.json
```

### Run on Specific Device

```powershell
# List devices
flutter devices

# Run on specific device
flutter run -d <device_id> --dart-define-from-file=.env.local.json
```

### Run in Debug Mode (with Hot Reload)

```powershell
flutter run --debug --dart-define-from-file=.env.local.json
```

### Run in Release Mode (Optimized)

```powershell
flutter run --release --dart-define-from-file=.env.classes-service.json
```

## 🔍 Step 8: Test Backend Connection

### Check Backend Services

```powershell
# API Gateway (Port 3012)
curl http://localhost:3012/health

# Classes Service (Port 3014)
curl http://localhost:3014/health

# Mobile Backend Service (Port 3015)
curl http://localhost:3015/health
```

### Test API from Flutter

The app will automatically connect to the API based on `API_BASE_URL` in your environment file.

**Production:** `https://app.sivakundalini.org`  
**Local:** `http://localhost:3012`

## 🎥 Step 9: Test HLS Video Streaming

### Test Video Config API

```powershell
# Get video configuration (requires auth)
curl http://localhost:3014/api/classes-v2/days/1/video-config?language=te \
  -H "Authorization: Bearer <firebase_token>"
```

### Expected Response

```json
{
  "success": true,
  "videoConfig": {
    "streamingType": "hls",
    "hlsUrl": "https://pub-9129a0cdf4ad4862bcc4c1a92c619c17.r2.dev/classes/videos/1/1/te/master.m3u8",
    "hlsBasePath": "classes/videos/1/1/te",
    "availableQualities": ["1080p", "720p", "480p", "360p"],
    "thumbnailUrl": "https://pub-9129a0cdf4ad4862bcc4c1a92c619c17.r2.dev/classes/videos/1/1/te/thumbnail.jpg",
    "language": "te",
    "allowSkip": false,
    "videoDurationSeconds": 1800
  }
}
```

## 🐛 Troubleshooting

### Flutter Not Recognized

```powershell
# Add Flutter to PATH manually
$env:Path += ";C:\src\flutter\bin"
```

### Android Licenses Not Accepted

```powershell
flutter doctor --android-licenses
# Press 'y' for all
```

### Gradle Build Failed

```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Hot Reload Not Working

```powershell
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

### Device Not Detected

```powershell
# Check ADB
adb devices

# Restart ADB
adb kill-server
adb start-server

# Check Flutter devices
flutter devices
```

### Build Errors

```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## 📊 Useful Flutter Commands

```powershell
# Check Flutter installation
flutter doctor -v

# List devices
flutter devices

# List emulators
flutter emulators

# Run app
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Format code
flutter format .

# Update packages
flutter pub upgrade

# Clean build
flutter clean
```

## 🎯 Quick Start Checklist

- [ ] Install Flutter SDK
- [ ] Install Android Studio
- [ ] Accept Android licenses
- [ ] Setup emulator or connect device
- [ ] Navigate to project: `cd s:\SKS-mobile-V2`
- [ ] Install dependencies: `flutter pub get`
- [ ] Check setup: `flutter doctor`
- [ ] Create `.env.local.json` for local development
- [ ] Start backend services (PM2)
- [ ] Run app: `flutter run --dart-define-from-file=.env.local.json`

## 🔗 Backend Services Required

Make sure these services are running:

```powershell
# Check PM2 services
pm2 list

# Should show:
# - api-gateway (Port 3012)
# - classes-service (Port 3014)
# - mobile-backend-service (Port 3015)
# - google-login-service (Port 3010)
# - otp-login-service (Port 3011)
# - notification-service (Port 3016)
```

## 📱 App Features to Test

1. **Authentication:**
   - Google Sign-In
   - Phone OTP Login

2. **Classes:**
   - View all classes
   - Enroll in class
   - View class days

3. **Video Streaming:**
   - Play HLS video
   - Quality selection
   - Progress tracking
   - Resume playback

4. **Redis Caching:**
   - Fast video config loading
   - Cached class data
   - User preferences

## 🚀 Next Steps

After Flutter is installed and running:

1. Test authentication flow
2. Test class enrollment
3. Test video playback with HLS
4. Test Redis caching (check response times)
5. Test multi-language support
6. Test offline functionality

## 📚 Resources

- Flutter Docs: https://docs.flutter.dev
- Flutter Cookbook: https://docs.flutter.dev/cookbook
- Dart Language: https://dart.dev
- Android Studio: https://developer.android.com/studio
- Firebase: https://firebase.google.com/docs/flutter/setup

## ✅ Success Indicators

You'll know everything is working when:

- ✅ `flutter doctor` shows no errors
- ✅ App builds successfully
- ✅ App connects to backend
- ✅ Authentication works
- ✅ Videos play smoothly
- ✅ Redis cache improves performance
- ✅ Hot reload works

Good luck! 🎉
