# ✅ Audio System Deployment Checklist

Print this and check off items as you complete them.

---

## 📋 Pre-Deployment Verification

- [ ] Backend code is in place
  - [ ] `s:\Backup\sks-mobile-backend-service\routes\audio.js` exists
  - [ ] `s:\Backup\sks-mobile-backend-service\server.js` is updated
  - [ ] `s:\Backup\sks-mobile-backend-service\sql\create_audios_table.sql` exists

- [ ] Flutter code is in place
  - [ ] `s:\SKS-mobile-V2\lib\core\models\audio_model.dart` exists
  - [ ] `s:\SKS-mobile-V2\lib\core\services\audio_cache_service.dart` exists
  - [ ] `s:\SKS-mobile-V2\lib\core\services\enhanced_audio_player_service.dart` exists
  - [ ] `s:\SKS-mobile-V2\lib\core\repositories\audio_repository.dart` exists
  - [ ] `s:\SKS-mobile-V2\pubspec.yaml` has `http` and `crypto` dependencies

- [ ] Documentation is available
  - [ ] Read `AUDIO_DEPLOYMENT_GUIDE.md`
  - [ ] Read `IMPLEMENTATION_SUMMARY.md`

---

## 🗄️ Phase 1: Database Setup (10 min)

### Connect to Database
- [ ] Open SQL Server Management Studio (SSMS)
- [ ] Connect to your MSSQL server
- [ ] Select your database

### Run SQL Script
- [ ] Open `s:\Backup\sks-mobile-backend-service\sql\create_audios_table.sql`
- [ ] Update database name on line 7: `USE [your_database_name];`
- [ ] Execute script (F5)
- [ ] Verify success messages in output

### Verify Table Creation
- [ ] Run: `SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'audios';`
- [ ] Verify table exists
- [ ] Run: `EXEC sp_help 'audios';`
- [ ] Verify all columns exist
- [ ] Run: `SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('audios');`
- [ ] Verify 5 indexes exist
- [ ] Run: `SELECT * FROM sys.triggers WHERE name = 'trg_audios_updated_at';`
- [ ] Verify trigger exists

**✅ Phase 1 Complete**

---

## ☁️ Phase 2: Cloudflare R2 Setup (15 min)

### Create Bucket
- [ ] Go to Cloudflare Dashboard → R2
- [ ] Click "Create bucket"
- [ ] Name: `sks-audio-files`
- [ ] Location: Auto (or choose closest region)
- [ ] Click "Create bucket"

### Enable Public Access
- [ ] Go to bucket settings
- [ ] Click "Settings" tab
- [ ] Under "Public access", click "Allow Access"
- [ ] Copy public URL: `https://pub-xxxxx.r2.dev`
- [ ] Save URL for later: ___________________________________

### Create Folder Structure
- [ ] Create folder: `audio`
- [ ] Create subfolder: `audio/meditation`
- [ ] Create subfolder: `audio/bhajans`
- [ ] Create subfolder: `audio/chants`
- [ ] Create folder: `thumbnails`

### Upload Audio Files

**Option A: Using Wrangler CLI**
- [ ] Install Wrangler: `npm install -g wrangler`
- [ ] Login: `wrangler login`
- [ ] Upload files:
  ```bash
  wrangler r2 object put sks-audio-files/audio/meditation/sivoham-15min.mp3 --file "path/to/file.mp3"
  ```
- [ ] Repeat for all audio files

**Option B: Using Dashboard**
- [ ] Go to bucket
- [ ] Click "Upload"
- [ ] Drag and drop audio files
- [ ] Organize into folders

### Verify Upload
- [ ] Test file accessibility:
  ```bash
  curl -I https://pub-xxxxx.r2.dev/audio/meditation/sivoham-15min.mp3
  ```
- [ ] Should return: `HTTP/2 200`

**✅ Phase 2 Complete**

---

## 📊 Phase 3: Populate Database (10 min)

### Get Audio Durations

For each audio file:
- [ ] Get duration using ffprobe:
  ```bash
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "path/to/file.mp3"
  ```
- [ ] Or check in media player and convert to seconds

### Prepare Insert Statements
- [ ] Replace `https://pub-xxxxx.r2.dev` with your actual R2 URL
- [ ] Update durations with actual values
- [ ] Update titles, artists, descriptions as needed

### Insert Audio Records
- [ ] Run insert statements in SSMS:
  ```sql
  INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
  VALUES
  ('Sivoham Chanting (15 min)', 'Gurudev', 'Powerful meditation', 'https://pub-xxx.r2.dev/audio/meditation/sivoham-15min.mp3', 900, 'meditation', 'sanskrit', 1),
  -- Add more records...
  ```

### Verify Data
- [ ] Run: `SELECT * FROM audios WHERE is_active = 1;`
- [ ] Verify all records inserted
- [ ] Run: `SELECT COUNT(*) FROM audios WHERE is_active = 1;`
- [ ] Note count: _____ audios

**✅ Phase 3 Complete**

---

## 🖥️ Phase 4: Backend Deployment (5 min)

### Test Locally
- [ ] Navigate to backend directory:
  ```bash
  cd s:\Backup\sks-mobile-backend-service
  ```
- [ ] Start server:
  ```bash
  npm start
  ```
- [ ] Server should start on port 3008

### Test Endpoints Locally
- [ ] Test all audios:
  ```bash
  curl http://localhost:3008/api/audios
  ```
- [ ] Test by category:
  ```bash
  curl http://localhost:3008/api/audios/category/bhajan
  ```
- [ ] Test search:
  ```bash
  curl "http://localhost:3008/api/audios/search?q=sivoham"
  ```
- [ ] Test single audio:
  ```bash
  curl http://localhost:3008/api/audios/1
  ```
- [ ] Test play count:
  ```bash
  curl -X POST http://localhost:3008/api/audios/1/play
  ```

### Deploy to Production
- [ ] Commit changes:
  ```bash
  git add routes/audio.js server.js sql/create_audios_table.sql
  git commit -m "Add audio API endpoints"
  git push origin main
  ```
- [ ] SSH to production server
- [ ] Pull changes:
  ```bash
  cd /path/to/sks-mobile-backend-service
  git pull
  ```
- [ ] Restart service:
  ```bash
  pm2 restart sks-mobile-backend-service
  # OR
  systemctl restart sks-mobile-backend-service
  ```

### Test Production Endpoints
- [ ] Test all audios:
  ```bash
  curl https://app.sivakundalini.org/api/audios
  ```
- [ ] Test by category:
  ```bash
  curl https://app.sivakundalini.org/api/audios/category/bhajan
  ```
- [ ] Verify response format is correct

**✅ Phase 4 Complete**

---

## 📱 Phase 5: Flutter Integration (15 min)

### Update Dependencies
- [ ] Navigate to Flutter project:
  ```bash
  cd s:\SKS-mobile-V2
  ```
- [ ] Get dependencies:
  ```bash
  flutter pub get
  ```
- [ ] Verify no errors

### Initialize Services in main.dart
- [ ] Open `lib/main.dart`
- [ ] Add initialization code:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // ... existing initialization ...
    
    // Initialize audio services
    await AudioCacheService().initialize();
    await EnhancedAudioPlayerService().initialize();
    
    runApp(MyApp());
  }
  ```
- [ ] Save file

### Update Home Page (or Songs Page)
- [ ] Open the page where you want to use dynamic audio
- [ ] Replace static audio loading with:
  ```dart
  final audioRepo = AudioRepository();
  final songs = await audioRepo.fetchBhajans();
  
  final audioService = EnhancedAudioPlayerService();
  await audioService.playSong(songs, 0);
  ```
- [ ] Save file

### Test on Device
- [ ] Connect device or start emulator
- [ ] Run app:
  ```bash
  flutter run
  ```
- [ ] Navigate to audio section
- [ ] Verify songs load from API

### Test Features
- [ ] Play a song (should download)
- [ ] Check download progress indicator
- [ ] Wait for download to complete
- [ ] Play same song again (should be instant)
- [ ] Close and reopen app
- [ ] Play same song (should be instant from cache)
- [ ] Enable airplane mode
- [ ] Play cached song (should work offline)
- [ ] Disable airplane mode

**✅ Phase 5 Complete**

---

## ✅ Phase 6: Final Verification (10 min)

### Backend Health Check
- [ ] Check backend is running:
  ```bash
  curl https://app.sivakundalini.org/health
  ```
- [ ] Check audio endpoints:
  ```bash
  curl https://app.sivakundalini.org/api/audios
  ```

### Database Verification
- [ ] Check record count:
  ```sql
  SELECT COUNT(*) as total_audios FROM audios WHERE is_active = 1;
  ```
- [ ] Check by category:
  ```sql
  SELECT category, COUNT(*) as count FROM audios WHERE is_active = 1 GROUP BY category;
  ```
- [ ] Check play counts:
  ```sql
  SELECT title, play_count FROM audios ORDER BY play_count DESC;
  ```

### R2 Verification
- [ ] Test file accessibility:
  ```bash
  curl -I https://pub-xxxxx.r2.dev/audio/meditation/sivoham-15min.mp3
  ```
- [ ] Should return: `HTTP/2 200`

### Flutter App Testing
- [ ] **First Launch Test**
  - [ ] Open app
  - [ ] Navigate to music/bhajans section
  - [ ] Verify songs load from API
  - [ ] Play a song (should download)
  - [ ] Check download progress indicator
  - [ ] Verify playback works

- [ ] **Second Launch Test**
  - [ ] Close and reopen app
  - [ ] Play same song
  - [ ] Should play instantly (from cache)

- [ ] **Offline Test**
  - [ ] Enable airplane mode
  - [ ] Play cached song
  - [ ] Should work offline

- [ ] **Analytics Test**
  - [ ] Play a song
  - [ ] Check database:
    ```sql
    SELECT play_count FROM audios WHERE id = 1;
    ```
  - [ ] Play count should increment

**✅ Phase 6 Complete**

---

## 🎉 Deployment Complete!

### Success Criteria (All should be ✅)
- [ ] Backend API responding with 200 OK
- [ ] Database populated with audio records
- [ ] R2 files publicly accessible
- [ ] Flutter app loading songs from API
- [ ] First play downloads and caches
- [ ] Second play is instant (from cache)
- [ ] Offline playback works
- [ ] Play counts incrementing

---

## 📝 Post-Deployment Tasks

### Monitor Performance
- [ ] Check backend logs for errors
- [ ] Monitor database query performance
- [ ] Check R2 bandwidth usage
- [ ] Monitor app crash reports

### Add More Content
- [ ] Upload more audio files to R2
- [ ] Insert more records in database
- [ ] Test new songs in app

### Gather Feedback
- [ ] Test with beta users
- [ ] Collect feedback on performance
- [ ] Monitor play counts
- [ ] Identify popular songs

---

## 🆘 Troubleshooting

If something doesn't work:

### Backend Issues
- [ ] Check backend logs: `pm2 logs sks-mobile-backend-service`
- [ ] Verify database connection
- [ ] Test endpoints with curl
- [ ] Check server.js has audio routes registered

### Database Issues
- [ ] Verify table exists
- [ ] Check if data is inserted
- [ ] Verify indexes exist
- [ ] Check trigger is working

### R2 Issues
- [ ] Verify public access is enabled
- [ ] Check file paths are correct
- [ ] Test file accessibility with curl
- [ ] Verify URL format

### Flutter Issues
- [ ] Check Flutter logs: `flutter logs`
- [ ] Verify dependencies installed
- [ ] Check API service initialization
- [ ] Verify cache directory permissions

---

## 📞 Support Resources

- **AUDIO_DEPLOYMENT_GUIDE.md** - Detailed deployment guide
- **IMPLEMENTATION_SUMMARY.md** - System overview
- **BACKEND_AUDIO_ROUTES.md** - Backend API details
- **ADD_SONG_QUICK_REFERENCE.md** - Quick guide to add songs

---

## ✅ Final Sign-Off

- [ ] All phases completed
- [ ] All tests passed
- [ ] Documentation reviewed
- [ ] Team trained
- [ ] Monitoring in place

**Deployment Date:** ___________________

**Deployed By:** ___________________

**Status:** ✅ COMPLETE

---

**Congratulations! Your dynamic audio system is live! 🎉**
