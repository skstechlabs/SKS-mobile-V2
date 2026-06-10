# R2 Wallpapers 401 Error - Quick Fix Guide

## Problem
Mobile backend getting 401 Unauthorized when fetching wallpapers from Cloudflare R2.

## Quick Diagnosis

Run the test script:
```bash
cd s:\Backup\sks-mobile-backend-service
node test-r2-credentials.js
```

This will tell you exactly what's wrong with the R2 configuration.

## Quick Fix Steps

### 1. Generate New R2 API Token (2 minutes)

1. Login to Cloudflare Dashboard: https://dash.cloudflare.com/
2. Go to **R2** → **Manage R2 API Tokens**
3. Click **Create API Token**
4. Configure:
   - Name: `sks-mobile-backend-service`
   - Permissions: ✅ Object Read & Write, ✅ Bucket Read
   - Bucket: `sadhaks` (or All buckets)
   - TTL: Never expire
5. Click **Create API Token**
6. **Copy both keys immediately** (you won't see them again!)

### 2. Update .env File (1 minute)

Edit `s:\Backup\sks-mobile-backend-service\.env`:

```env
# Replace these two lines with your new credentials:
R2_ACCESS_KEY_ID=YOUR_NEW_ACCESS_KEY_ID_HERE
R2_SECRET_ACCESS_KEY=YOUR_NEW_SECRET_ACCESS_KEY_HERE

# Keep these the same:
R2_ACCOUNT_ID=dfca0f529df9f308d904bbd559e88b81
R2_BUCKET_NAME=sadhaks
R2_PUBLIC_URL=https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev
```

### 3. Restart Service (30 seconds)

```bash
pm2 restart sks-mobile-backend-service
pm2 logs sks-mobile-backend-service --lines 20
```

### 4. Verify Fix (30 seconds)

```bash
# Test the endpoint
curl http://localhost:3013/api/wallpapers

# Or run the test script again
node test-r2-credentials.js
```

**Expected**: No more 401 errors, wallpapers list returned.

## If Still Not Working

### Check 1: Verify Wallpapers Exist in R2
1. Login to Cloudflare Dashboard
2. Go to R2 → Buckets → `sadhaks`
3. Navigate to `sadhaks/Wallpapers/` folder
4. Verify image files exist (.jpg, .png, etc.)

### Check 2: Verify Bucket Name
```bash
# Check bucket name in .env
cat s:\Backup\sks-mobile-backend-service\.env | grep R2_BUCKET_NAME
# Should show: R2_BUCKET_NAME=sadhaks
```

### Check 3: Test Credentials
```bash
cd s:\Backup\sks-mobile-backend-service
node test-r2-credentials.js
```

## Alternative: Temporary Disable Wallpapers

If you can't fix immediately, disable the feature:

Edit `s:\Backup\sks-mobile-backend-service\routes\wallpapers.js`:

```javascript
router.get('/', async (req, res) => {
  // Temporary: Return empty list until credentials are fixed
  return res.json({
    success: true,
    wallpapers: [],
    count: 0,
    message: 'Wallpapers temporarily unavailable'
  });
});
```

Then restart:
```bash
pm2 restart sks-mobile-backend-service
```

## Files Created

- ✅ `s:\Backup\sks-mobile-backend-service\R2_CREDENTIALS_FIX.md` - Detailed fix guide
- ✅ `s:\Backup\sks-mobile-backend-service\test-r2-credentials.js` - Test script
- ✅ `s:\SKS-mobile-V2\R2_WALLPAPERS_FIX_SUMMARY.md` - This file

## Priority

**Medium** - Wallpapers are a nice-to-have feature, not critical for app functionality.

## Impact

- Users cannot see/download wallpapers from the app
- No impact on other features (login, profile, classes, etc.)

---

**Next Steps**: Generate new R2 API token and update .env file
