# 📱 Manual APK Installation Guide

## 🎯 Quick Installation (Copy-Paste These Commands)

Since ADB is not in your PATH, use the full path to ADB:

### Step 1: Uninstall Old Version
```bash
~/Library/Android/sdk/platform-tools/adb uninstall com.spiritual.app
```

### Step 2: Install Fresh APK
```bash
~/Library/Android/sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Step 3: Launch App
```bash
~/Library/Android/sdk/platform-tools/adb shell am start -n com.spiritual.app/.MainActivity
```

---

## 🚀 One-Line Installation

Copy and paste this entire command:

```bash
~/Library/Android/sdk/platform-tools/adb uninstall com.spiritual.app && ~/Library/Android/sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk && ~/Library/Android/sdk/platform-tools/adb shell am start -n com.spiritual.app/.MainActivity
```

---

## 📱 Alternative: Install via File Transfer

If ADB commands don't work, transfer the APK file to your phone:

### Method 1: USB File Transfer

1. **Connect phone to Mac via USB**

2. **Open Android File Transfer** (if not installed, download from android.com/filetransfer)

3. **Copy APK to phone**
   - Navigate to: `build/app/outputs/flutter-apk/`
   - Copy `app-arm64-v8a-release.apk` to phone's Downloads folder

4. **On phone**
   - Open file manager
   - Go to Downloads
   - Tap `app-arm64-v8a-release.apk`
   - Allow "Install from unknown sources" if prompted
   - Tap "Install"
   - Wait for installation
   - Tap "Open"

### Method 2: AirDrop (Mac to iPhone, then to Android)

1. **AirDrop APK to your iPhone** (if you have one)
2. **Upload to Google Drive or email**
3. **Download on Android device**
4. **Install from Downloads**

### Method 3: Cloud Storage

1. **Upload APK to Google Drive**
   - Go to drive.google.com
   - Upload `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

2. **Download on Android device**
   - Open Google Drive app
   - Download the APK
   - Tap to install

---

## 🔧 Add ADB to PATH (Optional - For Future Use)

To use `adb` command without full path:

### Temporary (Current Terminal Session)
```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
```

### Permanent (All Terminal Sessions)

Add to your shell profile:

**For Bash** (~/.bash_profile or ~/.bashrc):
```bash
echo 'export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"' >> ~/.bash_profile
source ~/.bash_profile
```

**For Zsh** (~/.zshrc):
```bash
echo 'export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"' >> ~/.zshrc
source ~/.zshrc
```

After this, you can use `adb` directly:
```bash
adb devices
adb install app.apk
```

---

## ✅ Verification Commands

### Check if device is connected
```bash
~/Library/Android/sdk/platform-tools/adb devices
```

Should show:
```
List of devices attached
XXXXXXXXXX      device
```

### Check if app is installed
```bash
~/Library/Android/sdk/platform-tools/adb shell pm list packages | grep spiritual
```

Should show:
```
package:com.spiritual.app
```

### View app logs
```bash
~/Library/Android/sdk/platform-tools/adb logcat | grep -i onesignal
```

---

## 🎯 Recommended: Use File Transfer Method

Since ADB setup requires extra steps, the easiest way is:

1. **Copy APK to phone via USB**
   - Connect phone to Mac
   - Open Android File Transfer
   - Copy `app-arm64-v8a-release.apk` to Downloads

2. **Install on phone**
   - Open file manager
   - Tap APK file
   - Install

3. **Test immediately**
   - Open app
   - Test notification permission

---

## 📍 APK Location

The fresh APK is at:
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

You can also find it in Finder:
1. Open Finder
2. Go to your project folder
3. Navigate to: `build/app/outputs/flutter-apk/`
4. Find `app-arm64-v8a-release.apk`
5. Copy to phone

---

## 🚀 Quick Start (Choose One Method)

### Method 1: ADB Commands (If device connected)
```bash
~/Library/Android/sdk/platform-tools/adb uninstall com.spiritual.app
~/Library/Android/sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Method 2: File Transfer (Easiest)
1. Connect phone via USB
2. Open Android File Transfer
3. Copy APK to phone
4. Install from file manager

### Method 3: Cloud Storage
1. Upload APK to Google Drive
2. Download on phone
3. Install

---

## ✅ After Installation

1. Open app on phone
2. Login or skip
3. Click "Allow Notifications"
4. Should work without "Missing Plugin Exception"!
5. Grant system permission
6. Navigate to home screen

---

## 🐛 Troubleshooting

### "Android File Transfer not opening"
- Download from: https://www.android.com/filetransfer/
- Install and try again

### "Install blocked" on phone
- Go to Settings → Security
- Enable "Install from unknown sources"
- Try installing again

### "App not installed" error
- Uninstall old version first from phone
- Settings → Apps → SKS → Uninstall
- Try installing again

---

## 📚 Related Documentation

- [Final Installation Steps](docs/FINAL_INSTALLATION_STEPS.md)
- [Persistent Plugin Exception Fix](docs/troubleshooting/PERSISTENT_PLUGIN_EXCEPTION_FIX.md)

---

**Recommended**: Use the file transfer method - it's the easiest and most reliable!
