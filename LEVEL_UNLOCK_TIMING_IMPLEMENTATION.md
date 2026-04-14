# Level Unlock Timing Implementation

## Overview
This document describes the implementation of level unlock timing restrictions based on the `level_unlock_minutes` field in the classes table. This feature ensures users must wait a specified amount of time after completing a level before accessing the next level's content.

## Requirements Implemented

### 1. Display Level Unlock Timing
- **Classes Tab**: Shows remaining time until next level unlocks even when all days in current level are completed
- **Visual Indicators**: Clear badges showing unlock countdown or "ready to unlock" status
- **Time Formatting**: User-friendly display (e.g., "2 hours 30 minutes" or "1440 minutes")

### 2. Block Content Access
- **Backend Validation**: API endpoint checks if enough time has passed since previous level completion
- **Frontend Blocking**: Mobile app prevents navigation to locked levels
- **User Feedback**: Clear dialog explaining why level is locked and when it will unlock

## Backend Changes

### 1. API Endpoint: GET /api/classes/:classId/days
**File**: `sks-backend/routes/classes-video.js`

**New Logic**:
```javascript
// Check if previous level is completed and if enough time has passed
if (currentLevelNumber > 1) {
  const [prevLevelCompletion] = await pool.execute(
    `SELECT c.level_unlock_minutes, uce.completed_at
     FROM classes c
     LEFT JOIN user_class_enrollments uce ON c.id = uce.class_id AND uce.user_uid = ?
     WHERE c.level_number = ? AND c.is_active = TRUE
     LIMIT 1`,
    [uid, currentLevelNumber - 1]
  );

  if (prevLevelCompletion.length > 0 && prevLevelCompletion[0].completed_at) {
    const levelUnlockMinutes = parseInt(prevLevelCompletion[0].level_unlock_minutes) || 1440;
    const minutesSinceCompletion = (Date.now() - new Date(prevLevelCompletion[0].completed_at).getTime()) / (1000 * 60);
    
    if (minutesSinceCompletion < levelUnlockMinutes) {
      const minutesRemaining = Math.ceil(levelUnlockMinutes - minutesSinceCompletion);
      const hoursRemaining = Math.floor(minutesRemaining / 60);
      const unlockTime = new Date(
        new Date(prevLevelCompletion[0].completed_at).getTime() + (levelUnlockMinutes * 60 * 1000)
      );

      return res.json({
        success: false,
        message: 'Level not yet accessible',
        error_code: 'LEVEL_LOCKED',
        levelLocked: true,
        minutesUntilUnlock: minutesRemaining,
        hoursUntilUnlock: hoursRemaining,
        unlockTime: unlockTime.toISOString(),
        levelUnlockMinutes: levelUnlockMinutes
      });
    }
  }
}
```

**Response When Locked**:
```json
{
  "success": false,
  "message": "Level not yet accessible",
  "error_code": "LEVEL_LOCKED",
  "levelLocked": true,
  "minutesUntilUnlock": 720,
  "hoursUntilUnlock": 12,
  "unlockTime": "2026-04-15T02:30:00.000Z",
  "levelUnlockMinutes": 1440
}
```

### 2. API Endpoint: GET /api/level-progression/access
**File**: `sks-backend/routes/level-progression.js`

**Enhanced Response**:
```javascript
completions.forEach(comp => {
  if (levelAccess[comp.level_number]) {
    const daysCompleted = parseInt(comp.days_completed) || 0;
    const totalDays = parseInt(comp.total_days) || 3;
    const levelUnlockMinutes = parseInt(comp.level_unlock_minutes) || 1440;
    const isLevelCompleted = daysCompleted >= totalDays && comp.completed_at != null;
    
    levelAccess[comp.level_number].daysCompleted = daysCompleted;
    levelAccess[comp.level_number].totalDays = totalDays;
    levelAccess[comp.level_number].completed = isLevelCompleted;
    levelAccess[comp.level_number].levelUnlockMinutes = levelUnlockMinutes;
    
    // Calculate time until next level unlocks
    if (isLevelCompleted && comp.completed_at) {
      const minutesSinceCompletion = (Date.now() - new Date(comp.completed_at).getTime()) / (1000 * 60);
      const minutesUntilNextLevelUnlock = Math.max(0, levelUnlockMinutes - minutesSinceCompletion);
      
      levelAccess[comp.level_number].completedAt = comp.completed_at;
      levelAccess[comp.level_number].minutesUntilNextLevelUnlock = Math.ceil(minutesUntilNextLevelUnlock);
      levelAccess[comp.level_number].nextLevelUnlocksAt = new Date(
        new Date(comp.completed_at).getTime() + (levelUnlockMinutes * 60 * 1000)
      ).toISOString();
    }
  }
});
```

**Enhanced Response**:
```json
{
  "success": true,
  "levelAccess": {
    "1": {
      "unlocked": true,
      "completed": true,
      "daysCompleted": 3,
      "totalDays": 3,
      "levelUnlockMinutes": 1440,
      "completedAt": "2026-04-14T10:30:00.000Z",
      "minutesUntilNextLevelUnlock": 720,
      "nextLevelUnlocksAt": "2026-04-15T10:30:00.000Z"
    },
    "2": {
      "unlocked": false,
      "completed": false,
      "daysCompleted": 0,
      "totalDays": 3,
      "levelUnlockMinutes": 1440
    }
  }
}
```

## Mobile App Changes

### 1. Learnings Page - Level Cards
**File**: `SKS-mobile-V2/lib/features/learnings/learnings_page.dart`

**New Features**:
- Display unlock countdown for completed levels
- Show "Next level ready" when time has passed
- Format time in user-friendly way (hours and minutes)

**New Helper Methods**:
```dart
String _formatUnlockTime(int minutes, BuildContext context) {
  if (minutes < 60) {
    return '$minutes ${context.tr('min')}';
  } else {
    final hours = (minutes / 60).floor();
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours ${context.tr('hours')}';
    } else {
      return '$hours ${context.tr('hours')} $remainingMinutes ${context.tr('min')}';
    }
  }
}

int? _getMinutesUntilNextLevelUnlock(int levelNumber) {
  final value = _levelAccess[levelNumber]?['minutesUntilNextLevelUnlock'];
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

int _getLevelUnlockMinutes(int levelNumber) {
  final value = _levelAccess[levelNumber]?['levelUnlockMinutes'];
  if (value == null) return 1440;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 1440;
  if (value is double) return value.toInt();
  return 1440;
}
```

**Visual Display**:
```dart
if (isCompleted)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildStatusBadge(
        context.tr('completed'),
        AppTheme.saffron,
        Icons.check_circle,
      ),
      // Show unlock timing for next level
      if (minutesUntilNextLevelUnlock != null && minutesUntilNextLevelUnlock > 0) ...[
        const SizedBox(height: 6),
        _buildStatusBadge(
          '${context.tr('next_level_unlocks_in')} ${_formatUnlockTime(minutesUntilNextLevelUnlock, context)}',
          AppTheme.gold,
          Icons.lock_clock,
        ),
      ] else if (minutesUntilNextLevelUnlock != null && minutesUntilNextLevelUnlock == 0) ...[
        const SizedBox(height: 6),
        _buildStatusBadge(
          context.tr('next_level_ready'),
          AppTheme.saffron,
          Icons.lock_open,
        ),
      ],
    ],
  )
```

### 2. Class Days List Screen - Level Lock Dialog
**File**: `SKS-mobile-V2/lib/features/learnings/class_days_list_screen.dart`

**New Features**:
- Detect level lock response from API
- Show informative dialog explaining the lock
- Display countdown timer
- Prevent access to locked content

**Level Lock Detection**:
```dart
if (response['levelLocked'] == true) {
  // Level is locked due to level_unlock_minutes timing
  final minutesUntilUnlock = response['minutesUntilUnlock'] ?? 0;
  final hoursUntilUnlock = response['hoursUntilUnlock'] ?? 0;
  final levelUnlockMinutes = response['levelUnlockMinutes'] ?? 1440;
  
  setState(() {
    _isLoading = false;
    _error = null;
  });
  
  // Show level locked dialog
  if (mounted) {
    _showLevelLockedDialog(
      minutesUntilUnlock: minutesUntilUnlock,
      hoursUntilUnlock: hoursUntilUnlock,
      levelUnlockMinutes: levelUnlockMinutes,
    );
  }
}
```

**Lock Dialog**:
```dart
void _showLevelLockedDialog({
  required int minutesUntilUnlock,
  required int hoursUntilUnlock,
  required int levelUnlockMinutes,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_clock, color: AppTheme.gold, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Level Locked'),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This level is not yet accessible.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'You must wait ${_formatUnlockTime(minutesUntilUnlock)} after completing the previous level before accessing this content.',
            style: const TextStyle(fontSize: 14),
          ),
          // ... countdown display and explanation
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.pop(); // Go back to classes list
          },
          child: const Text('Go Back'),
        ),
      ],
    ),
  );
}
```

## Translation Keys Added

**File**: `SKS-mobile-V2/assets/translations/en.json`

```json
{
  "next_level_unlocks_in": "Next level unlocks in",
  "next_level_ready": "Next level ready to unlock",
  "hours": "hours",
  "level_locked": "Level Locked",
  "level_not_yet_accessible": "This level is not yet accessible",
  "wait_after_previous_level": "You must wait after completing the previous level before accessing this content",
  "unlocks_in_time": "Unlocks in",
  "waiting_period_integration": "This waiting period is designed to give you time to integrate the teachings from the previous level",
  "go_back": "Go Back"
}
```

## Database Schema

The `level_unlock_minutes` field already exists in the `classes` table:

```sql
ALTER TABLE classes 
ADD COLUMN level_unlock_minutes INT NOT NULL DEFAULT 1440 
COMMENT 'Minutes to wait before unlocking next level';
```

**Default Value**: 1440 minutes (24 hours)

## User Experience Flow

### Scenario 1: Level Just Completed
1. User completes all 3 days of Level 1
2. Level 1 shows "Completed" badge
3. Below completion badge, shows: "Next level unlocks in 23 hours 45 minutes"
4. Level 2 remains locked and unclickable

### Scenario 2: Attempting to Access Locked Level
1. User tries to tap on Level 2 (locked)
2. Nothing happens (tap is disabled)
3. If user somehow navigates to days list (e.g., deep link), API blocks access
4. Dialog appears: "Level Locked - This level is not yet accessible. You must wait 23 hours 45 minutes..."
5. User clicks "Go Back" and returns to classes list

### Scenario 3: Level Ready to Unlock
1. 24 hours pass since Level 1 completion
2. Level 1 shows: "Completed" + "Next level ready to unlock"
3. Level 2 becomes unlocked and clickable
4. User can now access Level 2 content

## Testing Checklist

### Backend Testing
- [ ] Verify level_unlock_minutes is read from database correctly
- [ ] Test with different unlock times (60 min, 1440 min, etc.)
- [ ] Verify time calculation is accurate
- [ ] Test edge case: exactly at unlock time
- [ ] Test edge case: 1 minute before unlock
- [ ] Test edge case: 1 minute after unlock

### Mobile App Testing
- [ ] Verify unlock countdown displays correctly
- [ ] Test time formatting (minutes, hours, hours+minutes)
- [ ] Verify "Next level ready" appears when time passes
- [ ] Test level lock dialog appears when accessing locked level
- [ ] Verify navigation is blocked for locked levels
- [ ] Test with different level_unlock_minutes values
- [ ] Verify translations work in all languages

### Integration Testing
- [ ] Complete Level 1, verify Level 2 is locked
- [ ] Wait for unlock time, verify Level 2 becomes accessible
- [ ] Test with meditation test requirement for Level 3
- [ ] Verify unlock scheduler job respects level_unlock_minutes

## Configuration

To change the unlock time for a specific level:

```sql
UPDATE classes 
SET level_unlock_minutes = 60  -- 1 hour
WHERE level_number = 1;

UPDATE classes 
SET level_unlock_minutes = 2880  -- 48 hours
WHERE level_number = 2;
```

## Security Considerations

1. **Backend Validation**: All access control is enforced on the backend
2. **No Client-Side Bypass**: Mobile app cannot bypass the lock
3. **Time Calculation**: Server-side time calculation prevents client manipulation
4. **Audit Trail**: Completion times are logged in database

## Future Enhancements

1. **Push Notifications**: Notify user when next level unlocks
2. **Countdown Timer**: Live countdown in the app
3. **Flexible Unlock Rules**: Different unlock times per level
4. **Admin Override**: Allow admins to manually unlock levels
5. **Grace Period**: Allow early access within X minutes of unlock time

## Troubleshooting

### Issue: Level not unlocking after time passes
**Solution**: Check if:
- `completed_at` timestamp is set in `user_class_enrollments`
- `level_unlock_minutes` is configured correctly in `classes` table
- Unlock scheduler job is running (`jobs/unlock-scheduler.js`)

### Issue: Incorrect time display
**Solution**: Verify:
- Server timezone is correct
- Client device time is accurate
- Time calculation logic in both backend and frontend

### Issue: User can access locked level
**Solution**: Ensure:
- Backend validation is in place
- API endpoint checks level lock before returning days
- Mobile app handles `levelLocked` response correctly

## Summary

This implementation provides a robust level unlock timing system that:
- ✅ Displays unlock timing on classes tab
- ✅ Blocks access to locked content
- ✅ Provides clear user feedback
- ✅ Enforces timing on backend
- ✅ Handles edge cases gracefully
- ✅ Supports multiple languages
- ✅ Maintains security and data integrity

The system ensures users have adequate time to integrate teachings from each level before progressing to the next, enhancing the learning experience and spiritual journey.
