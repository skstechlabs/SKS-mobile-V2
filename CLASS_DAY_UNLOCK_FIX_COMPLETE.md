# Class Day Unlock Configuration - COMPLETE ✅

## Problem Fixed
After completing Day 1, Day 2 was not unlocking after 24 hours. The wait time was hardcoded and not configurable from the database.

## Solution Implemented

### 1. Database Configuration Added
- Added `day_unlock_hours` column to `classes` table
- Default value: 24 hours
- Fully configurable per class
- Can be changed via SQL without code changes

### 2. Backend API Updated
- Modified `/api/classes/:classId/days` endpoint
- Now reads `day_unlock_hours` from database
- Uses configured value instead of hardcoded 24 hours
- Calculates unlock time dynamically

### 3. Stored Procedure Created
- `unlock_next_day_if_eligible` procedure
- Automatically unlocks next day when time has passed
- Called after video completion
- Respects the configured unlock hours

## Files Changed

### Backend Files
1. `sks-backend/routes/classes-video.js`
   - Updated to fetch and use `day_unlock_hours` from database
   - Replaced hardcoded 24 with dynamic configuration

2. `sks-backend/migrations/add_day_unlock_hours_config.sql`
   - Migration to add the new column
   - Creates stored procedure
   - Sets default values

3. `sks-backend/CLASS_DAY_UNLOCK_CONFIGURATION.md`
   - Complete documentation
   - Usage examples
   - Testing instructions

4. `sks-backend/RUN_DAY_UNLOCK_MIGRATION.md`
   - Quick start guide
   - Step-by-step migration instructions

## How to Deploy

### Step 1: Run Database Migration
```bash
cd sks-backend
mysql -u root -p sivoham_dev < migrations/add_day_unlock_hours_config.sql
```

### Step 2: Restart Backend
```bash
pm2 restart all
# or
npm restart
```

### Step 3: Test
1. Complete Day 1 of any class
2. Check API response - should show `hoursUntilUnlock`
3. Wait for configured hours (or test with shorter duration)
4. Day 2 should unlock automatically

## Configuration Examples

### View Current Settings
```sql
SELECT id, level, title, day_unlock_hours FROM classes;
```

### Change Unlock Hours
```sql
-- Set to 48 hours (2 days)
UPDATE classes SET day_unlock_hours = 48 WHERE id = 1;

-- Set to 12 hours (half day)
UPDATE classes SET day_unlock_hours = 12 WHERE id = 2;

-- Set to 1 hour (for testing)
UPDATE classes SET day_unlock_hours = 1 WHERE id = 3;
```

## API Response Format

### Before (Hardcoded)
```javascript
// Always used 24 hours
if (hoursSinceCompletion >= 24) {
  unlockStatus = 'ready_to_unlock';
}
```

### After (Configurable)
```javascript
// Uses database configuration
const unlockHours = day.day_unlock_hours || 24;
if (hoursSinceCompletion >= unlockHours) {
  unlockStatus = 'ready_to_unlock';
}
```

### Mobile App Response
```json
{
  "success": true,
  "days": [
    {
      "id": 1,
      "dayNumber": 1,
      "isUnlocked": true,
      "isCompleted": true,
      "completedAt": "2026-04-09T10:00:00Z"
    },
    {
      "id": 2,
      "dayNumber": 2,
      "isUnlocked": false,
      "unlockStatus": "locked",
      "hoursUntilUnlock": 18
    }
  ]
}
```

## Testing Instructions

### Quick Test (1 Hour Unlock)
```sql
-- 1. Set test class to 1 hour unlock
UPDATE classes SET day_unlock_hours = 1 WHERE id = 1;

-- 2. Complete Day 1 (set to 2 hours ago)
UPDATE user_day_progress 
SET is_completed = TRUE, 
    completed_at = NOW() - INTERVAL 2 HOUR
WHERE user_uid = 'test_user' AND day_number = 1 AND class_id = 1;

-- 3. Trigger unlock
CALL unlock_next_day_if_eligible('test_user', 1);

-- 4. Verify Day 2 is unlocked
SELECT day_number, is_unlocked, unlocked_at 
FROM user_day_progress 
WHERE user_uid = 'test_user' AND class_id = 1;
```

### Production Test (24 Hours)
```sql
-- 1. Ensure production class uses 24 hours
UPDATE classes SET day_unlock_hours = 24 WHERE id = 1;

-- 2. Complete Day 1 normally through the app
-- 3. Wait 24 hours
-- 4. Open app - Day 2 should be unlocked
```

## Benefits

1. **Flexible Configuration**: Change unlock hours without code deployment
2. **Per-Class Control**: Different classes can have different unlock times
3. **Easy Testing**: Set to 1 hour for testing, 24 hours for production
4. **Automatic Unlocking**: No manual intervention needed
5. **User-Friendly**: Shows exact hours remaining until unlock

## Troubleshooting

### Day Not Unlocking
```sql
-- Check if previous day is completed
SELECT * FROM user_day_progress 
WHERE user_uid = 'user_id' AND class_id = 1 AND day_number = 1;

-- Check class configuration
SELECT day_unlock_hours FROM classes WHERE id = 1;

-- Manually trigger unlock
CALL unlock_next_day_if_eligible('user_id', 1);
```

### Stored Procedure Missing
```bash
# Re-run migration
mysql -u root -p sivoham_dev < migrations/add_day_unlock_hours_config.sql
```

## Next Steps

1. Run the migration on development database
2. Test with 1-hour unlock time
3. Verify automatic unlocking works
4. Run migration on production database
5. Monitor user feedback

## Documentation
- Full docs: `sks-backend/CLASS_DAY_UNLOCK_CONFIGURATION.md`
- Quick guide: `sks-backend/RUN_DAY_UNLOCK_MIGRATION.md`

---

**Status**: ✅ COMPLETE - Ready for deployment
**Date**: April 10, 2026
**Impact**: All classes now have configurable day unlock times
