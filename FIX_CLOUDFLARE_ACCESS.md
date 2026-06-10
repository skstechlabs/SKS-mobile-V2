# 🔧 Fix Cloudflare R2 Access - Step by Step

## ⚠️ Current Issue
All 11 audio files are returning errors when tested. This means either:
1. Public access is not enabled on the R2 bucket
2. Files are not in the expected paths
3. Bucket name is different

---

## 🎯 STEP 1: Enable Public Access (MOST LIKELY FIX)

### 1.1 Go to Cloudflare Dashboard
1. Open browser: https://dash.cloudflare.com/
2. Login with your credentials
3. Click **"R2"** in the left sidebar

### 1.2 Find Your Bucket
Look for bucket named: **`sks-audio-files`**

(If you don't see this bucket, check what buckets you have and note the name)

### 1.3 Enable Public Access
1. Click on the **`sks-audio-files`** bucket
2. Click on the **"Settings"** tab
3. Scroll down to find one of these sections:
   - **"Public Access"**
   - **"R2.dev subdomain"**
   - **"Domain Access"**
4. Look for a toggle or button to **Enable**
5. **Enable it!**
6. Click **"Save"** or **"Apply"**

### 1.4 Wait and Test
- Wait 1-2 minutes for changes to propagate
- Then run test again (see Step 2 below)

---

## 🎯 STEP 2: Test After Enabling Access

### Run PowerShell Test:
```powershell
cd s:\Backup\sks-mobile-backend-service
.\test-audio-urls-correct.ps1
```

### Expected After Fix:
```
[Meditation] Sivoham 15min ... OK (8.5 MB)
[Meditation] Sivoham 10min ... OK (5.7 MB)
[Meditation] Meditation Start ... OK (2.1 MB)
[Meditation] Meditation End ... OK (1.5 MB)
[Bhajan] Sri Jeeveswarastakam ... OK (3.8 MB)
[Bhajan] Gundello Gudi ... OK (3.2 MB)
[Bhajan] Nirvana Shatkam ... OK (4.1 MB)
[Bhajan] Jeeveswara Yogi Taluva ... OK (4.5 MB)
[Bhajan] Pralaya Kala Beekara ... OK (2.9 MB)
[Bhajan] Ni Namamalo Moksha ... OK (3.4 MB)
[Ringtone] Sivoham Ringtone ... OK (0.5 MB)

Success: 11, Failed: 0
```

**If all 11 pass → Continue to Step 3!**

---

## 🎯 STEP 3: Verify File Paths (If Still Failing)

### 3.1 Check Bucket Structure
In Cloudflare R2 dashboard:
1. Click on **`sks-audio-files`** bucket
2. Browse the files/folders
3. Verify this structure exists:

```
sks-audio-files/    (this is the bucket root)
├── audio/
│   ├── bhajans/
│   │   ├── Sri_Jeeveswarastakam_song.mp3
│   │   ├── Gundello_gudi_song.mp3
│   │   ├── Nirvana_Shatkam_song.mp3
│   │   ├── Jeeveswara_yogi_taluva_song.mp3
│   │   ├── Pralaya_kala_beekara_song.mp3
│   │   └── Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3
│   ├── meditation/
│   │   ├── Sivoham_Mantra_15min_guided_Meditation.mp3
│   │   ├── Sivoham_Mantra_10min_guided_Meditation.mp3
│   │   ├── Meditation_start.mp3
│   │   └── Meditation_end.mp3
│   └── chants/
│       └── Sivoham_ringtone.mp3
└── thumbnails/
    └── (album art images)
```

### 3.2 If Structure is Different
Take a screenshot of your actual folder structure and I'll update the configuration accordingly.

---

## 🎯 STEP 4: Test One URL Manually

### Open in Browser:
```
https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/sks-audio-files/audio/meditation/Meditation_start.mp3
```

### What Should Happen:

**✅ SUCCESS:**
- Audio file plays in browser
- OR download popup appears
- **→ Public access is working!**

**❌ 403 Forbidden:**
- Public access not enabled
- **→ Go back to Step 1.3**

**❌ 404 Not Found:**
- File path is wrong OR files not uploaded
- **→ Check Step 3**

---

## 🎯 STEP 5: Alternative - Check Bucket Name

### Maybe bucket has different name?

In Cloudflare R2 dashboard, check all your buckets:
- Is it called `sks-audio-files`?
- Or maybe `sadhaks/sks-audio-files`?
- Or something else?

If bucket name is different, let me know and I'll update the configuration.

---

## 📋 Quick Checklist

Before proceeding with database population, ensure:

- [ ] Step 1: Public access enabled on R2 bucket
- [ ] Step 2: Test script shows "Success: 11, Failed: 0"
- [ ] Step 3: File structure verified in R2 dashboard
- [ ] Step 4: One URL works in browser
- [ ] Configuration matches:
  - Bucket: `sks-audio-files`
  - Public URL: `https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev`
  - Files in: `audio/meditation/`, `audio/bhajans/`, `audio/chants/`

---

## 🚀 Once URLs Work

After all tests pass, continue with:

### Populate Database:
```cmd
cd s:\Backup\sks-mobile-backend-service
sqlcmd -S localhost\SQLEXPRESS -U sa -P Sivoham@26 -d sivoham_dev -i sql\populate_audios_CORRECT.sql
```

### Start Backend:
```cmd
node server.js
```

### Test API:
```
http://localhost:3013/api/audios
```

### Test Mobile App:
```cmd
cd s:\SKS-mobile-V2
flutter run
```

---

## 🆘 Still Not Working?

### Check These:

**1. Bucket Name Issue:**
- Your `.env` shows main bucket is `sadhaks`
- But audio files should be in `sks-audio-files` bucket
- Are there two separate buckets?
- Or is `sks-audio-files` a folder inside `sadhaks` bucket?

**2. Account/Region Issue:**
- Verify account ID: `dfca0f529df9f308d904bbd559e88b81`
- Check if public URL is correct: `https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev`

**3. CORS Settings:**
- In R2 bucket settings
- Check if CORS is configured
- May need to allow `*` or specific origins

---

## 📸 Need Help?

Take screenshots of:
1. R2 bucket list (showing bucket names)
2. Inside `sks-audio-files` bucket (showing folder structure)
3. Bucket Settings page (showing public access toggle)
4. Browser error when testing URL

Then I can provide exact configuration!

---

## ⚡ Most Common Fix

**90% of the time, the issue is:**
**Public access not enabled on the R2 bucket!**

**Go to Cloudflare Dashboard → R2 → sks-audio-files → Settings → Enable Public Access**

Then rerun the test! 🎯
