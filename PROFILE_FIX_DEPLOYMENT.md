# Profile Completion Fix - Deployment Guide

## Overview
This guide provides step-by-step instructions to deploy the profile completion fix that resolves:
1. Database mismatch between services
2. Endpoint URL mismatch causing 404 errors
3. Missing profile fields not being saved

---

## Pre-Deployment Checklist

### ✅ Verify Current State
```bash
# Check which services are running
pm2 list

# Check current database configuration
cat s:\Backup\sks-google-login-service\.env | grep DB_DATABASE
cat s:\Backup\sks-mobile-backend-service\.env | grep DB_DATABASE

# Check service logs for errors
pm2 logs sks-google-login-service --lines 50
pm2 logs sks-mobile-backend-service --lines 50
```

### ✅ Backup Current Configuration
```bash
# Backup .env files
copy s:\Backup\sks-google-login-service\.env s:\Backup\sks-google-login-service\.env.backup
copy s:\Backup\sks-mobile-backend-service\.env s:\Backup\sks-mobile-backend-service\.env.backup

# Backup database (optional but recommended)
# Use SQL Server Management Studio to backup sivoham_dev database
```

---

## Deployment Steps

### Step 1: Update Database Schema

**Run the migration script to add missing columns:**

```sql
-- Open SQL Server Management Studio
-- Connect to your SQL Server instance
-- Open file: s:\Backup\sks-google-login-service\migrations\002_add_missing_profile_fields.sql
-- Execute the script

-- OR run from command line:
sqlcmd -S localhost\SQLEXPRESS -U sa -P Sivoham@26 -d sivoham_dev -i "s:\Backup\sks-google-login-service\migrations\002_add_missing_profile_fields.sql"
```

**Expected Output:**
```
Starting migration: Add missing profile fields
✅ Added column: age
✅ Added column: profession
✅ Added column: preferred_language
✅ Added column: how_did_you_know
✅ Added column: how_did_you_know_other
✅ Added column: referrer_name
✅ Added column: referrer_mobile
✅ Added column: full_address
✅ Added column: comments
✅ Migration 002_add_missing_profile_fields completed successfully
```

**Verify columns were added:**
```sql
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users'
ORDER BY COLUMN_NAME;
```

---

### Step 2: Verify Configuration Changes

**All configuration changes have already been made. Verify they are correct:**

#### Google Login Service (.env)
```bash
# Check database configuration
cat s:\Backup\sks-google-login-service\.env | grep DB_DATABASE
# Should show: DB_DATABASE=sivoham_dev
```

#### Mobile Backend Service (.env)
```bash
# Check Google login service URL
cat s:\Backup\sks-mobile-backend-service\.env | grep GOOGLE_LOGIN_SERVICE_URL
# Should show: GOOGLE_LOGIN_SERVICE_URL=http://localhost:3010
```

#### Mobile Backend Service (routes/user.js)
```bash
# Verify endpoint URLs are correct (should be /auth/profile, not /api/auth/profile)
grep -n "auth/profile" s:\Backup\sks-mobile-backend-service\routes\user.js
# Should show lines with: ${googleLoginServiceUrl}/auth/profile
```

---

### Step 3: Restart Services

**Restart services in the correct order:**

```bash
# 1. Restart Google login service first (picks up new database config)
pm2 restart sks-google-login-service

# Wait 5 seconds for service to fully start
timeout /t 5

# 2. Restart mobile backend service (picks up endpoint fix)
pm2 restart sks-mobile-backend-service

# Wait 5 seconds
timeout /t 5

# 3. Verify services are running
pm2 list

# 4. Check logs for startup errors
pm2 logs sks-google-login-service --lines 20
pm2 logs sks-mobile-backend-service --lines 20
```

**Expected Log Output:**

Google Login Service:
```
✅ Database connected successfully
✅ Redis connected successfully
🚀 Google Login Service running on port 3010
```

Mobile Backend Service:
```
✅ Database connected successfully
✅ Redis connected successfully
🚀 Mobile Backend Service running on port 3013
```

---

### Step 4: Test Profile Completion

#### Test Case 1: New User Profile Completion

1. **Open mobile app**
2. **Login with Google** (use a test account)
3. **Fill profile form** with ALL fields:
   ```
   Name: Test User
   Gender: Male
   Date of Birth: 01/01/1990
   Age: 34
   Mobile: +919876543210
   City: Bangalore
   State: Karnataka
   Pincode: 560001
   Country: India
   Profession: Software Engineer
   Preferred Language: English
   How did you know: Friend
   Referrer Name: John Doe
   Referrer Mobile: +919876543211
   Address: Test Address
   Comments: Test comments
   ```
4. **Submit profile**
5. **Check logs** for success messages:
   ```bash
   pm2 logs sks-mobile-backend-service --lines 50 | grep "profile"
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

6. **Verify in database:**
   ```sql
   SELECT 
       uid,
       name,
       mobile,
       email,
       gender,
       age,
       city,
       profession,
       preferred_language,
       is_profile_complete,
       created_at,
       updated_at
   FROM sivoham_dev.dbo.users
   WHERE email = 'test@example.com';  -- Replace with your test email
   ```
   
   **Expected:**
   - All fields should have values
   - `is_profile_complete` should be `1`
   - `mobile` should be `+919876543210`
   - `city` should be `Bangalore`
   - `age` should be `34`
   - `profession` should be `Software Engineer`

#### Test Case 2: Re-login (No Profile Re-prompt)

1. **Logout** from the app
2. **Close the app** completely
3. **Open the app** again
4. **Login with same Google account**
5. **Verify**: Should go directly to home screen (NOT profile form)
6. **Check database:**
   ```sql
   SELECT 
       uid,
       name,
       is_profile_complete,
       last_login_at
   FROM sivoham_dev.dbo.users
   WHERE email = 'test@example.com';
   ```
   
   **Expected:**
   - `is_profile_complete` should still be `1`
   - `last_login_at` should be updated to current time

#### Test Case 3: Profile Update

1. **Go to Profile screen** in app
2. **Update some fields** (e.g., change city to "Mumbai")
3. **Save changes**
4. **Check database:**
   ```sql
   SELECT 
       uid,
       city,
       updated_at
   FROM sivoham_dev.dbo.users
   WHERE email = 'test@example.com';
   ```
   
   **Expected:**
   - `city` should be `Mumbai`
   - `updated_at` should be current time

---

### Step 5: Monitor Logs

**Monitor logs for any errors during testing:**

```bash
# Real-time log monitoring
pm2 logs sks-google-login-service sks-mobile-backend-service

# Filter for errors
pm2 logs sks-google-login-service --err
pm2 logs sks-mobile-backend-service --err

# Filter for profile-related logs
pm2 logs sks-mobile-backend-service | grep -i "profile"
```

**Common Issues to Watch For:**

❌ **404 Error** - Endpoint mismatch not fixed
```
⚠️  Failed to sync with Google login service: Request failed with status code 404
```
**Solution**: Verify endpoint URL is `/auth/profile` (not `/api/auth/profile`)

❌ **Database Error** - Missing columns
```
Invalid column name 'age'
Invalid column name 'profession'
```
**Solution**: Run migration script from Step 1

❌ **Connection Refused** - Service not running
```
ECONNREFUSED
```
**Solution**: Check service is running on correct port (3010 for Google login)

---

## Rollback Plan

If issues occur, rollback using these steps:

### 1. Restore Configuration
```bash
# Restore .env files
copy s:\Backup\sks-google-login-service\.env.backup s:\Backup\sks-google-login-service\.env
copy s:\Backup\sks-mobile-backend-service\.env.backup s:\Backup\sks-mobile-backend-service\.env

# Restart services
pm2 restart sks-google-login-service sks-mobile-backend-service
```

### 2. Rollback Database (if needed)
```sql
-- Remove added columns (only if they cause issues)
ALTER TABLE users DROP COLUMN age;
ALTER TABLE users DROP COLUMN profession;
ALTER TABLE users DROP COLUMN preferred_language;
ALTER TABLE users DROP COLUMN how_did_you_know;
ALTER TABLE users DROP COLUMN how_did_you_know_other;
ALTER TABLE users DROP COLUMN referrer_name;
ALTER TABLE users DROP COLUMN referrer_mobile;
ALTER TABLE users DROP COLUMN full_address;
ALTER TABLE users DROP COLUMN comments;
```

---

## Post-Deployment Verification

### ✅ Service Health Check
```bash
# Check all services are running
pm2 list

# Check service health endpoints
curl http://localhost:3010/health
curl http://localhost:3013/health
```

### ✅ Database Verification
```sql
-- Check recent profile completions
SELECT TOP 10
    uid,
    name,
    mobile,
    city,
    age,
    profession,
    is_profile_complete,
    created_at,
    updated_at
FROM sivoham_dev.dbo.users
WHERE is_profile_complete = 1
ORDER BY updated_at DESC;

-- Check for any NULL values in critical fields
SELECT 
    COUNT(*) as total_users,
    SUM(CASE WHEN is_profile_complete = 1 THEN 1 ELSE 0 END) as completed_profiles,
    SUM(CASE WHEN mobile IS NULL THEN 1 ELSE 0 END) as missing_mobile,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) as missing_city
FROM sivoham_dev.dbo.users;
```

### ✅ Redis Cache Check
```bash
# Connect to Redis
redis-cli

# Check cached users
KEYS user:*

# Check a specific user cache
GET user:YOUR_UID

# Exit Redis
exit
```

---

## Success Criteria

Deployment is successful when:

- ✅ All services running without errors
- ✅ Database schema has all required columns
- ✅ Profile completion saves all fields to database
- ✅ No 404 errors in logs
- ✅ Re-login does not re-prompt for profile
- ✅ `is_profile_complete` flag works correctly
- ✅ Redis cache invalidation working
- ✅ Service sync working (no sync errors)

---

## Support

If issues persist after deployment:

1. **Check logs**: `pm2 logs sks-google-login-service sks-mobile-backend-service`
2. **Verify database**: Run verification queries above
3. **Check Redis**: Ensure Redis is running and accessible
4. **Review configuration**: Double-check all .env files
5. **Restart services**: `pm2 restart all`

For additional help, refer to:
- `s:\SKS-mobile-V2\PROFILE_FIX_COMPLETE.md` - Complete fix documentation
- `s:\SKS-mobile-V2\PROFILE_COMPLETION_FIX.md` - Original investigation
- Service logs in PM2

---

## Files Modified Summary

### Configuration Files
- ✅ `s:\Backup\sks-google-login-service\.env`
- ✅ `s:\Backup\sks-mobile-backend-service\routes\user.js`

### Code Files
- ✅ `s:\Backup\sks-google-login-service\src\repositories\userRepository.js`
- ✅ `s:\Backup\sks-google-login-service\src\controllers\profileController.js`

### Database Files
- ✅ `s:\Backup\sks-google-login-service\migrations\002_add_missing_profile_fields.sql`

### Documentation Files
- ✅ `s:\SKS-mobile-V2\PROFILE_FIX_COMPLETE.md`
- ✅ `s:\SKS-mobile-V2\PROFILE_FIX_DEPLOYMENT.md`

---

**Deployment Date**: 2026-06-01  
**Version**: 1.0  
**Status**: Ready for deployment
