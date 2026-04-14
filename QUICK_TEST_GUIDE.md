# Quick Test Guide - Day Video Completion Fix

## 🚀 Quick Start

```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter run
```

## ✅ Test Checklist (5 minutes)

### Test 1: Back Button Visibility (30 seconds)
1. Open app
2. Go to Classes → Select any class → Select Day 1
3. **CHECK**: White back button visible in top-left corner
4. Tap back button
5. **CHECK**: Returns to class days list

**Expected**: ✅ White arrow clearly visible on black background

---

### Test 2: Video Duration Display (30 seconds)
1. Open any day video
2. **CHECK**: Below video player, see "🕐 Video Length: XX:XX"
3. Verify time format is MM:SS (e.g., "15:30" for 15 minutes 30 seconds)

**Expected**: ✅ Duration displayed in dark bar below video

---

### Test 3: Progress Tracking (2 minutes)
1. Start watching Day 1 (play for 10 seconds)
2. Go back to class days list
3. **CHECK**: Day 1 shows "▶️ X% watched"
4. **CHECK**: Shows "Started: Today"
5. **CHECK**: Shows "Watch time: Xs" or "Xm"

**Expected**: ✅ Progress percentage, start date, and watch time visible

---

### Test 4: Completion Status (2 minutes)
1. Watch Day 1 video to completion (or skip to end if allowed)
2. Wait for completion dialog
3. Tap "Continue" to go back
4. **CHECK**: Day 1 shows "✅ Completed" badge
5. **CHECK**: Shows "Completed: Today"
6. **CHECK**: Shows total watch time

**Expected**: ✅ Green checkmark, completion date, and total watch time

---

### Test 5: Stats Persistence (1 minute)
1. After completing Day 1, close app completely
2. Reopen app
3. Navigate to Classes → Select class
4. **CHECK**: Day 1 still shows "✅ Completed"
5. **CHECK**: Stats still visible (date, watch time)

**Expected**: ✅ All stats persist after app restart

---

## 🎯 What to Look For

### Day Card States

#### Not Started
```
▶️ Day 1: Welcome
    ▶️ Start watching
```

#### In Progress (10% watched)
```
▶️ Day 1: Welcome
    ▶️ 10% watched
    Started: Today
    Watch time: 1m
```

#### In Progress (50% watched)
```
▶️ Day 1: Welcome
    ▶️ 50% watched
    Started: Today
    Watch time: 5m
```

#### Completed
```
✅ Day 1: Welcome
    ✅ Completed
    Completed: Today
    Watch time: 15m
```

#### Locked (Day 2 before Day 1 complete)
```
🔒 Day 2: Introduction
    🔒 Locked
```

#### Ready to Unlock (Day 2 after Day 1 complete, <24h)
```
🔒 Day 2: Introduction
    🔒 Unlocks in 18h
```

---

## 🐛 Common Issues & Solutions

### Issue: Back button not visible
**Solution**: Check AppBar background is black and icon color is white

### Issue: Video duration not showing
**Solution**: Check `videoDurationSeconds` is being parsed from API response

### Issue: Stats not showing
**Solution**: Check API response includes `completionPercentage`, `watchTimeSeconds`, `startedAt`, `completedAt`

### Issue: Completion status not updating
**Solution**: 
1. Check backend `/api/classes/days/:dayId/track` is being called
2. Check `eventType: 'complete'` is sent when video ends
3. Verify backend sets `is_completed = TRUE` in database

---

## 📊 Backend Verification

### Check Database
```sql
-- Check user progress
SELECT 
  day_number,
  is_completed,
  completion_percentage,
  watch_time_seconds,
  started_at,
  completed_at
FROM user_day_progress
WHERE user_uid = 'YOUR_USER_UID'
ORDER BY day_number;
```

### Check API Response
```bash
# Get days with progress
curl -X GET "http://your-api/api/classes/1/days" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected response:
```json
{
  "success": true,
  "days": [
    {
      "dayNumber": 1,
      "isCompleted": true,
      "completionPercentage": 100,
      "watchTimeSeconds": 900,
      "startedAt": "2026-04-08T10:00:00Z",
      "completedAt": "2026-04-08T10:15:00Z"
    }
  ]
}
```

---

## 🎨 UI Elements to Verify

### Video Player Screen
- [ ] White back button (top-left)
- [ ] Video player (center)
- [ ] Duration bar below video: "🕐 Video Length: XX:XX"
- [ ] Video info section (scrollable)
- [ ] Security warning banner

### Class Days List
- [ ] Day cards with proper spacing
- [ ] Status badges (▶️ for unlocked, ✅ for completed, 🔒 for locked)
- [ ] Progress percentage for in-progress videos
- [ ] Date information (Started/Completed)
- [ ] Watch time information
- [ ] Arrow icon on right for unlocked days

---

## 📱 Device Testing

### Test on Different Devices
- [ ] Android phone (physical device)
- [ ] Android tablet
- [ ] Different screen sizes
- [ ] Different Android versions

### Test Different Scenarios
- [ ] First time user (no progress)
- [ ] User with partial progress
- [ ] User with completed days
- [ ] User with multiple classes

---

## 🔍 Debug Mode

### Enable Debug Logging
The app already has debug prints. Check logs:

```bash
# Android
adb logcat | grep -E "📚|📹|✅|❌"

# Look for:
# 📚 Loading days for class...
# 📹 Video config request...
# ✅ Day completed
# ❌ Error messages
```

### Key Log Messages
- `📚 Loading days for class X, user: Y`
- `📊 Found X days for class Y`
- `📹 Video config request - User: X, Day ID: Y`
- `✅ Returning video config for Day X`
- `🎬 Initializing video player`
- `▶️ Video started playing`
- `✅ Video completed`

---

## ✨ Success Criteria

All tests pass if:
1. ✅ Back button is clearly visible and works
2. ✅ Video duration shows below player
3. ✅ Progress percentage updates as you watch
4. ✅ Started date shows when you begin watching
5. ✅ Watch time accumulates correctly
6. ✅ Completion status shows after finishing
7. ✅ Completed date shows after finishing
8. ✅ All stats persist after app restart

---

## 📞 Support

If any test fails:
1. Check console logs for errors
2. Verify backend API is responding correctly
3. Check database has correct data
4. Review the fix documentation:
   - `DAY_VIDEO_COMPLETION_TRACKING_FIXED.md`
   - `CLASSES_COMPLETION_FIX_SUMMARY.md`
   - `BEFORE_AFTER_DAY_VIDEO_FIX.md`

---

**Testing Time**: ~5 minutes  
**Expected Result**: All tests pass ✅  
**Status**: Ready for testing
