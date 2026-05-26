# How to Build and Run Flutter App in Android Studio

## Method 1: Using Android Studio UI (Easiest)

### Step 1: Open Project
1. Open **Android Studio**
2. Click **"Open"** (or File → Open)
3. Navigate to and select: **`SKS-mobile-V2`** folder
4. Click **"Open"**
5. Wait for **Gradle sync** to complete (bottom right shows progress)

### Step 2: Get Flutter Dependencies
1. Open **Terminal** in Android Studio (bottom panel)
2. Run:
   ```bash
   flutter pub get
   ```
3. Wait for packages to download (takes 30-60 seconds)

### Step 3: Start Android Emulator
1. Click **"Device Manager"** icon (phone icon on right sidebar)
2. If no emulator exists:
   - Click **"Create Device"**
   - Select **"Pixel 5"** or any phone
   - Select **"API 33"** (Android 13) or latest
   - Click **"Next"** → **"Finish"**
3. Click the **▶️ Play button** next to your emulator
4. Wait for emulator to boot (1-2 minutes)
5. You'll see the Android home screen

### Step 4: Build and Run App
1. Make sure emulator is selected in **device dropdown** (top toolbar)
2. Click the **green ▶️ Run button** (or press `Shift + F10`)
3. Android Studio will:
   - Build the app (2-5 minutes first time)
   - Install APK on emulator
   - Launch the app automatically
4. ✅ App opens on emulator!

---

## Method 2: Using Terminal (More Control)

### Step 1: Open Terminal in Android Studio
Click **"Terminal"** tab at bottom of Android Studio

### Step 2: Navigate to Project
```bash
cd /path/to/SKS-mobile-V2
```

### Step 3: Get Dependencies
```bash
flutter pub get
```

### Step 4: Check Available Devices
```bash
flutter devices
```

You should see:
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
Chrome (web)                • chrome        • web-javascript • Google Chrome 120.0
```

### Step 5: Build and Run
```bash
# Run on first available device
flutter run

# Or run on specific device
flutter run -d emulator-5554

# Or run in debug mode with hot reload
flutter run --debug

# Or run in release mode (faster)
flutter run --release
```

### Step 6: Watch Build Progress
You'll see:
```
Launching lib/main.dart on sdk gphone64 arm64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app-debug.apk...
Syncing files to device sdk gphone64 arm64...
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

---

## Method 3: Build First, Then Install (Advanced)

### Step 1: Build APK
```bash
# Build debug APK
flutter build apk --debug

# Or build release APK
flutter build apk --release

# APK will be created at:
# build/app/outputs/flutter-apk/app-debug.apk
```

### Step 2: Start Emulator
```bash
# List available emulators
emulator -list-avds

# Start specific emulator
emulator -avd Pixel_5_API_33 &
```

### Step 3: Install APK
```bash
# Install the built APK
flutter install

# Or use adb directly
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## Understanding the Build Process

### What Happens When You Click Run:

```
1. Flutter pub get
   ↓ Downloads all dependencies
   
2. Flutter build
   ↓ Compiles Dart code to native code
   
3. Gradle build
   ↓ Builds Android APK
   ↓ Takes 2-5 minutes first time
   ↓ Faster on subsequent builds (30-60 seconds)
   
4. Install APK
   ↓ Installs app on emulator/device
   
5. Launch app
   ↓ Opens app automatically
   
✅ App running!
```

---

## Build Configurations

### Debug Build (Default)
```bash
flutter run --debug
```
- ✅ Hot reload enabled
- ✅ Debugging tools available
- ✅ Faster build time
- ⚠️ Larger APK size
- ⚠️ Slower app performance

### Release Build (Production)
```bash
flutter run --release
```
- ✅ Optimized performance
- ✅ Smaller APK size
- ❌ No hot reload
- ❌ No debugging tools

### Profile Build (Performance Testing)
```bash
flutter run --profile
```
- ✅ Performance profiling enabled
- ✅ Near-release performance
- ✅ Some debugging tools

---

## Hot Reload vs Hot Restart

### Hot Reload (Press 'r')
- ⚡ Super fast (< 1 second)
- Updates UI changes
- Preserves app state
- Use for: UI changes, styling, layout

### Hot Restart (Press 'R')
- 🔄 Medium speed (2-5 seconds)
- Restarts app completely
- Resets app state
- Use for: Logic changes, new dependencies

### Full Rebuild (Stop and Run again)
- 🐌 Slow (30-60 seconds)
- Complete rebuild
- Use for: Major changes, build errors

---

## Common Build Commands

```bash
# Clean build (fixes many issues)
flutter clean
flutter pub get
flutter run

# Build APK for distribution
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build for specific architecture
flutter build apk --target-platform android-arm64

# Build with specific flavor
flutter run --flavor production

# Run with verbose logging
flutter run -v

# Run on specific device
flutter run -d <device-id>
```

---

## Troubleshooting

### Issue: "Gradle build failed"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "No devices found"
**Solution:**
```bash
# Check if emulator is running
flutter devices

# If not, start emulator from Android Studio
# Device Manager → Play button
```

### Issue: "Build taking too long"
**Solution:**
- First build takes 2-5 minutes (normal)
- Subsequent builds are faster (30-60 seconds)
- Use `flutter run --release` for faster performance

### Issue: "Hot reload not working"
**Solution:**
- Press `R` (capital R) for hot restart
- Or stop and run again for full rebuild

### Issue: "Dependencies not found"
**Solution:**
```bash
flutter pub get
flutter pub upgrade
```

---

## Build Performance Tips

### 1. Enable Gradle Daemon
Add to `android/gradle.properties`:
```properties
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true
```

### 2. Increase Gradle Memory
Add to `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m
```

### 3. Use Release Mode for Testing Performance
```bash
flutter run --release
```

### 4. Clean Build When Stuck
```bash
flutter clean && flutter pub get && flutter run
```

---

## Recommended Workflow

### For Development (Daily Work):
1. Open Android Studio
2. Start emulator
3. Click **Run** (green play button)
4. Make changes in code
5. Press **'r'** for hot reload
6. Test changes instantly ⚡

### For Testing (Before Release):
1. Clean build:
   ```bash
   flutter clean
   flutter pub get
   ```
2. Build release APK:
   ```bash
   flutter build apk --release
   ```
3. Test on physical device
4. Check performance

### For Distribution:
1. Update version in `pubspec.yaml`
2. Build release bundle:
   ```bash
   flutter build appbundle --release
   ```
3. Upload to Play Store

---

## Quick Reference

| Action | Command | Shortcut |
|--------|---------|----------|
| Run app | `flutter run` | `Shift + F10` |
| Hot reload | Press `r` in terminal | `Ctrl + \` |
| Hot restart | Press `R` in terminal | `Ctrl + Shift + \` |
| Stop app | Press `q` in terminal | `Shift + F5` |
| Clean build | `flutter clean` | - |
| Get dependencies | `flutter pub get` | - |
| Build APK | `flutter build apk` | - |

---

## Step-by-Step: First Time Setup

### 1. Open Project (1 minute)
```
Android Studio → Open → Select SKS-mobile-V2 folder
Wait for Gradle sync
```

### 2. Get Dependencies (1 minute)
```bash
flutter pub get
```

### 3. Start Emulator (2 minutes)
```
Device Manager → Create Device (if needed) → Play button
Wait for emulator to boot
```

### 4. Run App (3-5 minutes first time)
```
Click green Run button
Wait for build
App launches automatically
```

### 5. Test Google Login
```
Tap "Sign in with Google"
Select account
Should log in successfully ✅
```

**Total time: ~10 minutes** ⏱️

---

## Summary

**Easiest Way:**
1. Open Android Studio
2. Open `SKS-mobile-V2` project
3. Start emulator (Device Manager → Play)
4. Click green **Run** button
5. Wait for build
6. App launches! ✅

**Using Terminal:**
```bash
cd SKS-mobile-V2
flutter pub get
flutter run
```

**That's it!** 🚀
