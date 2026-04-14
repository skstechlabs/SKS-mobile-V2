# Quick Start Guide - Video Completion System

## 🚀 Getting Started

### Step 1: Apply Database Migration
```bash
cd sks-backend
mysql -u root -p your_database < migrations/add_video_milestones.sql
```

### Step 2: Restart Backend Server
```bash
cd sks-backend
npm start
```

### Step 3: Run Flutter App
```bash
cd SKS-mobile-V2
flutter run
```

## 🎯 What to Expect

### When User Watches Video

**At 25% completion:**
- Console: `🎯 Milestone reached: 25%`
- API call made immediately
- Database: `milestone_25_reached = TRUE`

**At 50% completion:**
- Console: `🎯 Milestone reached: 50%`
- API call made immediately
- Database: `milestone_50_reached = TRUE`

**At 75% completion:**
- Console: `🎯 Milestone reached: 75%`
- API call made immediately
- Database: `milestone_75_reached = TRUE`

**At 90% completion (if this is the requirement):**
- Console: `🎯 Milestone reached: 90%`
- Console: `✅ Day marked as completed`
- Day marked as complete in database
- Completion dialog appears
- Video stops and prevents replay
- Next day unlocks after configured hours

**At 100% completion:**
- Console: `🎯 Milestone reached: 100%`
- Final milestone recorded

## 🔍 How to Verify It's Working

### 1. Check Frontend Console
Look for these messages:
```
📹 Video event: progress at 45s / 180s
🎯 Milestone reached: 25%
📡 Tracking: milestone_25 at 45s / 180s
🎯 Backend confirmed milestones: 25%
```

### 2. Check Backend Logs
Look for these messages:
```
📊 Progress: 25.00% (required: 90%)
🎯 Milestones reached: 25% for user abc123, day 5
✅ Day 3 marked as completed for user abc123
```

### 3. Check Database
```sql
SELECT 
  user_uid,
  day_id,
  completion_percentage,
  milestone_25_reached,
  milestone_50_reached,
  milestone_75_reached,
  milestone_90_reached,
  milestone_100_reached,
  is_completed
FROM user_day_progress
WHERE user_uid = 'your_user_id'
ORDER BY day_id;
```

## 📊 Key Configuration

### Completion Percentage Requirement
Set in `class_days` table:
```sql
UPDATE class_days 
SET completion_percentage_required = 90 
WHERE id = 1;
```

### Day Unlock Hours
Set in `classes` table:
```sql
UPDATE classes 
SET day_unlock_hours = 24 
WHERE id = 1;
```

## 🐛 Troubleshooting

### Milestones Not Recording

**Problem:** No milestone messages in console

**Solution:**
1. Check video is playing
2. Verify duration > 0
3. Check `_reportedMilestones` set in video player

**Problem:** API calls not being made

**Solution:**
1. Check network tab in browser/dev tools
2. Verify backend is running
3. Check API endpoint URL is correct

**Problem:** Database not updating

**Solution:**
1. Verify migration was applied
2. Check backend logs for SQL errors
3. Verify database connection

### Day Not Completing

**Problem:** Reached 90% but day not marked complete

**Solution:**
1. Check `completion_percentage_required` in database
2. Verify backend receives correct percentage
3. Check backend logs for completion logic

**Problem:** Completion dialog not showing

**Solution:**
1. Check `dayCompleted: true` in API response
2. Verify `_showCompletionDialog` is called
3. Check for JavaScript errors in console

## 📱 Testing Flow

1. **Login** to the app
2. **Navigate** to Classes tab
3. **Select** a class
4. **Enroll** if not already enrolled
5. **Open** Day 1 (should be unlocked)
6. **Watch** video and observe:
   - Progress bar updates
   - Console shows milestone messages
   - API calls in network tab
7. **Reach 90%** (or configured requirement)
   - Completion dialog appears
   - Video stops
   - Can't replay
8. **Go back** to class days list
   - Day 1 shows as completed
   - Day 2 shows unlock timer
9. **Wait** for unlock hours to pass (or adjust in database for testing)
10. **Refresh** - Day 2 should now be unlocked

## 🎓 Understanding the System

### Milestone Tracking
- **Purpose**: Track user engagement at key points
- **Thresholds**: 25%, 50%, 75%, 90%, 100%
- **Storage**: Database with timestamps
- **Use Cases**: Analytics, gamification, validation

### Completion Logic
- **Trigger**: When user reaches `completion_percentage_required`
- **Default**: 90% (configurable per day)
- **Effect**: Day marked complete, next day unlocks after delay
- **Validation**: Ensures users actually watched content

### Day Unlocking
- **Day 1**: Auto-unlocked on enrollment
- **Other Days**: Unlock after previous day complete + configured hours
- **Default Delay**: 24 hours (configurable per class)
- **Purpose**: Paced learning, prevent rushing

### Class Completion
- **Trigger**: All days marked as completed
- **Effect**: Class marked complete in database
- **Display**: Special completion message
- **Future**: Could unlock next level/class

## 📚 Documentation Files

- `VIDEO_COMPLETION_FIXES_COMPLETE.md` - Original completion system
- `MILESTONE_TRACKING_IMPLEMENTATION.md` - Detailed milestone docs
- `COMPLETION_SYSTEM_SUMMARY.md` - Complete system overview
- `QUICK_START_GUIDE.md` - This file

## ✅ Success Criteria

System is working correctly when:
- [x] Videos play without errors
- [x] Progress updates every 2 seconds
- [x] Milestones trigger at 25%, 50%, 75%, 90%, 100%
- [x] API calls made immediately at milestones
- [x] Database records all milestones with timestamps
- [x] Day completes at configured percentage
- [x] Completion dialog appears
- [x] Video stops and prevents replay
- [x] Next day unlocks after configured hours
- [x] Class completes when all days done
- [x] All translations work (English, Hindi, Telugu)

---

**Need Help?** Check the detailed documentation files or review the code comments.
