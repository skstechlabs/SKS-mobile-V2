# Action Plan - Video Completion Fix

## Critical Issue
Video progress tracking is NOT working. No API calls are being made when users watch videos.

## Immediate Actions Required

### 1. Restart Backend Server
```bash
cd sks-backend
pm2 restart sks-backend
# OR
npm start
```

Watch the logs carefully for tracking messages.

### 2. Rebuild Flutter App
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter run
```

The new code with enhanced logging and fallback tracking needs to be deployed.

### 3. Test Video Playback
1. Open app
2. Go to Classes → Level 1 → Day 1
3. Play the video
4. **Watch the console carefully**

### 4. Look for These Logs

#### Frontend Console (Flutter)
```
💉 Injecting JavaScript for video tracking
✅ JavaScript injected successfully
📨 Received video event: ...
📹 Video event: progress at Xs / Ys
⏱️ Timer-based progress: Xs / Ys
📡 Tracking: progress at Xs / Ys (X.X%)
```

#### Backend Console
```
📊 Progress: X.XX% (required: 90%)
🎯 Milestones reached: 25% for user ..., day 4
✅ Day 1 marked as completed for user ...
```

## What to Check

### If NO frontend logs appear:
**Problem**: JavaScript not injecting or WebView not working
**Action**: 
- Check if WebView is enabled
- Try on different device
- Check for JavaScript errors

### If frontend logs appear but NO backend logs:
**Problem**: API calls not being made
**Action**:
- Check network connectivity
- Verify API endpoint URL
- Check authentication token

### If backend logs appear but nothing updates:
**Problem**: Database issue
**Action**:
- Check database connection
- Verify tables exist
- Run migrations

## Database Checks

### 1. Check if video_duration_seconds is correct
```sql
SELECT 
  cd.id,
  cd.day_number,
  cd.title,
  cd.video_duration_seconds,
  cd.cloudflare_video_id
FROM class_days cd
WHERE cd.class_id = 1
ORDER BY cd.day_number;
```

**Expected**: video_duration_seconds should match actual video length (in seconds)
**If wrong**: Update it:
```sql
UPDATE class_days 
SET video_duration_seconds = 1800  -- 30 minutes
WHERE id = 4;
```

### 2. Check if day_unlock_hours is set
```sql
SELECT 
  id,
  level,
  title,
  day_unlock_hours
FROM classes
WHERE is_active = TRUE;
```

**Expected**: day_unlock_hours should be 24 (or your desired value)
**If NULL**: Update it:
```sql
UPDATE classes 
SET day_unlock_hours = 24
WHERE id = 1;
```

### 3. Check if user_day_progress exists
```sql
SELECT 
  udp.id,
  udp.user_uid,
  udp.day_id,
  udp.is_unlocked,
  udp.is_completed,
  udp.completion_percentage
FROM user_day_progress udp
WHERE udp.user_uid = 'qtVkWhLodIcZCupi4IxSV3zNOH53'
  AND udp.day_id = 4;
```

**Expected**: Row should exist with is_unlocked = TRUE
**If missing**: Create it:
```sql
INSERT INTO user_day_progress (user_uid, class_id, day_id, day_number, is_unlocked, unlocked_at)
VALUES ('qtVkWhLodIcZCupi4IxSV3zNOH53', 1, 4, 1, TRUE, NOW())
ON DUPLICATE KEY UPDATE is_unlocked = TRUE;
```

### 4. Check if milestone columns exist
```sql
SHOW COLUMNS FROM user_day_progress LIKE 'milestone%';
```

**Expected**: Should show 10 milestone columns
**If missing**: Run migration:
```bash
mysql -u root -p'Srinath@123' sks_db < migrations/add_video_milestones.sql
```

## Testing Checklist

- [ ] Backend server running
- [ ] Flutter app rebuilt with new code
- [ ] Video loads and plays
- [ ] Frontend console shows JavaScript injection
- [ ] Frontend console shows video events
- [ ] Frontend console shows tracking calls
- [ ] Backend console shows progress updates
- [ ] Toast notifications appear (50%, completion)
- [ ] Completion dialog shows
- [ ] Database updates (check user_day_progress)
- [ ] Next day unlocks after 24 hours
- [ ] Class completes when all days done
- [ ] Next level unlocks

## Expected User Experience

### During Video Playback
1. Video loads and plays normally
2. Progress bar updates
3. At 50%: Toast appears "Halfway there! 50% Completed"
4. Progress continues

### At Completion (90%+)
1. Toast appears: "Congratulations! Day Completed"
2. Completion dialog shows with:
   - Checkmark icon
   - "Day Completed!" title
   - Congratulations message
   - Next day unlock info (24 hours)
3. Video stops and prevents replay
4. User clicks "Continue" to go back

### After Completion
1. Day shows as "Completed" in list
2. Completion percentage: 100%
3. Green checkmark badge
4. Next day shows "Unlocks in Xh" timer

## Troubleshooting

### Video not loading
- Check cloudflare_video_id in database
- Verify Cloudflare Stream account
- Check network connectivity

### Progress not tracking
- Check frontend console for errors
- Verify API endpoint accessible
- Check authentication token valid

### Completion not working
- Verify completion_percentage_required in database
- Check if percentage calculation is correct
- Verify backend completion logic

### Next day not unlocking
- Check day_unlock_hours configuration
- Verify unlock_next_day_if_eligible procedure exists
- Check if previous day is marked complete

### Level not unlocking
- Verify unlock_next_level_if_eligible procedure exists
- Check if all days of current level are complete
- For Level 2→3: Check meditation test status

## Quick Fixes

### Force complete a day (for testing)
```sql
UPDATE user_day_progress 
SET is_completed = TRUE,
    completed_at = NOW(),
    completion_percentage = 100,
    milestone_90_reached = TRUE,
    milestone_90_at = NOW(),
    milestone_100_reached = TRUE,
    milestone_100_at = NOW()
WHERE user_uid = 'qtVkWhLodIcZCupi4IxSV3zNOH53'
  AND day_id = 4;
```

### Force unlock next day
```sql
CALL unlock_next_day_if_eligible('qtVkWhLodIcZCupi4IxSV3zNOH53', 1);
```

### Force unlock next level
```sql
CALL unlock_next_level_if_eligible('qtVkWhLodIcZCupi4IxSV3zNOH53', 1);
```

## Success Criteria

✅ Video plays without errors
✅ Progress tracked every 2 seconds
✅ Milestones trigger at 25%, 50%, 75%, 90%, 100%
✅ Toast notifications appear
✅ Day marked complete at 90%+
✅ Completion dialog shows
✅ Video stops and prevents replay
✅ Database updated correctly
✅ Next day unlocks after 24 hours
✅ Class completes when all days done
✅ Next level unlocks

## Contact for Issues

If issues persist after following this plan:
1. Share frontend console logs
2. Share backend console logs
3. Share database query results
4. Share network tab screenshots

---

**Priority**: 🔴 CRITICAL
**Status**: ⚠️ NEEDS IMMEDIATE TESTING
**Impact**: Core learning functionality
