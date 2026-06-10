# Profile Fix - Quick Start Guide

## 🚀 Quick Deployment (5 Minutes)

### Step 1: Run Database Migration (1 min)
```bash
sqlcmd -S localhost\SQLEXPRESS -U sa -P Sivoham@26 -d sivoham_dev -i "s:\Backup\sks-google-login-service\migrations\002_add_missing_profile_fields.sql"
```

### Step 2: Restart Services (1 min)
```bash
pm2 restart sks-google-login-service
pm2 restart sks-mobile-backend-service
pm2 list
```

### Step 3: Test Profile Completion (3 min)
1. Open mobile app
2. Login with Google
3. Fill profile form (all fields)
4. Submit
5. Logout and login again
6. ✅ Should NOT ask for profile again

---

## ✅ Quick Verification

### Check Logs
```bash
pm2 logs sks-mobile-backend-service --lines 20 | grep "profile"
```

**Expected:**
```
✅ Invalidated Redis cache for user {uid} after profile completion
✅ Synced profile completion to Google login service for user {uid}
```

**Should NOT see:**
```
⚠️  Failed to sync with Google login service: Request failed with status code 404
```

### Check Database
```sql
SELECT TOP 5
    uid,
    name,
    mobile,
    city,
    age,
    profession,
    is_profile_complete
FROM sivoham_dev.dbo.users
ORDER BY updated_at DESC;
```

**Expected:**
- All fields have values
- `is_profile_complete` = 1

---

## 🔧 What Was Fixed

1. **Database Mismatch** ✅
   - Both services now use `sivoham_dev`

2. **Endpoint Mismatch** ✅
   - Fixed URL: `/auth/profile` (was `/api/auth/profile`)

3. **Missing Fields** ✅
   - Added: age, profession, preferred_language, how_did_you_know, referrer_name, referrer_mobile, full_address, comments

---

## 📋 Files Changed

- `s:\Backup\sks-google-login-service\.env` - Database config
- `s:\Backup\sks-mobile-backend-service\routes\user.js` - Endpoint URL
- `s:\Backup\sks-google-login-service\src\repositories\userRepository.js` - Added fields
- `s:\Backup\sks-google-login-service\src\controllers\profileController.js` - Added fields
- `s:\Backup\sks-google-login-service\migrations\002_add_missing_profile_fields.sql` - Database migration

---

## 🆘 Quick Troubleshooting

### Issue: 404 Error
```bash
# Check endpoint URL
grep "auth/profile" s:\Backup\sks-mobile-backend-service\routes\user.js
# Should show: /auth/profile (not /api/auth/profile)
```

### Issue: Fields Not Saving
```sql
-- Check columns exist
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'users' AND COLUMN_NAME IN ('age', 'profession', 'mobile', 'city');
```

### Issue: Profile Re-prompt
```sql
-- Check is_profile_complete flag
SELECT uid, name, is_profile_complete FROM sivoham_dev.dbo.users WHERE email = 'YOUR_EMAIL';
-- Should be 1 (true)
```

---

## 📚 Full Documentation

- **Complete Fix**: `s:\SKS-mobile-V2\PROFILE_FIX_COMPLETE.md`
- **Deployment Guide**: `s:\SKS-mobile-V2\PROFILE_FIX_DEPLOYMENT.md`
- **Investigation**: `s:\SKS-mobile-V2\PROFILE_COMPLETION_FIX.md`

---

**Status**: ✅ Ready to Deploy  
**Time Required**: 5 minutes  
**Risk Level**: Low (all changes are backward compatible)
