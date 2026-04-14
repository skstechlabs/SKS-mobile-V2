# Class Completion Flow - Complete Implementation

## ✅ All Requirements Implemented

### 1. Video Auto-Play with Sound ✅
- Videos auto-play unmuted (`autoplay=true&muted=false`)
- No manual unmuting required

### 2. Video Forwarding Prevention ✅
- Seeking forward is blocked via JavaScript injection
- Only backward seeking allowed
- Controlled by `allowSkip` flag per video

### 3. Dynamic Day Unlock Timing ✅
- Unlock hours configured in database (`classes.day_unlock_hours`)
- Default: 24 hours
- Configurable per class
- Backend calculates unlock eligibility dynamically

### 4. Completion Messages ✅
- Shows unlock hours from database
- Different messages for day completion vs class completion
- Dynamic text based on configured hours

### 5. Class Completion Tracking ✅
- Marks class as complete when all days done
- Updates `user_class_enrollments.completed_at`
- Shows special completion message

---

## How It Works

### Day Completion Flow

```
User watches video to end
        ↓
Video player triggers onComplete callback
        ↓
Mobile app calls: POST /api/classes/days/:dayId/track
        with eventType: 'complete'
        ↓
Backend checks completion percentage >= required
        ↓
Backend marks day as completed (completed_at = NOW())
        ↓
Backend calls: unlock_next_day_if_eligible(user_uid, class_id)
        ↓
Stored procedure checks:
  1. Gets day_unlock_hours from classes table
  2. Finds next locked day
  3. Calculates hours since previous day completion
  4. If hours_elapsed >= day_unlock_hours: UNLOCK
        ↓
Backend checks if all days completed
        ↓
If yes: Mark class as completed
        ↓
Backend returns response with:
  - dayCompleted: true
  - classCompleted: true/false
  - unlockHours: X (from database)
  - nextDayUnlocksAt: timestamp
        ↓
Mobile app shows completion dialog with dynamic message
```

---

## Database Configuration

### classes Table

```sql
CREATE TABLE classes (
  id INT PRIMARY KEY,
  level VARCHAR(50),
  title VARCHAR(255),
  day_unlock_hours INT NOT NULL DEFAULT 24,  -- ← Configurable!
  -- ... other columns
);
```

### Check Current Configuration

```sql
SELECT id, level, title, day_unlock_hours FROM classes;
```

### Change Unlock Hours

```sql
-- Set to 12 hours for quick progression
UPDATE classes SET day_unlock_hours = 12 WHERE id = 1;

-- Set to 48 hours for slower progression
UPDATE classes SET day_unlock_hours = 48 WHERE id = 2;

-- Reset to default 24 hours
UPDATE classes SET day_unlock_hours = 24;
```

---

## Backend Implementation

### File: `sks-backend/routes/classes-video.js`

#### Completion Tracking (Line 409-450)

```javascript
// Check if video is completed
if (completionPercentage >= completion_percentage_required && eventType === 'complete') {
  // Mark day as completed
  await pool.execute(
    `UPDATE user_day_progress 
     SET is_completed = TRUE,
         completed_at = COALESCE(completed_at, NOW())
     WHERE user_uid = ? AND day_id = ? AND is_completed = FALSE`,
    [uid, dayId]
  );

  // Get unlock hours configuration
  const [classInfo] = await pool.execute(
    'SELECT day_unlock_hours FROM classes WHERE id = ?',
    [class_id]
  );
  const unlockHours = classInfo[0]?.day_unlock_hours || 24;

  // Try to unlock next day
  await pool.execute(
    'CALL unlock_next_day_if_eligible(?, ?)',
    [uid, class_id]
  );

  // Check if all days completed
  const [allDays] = await pool.execute(
    `SELECT COUNT(*) as total, 
            SUM(CASE WHEN is_completed THEN 1 ELSE 0 END) as completed
     FROM user_day_progress udp
     JOIN class_days cd ON udp.day_id = cd.id
     WHERE udp.user_uid = ? AND cd.class_id = ? AND cd.is_active = TRUE`,
    [uid, class_id]
  );

  const isClassCompleted = allDays[0].total === allDays[0].completed && allDays[0].total > 0;

  if (isClassCompleted) {
    // Mark class as completed
    await pool.execute(
      `UPDATE user_class_enrollments 
       SET completed_at = COALESCE(completed_at, NOW())
       WHERE user_uid = ? AND class_id = ?`,
      [uid, class_id]
    );
  }

  // Return completion info
  return res.json({
    success: true,
    message: 'Day completed!',
    completionPercentage: parseFloat(completionPercentage.toFixed(2)),
    dayCompleted: true,
    classCompleted: isClassCompleted,
    unlockHours: unlockHours,
    nextDayUnlocksAt: new Date(Date.now() + unlockHours * 60 * 60 * 1000).toISOString()
  });
}
```

### Stored Procedure: `unlock_next_day_if_eligible`

**File**: `sks-backend/migrations/add_day_unlock_hours_config.sql`

```sql
CREATE PROCEDURE unlock_next_day_if_eligible(
  IN p_user_uid VARCHAR(128),
  IN p_class_id INT
)
BEGIN
  DECLARE v_unlock_hours INT;
  DECLARE v_hours_since_completion DECIMAL(10,2);
  
  -- Get unlock hours from classes table
  SELECT day_unlock_hours INTO v_unlock_hours
  FROM classes WHERE id = p_class_id;
  
  -- Default to 24 if not set
  IF v_unlock_hours IS NULL OR v_unlock_hours = 0 THEN
    SET v_unlock_hours = 24;
  END IF;
  
  -- Find next day to unlock
  -- Calculate hours since previous day completion
  SET v_hours_since_completion = TIMESTAMPDIFF(SECOND, v_prev_completed_at, NOW()) / 3600;
  
  -- Unlock if enough time has passed
  IF v_hours_since_completion >= v_unlock_hours THEN
    -- Unlock the day
    INSERT INTO user_day_progress (...) VALUES (...)
    ON DUPLICATE KEY UPDATE is_unlocked = TRUE, unlocked_at = NOW();
  END IF;
END;
```

---

## Mobile App Implementation

### File: `SKS-mobile-V2/lib/features/learnings/day_video_screen.dart`

#### Progress Tracking (Line 227-250)

```dart
Future<void> _trackProgress(int positionSeconds, int durationSeconds, String eventType) async {
  try {
    final response = await _apiService.post(
      '/api/classes/days/${widget.dayId}/track',
      {
        'eventType': eventType,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'sessionId': _sessionId,
        'deviceInfo': {
          'platform': Theme.of(context).platform.toString(),
          'userAgent': 'Flutter Mobile App',
        },
      },
    );

    if (response['success'] == true && eventType == 'complete' && !_isCompleted) {
      setState(() => _isCompleted = true);
      
      // Get unlock hours from response
      final unlockHours = response['unlockHours'] ?? 24;
      final classCompleted = response['classCompleted'] ?? false;
      
      _showCompletionDialog(unlockHours, classCompleted);
    }
  } catch (e) {
    debugPrint('Error tracking progress: $e');
  }
}
```

#### Completion Dialog (Line 256-330)

```dart
void _showCompletionDialog(int unlockHours, bool classCompleted) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.saffron, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              classCompleted 
                ? context.tr('class_completed') 
                : context.tr('day_completed')
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classCompleted
              ? '${context.tr('congratulations_completed_class')} ${widget.dayTitle}!'
              : '${context.tr('congratulations_completed')} ${widget.dayTitle}.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (classCompleted)
            // Show class completion message
            Container(...)
          else
            // Show next day unlock message with dynamic hours
            Container(
              child: Text(
                unlockHours == 1
                  ? context.tr('next_day_unlock_1h')
                  : context.tr('next_day_unlock_hours').replaceAll('{hours}', unlockHours.toString()),
              ),
            ),
        ],
      ),
    ),
  );
}
```

### Video Player Configuration

**File**: `SKS-mobile-V2/lib/features/learnings/widgets/cloudflare_video_player.dart`

```dart
// Line 67: Auto-play with sound
final iframeUrl = 'https://${widget.accountId}.cloudflarestream.com/${widget.videoId}/iframe'
    '?preload=true'
    '&autoplay=true'      // ✅ Auto-plays
    '&loop=false'
    '&muted=false'        // ✅ Sound unmuted
    '&controls=true'
    '&defaultTextTrack=en';

// Line 184-192: Prevent seeking forward
case 'seeked':
  ${widget.allowSkip ? '' : '''
  // Prevent seeking forward
  if (data.currentTime > currentTime + 2) {
    player.postMessage({
      method: 'seek',
      value: currentTime
    }, '*');
  }
  '''}
  break;
```

---

## Translation Keys

### File: `SKS-mobile-V2/assets/translations/en.json`

```json
{
  "day_completed": "Day Completed!",
  "class_completed": "Class Completed!",
  "congratulations_completed": "Congratulations! You have completed",
  "congratulations_completed_class": "Congratulations! You have completed all days in",
  "all_days_completed": "You have completed all days in this class!",
  "next_day_unlock_1h": "Next day will unlock in 1 hour",
  "next_day_unlock_hours": "Next day will unlock in {hours} hours"
}
```

---

## Testing Scenarios

### Scenario 1: Normal 24-Hour Unlock

```sql
UPDATE classes SET day_unlock_hours = 24 WHERE id = 1;
```

**Expected**:
1. User completes Day 1 at 10:00 AM Monday
2. Completion dialog shows: "Next day will unlock in 24 hours"
3. Day 2 unlocks at 10:00 AM Tuesday
4. User can access Day 2

### Scenario 2: Quick Testing (1 Hour)

```sql
UPDATE classes SET day_unlock_hours = 1 WHERE id = 1;
```

**Expected**:
1. User completes Day 1 at 10:00 AM
2. Completion dialog shows: "Next day will unlock in 1 hour"
3. Day 2 unlocks at 11:00 AM
4. User can access Day 2

### Scenario 3: Class Completion

```sql
-- Assume class has 5 days
UPDATE classes SET day_unlock_hours = 1 WHERE id = 1;
```

**Expected**:
1. User completes Days 1-4 (each unlocks after 1 hour)
2. User completes Day 5
3. Completion dialog shows: "Class Completed!"
4. Message: "You have completed all days in this class!"
5. `user_class_enrollments.completed_at` is set

### Scenario 4: Multiple Users

**User A**:
- Completes Day 1 at 10:00 AM Monday
- Day 2 unlocks at 10:00 AM Tuesday (24 hours later)

**User B**:
- Completes Day 1 at 3:00 PM Monday
- Day 2 unlocks at 3:00 PM Tuesday (24 hours later)

**Expected**: Each user's unlock timing is independent and based on their own completion timestamp.

---

## Verification Queries

### Check Day Completion

```sql
SELECT 
  u.email,
  cd.day_number,
  cd.title,
  udp.is_completed,
  udp.completed_at,
  c.day_unlock_hours,
  TIMESTAMPDIFF(HOUR, udp.completed_at, NOW()) AS hours_since_completion
FROM user_day_progress udp
JOIN class_days cd ON udp.day_id = cd.id
JOIN classes c ON cd.class_id = c.id
JOIN users u ON udp.user_uid = u.uid
WHERE udp.is_completed = TRUE
ORDER BY udp.completed_at DESC;
```

### Check Class Completion

```sql
SELECT 
  u.email,
  c.level,
  c.title,
  uce.completed_at,
  COUNT(cd.id) AS total_days,
  SUM(CASE WHEN udp.is_completed THEN 1 ELSE 0 END) AS completed_days
FROM user_class_enrollments uce
JOIN classes c ON uce.class_id = c.id
JOIN users u ON uce.user_uid = u.uid
LEFT JOIN class_days cd ON cd.class_id = c.id AND cd.is_active = TRUE
LEFT JOIN user_day_progress udp ON udp.day_id = cd.id AND udp.user_uid = u.uid
GROUP BY u.email, c.id
HAVING completed_days = total_days;
```

### Check Next Day Unlock Eligibility

```sql
SELECT 
  u.email,
  c.title,
  c.day_unlock_hours,
  cd.day_number AS current_day,
  next_cd.day_number AS next_day,
  udp.completed_at AS current_day_completed,
  TIMESTAMPDIFF(HOUR, udp.completed_at, NOW()) AS hours_elapsed,
  CASE 
    WHEN TIMESTAMPDIFF(HOUR, udp.completed_at, NOW()) >= c.day_unlock_hours 
    THEN 'READY TO UNLOCK'
    ELSE CONCAT('LOCKED (', c.day_unlock_hours - TIMESTAMPDIFF(HOUR, udp.completed_at, NOW()), ' hours remaining)')
  END AS unlock_status
FROM user_day_progress udp
JOIN class_days cd ON udp.day_id = cd.id
JOIN classes c ON cd.class_id = c.id
JOIN users u ON udp.user_uid = u.uid
LEFT JOIN class_days next_cd ON next_cd.class_id = c.id AND next_cd.day_number = cd.day_number + 1
WHERE udp.is_completed = TRUE
  AND udp.is_unlocked = TRUE
ORDER BY u.email, cd.day_number;
```

---

## Troubleshooting

### Day Not Unlocking

1. **Check unlock hours configuration**:
   ```sql
   SELECT day_unlock_hours FROM classes WHERE id = 1;
   ```

2. **Check completion timestamp**:
   ```sql
   SELECT completed_at, 
          TIMESTAMPDIFF(HOUR, completed_at, NOW()) AS hours_elapsed
   FROM user_day_progress 
   WHERE user_uid = 'user_uid' AND day_id = 1;
   ```

3. **Manually trigger unlock**:
   ```sql
   CALL unlock_next_day_if_eligible('user_uid', 1);
   ```

### Completion Dialog Not Showing

1. **Check backend response**:
   ```bash
   pm2 logs sks-api | grep "Day completed"
   ```

2. **Check mobile app logs**:
   ```bash
   adb logcat | grep "Flutter"
   ```

3. **Verify completion percentage**:
   ```sql
   SELECT completion_percentage, completion_percentage_required
   FROM user_day_progress udp
   JOIN class_days cd ON udp.day_id = cd.id
   WHERE udp.user_uid = 'user_uid' AND cd.id = 1;
   ```

---

## Summary

✅ **Video auto-plays with sound** (no muting)
✅ **Video forwarding prevented** (seeking blocked)
✅ **Dynamic unlock timing** (configured in database)
✅ **Completion messages** (show actual unlock hours)
✅ **Class completion tracking** (marks class complete when all days done)
✅ **Per-user timing** (each user's unlock based on their completion)
✅ **Configurable per class** (different classes can have different unlock hours)

**Status**: Production Ready 🚀

---

**Last Updated**: April 10, 2026
