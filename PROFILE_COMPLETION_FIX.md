# 🔴 CRITICAL: Profile Completion Issues - Complete Fix

**Date:** June 1, 2026
**Status:** 🔴 CRITICAL ISSUES FOUND

---

## 🔴 Issues Found

### Issue 1: Wrong Service URL in Mobile Backend
**Problem:** Mobile backend is trying to sync profile data to wrong port
- Mobile backend `.env`: `GOOGLE_LOGIN_SERVICE_URL=http://localhost:3001`
- Google login service actual port: `3010`
- **Result:** Profile sync fails silently

### Issue 2: Profile Data Not Captured
**Problem:** Some fields like `mobile`, `city`, etc. not being saved to database
- Need to verify the actual SQL UPDATE query
- Need to check if all fields are being passed from Flutter

### Issue 3: Profile Re-prompt on Re-login
**Problem:** User logs out and logs in again, asked to fill profile again
- `is_profile_complete` flag not being set correctly
- OR cache not being invalidated properly
- OR Flutter app not checking the flag correctly

---

## ✅ Fix 1: Update Mobile Backend Service URL

### Step 1: Fix the .env file
```bash
# Update s:\Backup\sks-mobile-backend-service\.env
GOOGLE_LOGIN_SERVICE_URL=http://localhost:3010
```

### Step 2: Restart mobile backend service
```bash
pm2 restart mobile-backend-service
```

---

## ✅ Fix 2: Verify Database Schema and Data

### Check 1: Verify users table has all fields
```sql
-- Connect to sivoham_google_auth database
USE [sivoham_google_auth];
GO

-- Check table schema
EXEC sp_help 'users';

-- Check what fields exist
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;
```

### Check 2: See what data is actually in the table
```sql
-- Check recent users
SELECT TOP 10
    uid,
    mobile,
    email,
    name,
    gender,
    city,
    state,
    pincode,
    country,
    is_profile_complete,
    permissions_granted,
    created_at,
    updated_at
FROM users
ORDER BY updated_at DESC;
```

### Check 3: Check a specific user
```sql
-- Replace with actual UID
SELECT *
FROM users
WHERE uid = 'YOUR_USER_UID';
```

---

## ✅ Fix 3: Verify Profile Update Logic

### Check mobile-backend-service logs
```bash
pm2 logs mobile-backend-service --lines 100 | grep -i "profile\|update\|INSERT\|UPDATE"
```

Look for:
- ✅ "Profile completion successful"
- ✅ "Synced profile completion to Google login service"
- ❌ "Failed to sync with Google login service" (this means wrong URL)

### Check google-login-service logs
```bash
pm2 logs google-login-service --lines 100 | grep -i "profile\|update"
```

Look for:
- ✅ "Profile updated successfully"
- ✅ "Profile completion status changed"

---

## ✅ Fix 4: Verify Flutter App Logic

### Check 1: Profile completion request
The Flutter app should send ALL required fields:

```dart
// In ApiService.completeProfile()
{
  "name": "John Doe",
  "mobile": "+919876543210",  // ⚠️ MUST be included
  "gender": "Male",
  "age": 30,
  "city": "Hyderabad",        // ⚠️ MUST be included
  "state": "Telangana",
  "pincode": "500001",
  "profession": "Engineer",
  "preferred_language": "Telugu",
  "country": "India",
  "date_of_birth": "1994-01-01",
  "address": "Full address",
  "how_did_you_know": "Friend",
  "referrer_name": "Friend Name",
  "referrer_mobile": "+919876543210"
}
```

### Check 2: Profile complete flag check
After login, Flutter should check:

```dart
if (response['user']['is_profile_complete'] == true) {
  // Go to home
} else {
  // Go to profile completion
}
```

---

## 🧪 Testing Procedure

### Test 1: Fresh Login
1. Delete app data (or use new Google account)
2. Login with Google
3. Fill profile form with ALL fields
4. Submit
5. **Verify in database:**
   ```sql
   SELECT mobile, city, state, pincode, is_profile_complete
   FROM users
   WHERE uid = 'YOUR_UID';
   ```
6. **Expected:** All fields should be populated, `is_profile_complete = 1`

### Test 2: Re-login
1. Logout from app
2. Login again with same Google account
3. **Expected:** Should go directly to home (NOT profile form)
4. **If it shows profile form again:**
   - Check database: `SELECT is_profile_complete FROM users WHERE uid = 'YOUR_UID';`
   - Should be `1` (true)
   - If it's `0` (false), profile completion failed

### Test 3: Profile Data Persistence
1. Login
2. Go to Profile screen
3. **Verify all fields are shown:**
   - Name ✅
   - Mobile ✅
   - Email ✅
   - Gender ✅
   - City ✅
   - State ✅
   - Pincode ✅
   - etc.

---

## 🔍 Debugging Commands

### Check if mobile backend can reach google login service
```bash
# From mobile backend server
curl http://localhost:3010/health
# Should return: {"status":"OK"}
```

### Check profile sync endpoint
```bash
# Test the sync endpoint
curl -X PUT http://localhost:3010/api/auth/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{"name":"Test","is_profile_complete":true}'
```

### Monitor logs in real-time
```bash
# Terminal 1: Mobile backend logs
pm2 logs mobile-backend-service --lines 0

# Terminal 2: Google login service logs
pm2 logs google-login-service --lines 0

# Terminal 3: API gateway logs
pm2 logs api-gateway --lines 0

# Then test profile completion from app
```

---

## 📋 Complete Fix Checklist

- [ ] **Fix 1: Update mobile backend .env**
  ```bash
  # Change GOOGLE_LOGIN_SERVICE_URL from 3001 to 3010
  # Restart: pm2 restart mobile-backend-service
  ```

- [ ] **Fix 2: Verify database schema**
  ```sql
  -- Check users table has all required fields
  EXEC sp_help 'users';
  ```

- [ ] **Fix 3: Test profile completion**
  - [ ] Fresh login → Fill profile → Check database
  - [ ] Verify all fields saved (mobile, city, etc.)
  - [ ] Verify `is_profile_complete = 1`

- [ ] **Fix 4: Test re-login**
  - [ ] Logout → Login again
  - [ ] Should NOT show profile form
  - [ ] Should go directly to home

- [ ] **Fix 5: Check logs for errors**
  - [ ] Mobile backend logs: No "Failed to sync" errors
  - [ ] Google login service logs: "Profile updated successfully"

---

## 🚨 Common Issues

### Issue: "Failed to sync with Google login service"
**Cause:** Wrong URL in mobile backend .env
**Fix:** Update `GOOGLE_LOGIN_SERVICE_URL=http://localhost:3010`

### Issue: Mobile field is NULL in database
**Cause:** Flutter app not sending mobile in profile completion request
**Fix:** Check `ApiService.completeProfile()` includes mobile field

### Issue: is_profile_complete is 0 after completion
**Cause:** Profile completion SQL UPDATE not setting the flag
**Fix:** Check mobile-backend-service `POST /api/user/profile` route

### Issue: Profile form shows again after re-login
**Cause:** Flutter app not checking `is_profile_complete` flag
**Fix:** Check login response handling in Flutter

---

## 📝 Files to Check

### Backend Files:
1. `s:\Backup\sks-mobile-backend-service\.env` - Fix GOOGLE_LOGIN_SERVICE_URL
2. `s:\Backup\sks-mobile-backend-service\routes\user.js` - Profile completion logic
3. `s:\Backup\sks-google-login-service\src\controllers\profileController.js` - Profile update
4. `s:\Backup\sks-google-login-service\src\repositories\userRepository.js` - Database operations

### Flutter Files:
1. `s:\SKS-mobile-V2\lib\core\services\api_service.dart` - completeProfile() method
2. `s:\SKS-mobile-V2\lib\features\auth\login_page.dart` - Login response handling
3. `s:\SKS-mobile-V2\lib\features\profile\complete_profile_page.dart` - Profile form

---

## ✅ Quick Fix Script

```bash
# 1. Fix mobile backend URL
cd s:\Backup\sks-mobile-backend-service
# Edit .env: Change GOOGLE_LOGIN_SERVICE_URL to http://localhost:3010

# 2. Restart services
pm2 restart mobile-backend-service
pm2 restart google-login-service

# 3. Test
curl http://localhost:3010/health
# Should return: {"status":"OK"}

# 4. Check database
sqlcmd -S localhost\SQLEXPRESS -d sivoham_google_auth -Q "SELECT TOP 5 uid, mobile, city, is_profile_complete FROM users ORDER BY updated_at DESC"
```

---

## 🎯 Next Steps

1. **Immediate:** Fix mobile backend .env and restart
2. **Verify:** Check database to see what's actually being saved
3. **Test:** Do a fresh profile completion and check database
4. **Monitor:** Watch logs during profile completion
5. **Fix:** Update code based on what you find

---

**Status:** Ready to fix - Follow the checklist above
