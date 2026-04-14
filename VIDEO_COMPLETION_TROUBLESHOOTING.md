# Video Completion Troubleshooting Guide

## Issue
Videos are not being marked as completed even after watching them fully. The backend is not updating the relevant tables and users are not seeing completion messages.

## Recent Fixes Applied

### 1. Added Level Progression Call
**File**: `sks-backend/routes/classes-video.js`
**Change**: Added call to `unlock_next_level_if_eligible` stored procedure when a class is completed.

```javascript
if (isClassCompleted) {
  // Mark class as completed
  await pool.execute(
    `UPDATE user_class_enrollments 
     SET completed_at = COALESCE(completed_at, NOW())
     WHERE user_uid = ? AND class_id = ?`,
    [uid, class_id]
  );

  // Try to unlock next level (NEW)
  try {
    await pool.execute(
      'CALL unlock_next_level_if_eligible(?, ?)',
      [uid, class_id]
    );
    console.log(`🔓 Checked level progression for user ${uid}`);
  } catch (levelError) {
    console.error('Error checking level progression:', levelError);
  }
}
```

### 2. Enhanced Logging
Added comprehensive logging to track the completion flow:
- `🎯 Completion threshold reached` - When percentage meets requirement
- `✅ Day marked as completed` - When day is successfully marked complete
- `ℹ️ Day was already completed` - When trying to complete an already completed day
- `⏳ Not yet complete` - When percentage is below requirement
- `🔓 Checked next day unlock` - After calling unlock procedure
- `📊 Class completion check` - Shows X/Y days completed
- `🎉 User completed class` - When all days are done
- `🔓 Checked level progression` - After calling level unlock procedure

## Debugging Steps

### Step 1: Check Backend Logs
Watch the backend console for these messages when a video is being watched:

```bash
# Start backend with logging
cd sks-backend
npm start

# Watch for these patterns:
📊 Progress: X.XX% (required: 90%)
🎯 Completion threshold reached: X.XX% >= 90%
✅ Day X marked as completed for user abc123, class 1
🔓 Checked next day unlock for user abc123, class 1
📊 Class completion check: 3/3 days completed
🎉 User abc123 completed class 1!
🔓 Checked level progression for user abc123 after completing class 1
```

### Step 2: Check Database State
Run the debugging SQL queries:

```bash
cd sks-backend
mysql -u your_user -p your_database < debug_video_completion.sql
```

Replace `'YOUR_USER_UID'` in the queries with the actual user UID.

**Key queries to run**:

1. **Check user_day_progress**:
```sql
SELECT 
  cd.day_number,
  cd.title,
  udp.completion_percentage,
  cd.completion_percentage_required,
  udp.is_completed,
  udp.completed_at
FROM user_day_progress udp
JOIN class_days cd ON udp.day_id = cd.id
WHERE udp.user_uid = 'YOUR_USER_UID'
ORDER BY cd.day_number;
```

2. **Check for days that should be completed**:
```sql
SELECT 
  cd.day_number,
  udp.completion_percentage,
  cd.completion_percentage_required,
  udp.is_completed,
  CASE 
    WHEN udp.completion_percentage >= cd.completion_percentage_required THEN 'SHOULD BE COMPLETED'
    ELSE 'NOT YET'
  END as status
FROM user_day_progress udp
JOIN class_days cd ON udp.day_id = cd.id
WHERE udp.user_uid = 'YOUR_USER_UID';
```

3. **Check class enrollments**:
```sql
SELECT 
  c.title,
  uce.current_day,
  uce.completed_at,
  c.total_days
FROM user_class_enrollments uce
JOIN classes c ON uce.class_id = c.id
WHERE uce.user_uid = 'YOUR_USER_UID';
```

4. **Check level access**:
```sql
SELECT 
  level_number,
  is_unlocked,
  unlocked_at,
  unlocked_by
FROM user_level_access
WHERE user_uid = 'YOUR_USER_UID'
ORDER BY level_number;
```

### Step 3: Check Frontend Logs
Open the app and watch the console:

```
📹 Video event: progress at 45s / 180s
🎯 Milestone reached: 25%
📡 Tracking: milestone_25 at 45s / 180s
🎯 Backend confirmed milestones: 25%
...
📹 Video event: complete at 180s / 180s
✅ Video completed - preventing auto-replay
📡 Tracking: complete at 180s / 180s
```

### Step 4: Check API Responses
Use browser dev tools Network tab to inspect API responses:

**Track API Response** (`POST /api/classes/days/:dayId/track`):
```json
{
  "success": true,
  "message": "Day completed!",
  "completionPercentage": 92.5,
  "dayCompleted": true,
  "classCompleted": false,
  "unlockHours": 24,
  "nextDayUnlocksAt": "2026-04-11T10:30:00.000Z",
  "milestonesReached": [90, 100]
}
```

## Common Issues and Solutions

### Issue 1: Video Not Sending Complete Event
**Symptoms**: 
- Progress tracked but never reaches 100%
- No "complete" event in logs
- Video loops instead of stopping

**Solution**:
Check `cloudflare_video_player.dart`:
- Ensure `loop=false` in iframe URL
- Verify `onComplete` callback is set
- Check JavaScript injection for 'ended' event handling

### Issue 2: Completion Percentage Not Reaching Threshold
**Symptoms**:
- Video watched fully but completion_percentage < 90%
- Backend logs show: `⏳ Not yet complete: 85.00% < 90%`

**Possible Causes**:
1. Video duration mismatch (frontend vs backend)
2. Position not reaching end (stopped a few seconds early)
3. Calculation error

**Solution**:
```sql
-- Check video duration configuration
SELECT 
  cd.day_number,
  cd.video_duration_seconds,
  udp.last_position_seconds,
  udp.completion_percentage,
  cd.completion_percentage_required
FROM user_day_progress udp
JOIN class_days cd ON udp.day_id = cd.id
WHERE udp.user_uid = 'YOUR_USER_UID';

-- Manually complete if needed (for testing)
UPDATE user_day_progress 
SET is_completed = TRUE,
    completed_at = NOW(),
    completion_percentage = 100
WHERE user_uid = 'YOUR_USER_UID'
  AND day_id = YOUR_DAY_ID;
```

### Issue 3: user_day_progress Row Not Created
**Symptoms**:
- No progress data in database
- API returns 404 or errors

**Solution**:
Ensure day is unlocked first:
```sql
-- Check if day is unlocked
SELECT 
  cd.day_number,
  udp.is_unlocked,
  udp.unlocked_at
FROM class_days cd
LEFT JOIN user_day_progress udp ON cd.id = udp.day_id AND udp.user_uid = 'YOUR_USER_UID'
WHERE cd.class_id = YOUR_CLASS_ID;

-- Manually unlock if needed
INSERT INTO user_day_progress (user_uid, class_id, day_id, day_number, is_unlocked, unlocked_at)
VALUES ('YOUR_USER_UID', YOUR_CLASS_ID, YOUR_DAY_ID, 1, TRUE, NOW())
ON DUPLICATE KEY UPDATE is_unlocked = TRUE, unlocked_at = NOW();
```

### Issue 4: Stored Procedures Not Found
**Symptoms**:
- Backend error: "PROCEDURE does not exist"
- Level progression not working

**Solution**:
```bash
# Check if procedures exist
mysql -u your_user -p your_database -e "SHOW PROCEDURE STATUS WHERE Db = DATABASE() AND Name LIKE '%unlock%';"

# If missing, run migrations
mysql -u your_user -p your_database < database/migrations/run_procedures.sql
mysql -u your_user -p your_database < database/migrations/add_level_progression.sql
mysql -u your_user -p your_database < migrations/add_day_unlock_hours_config.sql
```

### Issue 5: Milestone Columns Missing
**Symptoms**:
- Backend error: "Unknown column 'milestone_25_reached'"
- Milestone tracking not working

**Solution**:
```bash
# Apply milestone migration
mysql -u your_user -p your_database < migrations/add_video_milestones.sql
```

### Issue 6: Completion Dialog Not Showing
**Symptoms**:
- Day marked complete in database
- No dialog shown to user
- Video continues playing

**Possible Causes**:
1. Frontend not receiving `dayCompleted: true` in response
2. `_showCompletionDialog` not being called
3. Dialog dismissed or blocked

**Solution**:
Check frontend logs for:
```
🎉 Day completed! Class completed: false, Next unlock in: 24h
```

If missing, check API response in Network tab.

### Issue 7: Next Day Not Unlocking
**Symptoms**:
- Day 1 completed
- Day 2 still locked after 24 hours

**Solution**:
```sql
-- Check unlock timing
SELECT 
  cd.day_number,
  udp.is_completed,
  udp.completed_at,
  c.day_unlock_hours,
  TIMESTAMPDIFF(HOUR, udp.completed_at, NOW()) as hours_since_completion,
  CASE 
    WHEN TIMESTAMPDIFF(HOUR, udp.completed_at, NOW()) >= c.day_unlock_hours THEN 'SHOULD BE UNLOCKED'
    ELSE 'STILL LOCKED'
  END as status
FROM user_day_progress udp
JOIN class_days cd ON udp.day_id = cd.id
JOIN classes c ON cd.class_id = c.id
WHERE udp.user_uid = 'YOUR_USER_UID'
  AND udp.is_completed = TRUE;

-- Manually unlock next day
CALL unlock_next_day_if_eligible('YOUR_USER_UID', YOUR_CLASS_ID);
```

### Issue 8: Class Not Marked Complete
**Symptoms**:
- All days completed
- `user_class_enrollments.completed_at` is NULL

**Solution**:
```sql
-- Check completion status
SELECT 
  c.title,
  c.total_days,
  COUNT(udp.id) as days_with_progress,
  SUM(CASE WHEN udp.is_completed THEN 1 ELSE 0 END) as days_completed,
  uce.completed_at
FROM user_class_enrollments uce
JOIN classes c ON uce.class_id = c.id
LEFT JOIN user_day_progress udp ON uce.user_uid = udp.user_uid AND uce.class_id = udp.class_id
WHERE uce.user_uid = 'YOUR_USER_UID'
GROUP BY c.id, c.title, c.total_days, uce.completed_at;

-- Manually mark as complete if all days done
UPDATE user_class_enrollments 
SET completed_at = NOW()
WHERE user_uid = 'YOUR_USER_UID'
  AND class_id = YOUR_CLASS_ID
  AND completed_at IS NULL;
```

### Issue 9: Next Level Not Unlocking
**Symptoms**:
- Class completed
- Next level still locked

**Solution**:
```sql
-- Check level access
SELECT * FROM user_level_access WHERE user_uid = 'YOUR_USER_UID';

-- Manually unlock next level
CALL unlock_next_level_if_eligible('YOUR_USER_UID', YOUR_CLASS_ID);

-- Or manually insert
INSERT INTO user_level_access (user_uid, level_number, is_unlocked, unlocked_at, unlocked_by)
VALUES ('YOUR_USER_UID', 2, TRUE, NOW(), 'manual')
ON DUPLICATE KEY UPDATE is_unlocked = TRUE, unlocked_at = NOW();
```

## Testing Checklist

- [ ] Backend server running and logs visible
- [ ] Database migrations applied (check with SQL queries)
- [ ] Stored procedures exist (run SHOW PROCEDURE STATUS)
- [ ] Video plays correctly
- [ ] Progress updates every 2 seconds
- [ ] Milestones trigger at 25%, 50%, 75%, 90%, 100%
- [ ] Backend logs show completion threshold reached
- [ ] Day marked as completed in database
- [ ] Completion dialog appears
- [ ] Video stops and prevents replay
- [ ] Next day unlocks after configured hours
- [ ] Class marked complete when all days done
- [ ] Next level unlocks when class complete
- [ ] All tables updated correctly

## Tables to Monitor

1. **user_day_progress** - Day-level progress
   - `is_completed` - Should be TRUE when done
   - `completed_at` - Timestamp of completion
   - `completion_percentage` - Should be >= requirement
   - Milestone columns - Track progress points

2. **user_class_enrollments** - Class-level enrollment
   - `completed_at` - Should be set when all days done
   - `current_day` - Tracks which day user is on

3. **user_level_access** - Level unlocking
   - `is_unlocked` - Should be TRUE for accessible levels
   - `unlocked_at` - When level was unlocked
   - `unlocked_by` - How it was unlocked (auto/manual/meditation_test)

4. **video_watch_events** - Detailed event log
   - Check for 'complete' events
   - Verify position_seconds reaches duration_seconds

## Quick Fixes for Testing

### Reset User Progress
```sql
-- WARNING: This deletes all progress for a user
DELETE FROM user_day_progress WHERE user_uid = 'YOUR_USER_UID';
DELETE FROM user_class_enrollments WHERE user_uid = 'YOUR_USER_UID';
DELETE FROM user_level_access WHERE user_uid = 'YOUR_USER_UID';
DELETE FROM video_watch_events WHERE user_uid = 'YOUR_USER_UID';
```

### Force Complete a Day
```sql
UPDATE user_day_progress 
SET is_completed = TRUE,
    completed_at = NOW(),
    completion_percentage = 100,
    milestone_90_reached = TRUE,
    milestone_90_at = NOW(),
    milestone_100_reached = TRUE,
    milestone_100_at = NOW()
WHERE user_uid = 'YOUR_USER_UID'
  AND day_id = YOUR_DAY_ID;
```

### Force Complete a Class
```sql
-- Complete all days
UPDATE user_day_progress 
SET is_completed = TRUE,
    completed_at = NOW(),
    completion_percentage = 100
WHERE user_uid = 'YOUR_USER_UID'
  AND class_id = YOUR_CLASS_ID;

-- Mark class as complete
UPDATE user_class_enrollments 
SET completed_at = NOW()
WHERE user_uid = 'YOUR_USER_UID'
  AND class_id = YOUR_CLASS_ID;
```

### Force Unlock Next Level
```sql
INSERT INTO user_level_access (user_uid, level_number, is_unlocked, unlocked_at, unlocked_by)
VALUES ('YOUR_USER_UID', 2, TRUE, NOW(), 'manual')
ON DUPLICATE KEY UPDATE is_unlocked = TRUE, unlocked_at = NOW();
```

## Contact Points for Issues

1. **Backend not responding**: Check server logs, restart if needed
2. **Database errors**: Check migrations applied, verify table structure
3. **Frontend not tracking**: Check console logs, verify API calls
4. **Stored procedures failing**: Re-run migration scripts

---

**Last Updated**: 2026-04-10
**Status**: Enhanced with level progression and comprehensive logging
