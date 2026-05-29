# OneSignal Push Notification Fix Applied

## Problem Identified

The mobile app was calling `OneSignal.login(uid)` **without checking if notification permission was granted first**. This caused:

- Users to be registered in OneSignal without a valid push token
- Backend sending notifications that returned `recipients: 0`
- 48 registered users but only 9 messageable (81% failure rate)

## Root Cause

In `login_screen.dart`, after successful login:
```dart
// ❌ OLD CODE - Fire and forget, no permission check
_oneSignal.setExternalUserId(user.uid).catchError((_) {});
```

This would call `OneSignal.login(uid)` even if the user hadn't granted notification permission yet, resulting in a registration without a push token.

## Fixes Applied

### 1. Fixed Login Flow (`lib/features/auth/login_screen.dart`)

**Before:**
```dart
// OneSignal — fire and forget
_oneSignal.setExternalUserId(user.uid).catchError((_) {});
_oneSignal.setTags({...}).catchError((_) {});
```

**After:**
```dart
// OneSignal — CRITICAL: Only register if permission was granted
try {
  final hasPermission = await _oneSignal.hasPermission();
  if (hasPermission) {
    await _oneSignal.setExternalUserId(user.uid);
    await _oneSignal.setTags({...});
    debugPrint('✅ OneSignal registered for user: ${user.uid}');
  } else {
    debugPrint('⚠️ OneSignal: Permission not granted, skipping registration');
    debugPrint('   User will be registered when they grant permission later');
  }
} catch (e) {
  debugPrint('❌ OneSignal registration error: $e');
}
```

**Impact:** Users who login without granting notification permission won't be registered in OneSignal until they grant permission later.

### 2. Improved Startup Logging (`lib/main.dart`)

**Before:**
```dart
// Step 5: if user is already logged in, link them to OneSignal immediately
final authState = AuthState();
if (authState.user != null && permissionGranted) {
  OneSignal.login(authState.user!.uid);
  ...
}
```

**After:**
```dart
// Step 5: if user is already logged in AND permission granted, link them immediately
final authState = AuthState();
if (authState.user != null && permissionGranted) {
  OneSignal.login(authState.user!.uid);
  OneSignal.User.pushSubscription.optIn();
  developer.log('✅ OneSignal.login(${authState.user!.uid}) called on startup');
} else if (authState.user != null && !permissionGranted) {
  developer.log('⚠️ User logged in but no notification permission - will register after permission granted');
}
```

**Impact:** Better logging to understand when and why OneSignal registration happens or doesn't happen.

## How It Works Now

### Scenario 1: New User Login (No Permission Yet)
1. User logs in with OTP or Google
2. App checks: `hasPermission()` → `false`
3. App skips OneSignal registration
4. User proceeds to permission screen
5. User grants notification permission
6. `all_permissions_screen.dart` calls `_setupOneSignalUser()`
7. ✅ User registered in OneSignal with valid push token

### Scenario 2: Existing User (Permission Already Granted)
1. User logs in with OTP or Google
2. App checks: `hasPermission()` → `true`
3. App immediately registers user in OneSignal
4. ✅ User can receive push notifications

### Scenario 3: App Restart (User Already Logged In)
1. App starts, checks if user logged in
2. Checks if permission granted
3. If both true: calls `OneSignal.login(uid)`
4. ✅ User re-linked to OneSignal on startup

## Expected Results

### Before Fix
- 48 registered users
- 9 messageable users (19%)
- 39 users cannot receive notifications (81%)

### After Fix
- New users will only be registered after granting permission
- Existing users with permission will be re-registered on next login
- Expected messageable rate: **90%+** (only users who explicitly deny permission will be excluded)

## Testing the Fix

### 1. Test New User Flow
```bash
# Build and install the app
cd s:\SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Steps:**
1. Uninstall the app completely
2. Install fresh APK
3. Login with OTP or Google
4. **DO NOT grant notification permission yet**
5. Check backend logs - should see: "⚠️ Permission not granted, skipping registration"
6. Go to permission screen and grant notification permission
7. Check backend logs - should see: "✅ OneSignal registered for user: [uid]"
8. Send test notification from backend
9. ✅ Should receive notification

### 2. Test Existing User
```bash
# From backend service
cd s:\Backup\sks-notification-service
node test-onesignal.js <firebase-user-uid>
```

**Expected output:**
```
✅ User Found in OneSignal
✅ User can receive push notifications
✅ Notification Sent Successfully
   Recipients: 1
```

### 3. Test via API
```bash
# Start the notification service
cd s:\Backup\sks-notification-service
pm2 restart sks-notification-service

# Send test notification (requires Firebase auth token)
curl -X POST http://localhost:3007/api/notifications/test \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json"
```

## Monitoring

### Check User Status
```bash
# Check specific user
cd s:\Backup\sks-notification-service
node test-onesignal.js <firebase-uid>

# Check multiple users
node check-users-status.js <uid1> <uid2> <uid3>
```

### View App Logs
```bash
# Android device logs
adb logcat | grep -E "OneSignal|🔔|✅|❌"

# Or use the filtering script
cd s:\SKS-mobile-V2
./logcat-filter.sh
```

### View Backend Logs
```bash
cd s:\Backup\sks-notification-service
pm2 logs sks-notification-service --lines 50
```

## Rollout Plan

### Phase 1: Deploy Backend (Already Done)
- ✅ Backend service is working correctly
- ✅ Test scripts created
- ✅ Troubleshooting guides created

### Phase 2: Deploy Mobile App (Next)
1. Build release APK with fixes
2. Test with 2-3 users first
3. Verify notifications working
4. Roll out to all users

### Phase 3: Monitor (After Deployment)
1. Check OneSignal dashboard daily
2. Monitor messageable players count
3. Target: 90%+ messageable rate within 1 week

## Additional Improvements

### For Future Consideration

1. **Re-prompt Permission:**
   - If user denies permission, show educational dialog
   - Explain benefits of notifications
   - Offer to open settings

2. **Permission Status Indicator:**
   - Show notification status in profile
   - Allow users to enable/disable easily

3. **Periodic Re-registration:**
   - Re-register users weekly to refresh tokens
   - Handle token expiration gracefully

4. **Analytics:**
   - Track permission grant rate
   - Track notification delivery rate
   - Monitor opt-out rate

## Files Modified

1. `lib/features/auth/login_screen.dart` - Fixed login flow
2. `lib/main.dart` - Improved startup logging

## Files Created (Backend)

1. `test-onesignal.js` - Test OneSignal configuration
2. `check-users-status.js` - Check multiple users
3. `QUICK_FIX_GUIDE.md` - Quick reference guide
4. `ONESIGNAL_TROUBLESHOOTING.md` - Comprehensive troubleshooting

## Support

If issues persist after deployment:

1. Check app logs: `adb logcat | grep OneSignal`
2. Check backend logs: `pm2 logs sks-notification-service`
3. Test specific user: `node test-onesignal.js <uid>`
4. Review troubleshooting guide: `ONESIGNAL_TROUBLESHOOTING.md`

## Summary

✅ **Root cause identified:** Registering users without checking permission first
✅ **Fix applied:** Check permission before calling `OneSignal.login(uid)`
✅ **Testing tools created:** Scripts to verify fix is working
✅ **Documentation created:** Guides for troubleshooting and monitoring

**Next Step:** Build and deploy the mobile app with these fixes.
