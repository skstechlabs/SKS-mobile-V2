# Splash Screen Hang Fix

## Problem
App was stuck on splash screen with continuous loader, not navigating to any screen.

## Root Causes Identified

### 1. **Backend SQL Syntax Error** ❌
**File:** `s:\Backup\sks-classes-service\routes\classes-video.js`

**Problem:**
The milestone-based tracking SQL query had invalid syntax:
```javascript
// BAD - Creates invalid SQL when no milestones reached
const positionSQL = shouldUpdatePosition 
  ? `last_position_seconds = ${milestonePositionToSave},`  // ← Trailing comma!
  : '';

await execute(
  `UPDATE user_day_progress SET ${positionSQL}
     completion_percentage = GREATEST(completion_percentage, ?),
     ...`
);
```

When no milestones are reached, this produces:
```sql
UPDATE user_day_progress SET 
   completion_percentage = GREATEST(completion_percentage, ?),
   -- Missing field before comma!
```

**Fix:**
```javascript
// GOOD - Comma before optional fields
const positionSQL = shouldUpdatePosition 
  ? `, last_position_seconds = ${milestonePositionToSave}` 
  : '';

await execute(
  `UPDATE user_day_progress SET 
     completion_percentage = GREATEST(completion_percentage, ?),
     watch_time_seconds = watch_time_seconds + 1,
     last_watched_at = GETDATE()
     ${positionSQL}
     ${milestoneSQL}
   WHERE user_uid = ? AND day_id = ?`,
  [completionPercentage, uid, dayId]
);
```

### 2. **Missing Timeouts in Splash Screen** ⏰
**File:** `s:\SKS-mobile-V2\lib\features\splash\splash_screen.dart`

**Problems:**
1. **No overall initialization timeout** - Could hang forever
2. **Localization wait loop** - Could loop infinitely
3. **Silent sign-in timeout too short** - 2 seconds insufficient for slow networks
4. **No backend login timeout** - Could hang on API call
5. **Token fetch retries** - 3 attempts with 500ms delay was too slow

**Fixes:**

#### Added Overall Timeout (10 seconds)
```dart
Future<void> _initializeApp() async {
  try {
    // Add overall timeout to prevent infinite loading
    await Future.any([
      _performInitialization(),
      Future.delayed(const Duration(seconds: 10), () {
        developer.log('⏰ Splash initialization timeout - going to login');
        throw TimeoutException('Splash initialization timed out');
      }),
    ]);
  } catch (e, st) {
    developer.log('❌ Splash error: $e\n$st');
    _navigate('/login');
  }
}
```

#### Fixed Localization Wait with Timeout
```dart
// Wait for localization with timeout
final localizationTimeout = DateTime.now().add(const Duration(seconds: 3));
while (!LocalizationService().isInitialized) {
  if (DateTime.now().isAfter(localizationTimeout)) {
    developer.log('⏰ Localization timeout - continuing anyway');
    break;
  }
  await Future.delayed(const Duration(milliseconds: 50));
  if (!mounted) return;
}
```

#### Increased Silent Sign-in Timeout
```dart
// Changed from 2 seconds to 3 seconds
firebaseUser = await AuthService()
    .attemptSilentSignIn()
    .timeout(const Duration(seconds: 3), onTimeout: () {
      developer.log('⏰ Silent sign-in timeout');
      return null;
    });
```

#### Added Backend Login Timeout
```dart
final result = await ApiService().loginWithGoogle(
  mobile: firebaseUser.phoneNumber ?? email,
  email: email,
  name: firebaseUser.displayName,
  photo: firebaseUser.photoURL,
  idToken: idToken,
).timeout(const Duration(seconds: 5), onTimeout: () {
  developer.log('⏰ Backend login timeout');
  return {'success': false, 'message': 'Login timeout'};
});
```

#### Optimized Token Fetching
```dart
// Reduced from 3 attempts to 2, faster timeouts
for (int i = 0; i < 2; i++) {
  try {
    idToken = await firebaseUser.getIdToken(i == 0)
        .timeout(const Duration(seconds: 3));
    if (idToken != null && idToken.isNotEmpty) break;
  } catch (e) {
    developer.log('⚠️ Token attempt $i failed: $e');
  }
  await Future.delayed(const Duration(milliseconds: 300)); // Reduced from 500ms
}
```

## Timeouts Summary

| Operation | Previous | Fixed | Reason |
|-----------|----------|-------|--------|
| Overall init | None ❌ | 10s | Prevent infinite loading |
| Localization | Infinite loop ❌ | 3s | Don't block app start |
| Silent sign-in | 2s | 3s | Handle slow networks |
| Backend login | None ❌ | 5s | Prevent API hang |
| Token fetch per attempt | None ❌ | 3s | Fail fast |
| Token retry delay | 500ms | 300ms | Faster recovery |

## Files Modified

### Backend
1. **`s:\Backup\sks-classes-service\routes\classes-video.js`**
   - Fixed SQL syntax error in milestone tracking
   - Properly formatted UPDATE query with optional fields

### Mobile App
1. **`s:\SKS-mobile-V2\lib\features\splash\splash_screen.dart`**
   - Added `dart:async` import for `TimeoutException`
   - Added overall 10-second initialization timeout
   - Added 3-second localization timeout
   - Increased silent sign-in timeout to 3 seconds
   - Added 5-second backend login timeout
   - Added 3-second token fetch timeout per attempt
   - Reduced token retry attempts from 3 to 2
   - Reduced retry delay from 500ms to 300ms
   - Split initialization into `_initializeApp()` and `_performInitialization()`

## Why It Was Hanging

### Scenario 1: Backend Not Running
If backend service was down or not responding:
- Silent login would call `ApiService().loginWithGoogle()`
- API call would wait for 45 seconds (Dio timeout)
- User sees loader for 45 seconds before timeout
- **Fix:** Added 5-second timeout to backend login call

### Scenario 2: Firebase Token Issues
If Firebase Auth had issues getting token:
- Loop tried 3 times with 500ms delay each
- Each attempt could hang without timeout
- Total possible hang: infinite
- **Fix:** Added 3-second timeout per attempt, reduced to 2 attempts

### Scenario 3: Localization Not Loading
If LocalizationService failed to initialize:
- Infinite while loop waiting for initialization
- App would never proceed
- **Fix:** Added 3-second timeout, then continue anyway

### Scenario 4: Silent Sign-in Hanging
If Google Play Services was slow:
- 2-second timeout was too aggressive for slow networks
- Might have caused repeated failures
- **Fix:** Increased to 3 seconds with proper null handling

## Testing Checklist

### Normal Flow
- [x] Fresh install (no language selected) → Language Selection
- [x] Logged out user → Login Screen
- [x] Logged in user → Home Page
- [x] Incomplete profile → Profile Setup

### Timeout Scenarios
- [x] Backend down → Login Screen after 5s
- [x] Slow network → Login Screen after 10s max
- [x] Firebase token failure → Login Screen
- [x] Localization slow → Continues after 3s

### Error Handling
- [x] All errors navigate to login screen
- [x] Logs show clear timeout messages
- [x] No infinite loops

## Deployment Steps

### Backend
```bash
cd s:\Backup\sks-classes-service
pm2 restart classes-service
pm2 logs classes-service --lines 50
```

### Mobile App
```bash
cd s:\SKS-mobile-V2
flutter clean
flutter pub get
flutter run
```

## Monitoring

Check logs for these patterns:

### Good Signs ✅
```
🚀 Splash: initializing...
✅ Cached user found → home
```
or
```
🚀 Splash: initializing...
👤 No session → login screen
```

### Timeout Messages (Expected) ⏰
```
⏰ Splash initialization timeout - going to login
⏰ Localization timeout - continuing anyway
⏰ Silent sign-in timeout
⏰ Backend login timeout
⏰ Token fetch timeout
```

### Error Messages (Investigate) ❌
```
❌ Splash error: [error details]
❌ Token attempt failed
❌ Backend rejected silent login
```

## Summary

✅ **Fixed SQL syntax error** in backend milestone tracking
✅ **Added overall 10-second timeout** to prevent infinite loading
✅ **Added timeouts to all async operations** (localization, sign-in, login, token)
✅ **Improved error handling** with proper fallbacks
✅ **Optimized token fetching** (2 attempts instead of 3, faster delays)
✅ **App now always navigates** within 10 seconds maximum

**Result:** Splash screen will never hang indefinitely. If anything fails, user sees login screen.
