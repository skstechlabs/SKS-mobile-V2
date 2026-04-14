# Build APK with Video Tracking Fixes

## Current Situation
The APK you have installed does NOT have the video tracking fixes. You need to rebuild and reinstall.

## Quick Build Steps

### Option 1: Production APK (Recommended)
```bash
cd SKS-mobile-V2

# Clean previous build
flutter clean
flutter pub get

# Build production APK
flutter build apk --release

# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

### Option 2: Debug APK (Faster, for testing)
```bash
cd SKS-mobile-V2

# Clean previous build
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

# APK will be at: build/app/outputs/flutter-apk/app-debug.apk
```

### Option 3: Use Build Script
```bash
cd SKS-mobile-V2

# Make script executable
chmod +x rebuild-production.sh

# Run build script
./rebuild-production.sh
```

## Install on Device

### Method 1: ADB Install
```bash
# Connect device via USB
# Enable USB debugging on device

# Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or for debug APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Method 2: Manual Install
1. Copy APK to device (via USB, email, or cloud)
2. Open file manager on device
3. Tap the APK file
4. Allow installation from unknown sources if prompted
5. Install

## What's Fixed in New APK

### 1. Video Progress Tracking
- ✅ Progress now tracked every 2 seconds
- ✅ Fallback timer-based tracking if iframe fails
- ✅ Enhanced logging for debugging

### 2. User Feedback
- ✅ Toast notification at 50% milestone
- ✅ Toast notification when day completed
- ✅ Toast notification when class completed
- ✅ Error messages if tracking fails

### 3. Completion Flow
- ✅ Day marked complete at 90%+ (or configured percentage)
- ✅ Completion dialog shows with unlock info
- ✅ Video stops and prevents replay
- ✅ Next day unlocks after 24 hours
- ✅ Class marked complete when all days done
- ✅ Next level unlocks automatically

### 4. Better Error Handling
- ✅ Detailed console logs
- ✅ Stack traces for errors
- ✅ Graceful fallbacks

## Testing After Install

### 1. Open App
- Login with your account
- Navigate to Classes

### 2. Play a Video
- Select Level 1 → Day 1
- Play the video
- Watch for toast messages

### 3. Expected Behavior

**During Playback:**
- Video plays normally
- Progress bar updates

**At 50%:**
- Toast appears: "Halfway there! 50% Completed"

**At 90%+ (Completion):**
- Toast appears: "Congratulations! Day Completed"
- Completion dialog shows
- Video stops

**After Completion:**
- Day shows as "Completed" with checkmark
- Next day shows "Unlocks in 24h"

### 4. Check Backend Logs
If you have access to backend logs, watch for:
```
📊 Progress: 25.00% (required: 90%)
🎯 Milestones reached: 25% for user ..., day 4
✅ Day 1 marked as completed for user ...
```

## Troubleshooting

### Issue: APK won't install
**Solution**: Uninstall old version first
```bash
adb uninstall com.spiritual.app
# Then install new APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Issue: Build fails
**Solution**: Clean and retry
```bash
flutter clean
rm -rf build/
flutter pub get
flutter build apk --release
```

### Issue: Still not tracking
**Possible causes**:
1. Backend server not running
2. Network connectivity issue
3. API endpoint URL wrong
4. Database not configured

**Check**:
- Backend server is running
- Device can reach backend API
- Check `.env.json` for correct API URL

## Verify Build Has Fixes

After building, check the code is included:

```bash
# Check if new code is in build
grep -r "Timer-based progress" build/app/outputs/flutter-apk/

# Or check the source files
grep "Timer-based progress" lib/features/learnings/widgets/cloudflare_video_player.dart
```

Should show: `⏱️ Timer-based progress`

## Build Time
- Debug APK: ~2-5 minutes
- Release APK: ~5-10 minutes

## APK Size
- Debug: ~50-80 MB
- Release: ~20-30 MB

## Important Notes

1. **Must rebuild** - The fixes are in the code, not in your current APK
2. **Clean build recommended** - Use `flutter clean` first
3. **Test on real device** - Emulator might behave differently
4. **Check backend** - Ensure backend server is running and accessible
5. **Network required** - Video streaming and tracking need internet

## Quick Command Summary

```bash
# Full rebuild and install
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## After Installation

1. **Uninstall old app** from device (if needed)
2. **Install new APK**
3. **Open app and login**
4. **Go to Classes → Level 1 → Day 1**
5. **Play video and watch for toasts**
6. **Let video play to 50%** - Should see "Halfway there!" toast
7. **Let video play to 90%+** - Should see "Congratulations!" toast and dialog

---

**Status**: ⚠️ REBUILD REQUIRED
**Priority**: 🔴 CRITICAL
**Action**: Build new APK and install on device
