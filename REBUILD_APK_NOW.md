# ⚠️ REBUILD APK REQUIRED

## Your Current APK Does NOT Have the Fixes

The APK installed on your Android device was built BEFORE the video tracking fixes were applied. You MUST rebuild and reinstall.

## Quick Rebuild (Choose One Method)

### Method 1: Automated Script (Easiest) ⭐
```bash
cd SKS-mobile-V2
./build-and-install.sh
```

This script will:
1. Clean previous build
2. Get dependencies
3. Build APK (you choose release or debug)
4. Optionally install on connected device

### Method 2: Manual Commands
```bash
cd SKS-mobile-V2

# Clean and prepare
flutter clean
flutter pub get

# Build release APK (recommended)
flutter build apk --release

# Install on device (if connected via USB)
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Method 3: Debug APK (Faster for Testing)
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## What Will Be Fixed

After rebuilding and installing the new APK:

✅ **Video progress tracking** - Every 2 seconds
✅ **Toast notifications** - At 50%, 90%, completion
✅ **Completion dialog** - Shows when day is done
✅ **Database updates** - Progress saved properly
✅ **Day completion** - Marked at 90%+
✅ **Next day unlock** - After 24 hours
✅ **Class completion** - When all days done
✅ **Level unlock** - Automatic progression

## Expected User Experience

### During Video:
- Video plays normally
- Progress tracked automatically
- At 50%: Toast "Halfway there! 50% Completed"

### At Completion (90%+):
- Toast "Congratulations! Day Completed"
- Dialog appears with:
  - ✅ Checkmark
  - Congratulations message
  - Next day unlock info
- Video stops automatically

### After Completion:
- Day shows "Completed" badge
- Green checkmark icon
- Next day shows "Unlocks in Xh"

## Build Time

- **Release APK**: 5-10 minutes
- **Debug APK**: 2-5 minutes

## Installation

### If Device Connected via USB:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### If Manual Install:
1. Copy APK from `build/app/outputs/flutter-apk/app-release.apk`
2. Transfer to device (USB, email, cloud)
3. Open file manager on device
4. Tap APK file
5. Allow installation from unknown sources
6. Install

## Verify It's Working

After installing new APK:

1. **Open app** and login
2. **Go to Classes** → Level 1 → Day 1
3. **Play video**
4. **Watch for toast** at 50%
5. **Watch for toast** at 90%+
6. **Completion dialog** should appear
7. **Check backend logs** for tracking messages

## Backend Must Be Running

Ensure your backend server is running:
```bash
cd sks-backend
pm2 status
# OR
npm start
```

Backend should show these logs when video is playing:
```
📊 Progress: 25.00% (required: 90%)
🎯 Milestones reached: 25% for user ..., day 4
✅ Day 1 marked as completed for user ...
```

## Common Issues

### "Build failed"
```bash
flutter clean
rm -rf build/
flutter pub get
flutter build apk --release
```

### "Installation failed"
```bash
# Uninstall old version first
adb uninstall com.spiritual.app
# Then install new
adb install build/app/outputs/flutter-apk/app-release.apk
```

### "No devices found"
- Connect device via USB
- Enable USB debugging on device
- Accept USB debugging prompt on device

### "Still not tracking"
- Check backend is running
- Check device has internet
- Check API URL in `.env.json`
- Check backend logs for errors

## Files Changed (In New APK)

1. `cloudflare_video_player.dart` - Enhanced tracking
2. `day_video_screen.dart` - Toast notifications
3. Translation files - New messages

## Documentation

- `BUILD_APK_WITH_FIXES.md` - Detailed build guide
- `VIDEO_TRACKING_CRITICAL_FIX.md` - Technical details
- `ACTION_PLAN_VIDEO_COMPLETION.md` - Testing guide

---

## TL;DR - Just Run This:

```bash
cd SKS-mobile-V2
./build-and-install.sh
```

Then test the video playback!

---

**Status**: ⚠️ ACTION REQUIRED
**Priority**: 🔴 CRITICAL
**Time**: ~5-10 minutes to rebuild
