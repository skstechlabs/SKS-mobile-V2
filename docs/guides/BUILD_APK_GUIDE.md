# 📦 Build APK & Test on Real Device

## 🚀 Quick Commands

### Build APK (Debug - for testing)
```bash
flutter build apk --debug
```

### Build APK (Release - for production)
```bash
flutter build apk --release
```

### Build APK (Split by ABI - smaller size)
```bash
flutter build apk --split-per-abi
```

## 📍 Where to Find APK

After building, APK will be at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

Or for release:
```
build/app/outputs/flutter-apk/app-release.apk
```

## 📱 Install APK on Real Device

### Method 1: USB Cable (Recommended)

1. **Enable Developer Mode on Phone**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - "You are now a developer!" message appears

2. **Enable USB Debugging**
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
   - Enable "Install via USB" (if available)

3. **Connect Phone to Computer**
   - Use USB cable
   - On phone: Allow USB debugging when prompted
   - Select "File Transfer" mode

4. **Install APK**
   ```bash
   # Check if device is connected
   adb devices
   
   # Install APK
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

### Method 2: Transfer APK File

1. **Build APK**
   ```bash
   flutter build apk --debug
   ```

2. **Copy APK to Phone**
   - Connect phone via USB
   - Copy `build/app/outputs/flutter-apk/app-debug.apk` to phone
   - Or use Google Drive, WhatsApp, Email, etc.

3. **Install on Phone**
   - Open file manager on phone
   - Navigate to APK file
   - Tap to install
   - Allow "Install from unknown sources" if prompted

### Method 3: Direct Install (if device connected)
```bash
# Build and install in one command
flutter install
```

## 🖥️ Test with Virtual Device (Android Emulator)

### Option 1: Using Android Studio (Easiest)

#### Step 1: Install Android Studio
1. Download from https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio
4. Complete setup wizard

#### Step 2: Create Virtual Device
1. Open Android Studio
2. Click "More Actions" → "Virtual Device Manager"
   - Or: Tools → Device Manager
3. Click "Create Device"
4. Select device:
   - **Recommended**: Pixel 5 or Pixel 6
   - Category: Phone
   - Click "Next"
5. Select system image:
   - **Recommended**: Android 13 (API 33) or Android 14 (API 34)
   - Click "Download" if not installed
   - Click "Next"
6. Configure AVD:
   - Name: Pixel_5_API_33
   - Click "Finish"

#### Step 3: Start Emulator
1. In Device Manager, click ▶️ (Play button) next to your device
2. Wait for emulator to boot (1-2 minutes first time)
3. Emulator window opens

#### Step 4: Run App
```bash
# Check if emulator is detected
flutter devices

# Run app
flutter run
```

### Option 2: Using Command Line

#### Create Emulator
```bash
# List available system images
sdkmanager --list | grep system-images

# Download system image (if needed)
sdkmanager "system-images;android-33;google_apis;x86_64"

# Create AVD
avdmanager create avd -n Pixel_5_API_33 -k "system-images;android-33;google_apis;x86_64" -d pixel_5
```

#### Start Emulator
```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_5_API_33
```

#### Run App
```bash
flutter run
```

## 🎯 Complete Testing Workflow

### For Real Device

```bash
# 1. Build APK
flutter build apk --debug

# 2. Connect phone via USB

# 3. Check device is connected
adb devices

# 4. Install APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# 5. Open app on phone and test!
```

### For Virtual Device

```bash
# 1. Start Android Studio
# 2. Device Manager → Start emulator

# 3. Wait for emulator to boot

# 4. Run app
flutter run

# 5. Test in emulator!
```

## 📊 APK Build Types Comparison

| Type | Command | Size | Use Case |
|------|---------|------|----------|
| Debug | `flutter build apk --debug` | ~50MB | Testing, debugging |
| Release | `flutter build apk --release` | ~20MB | Production, distribution |
| Split ABI | `flutter build apk --split-per-abi` | ~15MB each | Smaller size, multiple APKs |

## 🔍 Verify APK Built Successfully

```bash
# Check if APK exists
ls -lh build/app/outputs/flutter-apk/

# You should see:
# app-debug.apk (or app-release.apk)
```

## 📱 Testing Checklist

### On Real Device
- [ ] APK installed successfully
- [ ] App opens without crash
- [ ] Login works (Phone OTP / Google)
- [ ] Notification permission screen appears
- [ ] Can grant notification permission
- [ ] Notification permission granted successfully
- [ ] Navigate to home screen
- [ ] Send test notification from OneSignal
- [ ] Notification appears in system tray
- [ ] Tap bell icon, see notification in list
- [ ] Test mark as read
- [ ] Test swipe to delete

### On Virtual Device
- [ ] Emulator starts successfully
- [ ] App runs with `flutter run`
- [ ] All features work same as real device
- [ ] Hot reload works (press 'r')
- [ ] Hot restart works (press 'R')

## 🐛 Troubleshooting

### Issue: "adb: command not found"

**Solution**: Add Android SDK to PATH

**Mac/Linux**:
```bash
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
```

**Windows**:
Add to System Environment Variables:
```
C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools
```

### Issue: "No devices found"

**Solution 1**: Check USB debugging
- Unplug and replug USB cable
- Check phone for "Allow USB debugging" prompt
- Accept the prompt

**Solution 2**: Check ADB
```bash
adb kill-server
adb start-server
adb devices
```

### Issue: "Installation failed"

**Solution**: Uninstall old version first
```bash
adb uninstall com.spiritual.app
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Issue: Emulator won't start

**Solution 1**: Enable virtualization in BIOS
- Restart computer
- Enter BIOS (usually F2, F10, or Del key)
- Enable Intel VT-x or AMD-V
- Save and exit

**Solution 2**: Allocate more RAM
- Android Studio → Device Manager
- Edit device → Show Advanced Settings
- Increase RAM to 4GB or more

**Solution 3**: Use ARM image instead of x86
- Create new AVD with ARM system image
- Slower but more compatible

### Issue: Build failed

**Solution**: Clean and rebuild
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

## 🎨 Build Variants

### Debug APK (Development)
```bash
flutter build apk --debug
```
- Larger size (~50MB)
- Includes debug symbols
- Hot reload enabled
- Performance not optimized

### Release APK (Production)
```bash
flutter build apk --release
```
- Smaller size (~20MB)
- Optimized performance
- No debug symbols
- Requires signing for Play Store

### Profile APK (Performance Testing)
```bash
flutter build apk --profile
```
- Performance profiling enabled
- Optimized but with profiling tools

## 📦 Build for Different ABIs

```bash
# Build separate APKs for each CPU architecture
flutter build apk --split-per-abi
```

This creates:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

**Benefits**:
- Smaller APK size (~15MB each)
- Faster download
- Better for Play Store

## 🚀 Quick Reference

### Build APK
```bash
flutter build apk --debug
```

### Install on Connected Device
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Run on Emulator
```bash
flutter run
```

### Check Connected Devices
```bash
flutter devices
```

### Uninstall App
```bash
adb uninstall com.spiritual.app
```

## 📍 APK Location

After building, find your APK at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

Copy this file to your phone and install!

---

**Ready to build?**

```bash
# Build APK
flutter build apk --debug

# Find APK at:
# build/app/outputs/flutter-apk/app-debug.apk

# Install on phone:
adb install build/app/outputs/flutter-apk/app-debug.apk
```
