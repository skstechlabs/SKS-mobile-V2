# 🔧 Production Setup Fix - Complete Integration

## 🎯 Problem Summary

Mobile app showing "No songs available" even though:
- ✅ Backend services running in PM2 at app.sivakundalini.org
- ✅ Audio files in Cloudflare R2
- ✅ Database has audio records
- ❌ Mobile app can't fetch data

## 🔍 Root Cause

**Multiple issues:**
1. Mobile app built with **development config** (localhost URLs)
2. API Gateway doesn't have explicit `/api/audios` route (relies on catch-all)
3. Database might be using wrong connection (sivoham_dev vs production)

---

## ✅ Step-by-Step Fix

### **STEP 1: Verify Backend Services Are Running**

Check PM2 status:
```bash
pm2 list
```

**Expected services:**
- `api-gateway` (port 3000)
- `sks-mobile-backend-service` (port 3013)
- Others (notification, classes, etc.)

If NOT running:
```bash
cd /path/to/api-gateway
pm2 start ecosystem.config.js
```

---

### **STEP 2: Test Backend Locally**

Run test script:
```powershell
cd s:\Backup\sks-mobile-backend-service
.\test-audio-endpoint.ps1
```

**Expected output:**
```
✅ Service is running
✅ Audios endpoint working
Total audios: 11
✅ Cloudflare URL is accessible
```

**If service NOT running:**
```bash
cd s:\Backup\sks-mobile-backend-service
node server.js
```

**If no audios found:**
```sql
-- Connect to SQL Server
-- Run: s:\Backup\sks-mobile-backend-service\sql\populate_audios_NOW.sql
```

---

### **STEP 3: Test Through API Gateway**

```powershell
# Test gateway routing
curl http://localhost:3000/api/audios

# Test via domain (if on server)
curl https://app.sivakundalini.org/api/audios
```

**Expected:** JSON with audio list

---

### **STEP 4: Update Mobile App Configuration**

The `.env.json` has been updated to:
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org",
  ...
}
```

Also created `.env.prod.json` for production builds.

---

### **STEP 5: Rebuild Mobile App**

**For immediate testing (debug):**
```cmd
cd s:\SKS-mobile-V2
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env.json
```

**For production APK:**
```cmd
flutter build apk --release --dart-define-from-file=.env.prod.json
```

---

### **STEP 6: Verify Mobile App Connection**

After running the app, check logs:
```
✅ AudioProvider initialized
[AudioProvider] Fetching audios from API...
[AudioProvider] Fetched 11 audios
[AudioProvider] - Bhajans: 6
[AudioProvider] - Meditations: 4
```

**If still failing:**
- Check mobile device has internet
- Try opening `https://app.sivakundalini.org/api/audios` in mobile browser
- Check DNS resolution

---

## 🗄️ Database Configuration Check

### **Option A: Using Production Database**

If your production database is different from `sivoham_dev`, update:

**File:** `s:\Backup\sks-mobile-backend-service\.env`
```env
# Change from:
DB_DATABASE=sivoham_dev

# To:
DB_DATABASE=sivoham_production  # or your actual production DB name
```

Restart service:
```bash
pm2 restart sks-mobile-backend-service
```

### **Option B: Populate sivoham_dev with Data**

If using sivoham_dev, ensure it has data:

```sql
USE sivoham_dev;

-- Check if audios table exists
SELECT COUNT(*) FROM audios WHERE is_active = 1;

-- If empty or table doesn't exist, run:
-- s:\Backup\sks-mobile-backend-service\sql\populate_audios_NOW.sql
```

---

## 🌐 Network & DNS Troubleshooting

### Test DNS Resolution

**From mobile device:**
```
Open browser → https://app.sivakundalini.org/api/audios
```

**Expected:** JSON response with audio data

**If DNS fails:**
1. Check domain DNS settings
2. Use server IP directly in `.env.prod.json`:
   ```json
   {
     "API_BASE_URL": "http://YOUR_SERVER_IP:3000",
     ...
   }
   ```

### Test from Server

```bash
# On your server (app.sivakundalini.org)
curl http://localhost:3000/api/audios
curl http://localhost:3013/api/audios
```

Both should return audio data.

---

## 🔍 Debugging Checklist

### Backend Services

- [ ] PM2 shows services running
- [ ] `http://localhost:3013/api/audios` returns data
- [ ] `http://localhost:3000/api/audios` returns data (through gateway)
- [ ] `https://app.sivakundalini.org/api/audios` returns data (public)
- [ ] Database has 11+ audio records
- [ ] Cloudflare URLs are accessible

### Mobile App

- [ ] `.env.json` has correct `API_BASE_URL`
- [ ] App built with `--dart-define-from-file=.env.json`
- [ ] Mobile device has internet connection
- [ ] Mobile can access `app.sivakundalini.org` in browser
- [ ] Console shows "AudioProvider initialized"
- [ ] Console shows "Fetched X audios"

---

## 🚀 Production Deployment Checklist

### Server Side (One Time)

1. **Database Setup:**
   ```sql
   -- Create production database if needed
   CREATE DATABASE sivoham_production;
   
   -- Run audio schema
   USE sivoham_production;
   -- Execute: sql/create_audios_table.sql
   -- Execute: sql/populate_audios_NOW.sql
   ```

2. **Update Backend .env:**
   ```env
   NODE_ENV=production
   DB_DATABASE=sivoham_production
   ```

3. **Start Services:**
   ```bash
   pm2 restart all
   pm2 save
   ```

### Mobile App (Every Release)

1. **Build APK:**
   ```cmd
   flutter build apk --release --dart-define-from-file=.env.prod.json
   ```

2. **Test APK:**
   - Install on test device
   - Verify audio loads
   - Test playback

3. **Deploy:**
   - Upload to Play Store
   - Users get update

---

## 📊 Expected Flow

### Correct Data Flow:
```
Mobile App (.env.json: app.sivakundalini.org)
    ↓
API Gateway (port 3000)
    ↓
Mobile Backend Service (port 3013)
    ↓
MSSQL Database (sivoham_dev or sivoham_production)
    ↓
Returns: Audio URLs (Cloudflare R2)
    ↓
Mobile App downloads from Cloudflare
    ↓
Plays audio
```

### What Was Wrong:
```
Mobile App (.env.json: localhost:3000) ❌
    ↓
Can't connect (not accessible from real device)
    ↓
Falls back to: app.sivakundalini.org ❌
    ↓
DNS resolution fails / Network issue
    ↓
No data loaded
```

---

## 🎯 Quick Test Script

Create this test on your server:

**File:** `/tmp/test-integration.sh`
```bash
#!/bin/bash

echo "=== Testing SKS Integration ==="

# Test backend service
echo "1. Testing backend service..."
curl -s http://localhost:3013/api/audios | jq '.success, .audios | length'

# Test gateway
echo "2. Testing API gateway..."
curl -s http://localhost:3000/api/audios | jq '.success, .audios | length'

# Test public domain
echo "3. Testing public domain..."
curl -s https://app.sivakundalini.org/api/audios | jq '.success, .audios | length'

# Test Cloudflare
echo "4. Testing Cloudflare R2..."
curl -I https://pub-feda269d36484d78b7cfc71353b6d67c.r2.dev/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3

echo "=== Test Complete ==="
```

Run:
```bash
chmod +x /tmp/test-integration.sh
/tmp/test-integration.sh
```

**Expected:** All tests pass with success=true and audio count > 0

---

## 📞 Summary

### What Was Done:
1. ✅ Updated `.env.json` to use `https://app.sivakundalini.org`
2. ✅ Created `.env.prod.json` for production builds
3. ✅ Created test script `test-audio-endpoint.ps1`
4. ✅ Documented complete integration flow

### Next Steps:
1. **Verify backend services are running in PM2**
2. **Test backend locally** with PowerShell script
3. **Rebuild mobile app** with correct config
4. **Test on real device**

### If Still Failing:
- Check PM2 logs: `pm2 logs sks-mobile-backend-service`
- Check database connection
- Test domain accessibility from mobile
- Check firewall/network settings

---

## 🆘 Common Issues

### Issue 1: "No songs available"
**Cause:** Database empty or wrong database
**Fix:** Run `populate_audios_NOW.sql`

### Issue 2: "Connection timeout"
**Cause:** DNS not resolving or network blocked
**Fix:** Test domain in mobile browser first

### Issue 3: "No logs in services"
**Cause:** App not reaching backend
**Fix:** Check `.env.json` has correct URL

### Issue 4: Services not in PM2
**Cause:** Services not started
**Fix:** `pm2 start ecosystem.config.js`

---

**Ready to test! Start with Step 1 and work through each step.** 🚀
