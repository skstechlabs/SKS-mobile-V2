# Quick Reminder Test

## Test Now (1 Minute Test)

### Step 1: Check Current Time
```
Current time: [YOUR TIME]
Example: 2:30 PM
```

### Step 2: Set Test Reminder
1. Open app
2. Go to Reminders → Add New
3. Set:
   - Title: "Test Reminder"
   - Time: [CURRENT TIME + 1 MINUTE]
   - Days: Select today
   - Enable: ON

### Step 3: Wait 1 Minute
- Keep phone nearby
- Can close the app
- Wait for notification

### Step 4: Expected Result
At the scheduled time:
- ✅ Notification appears
- ✅ Sound plays
- ✅ Device vibrates
- ✅ Shows "Test Reminder"

---

## If It Doesn't Work

### Check 1: Permissions
```
Settings → Apps → SKS → Permissions
- Notifications: ✅ Allowed
- Alarms & reminders: ✅ Allowed
```

### Check 2: Battery
```
Settings → Battery → Battery optimization
- SKS: ✅ Don't optimize
```

### Check 3: Do Not Disturb
```
Settings → Sound → Do Not Disturb
- ✅ OFF (or add SKS to exceptions)
```

### Check 4: Logs
```bash
adb logcat | grep "Scheduled reminder"
```

Should show:
```
✅ Scheduled reminder X: Test Reminder on day Y at HH:MM
```

---

## Quick Commands

```bash
# Rebuild with new permissions
cd SKS-mobile-V2
./rebuild-production.sh

# Install
adb install build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb logcat | grep -i "reminder\|notification"
```

---

## Success Criteria

✅ Notification appears at exact time
✅ Sound plays
✅ Vibration works
✅ Can tap to open app
✅ Works even if app is closed

If all ✅, reminders are working perfectly!
