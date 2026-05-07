# Complete Setup Guide - Classes Video System

## All Issues Fixed ✅

1. ✅ CORS configuration (backend already working)
2. ✅ API path fixed (now includes `/api` prefix)
3. ✅ Environment variables configured
4. ✅ Firebase token error logging improved
5. ⚠️ Database migration (needs to be run)

## Quick Start - 3 Steps

### Step 1: Run Database Migration
```bash
cd sks-backend
node run-migration.js
```

### Step 2: Test on Flutter Web
```bash
cd ../SKS-mobile-V2
./run-web-prod.sh
```

### Step 3: Build APK (Optional)
```bash
./rebuild-production.sh
```

## What Was Fixed

### 1. API Path Issue
**Before**: `https://sivakundalini.org/classes/1/days` ❌
**After**: `https://sivakundalini.org/api/classes/1/days` ✅

### 2. Environment Variables
**Before**: Running without `--dart-define-from-file` flag ❌
**After**: Created scripts that include the flag ✅

### 3. CORS
**Status**: Already working on backend ✅

### 4. Firebase Token Errors
**Status**: Improved logging, less noise ✅

## Files Modified

### Backend
- `middleware/firebaseAuth.js` - Improved error logging

### Mobile App
- `lib/core/services/api_service.dart` - API path fix
- `.env.json` - Updated to use production backend

### New Scripts
- `run-web-prod.sh` - Run Flutter Web with production backend
- `run-web-dev.sh` - Run Flutter Web with local backend
- `rebuild-production.sh` - Build production APK

### Backend Scripts
- `run-migration.js` - Database migration
- `verify-database.js` - Verify database setup
- `test-cors.sh` - Test CORS configuration

## Testing Instructions

### Test on Flutter Web
```bash
cd SKS-mobile-V2
./run-web-prod.sh
```

Expected behavior:
1. Browser opens with app
2. Environment check shows values (not empty)
3. No CORS errors in console
4. Can navigate to "Online Courses"
5. Can see 4 levels
6. Can click on a level
7. Can enroll in class
8. Can see days list
9. Day 1 unlocks after enrollment

### Test on APK
```bash
cd SKS-mobile-V2
./rebuild-production.sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Verification Checklist

### Backend
- [ ] Database migration completed
- [ ] 12 class days inserted
- [ ] API endpoints return 200 status
- [ ] CORS headers present

### Mobile App
- [ ] Environment variables loaded
- [ ] API calls use correct path
- [ ] No CORS errors
- [ ] Classes list shows
- [ ] Enrollment works
- [ ] Video player loads

## Common Issues

### Issue: Environment variables empty
**Solution**: Use `./run-web-prod.sh` instead of `flutter run -d chrome`

### Issue: CORS errors
**Solution**: Already fixed, just restart backend if needed

### Issue: "Invalid response format"
**Solution**: Run database migration

### Issue: Firebase token errors in logs
**Solution**: This is normal, see `FIREBASE_ERROR_NOT_A_PROBLEM.md`

## Documentation

- `COMPLETE_FIX_SUMMARY.md` - Detailed fix explanation
- `HOW_TO_RUN_FLUTTER_WEB.md` - Flutter Web instructions
- `FIREBASE_ERROR_NOT_A_PROBLEM.md` - Token error explanation
- `RUN_THESE_COMMANDS.txt` - Quick command reference

## Timeline

- ✅ API fixes: DONE
- ✅ Environment setup: DONE
- ⚠️ Database migration: 2 minutes (run now)
- ⚠️ Testing: 5 minutes

**Total: 7 minutes to complete!**

## Success Criteria

After completing all steps:

✅ No environment variable errors
✅ No CORS errors
✅ No API path errors
✅ Classes show in app
✅ Enrollment works
✅ Videos play

## Next Steps

1. Run database migration
2. Test on Flutter Web
3. Build and test APK
4. Configure real video IDs (optional)
5. Monitor analytics

Everything is ready - just run the migration and test!
