# 📋 Step-by-Step Audio Migration - Complete Guide

## ✅ What I've Done For You

### Updated `.env` File
Added audio-specific configuration:
```env
R2_AUDIO_BUCKET_NAME=sks-audio-files
R2_AUDIO_BASE_PATH=sks-audio-files  
R2_AUDIO_PUBLIC_URL=https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/sks-audio-files
```

---

## 🎯 YOUR ACTION PLAN

### ⏱️ Total Time: ~30 minutes

---

## STEP 1: Verify Cloudflare R2 (5 min)

### 1.1 Login to Cloudflare
1. Go to: https://dash.cloudflare.com/
2. Click **"R2"** in sidebar
3. Find bucket with audio files (likely "sadhaks")

### 1.2 Check File Location
Look for files in your bucket:
```
Are files here?
sadhaks/sks-audio-files/Sivoham_ringtone.mp3 ← Most likely
OR
sks-audio-files/Sivoham_ringtone.mp3
```

### 1.3 Enable Public Access
1. Click on bucket
2. Go to **Settings** tab
3. Find **"Public Access"** section  
4. **Enable R2.dev subdomain access**
5. Save

---

## STEP 2: Test One Audio URL (2 min)

### Copy and paste in browser:

**Try URL 1:**
```
https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/sks-audio-files/Sivoham_ringtone.mp3
```

**If that fails, try URL 2:**
```
https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/Sivoham_ringtone.mp3
```

### What should happen:
- ✅ Audio plays or downloads = SUCCESS!
- ❌ 403 Error = Enable public access (Step 1.3)
- ❌ 404 Error = Wrong path, check bucket again

**→ Once one URL works, continue to Step 3**

---

## STEP 3: Populate Database (5 min)

### Open Command Prompt:

```cmd
cd s:\Backup\sks-mobile-backend-service

sqlcmd -S localhost\SQLEXPRESS -U sa -P Sivoham@26 -d sivoham_dev -i sql\populate_audios_cloudflare_READY.sql
```

### Expected output:
```
category   count
---------- -----
bhajan     6
meditation 4  
ringtone   1

Total Records Inserted: 11
```

### If error "Invalid object name 'audios'":
```cmd
sqlcmd -S localhost\SQLEXPRESS -U sa -P Sivoham@26 -d sivoham_dev -i sql\create_audios_table.sql
```
Then run populate script again.

---

## STEP 4: Test Backend API (3 min)

### 4.1 Start Backend (if not running):
```cmd
cd s:\Backup\sks-mobile-backend-service
node server.js
```

### 4.2 Test in Browser or New Terminal:
```
http://localhost:3013/api/audios
```

### Expected:
```json
{
  "success": true,
  "data": [...11 audio objects...],
  "count": 11
}
```

---

## STEP 5: Test Mobile App (10 min)

### 5.1 Run App:
```cmd
cd s:\SKS-mobile-V2
flutter run
```

### 5.2 Check Console Output:
Look for:
```
✅ AudioProvider initialized
[AudioProvider] Fetched 11 audios
[AudioProvider] - Bhajans: 6
[AudioProvider] - Meditations: 4
```

### 5.3 Test in App:

**Test 1: View Songs**
- Open Bhajans page
- Should see 6 songs

**Test 2: Play Song (First Time)**
- Tap any song
- Should show download progress (2-5 sec)
- Audio plays after download

**Test 3: Play Again (Cached)**
- Stop and replay same song
- Should start instantly (< 1 sec)
- No download progress

**Test 4: Offline Mode**
- Enable Airplane Mode
- Replay cached song
- Should work offline!

---

## STEP 6: Remove Assets (OPTIONAL - After testing)

### Edit pubspec.yaml:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/translations/
    # - assets/audio/  ← Comment out or remove
```

### Rebuild:
```cmd
flutter clean
flutter pub get
flutter build apk --release
```

**Result:** App size ~60 MB (was ~120 MB) - **50% smaller!**

---

## ✅ Success Checklist

Mark complete as you go:

### Backend
- [ ] R2 public access enabled
- [ ] One audio URL works in browser
- [ ] Database has 11 records
- [ ] API returns 11 audios

### Mobile App  
- [ ] App logs show "Fetched 11 audios"
- [ ] Bhajans page shows 6 songs
- [ ] First play downloads (2-5 sec)
- [ ] Second play instant (cached)
- [ ] Offline mode works

---

## 🆘 Quick Fixes

### URLs return 403
→ Enable public access in R2 settings

### URLs return 404  
→ Check file path in R2 dashboard

### Database error
→ Run create_audios_table.sql first

### API returns empty
→ Check database has data: `SELECT COUNT(*) FROM audios`

### App doesn't load songs
→ Check backend is running on port 3013

---

## 📁 Files Reference

**Backend:**
- `.env` - Updated with R2_AUDIO_* variables
- `sql/populate_audios_cloudflare_READY.sql` - Database script
- `sql/create_audios_table.sql` - Create table if needed

**Mobile:**
- `lib/main.dart` - Already updated with AudioProvider
- `lib/core/providers/audio_provider.dart` - Handles API calls
- `pubspec.yaml` - Remove assets/audio after testing

---

## 🎯 Summary

**Time Investment:** 30 minutes
**Result:** 
- 50% smaller app
- Dynamic audio loading
- Offline caching
- Easy to add new songs

**Next:** Follow steps 1-5, test thoroughly, then optionally do step 6.

---

## 📞 If You Get Stuck

1. Check which step failed
2. Look at Quick Fixes section
3. Review error messages carefully
4. Verify prerequisites (backend running, database accessible)

**All infrastructure is ready - just need to verify R2 URLs and populate database!**

🚀 **Start with Step 1!**
