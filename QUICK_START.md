# 🚀 Audio Migration - Quick Start

## ✅ What's Ready
- ✅ Backend API ready
- ✅ Database schema ready  
- ✅ Mobile app code ready
- ✅ `.env` updated with audio config
- ✅ SQL scripts ready
- ✅ Audio files uploaded to R2

## ⏰ 30-Minute Setup

### 1️⃣ Test R2 URL (2 min)
Open in browser:
```
https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev/sks-audio-files/Sivoham_ringtone.mp3
```
- ✅ Plays/downloads → Continue
- ❌ 403 → Enable public access in R2
- ❌ 404 → Check R2 file path

### 2️⃣ Populate Database (5 min)
```cmd
cd s:\Backup\sks-mobile-backend-service
sqlcmd -S localhost\SQLEXPRESS -U sa -P Sivoham@26 -d sivoham_dev -i sql\populate_audios_cloudflare_READY.sql
```
Expected: "11 records inserted"

### 3️⃣ Test API (3 min)
```cmd
# Start backend
cd s:\Backup\sks-mobile-backend-service
node server.js

# In browser: http://localhost:3013/api/audios
```
Expected: JSON with 11 audio files

### 4️⃣ Test Mobile App (10 min)
```cmd
cd s:\SKS-mobile-V2
flutter run
```
Check logs for: "Fetched 11 audios"
Open Bhajans → Tap song → Should download & play

### 5️⃣ Remove Assets (5 min) - OPTIONAL
Edit `pubspec.yaml`:
```yaml
# Comment out:
# - assets/audio/
```
Then:
```cmd
flutter clean
flutter build apk --release
```

## 📋 Checklist
- [ ] Step 1: URL works
- [ ] Step 2: DB populated  
- [ ] Step 3: API returns data
- [ ] Step 4: App plays audio
- [ ] Step 5: Assets removed (optional)

## 🎯 Result
- 📦 50% smaller app (60 MB vs 120 MB)
- 🌐 Audio from CDN
- 💾 Smart offline caching
- 🔄 Easy to add new songs

## 📖 Detailed Guide
See: `STEP_BY_STEP_IMPLEMENTATION.md`

## 🆘 Problems?
- 403 Error → Enable R2 public access
- 404 Error → Check file path in R2
- DB Error → Run `create_audios_table.sql` first
- API Empty → Check database has data
- App Error → Check backend running

---

**Ready? Start with Step 1!** 🚀
