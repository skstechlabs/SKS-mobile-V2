# Manual Flutter Installation Guide

Since automated package managers (winget/chocolatey) are not available, follow these steps to install Flutter manually:

## 📥 Step 1: Download Flutter SDK

1. Open your browser and go to: **https://docs.flutter.dev/get-started/install/windows**
2. Click on **"Download Flutter SDK"** button
3. Download the latest stable release (e.g., `flutter_windows_3.x.x-stable.zip`)
4. File size: ~1.5 GB

## 📂 Step 2: Extract Flutter

1. Create a folder: `C:\src` (if it doesn't exist)
2. Extract the downloaded ZIP file to `C:\src\`
3. You should now have: `C:\src\flutter\`

## 🔧 Step 3: Add Flutter to PATH

### Option A: Using PowerShell (Run as Administrator)

```powershell
# Add Flutter to PATH permanently
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\src\flutter\bin",
    "Machine"
)

# Refresh current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### Option B: Using System Settings (GUI)

1. Press `Win + X` and select **System**
2. Click **Advanced system settings**
3. Click **Environment Variables**
4. Under **System variables**, find and select **Path**
5. Click **Edit**
6. Click **New**
7. Add: `C:\src\flutter\bin`
8. Click **OK** on all dialogs
9. **Restart PowerShell** for changes to take effect

## ✅ Step 4: Verify Installation

Open a **NEW** PowerShell window and run:

```powershell
flutter --version
```

You should see output like:
```
Flutter 3.x.x • channel stable
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart 3.x.x
```

## 🔍 Step 5: Run Flutter Doctor

```powershell
flutter doctor -v
```

This will check your environment and show what needs to be installed.

## 📱 Step 6: Install Android Studio (if needed)

If `flutter doctor` shows Android toolchain is missing:

1. Download Android Studio: **https://developer.android.com/studio**
2. Install Android Studio
3. Open Android Studio
4. Go to: **Settings → Appearance & Behavior → System Settings → Android SDK**
5. Install:
   - Android SDK Platform (API 34)
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android SDK Command-line Tools

## 📜 Step 7: Accept Android Licenses

```powershell
flutter doctor --android-licenses
```

Press `y` to accept all licenses.

## 📦 Step 8: Setup Project

```powershell
cd s:\SKS-mobile-V2
flutter pub get
```

## ▶️ Step 9: Run the App

```powershell
# With local backend
flutter run --dart-define-from-file=.env.local.json

# With production backend
flutter run --dart-define-from-file=.env.classes-service.json
```

## 🎯 Quick Commands After Installation

```powershell
# Check Flutter version
flutter --version

# Check environment
flutter doctor -v

# List devices
flutter devices

# Install dependencies
flutter pub get

# Run app
flutter run --dart-define-from-file=.env.local.json
```

## 🐛 Troubleshooting

### Flutter command not found after installation

**Solution:** Restart PowerShell or run:
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### Android licenses not accepted

**Solution:**
```powershell
flutter doctor --android-licenses
```

### Gradle build failed

**Solution:**
```powershell
cd s:\SKS-mobile-V2
flutter clean
flutter pub get
flutter run
```

## ✅ Success Checklist

- [ ] Flutter SDK downloaded and extracted to `C:\src\flutter`
- [ ] Flutter added to PATH
- [ ] `flutter --version` works
- [ ] `flutter doctor` shows no critical errors
- [ ] Android licenses accepted
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] Device connected or emulator running
- [ ] App runs successfully

## 📞 Need Help?

If you encounter issues:
1. Check Flutter documentation: https://docs.flutter.dev
2. Run `flutter doctor -v` for detailed diagnostics
3. Ensure you've restarted PowerShell after adding to PATH

Good luck! 🚀
