# 🖥️ Android Emulator Setup Guide

## 📥 Step 1: Install Android Studio

### Download
1. Go to https://developer.android.com/studio
2. Download Android Studio for your OS
3. Run installer

### Installation
- **Windows**: Run `.exe` file
- **Mac**: Drag to Applications folder
- **Linux**: Extract and run `studio.sh`

### First Launch
1. Open Android Studio
2. Complete setup wizard
3. Install Android SDK (automatic)
4. Wait for downloads to complete

## 📱 Step 2: Create Virtual Device

### Using Device Manager (Recommended)

1. **Open Device Manager**
   - Click "More Actions" (3 dots) on welcome screen
   - Select "Virtual Device Manager"
   - OR: Tools → Device Manager (if project open)

2. **Create New Device**
   - Click "Create Device" button
   
3. **Select Hardware**
   - Category: Phone
   - **Recommended devices**:
     - Pixel 5 (1080 x 2340, 440 dpi)
     - Pixel 6 (1080 x 2400, 420 dpi)
     - Pixel 7 (1080 x 2400, 420 dpi)
   - Click "Next"

4. **Select System Image**
   - **Recommended**: 
     - Android 13.0 (API 33) - Tiramisu
     - Android 14.0 (API 34) - UpsideDownCake
   - Click "Download" next to system image
   - Wait for download (1-2 GB)
   - Click "Next"

5. **Configure AVD**
   - AVD Name: `Pixel_5_API_33`
   - Startup orientation: Portrait
   - **Advanced Settings** (optional):
     - RAM: 4096 MB (4 GB)
     - VM heap: 512 MB
     - Internal Storage: 2048 MB
     - SD card: 512 MB
   - Click "Finish"

## ▶️ Step 3: Start Emulator

### From Android Studio
1. Open Device Manager
2. Find your device (e.g., Pixel_5_API_33)
3. Click ▶️ (Play button)
4. Wait 1-2 minutes for boot
5. Emulator window opens

### From Command Line
```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_5_API_33
```

### First Boot
- Takes 2-3 minutes
- Shows Android boot animation
- Loads to home screen
- Ready to use!

## 🚀 Step 4: Run Flutter App

### Check Device is Detected
```bash
flutter devices
```

You should see:
```
Pixel 5 API 33 (mobile) • emulator-5554 • android • Android 13 (API 33)
```

### Run App
```bash
flutter run
```

Or specify device:
```bash
flutter run -d emulator-5554
```

## 🎯 Quick Start Commands

```bash
# 1. Check if emulator is running
flutter devices

# 2. If no emulator, start from Android Studio
# Device Manager → Click ▶️

# 3. Run app
flutter run

# 4. Hot reload (after code changes)
# Press 'r' in terminal

# 5. Hot restart (full restart)
# Press 'R' in terminal
```

## 🖥️ Emulator Controls

### Toolbar (Right side of emulator)
- 🔙 Back button
- 🏠 Home button
- ⬜ Recent apps
- 🔊 Volume up/down
- 🔄 Rotate screen
- 📸 Screenshot
- ⚙️ Settings

### Keyboard Shortcuts
- `Ctrl + M` (Windows/Linux) or `Cmd + M` (Mac): Menu
- `Ctrl + Left/Right`: Rotate screen
- `Ctrl + Up/Down`: Volume
- `Ctrl + P`: Power button

## 📊 Recommended Emulator Configurations

### For Development (Fast)
- Device: Pixel 5
- System Image: Android 13 (API 33)
- RAM: 2048 MB
- Graphics: Automatic

### For Testing (Realistic)
- Device: Pixel 6
- System Image: Android 14 (API 34)
- RAM: 4096 MB
- Graphics: Hardware

### For Low-End Testing
- Device: Pixel 3a
- System Image: Android 11 (API 30)
- RAM: 1536 MB
- Graphics: Software

## 🐛 Troubleshooting

### Issue: Emulator won't start

**Solution 1: Enable Virtualization**
1. Restart computer
2. Enter BIOS (F2, F10, or Del during boot)
3. Find "Virtualization Technology" or "Intel VT-x"
4. Enable it
5. Save and exit

**Solution 2: Install Intel HAXM (Windows)**
1. Open Android Studio
2. Tools → SDK Manager
3. SDK Tools tab
4. Check "Intel x86 Emulator Accelerator (HAXM)"
5. Click "Apply"

**Solution 3: Use ARM Image**
1. Create new AVD
2. Select ARM system image instead of x86
3. Slower but more compatible

### Issue: Emulator is very slow

**Solution 1: Increase RAM**
1. Device Manager → Edit device
2. Show Advanced Settings
3. RAM: 4096 MB or more
4. Click "Finish"

**Solution 2: Enable Hardware Graphics**
1. Device Manager → Edit device
2. Graphics: Hardware - GLES 2.0
3. Click "Finish"

**Solution 3: Close Other Apps**
- Close Chrome, VS Code, etc.
- Free up system resources

### Issue: "INSTALL_FAILED_INSUFFICIENT_STORAGE"

**Solution**: Increase internal storage
1. Device Manager → Edit device
2. Show Advanced Settings
3. Internal Storage: 4096 MB or more
4. Click "Finish"

### Issue: Emulator not detected by Flutter

**Solution**: Restart ADB
```bash
adb kill-server
adb start-server
flutter devices
```

### Issue: Black screen on emulator

**Solution**: Change graphics mode
1. Device Manager → Edit device
2. Graphics: Software - GLES 2.0
3. Click "Finish"
4. Restart emulator

## 🎨 Multiple Emulators

### Create Multiple Devices
1. Create Pixel 5 (Android 13) - for development
2. Create Pixel 6 (Android 14) - for testing
3. Create Pixel 3a (Android 11) - for compatibility

### Run on Specific Emulator
```bash
# List all emulators
flutter devices

# Run on specific emulator
flutter run -d emulator-5554
```

## 📱 Emulator vs Real Device

| Feature | Emulator | Real Device |
|---------|----------|-------------|
| Setup Time | 10 minutes | 2 minutes |
| Performance | Slower | Faster |
| Camera | Simulated | Real |
| GPS | Simulated | Real |
| Sensors | Simulated | Real |
| Notifications | ✅ Works | ✅ Works |
| Hot Reload | ✅ Fast | ✅ Fast |
| Cost | Free | Need device |

## 🚀 Best Practices

### For Development
1. Use emulator for quick testing
2. Use hot reload for fast iteration
3. Test on real device before release

### For Testing
1. Test on multiple Android versions
2. Test on different screen sizes
3. Test on real device for final validation

### Performance Tips
1. Close unused emulators
2. Use hardware graphics
3. Allocate enough RAM (4GB+)
4. Use SSD for Android SDK

## 📍 Quick Reference

### Start Emulator
```bash
emulator -avd Pixel_5_API_33
```

### List Emulators
```bash
emulator -list-avds
```

### Check Running Devices
```bash
flutter devices
```

### Run App
```bash
flutter run
```

### Install APK
```bash
adb install app-debug.apk
```

## ✅ Verification Checklist

- [ ] Android Studio installed
- [ ] Virtual device created
- [ ] Emulator starts successfully
- [ ] Flutter detects emulator
- [ ] App runs on emulator
- [ ] Hot reload works
- [ ] Notifications work

## 🎯 Next Steps

1. **Create emulator** (10 minutes)
2. **Start emulator** (2 minutes)
3. **Run app** (1 minute)
4. **Test notifications** (5 minutes)

---

**Ready to start?**

1. Open Android Studio
2. Device Manager → Create Device
3. Select Pixel 5 → Android 13
4. Click Finish
5. Click ▶️ to start
6. Run `flutter run`

Done! 🎉
