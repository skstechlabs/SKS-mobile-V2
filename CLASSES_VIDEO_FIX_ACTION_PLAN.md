# Classes Video System - Fix Action Plan

## Issues Identified

### 1. CORS Error (Flutter Web Testing)
**Problem**: Backend was blocking requests from `localhost:62379` (Flutter Web dev server)

**Root Cause**: CORS configuration in `sks-backend/middleware/index.js` was only allowing specific production domains when `NODE_ENV=production`

**Fix Applied**: ✅
- Updated CORS configuration to allow ALL localhost origins for development/testing
- Changed from static array to dynamic function that checks origin
- Now allows: localhost, 127.0.0.1, production domains, and mobile apps (no origin)

### 2. API Response Type Cast Error
**Problem**: Mobile app expecting `Map<String, dynamic>` but receiving `String`

**Root Cause**: Dio might receive response as string in some cases, causing type cast failure

**Fix Applied**: ✅
- Added `responseType: ResponseType.json` to generic GET/POST methods
- Added fallback JSON parsing for string responses
- Added error handling for invalid response formats
- Imported `dart:convert` for JSON parsing

### 3. Database Migration Not Run
**Problem**: Tables `class_days`, `user_class_enrollments`, etc. don't exist in production database

**Status**: ⚠️ NEEDS TO BE RUN

**Action Required**: Run the migration script on production database

---

## Files Modified

### Backend Files
1. ✅ `sks-backend/middleware/index.js`
   - Updated CORS configuration to allow localhost origins
   - Changed from static array to dynamic origin function

### Mobile App Files
2. ✅ `SKS-mobile-V2/lib/core/services/api_service.dart`
   - Added `dart:convert` import
   - Updated `get()` method with JSON parsing fallback
   - Updated `post()` method with JSON parsing fallback
   - Added `responseType: ResponseType.json` to both methods

### New Files Created
3. ✅ `sks-backend/run-migration.js`
   - Node.js script to run database migration
   - Verifies tables were created
   - Shows sample data inserted

4. ✅ `sks-backend/test-classes-api.sh`
   - Bash script to test all classes video API endpoints
   - Tests enrollment, days, progress, video config, tracking

---

## Action Steps Required

### Step 1: Deploy Backend Changes ✅ DONE
```bash
cd sks-backend
# Restart the backend server to apply CORS changes
pm2 restart sks-backend
# OR if using ecosystem.config.js
pm2 restart ecosystem.config.js
```

### Step 2: Run Database Migration ⚠️ REQUIRED
```bash
cd sks-backend
node run-migration.js
```

**Expected Output**:
```
🚀 Starting database migration...
✅ Connected to database
📄 Running migration: create_classes_video_system.sql
✅ Migration completed successfully!

📊 Created tables:
   ✓ class_days
   ✓ user_class_enrollments
   ✓ user_day_progress
   ✓ video_analytics_summary
   ✓ video_watch_events

📝 Sample data: 12 class days inserted

📚 Classes configured:
   1. Level 1 - Brahmarandhra Opening (3 days)
   2. Level 2 - Sushumna Nadi Activation (3 days)
   3. Level 3 - Chakra Activation (3 days)
   4. Level 4 - Kundalini Activation (3 days)
```

### Step 3: Test API Endpoints ⚠️ REQUIRED
```bash
cd sks-backend
chmod +x test-classes-api.sh
./test-classes-api.sh <your-firebase-id-token>
```

**Note**: You need a valid Firebase ID token. Get it from:
- Flutter app: `FirebaseAuth.instance.currentUser?.getIdToken()`
- Or use the mobile app's network inspector to capture a real token

### Step 4: Rebuild Mobile App ⚠️ REQUIRED
```bash
cd SKS-mobile-V2
# For Flutter Web testing
flutter run -d chrome --dart-define-from-file=.env.prod.json

# For APK
./rebuild-production.sh
```

### Step 5: Test End-to-End Flow
1. Open mobile app (web or APK)
2. Navigate to "Online Courses"
3. Click on any level (Level 1, 2, 3, or 4)
4. Should see "Enroll Now" button
5. Click "Enroll Now"
6. Should see 3 days listed
7. Day 1 should be unlocked
8. Click on Day 1
9. Should see video player with Cloudflare Stream video

---

## Verification Checklist

### Backend Verification
- [ ] CORS headers allow localhost origins
- [ ] Database tables created successfully
- [ ] Sample data inserted (12 class days)
- [ ] API endpoints return JSON responses
- [ ] `/api/classes/1/days` returns array of days
- [ ] `/api/classes/1/enroll` creates enrollment

### Mobile App Verification
- [ ] No CORS errors in Flutter Web console
- [ ] No type cast errors in API service
- [ ] Classes list shows all 4 levels
- [ ] Clicking level shows days list
- [ ] Enrollment button works
- [ ] Day 1 unlocks after enrollment
- [ ] Video player loads Cloudflare Stream video

---

## Troubleshooting

### If CORS errors persist:
1. Check backend logs: `pm2 logs sks-backend`
2. Verify CORS headers in browser network tab
3. Ensure backend restarted after changes

### If database migration fails:
1. Check database credentials in `.env`
2. Verify MySQL connection: `mysql -u root -p`
3. Check if tables already exist: `SHOW TABLES LIKE 'class_%';`
4. If tables exist, migration will skip (uses `IF NOT EXISTS`)

### If API returns empty days:
1. Check if sample data was inserted: `SELECT COUNT(*) FROM class_days;`
2. Verify classes exist: `SELECT * FROM classes;`
3. Check class IDs match (1, 2, 3, 4)

### If video doesn't play:
1. Check Cloudflare video ID is correct
2. Verify video config endpoint returns `cloudflareVideoId`
3. Check browser console for iframe errors
4. Ensure Cloudflare account ID is correct

---

## Database Schema Overview

### Tables Created
1. **class_days** - Video content for each day
   - Links to classes table
   - Stores Cloudflare video ID
   - Configurable completion criteria

2. **user_class_enrollments** - User enrollment tracking
   - When user enrolled
   - Current day progress
   - Completion status

3. **user_day_progress** - Per-day progress tracking
   - Unlock status (24-hour mechanism)
   - Watch time and completion percentage
   - Last playback position

4. **video_watch_events** - Detailed analytics
   - Play, pause, seek, complete events
   - Session tracking
   - Device info

5. **video_analytics_summary** - Aggregated metrics
   - Daily summaries
   - Total views, watch time
   - Completion rates

### Stored Procedures
- **unlock_next_day_if_eligible** - Automatically unlocks next day after 24 hours

### Views
- **v_user_class_progress** - User's overall class progress
- **v_user_day_unlock_status** - Day unlock status with countdown

---

## Next Steps After Fix

1. **Configure Real Video IDs**
   - Currently all days use same video: `53a2449734925b7b5a41ac0f06099251`
   - Update `class_days` table with actual Cloudflare video IDs
   - Update video durations

2. **Test 24-Hour Unlock Mechanism**
   - Complete Day 1
   - Wait 24 hours (or manually update `completed_at` in database)
   - Verify Day 2 unlocks automatically

3. **Add Admin Panel**
   - Manage video content
   - View analytics
   - Configure completion criteria

4. **Monitor Analytics**
   - Track user engagement
   - Identify drop-off points
   - Optimize video content

---

## Support

If issues persist after following this guide:
1. Check backend logs: `pm2 logs sks-backend`
2. Check mobile app logs in console
3. Verify database connection and data
4. Test API endpoints with curl or Postman
