# Reminder Preset Sync Fix

## Problem
Preset reminders (Morning/Evening Meditation) not syncing properly with "Manage Reminders":
- Toggle ON → Shows in Manage ✅
- Toggle OFF → Still shows in Manage ❌ (should disappear)

## Root Cause
When toggling OFF a preset reminder, the code was **deactivating** it (`isActive: false`) instead of **deleting** it. This caused:
- Reminder still exists in database with `isActive: false`
- "Manage Reminders" shows ALL reminders (both active and inactive)
- User sees inactive reminder in the list (confusing!)

## Solution
Changed `_deactivateReminder()` in `home_page.dart` to **DELETE** the reminder instead of toggling it off.

### Before (Broken):
```dart
// Toggle OFF → Reminder stays in database with isActive: false
final toggleResponse = await _apiService.toggleReminder(existing['id']);
```

### After (Fixed):
```dart
// Toggle OFF → Reminder is DELETED from database
final deleteResponse = await _apiService.deleteReminder(existing['id']);
```

## Behavior Now

### Toggle ON (Morning/Evening Meditation):
1. Checks if reminder exists with that time
2. If exists but inactive → Activates it
3. If doesn't exist → Creates new reminder
4. Shows in "Manage Reminders" with toggle ON ✅

### Toggle OFF (Morning/Evening Meditation):
1. Finds reminder with that time
2. **DELETES it from database** ✅
3. **Disappears from "Manage Reminders"** ✅
4. Toggle shows OFF in home page ✅

## File Modified
`lib/features/home/home_page.dart` - Line ~928 in `_deactivateReminder()` function

## Testing

### Test Case 1: Toggle ON
1. Go to Home page
2. Toggle ON "Morning Meditation"
3. Go to "Manage Reminders"
4. **Expected:** Morning Meditation appears in list with toggle ON ✅

### Test Case 2: Toggle OFF
1. Go to Home page
2. Toggle OFF "Morning Meditation"
3. Go to "Manage Reminders"
4. **Expected:** Morning Meditation is GONE from list ✅

### Test Case 3: Toggle ON → OFF → ON
1. Toggle ON → Reminder created
2. Toggle OFF → Reminder deleted
3. Toggle ON again → New reminder created
4. Each time, "Manage Reminders" syncs correctly ✅

## Why Delete Instead of Deactivate?

### Option 1: Deactivate (Old Way - Confusing)
- Keeps reminder in database
- Shows in "Manage Reminders" even when OFF
- User must manually delete to remove
- ❌ Confusing UX

### Option 2: Delete (New Way - Clean)
- Removes reminder completely
- "Manage Reminders" only shows active reminders user cares about
- Toggle OFF = "I don't want this reminder anymore"
- ✅ Clear UX

## Alternative Approach (Not Chosen)
Could have filtered "Manage Reminders" to only show active reminders, but that would hide inactive reminders that user manually created (bad UX for custom reminders).

## Impact
- ✅ Preset reminders sync properly
- ✅ "Manage Reminders" shows accurate list
- ✅ No confusion about inactive preset reminders
- ✅ Custom reminders (created manually) still work normally
- ✅ User can toggle custom reminders ON/OFF (they stay in list)

## Rebuild

No need to rebuild APK - this is just logic change:
```bash
# Hot reload works
flutter run --dart-define-from-file=.env.prod.json

# Or rebuild if needed
flutter build apk --release --dart-define-from-file=.env.prod.json
```

The preset reminder toggles now work perfectly and stay in sync with "Manage Reminders"!
