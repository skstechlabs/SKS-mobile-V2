# Testing Flutter Mobile App on MacBook - Step by Step Guide

## Prerequisites
- ✅ MacBook with Android Studio installed
- ✅ Flutter SDK installed
- ✅ Backend server running on Windows (https://app.sivakundalini.org)

---

## Option 1: Test on Android Emulator (Easiest)

### Step 1: Open Android Studio on MacBook
1. Open **Android Studio**
2. Click **"Open"** and select the folder: `SKS-mobile-V2`
3. Wait for Gradle sync to complete

### Step 2: Start Android Emulator
1. In Android Studio, click **"Device Manager"** (phone icon on right side)
2. Click **"Create Device"** if you don't have an emulator
   - Select: **Pixel 5** or any device
   - Select: **API 33** (Android 13) or latest
   - Click **"Finish"**
3. Click the **Play button** next to your emulator to start it
4. Wait for emulator to boot (takes 1-2 minutes)

### Step 3: Run the App
1. Make sure emulator is selected in the device dropdown (top toolbar)
2. Click the **green Play button** (Run) or press `Shift + F10`
3. Wait for app to build and install (first time takes 2-5 minutes)
4. App will launch automatically on emulator

### Step 4: Test Google Login
1. In the emulator, tap **"Sign in with Google"**
2. Select a Google account
3. The app should successfully log in and navigate to home screen

---

## Option 2: Test on Physical Android Device

### Step 1: Enable Developer Mode on Android Phone
1. On your Android phone, go to **Settings** → **About Phone**
2. Tap **"Build Number"** 7 times (you'll see "You are now a developer!")
3. Go back to **Settings** → **Developer Options**
4. Enable **"USB Debugging"**

### Step 2: Connect Phone to MacBook
1. Connect your Android phone to MacBook using USB cable
2. On phone, tap **"Allow USB Debugging"** when prompted
3. Select **"File Transfer"** mode (not just charging)

### Step 3: Verify Connection
1. Open Terminal on MacBook
2. Run: `flutter devices`
3. You should see your phone listed

### Step 4: Run the App
1. In Android Studio, select your phone from device dropdown
2. Click the **green Play button** (Run)
3. App will install and launch on your phone

---

## Option 3: Test on iOS Simulator (MacBook Only)

### Step 1: Install Xcode (if not installed)
1. Open **App Store** on MacBook
2. Search for **"Xcode"**
3. Click **"Install"** (takes 30-60 minutes, ~12GB)

### Step 2: Open iOS Simulator
1. Open Terminal
2. Run: `open -a Simulator`
3. iOS Simulator will open with an iPhone

### Step 3: Run the App
1. In Android Studio, select **iOS Simulator** from device dropdown
2. Click the **green Play button** (Run)
3. App will build and launch on iOS Simulator

**Note**: iOS build takes longer first time (5-10 minutes)

---

## Option 4: Test on Physical iPhone (Requires Apple Developer Account)

### Requirements:
- Apple Developer Account ($99/year)
- iPhone connected to MacBook

### Steps:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your iPhone as target device
3. Sign the app with your Apple Developer account
4. Click **Run** in Xcode

---

## Troubleshooting

### Issue: "Flutter not found"
**Solution:**
```bash
# Check if Flutter is installed
flutter --version

# If not installed, install Flutter:
# Download from: https://docs.flutter.dev/get-started/install/macos
```

### Issue: "No devices found"
**Solution:**
```bash
# For Android Emulator:
# Make sure emulator is running in Android Studio

# For Physical Device:
# Make sure USB debugging is enabled
# Run: flutter devices
```

### Issue: "Gradle build failed"
**Solution:**
```bash
# Clean and rebuild
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter run
```

### Issue: "Certificate error" or "SSL error"
**Solution:**
This is expected with self-signed certificates. The app should still work.
If it doesn't, you can temporarily use HTTP:
- Change `.env.local.json`: `"API_BASE_URL": "http://app.sivakundalini.org"`

### Issue: "Connection refused"
**Solution:**
- Make sure backend server is running on Windows
- Test from MacBook browser: `https://app.sivakundalini.org/health`
- If browser works, app will work too

---

## Quick Commands (Terminal)

```bash
# Navigate to project
cd /path/to/SKS-mobile-V2

# Check Flutter installation
flutter doctor

# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on Android emulator
flutter run -d emulator-5554

# Run on iOS simulator
flutter run -d iPhone

# Clean build
flutter clean && flutter pub get && flutter run

# View logs
flutter logs
```

---

## Testing Checklist

After app launches, test these features:

### ✅ Google Login Flow
1. Tap "Sign in with Google"
2. Select Google account
3. Should navigate to home screen
4. Check if user profile loads

### ✅ API Connectivity
1. Navigate to different screens
2. Check if data loads from backend
3. Try creating/updating data
4. Check if all API calls work

### ✅ Network Requests
1. Open Android Studio → **Logcat** (bottom panel)
2. Filter by: `flutter` or `http`
3. Watch for API requests and responses
4. Look for any errors

---

## Recommended: Test on Android Emulator First

**Why?**
- ✅ Fastest to set up
- ✅ No physical device needed
- ✅ Easy to debug with Android Studio
- ✅ Can test different Android versions

**Steps:**
1. Open Android Studio
2. Open `SKS-mobile-V2` project
3. Start emulator (Device Manager → Play button)
4. Click Run (green play button)
5. Test Google login

**That's it!** 🚀

---

## Expected Result

When you tap "Sign in with Google":
1. Google sign-in screen appears
2. Select account
3. App makes request to: `https://app.sivakundalini.org/api/auth/login/google`
4. Backend validates token
5. Returns user data
6. App navigates to home screen
7. User is logged in ✅

---

## Need Help?

If you encounter any issues:
1. Check **Logcat** in Android Studio for errors
2. Check backend logs: `pm2 logs api-gateway`
3. Test API directly: `curl -k https://app.sivakundalini.org/health`
4. Make sure `.env.local.json` has correct `API_BASE_URL`

---

## Summary

**Easiest Method**: Android Emulator
- Time: 5 minutes
- No physical device needed
- Full debugging capabilities

**Best for Production Testing**: Physical Android Device
- Real-world performance
- Actual Google account login
- True user experience

Choose Android Emulator for quick testing! 📱
