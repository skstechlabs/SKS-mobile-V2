# OneSignal Subscription Debugging Guide

## Current Status

Users are not appearing in OneSignal Dashboard after installing APK and granting permissions.

## Enhanced Logging Added

I've added comprehensive logging to help identify the exact issue. The logs will show:

### Permission Request Flow
```
🔐 Starting permission request flow...
🔔 Requesting notification permission...
🔔 Notification permission result: true/false
✅ Notification permission granted - setting up OneSignal
```

### OneSignal Setup Flow
```
🔧 Starting OneSignal user setup...
📱 Step 1: Opting in to push notifications...
📱 OS Permission Status: true/false
👤 Step 2: Setting OneSignal external user ID: <uid>
🏷️  Step 3: Setting user tags...
✅ OneSignal user identified and tagged
📊 OneSignal subscription status:
   Subscribed: true/false
   Player ID: <id or null>
```

### Warning Messages
```
⚠️ WARNING: Player ID is null or empty! Subscription may have failed.
⚠️ WARNING: User is not subscribed! Attempting to opt-in again...
```

## How to Debug

### 1. Connect Device and View Logs

```bash
# Connect your Android device via USB
# Enable USB Debugging on device

# View all logs
adb logcat

# Filter for OneSignal and app logs
adb logcat | grep -E "(OneSignal|SKS|🔔|📱|👤|📊)"

# Save logs to file
adb logcat > onesignal_debug.log
```

### 2. Install Fresh APK

```bash
# Uninstall existing app
adb uninstall com.spiritual.app

# Install new APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Launch app
adb shell am start -n com.spiritual.app/.MainActivity
```

### 3. Check Logs During Permission Grant

When you grant notification permission, look for these specific log messages:

**Expected Success Flow:**
```
✅ OneSignal initialized successfully
🔐 Starting permission request flow...
🔔 Requesting notification permission...
🔔 Notification permission result: true
✅ Notification permission granted - setting up OneSignal
🔧 Starting OneSignal user setup...
📱 Step 1: Opting in to push notifications...
📱 OS Permission Status: true
👤 Step 2: Setting OneSignal external user ID: <firebase_uid>
🏷️  Step 3: Setting user tags...
✅ OneSignal user identified and tagged
📊 OneSignal subscription status:
   Subscribed: true
   Player ID: <valid_player_id>
✅ OneSignal user setup complete
🔐 Permission request flow complete
   Notifications: true
   Camera: true
   Microphone: true
   Location: true
✅ Critical permissions granted - navigating to home
```

**Failure Indicators:**
```
❌ Notification permission denied
⚠️ WARNING: Player ID is null or empty!
⚠️ WARNING: User is not subscribed!
📊 OneSignal subscription status:
   Subscribed: false
   Player ID: null
```

### 4. Check OneSignal Dashboard

1. Go to https://dashboard.onesignal.com
2. Select your app
3. Navigate to Audience > Subscriptions
4. Look for new subscriptions with:
   - Player ID matching the log
   - External User ID matching Firebase UID
   - Tags: auth_provider, has_camera, has_microphone, has_location

### 5. Verify AndroidManifest.xml

Check that OneSignal App ID is correct:

```xml
<meta-data
    android:name="onesignal_app_id"
    android:value="b89d199e-15be-4343-9e04-640c43f355e9" />
```

### 6. Check App Environment

Verify OneSignal App ID in code:

```dart
// lib/core/constants/app_env.dart
static const String oneSignalAppId = 'b89d199e-15be-4343-9e04-640c43f355e9';
```

## Common Issues and Solutions

### Issue 1: Permission Granted but No Subscription

**Symptoms:**
- Permission shows as granted
- Player ID is null
- isSubscribed is false

**Possible Causes:**
1. Network connectivity issue
2. OneSignal API timeout
3. App ID mismatch
4. Firebase UID not set

**Solution:**
- Check internet connection
- Verify App ID matches dashboard
- Ensure user is logged in (Firebase UID exists)
- Try uninstall/reinstall

### Issue 2: Subscription Created but Not Visible in Dashboard

**Symptoms:**
- Player ID exists in logs
- isSubscribed is true
- Not visible in OneSignal Dashboard

**Possible Causes:**
1. Dashboard sync delay (can take 1-2 minutes)
2. Viewing wrong app in dashboard
3. Subscription in test mode

**Solution:**
- Wait 2-3 minutes and refresh dashboard
- Verify correct app selected in dashboard
- Check "All Subscriptions" tab (not just "Active")

### Issue 3: Duplicate Subscriptions

**Symptoms:**
- Multiple subscriptions for same user
- Different Player IDs

**Possible Causes:**
1. Not calling logout before login
2. Multiple app installs without cleanup

**Solution:**
- Call `OneSignal.logout()` before `OneSignal.login()`
- Uninstall app completely before reinstalling

### Issue 4: Permission Denied

**Symptoms:**
- User denies notification permission
- Mandatory dialog shows

**Solution:**
- User must grant permission manually in device settings
- Guide user: Settings > Apps > SKS > Notifications > Allow

## Testing Checklist

- [ ] Fresh install on clean device
- [ ] Uninstall existing app first
- [ ] Install new APK
- [ ] Grant notification permission when prompted
- [ ] Check logs for success messages
- [ ] Verify Player ID is not null
- [ ] Verify isSubscribed is true
- [ ] Wait 2 minutes
- [ ] Check OneSignal Dashboard
- [ ] Send test notification
- [ ] Verify notification received

## Log Collection Commands

### Collect Full Logs
```bash
# Start logging before installing app
adb logcat -c  # Clear existing logs
adb logcat > full_debug.log &

# Install and test app
# Then stop logging (Ctrl+C)
```

### Filter OneSignal Specific Logs
```bash
adb logcat | grep -i onesignal > onesignal_only.log
```

### Filter App Specific Logs
```bash
adb logcat | grep "com.spiritual.app" > app_only.log
```

### Real-time Filtered Logs
```bash
adb logcat | grep -E "(OneSignal|🔔|📱|👤|📊|✅|❌|⚠️)"
```

## Send Test Notification

Once subscription appears in dashboard:

### Via Dashboard
1. Go to Messages > New Push
2. Select "Send to Test Device"
3. Enter Player ID from logs
4. Send notification

### Via API
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "b89d199e-15be-4343-9e04-640c43f355e9",
    "include_player_ids": ["PLAYER_ID_FROM_LOGS"],
    "contents": {"en": "Test notification"},
    "headings": {"en": "Test"}
  }'
```

## Next Steps

1. **Install APK with enhanced logging**
2. **Collect logs during permission grant**
3. **Share logs for analysis**
4. **Check OneSignal Dashboard after 2 minutes**
5. **Report findings:**
   - Is Player ID null or valid?
   - Is isSubscribed true or false?
   - Does subscription appear in dashboard?
   - Any error messages in logs?

## Files Modified

- `lib/features/auth/all_permissions_screen.dart` - Enhanced logging
- `ONESIGNAL_DEBUG_GUIDE.md` - This file

---

**Status:** Ready for debugging
**Action Required:** Install APK, grant permissions, collect logs
