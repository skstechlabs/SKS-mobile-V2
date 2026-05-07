# Install & Test - Quick Guide

## 📦 APK Information

**Location**: `build/app/outputs/flutter-apk/app-release.apk`  
**Size**: 141.1 MB  
**Build Date**: April 8, 2026  
**SHA1**: `1155bc3cb7bb9ccc60c991ecbec424a1fd61c6c0`

---

## 🚀 Install on Android Device

### Method 1: Using ADB (Recommended)

```bash
# Connect your Android device via USB
# Enable USB debugging on your device

# Install the APK
adb install build/app/outputs/flutter-apk/app-release.apk

# If already installed, use -r to reinstall
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual Installation

1. Copy `app-release.apk` to your Android device
2. On your device, go to Settings > Security
3. Enable "Install from Unknown Sources"
4. Open the APK file using a file manager
5. Tap "Install"
6. Grant necessary permissions

---

## ✅ Quick Test (2 minutes)

### Test the New Features

1. **Open the app**
2. **Navigate to**: Home → Classes → Select any class
3. **Test Back Button**:
   - Tap on Day 1
   - ✅ Check: White back button visible in top-left
   - Tap back button
   - ✅ Check: Returns to class list

4. **Test Video Duration**:
   - Open Day 1 video again
   - ✅ Check: Below video shows "🕐 Video Length: XX:XX"

5. **Test Progress Tracking**:
   - Play video for 10 seconds
   - Go back to class list
   - ✅ Check: Shows "▶️ X% watched"
   - ✅ Check: Shows "Started: Today"
   - ✅ Check: Shows "Watch time: Xs"

6. **Test Completion**:
   - Watch video to end (or skip if allowed)
   - ✅ Check: Shows "✅ Completed" badge
   - ✅ Check: Shows "Completed: Today"
   - ✅ Check: Shows total watch time

---

## 🎯 What to Look For

### Day Card States

**Not Started**:
```
▶️ Day 1: Welcome
   ▶️ Start watching
```

**In Progress**:
```
▶️ Day 1: Welcome
   ▶️ 45% watched
   Started: Today
   Watch time: 5m
```

**Completed**:
```
✅ Day 1: Welcome
   ✅ Completed
   Completed: Today
   Watch time: 15m
```

---

## 🐛 Troubleshooting

### APK Won't Install
- Enable "Install from Unknown Sources" in Settings
- Try: `adb install -r app-release.apk` to force reinstall
- Uninstall old version first if needed

### App Crashes
- Check logs: `adb logcat | grep SKS`
- Verify backend API is running
- Check internet connection

### Stats Not Showing
- Complete a video fully
- Go back and check the day card
- Close and reopen app to verify persistence

---

## 📱 Test Devices

Recommended to test on:
- [ ] Android phone (physical device)
- [ ] Different Android versions (8.0+)
- [ ] Different screen sizes

---

## ✨ Success Criteria

All features working if:
- ✅ Back button visible and working
- ✅ Video duration shows below player
- ✅ Progress percentage updates
- ✅ Started date shows
- ✅ Watch time accumulates
- ✅ Completion status shows
- ✅ Stats persist after app restart

---

## 📞 Need Help?

Check documentation:
- `QUICK_TEST_GUIDE.md` - Detailed testing
- `DAY_VIDEO_COMPLETION_TRACKING_FIXED.md` - Technical details
- `BEFORE_AFTER_DAY_VIDEO_FIX.md` - Visual comparison

---

**Ready to test! 🎉**
