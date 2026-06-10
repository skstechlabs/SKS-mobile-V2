# 🚀 Audio System Deployment Guide

Complete step-by-step guide to deploy the dynamic audio system.

---

## ✅ What's Already Done

### Flutter Side (100% Complete)
- ✅ `AudioModel` - Data model for audio metadata
- ✅ `AudioCacheService` - Local caching with download progress
- ✅ `EnhancedAudioPlayerService` - Audio player with caching
- ✅ `AudioRepository` - API integration using existing `ApiService`
- ✅ Dependencies added to `pubspec.yaml`

### Backend Side (100% Complete)
- ✅ `routes/audio.js` - Audio API routes created
- ✅ `server.js` - Routes registered
- ✅ `sql/create_audios_table.sql` - Database setup script

---

## 📋 Deployment Steps

### Step 1: Database Setup (10 minutes)

#### 1.1 Connect to Your MSSQL Database

```bash
# Using SQL Server Management Studio (SSMS)
# OR using sqlcmd
sqlcmd -S your-server -U your-username -P your-password -d your-database
```

#### 1.2 Run the SQL Script

```bash
# Option 1: Using SSMS
# - Open SQL Server Management Studio
# - Connect to your database
# - Open: s:\Backup\sks-mobile-backend-service\sql\create_audios_table.sql
# - Update database name on line 7
# - Execute (F5)

# Option 2: Using sqlcmd
sqlcmd -S your-server -U your-username -P your-password -d your-database -i s:\Backup\sks-mobile-backend-service\sql\create_audios_table.sql
```

#### 1.3 Verify Table Creation

```sql
-- Check if table exists
SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'audios';

-- Check table structure
EXEC sp_help 'audios';

-- Check indexes
SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('audios');
```

---

### Step 2: Cloudflare R2 Setup (15 minutes)

#### 2.1 Create R2 Bucket

1. Go to Cloudflare Dashboard → R2
2. Click "Create bucket"
3. Name: `sks-audio-files`
4. Location: Auto (or choose closest to your users)
5. Click "Create bucket"

#### 2.2 Enable Public Access

1. Go to bucket settings
2. Click "Settings" tab
3. Under "Public access", click "Allow Access"
4. Copy the public URL: `https://pub-xxxxx.r2.dev`

#### 2.3 Create Folder Structure

```
sks-audio-files/
├── audio/
│   ├── meditation/
│   │   ├── sivoham-15min.mp3
│   │   └── sivoham-10min.mp3
│   ├── bhajans/
│   │   ├── sri-jeeveswarastakam.mp3
│   │   ├── gundello-gudi.mp3
│   │   └── nirvana-shatkam.mp3
│   └── chants/
│       └── om-namah-shivaya.mp3
└── thumbnails/
    ├── meditation-thumb.jpg
    └── bhajan-thumb.jpg
```

#### 2.4 Upload Audio Files

**Option 1: Using Wrangler CLI**

```bash
# Install Wrangler
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Upload files
wrangler r2 object put sks-audio-files/audio/meditation/sivoham-15min.mp3 --file "s:\SKS-mobile-V2\assets\audio\sivoham-15min.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/sri-jeeveswarastakam.mp3 --file "s:\SKS-mobile-V2\assets\audio\sri-jeeveswarastakam.mp3"
# ... repeat for all files
```

**Option 2: Using Cloudflare Dashboard**

1. Go to your bucket
2. Click "Upload"
3. Drag and drop audio files
4. Organize into folders

#### 2.5 Get Public URLs

After upload, your files will be accessible at:
```
https://pub-xxxxx.r2.dev/audio/meditation/sivoham-15min.mp3
https://pub-xxxxx.r2.dev/audio/bhajans/sri-jeeveswarastakam.mp3
```

---

### Step 3: Populate Database (10 minutes)

#### 3.1 Get Audio File Durations

You need the duration in seconds for each audio file.

**Option 1: Using ffprobe (recommended)**

```bash
# Install ffmpeg (includes ffprobe)
# Windows: choco install ffmpeg
# Or download from: https://ffmpeg.org/download.html

# Get duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "s:\SKS-mobile-V2\assets\audio\sivoham-15min.mp3"
```

**Option 2: Using Media Player**
- Open file in VLC or Windows Media Player
- Note the duration
- Convert to seconds (e.g., 15:00 = 900 seconds)

#### 3.2 Insert Audio Records

Replace `https://pub-xxxxx.r2.dev` with your actual R2 public URL:

```sql
USE [your_database_name];
GO

-- Meditation Music
INSERT INTO audios (title, artist, description, audio_url, thumbnail_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Powerful Sivoham meditation with sacred mantra', 'https://pub-xxxxx.r2.dev/audio/meditation/sivoham-15min.mp3', 'https://pub-xxxxx.r2.dev/thumbnails/meditation-thumb.jpg', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham meditation session', 'https://pub-xxxxx.r2.dev/audio/meditation/sivoham-10min.mp3', 'https://pub-xxxxx.r2.dev/thumbnails/meditation-thumb.jpg', 600, 'meditation', 'sanskrit', 2);

-- Bhajans
INSERT INTO audios (title, artist, description, audio_url, thumbnail_url, duration_seconds, category, language, order_index) 
VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn glorifying Gurudev', 'https://pub-xxxxx.r2.dev/audio/bhajans/sri-jeeveswarastakam.mp3', 'https://pub-xxxxx.r2.dev/thumbnails/bhajan-thumb.jpg', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song', 'https://pub-xxxxx.r2.dev/audio/bhajans/gundello-gudi.mp3', 'https://pub-xxxxx.r2.dev/thumbnails/bhajan-thumb.jpg', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition by Adi Shankaracharya', 'https://pub-xxxxx.r2.dev/audio/bhajans/nirvana-shatkam.mp3', 'https://pub-xxxxx.r2.dev/thumbnails/bhajan-thumb.jpg', 347, 'bhajan', 'sanskrit', 3);

GO

-- Verify insertion
SELECT id, title, category, language, duration_seconds FROM audios ORDER BY category, order_index;
```

---

### Step 4: Backend Deployment (5 minutes)

#### 4.1 Verify Files Are in Place

```bash
# Check if audio routes file exists
dir "s:\Backup\sks-mobile-backend-service\routes\audio.js"

# Check if server.js is updated
findstr "audioRoutes" "s:\Backup\sks-mobile-backend-service\server.js"
```

#### 4.2 Test Backend Locally

```bash
# Navigate to backend directory
cd s:\Backup\sks-mobile-backend-service

# Install dependencies (if needed)
npm install

# Start server
npm start
# OR
node server.js
```

#### 4.3 Test API Endpoints

Open a new terminal and test:

```bash
# Test all audios
curl http://localhost:3008/api/audios

# Test by category
curl http://localhost:3008/api/audios/category/bhajan

# Test by language
curl http://localhost:3008/api/audios/language/telugu

# Test search
curl "http://localhost:3008/api/audios/search?q=sivoham"

# Test single audio
curl http://localhost:3008/api/audios/1

# Test play count
curl -X POST http://localhost:3008/api/audios/1/play
```

Expected response format:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Sivoham Chanting (15 min)",
      "artist": "Gurudev",
      "audio_url": "https://pub-xxxxx.r2.dev/audio/meditation/sivoham-15min.mp3",
      "duration_seconds": 900,
      "category": "meditation",
      "language": "sanskrit"
    }
  ],
  "count": 1
}
```

#### 4.4 Deploy to Production

```bash
# Commit changes
git add routes/audio.js server.js sql/create_audios_table.sql
git commit -m "Add audio API endpoints"

# Push to production
git push origin main

# SSH to production server and restart
ssh your-server
cd /path/to/sks-mobile-backend-service
git pull
pm2 restart sks-mobile-backend-service
# OR
systemctl restart sks-mobile-backend-service
```

#### 4.5 Test Production API

```bash
# Test production endpoints
curl https://app.sivakundalini.org/api/audios
curl https://app.sivakundalini.org/api/audios/category/bhajan
```

---

### Step 5: Flutter Integration (15 minutes)

#### 5.1 Update Dependencies

```bash
cd s:\SKS-mobile-V2
flutter pub get
```

#### 5.2 Initialize Audio Services in main.dart

The services need to be initialized in your app's main function. Check if this is already done:

```dart
// In lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization ...
  
  // Initialize audio services
  await AudioCacheService().initialize();
  await EnhancedAudioPlayerService().initialize();
  
  runApp(MyApp());
}
```

#### 5.3 Update Home Page to Use Dynamic Audio

You'll need to update your home page to fetch audio from the API instead of using static assets.

**Before (static assets):**
```dart
// Old code using static assets
final songs = [
  {'title': 'Song 1', 'path': 'assets/audio/song1.mp3'},
  {'title': 'Song 2', 'path': 'assets/audio/song2.mp3'},
];
```

**After (dynamic from API):**
```dart
// New code using AudioRepository
final audioRepo = AudioRepository();
final songs = await audioRepo.fetchBhajans();

// Play with caching
final audioService = EnhancedAudioPlayerService();
await audioService.playSong(songs, 0);
```

#### 5.4 Test on Device

```bash
# Run on connected device
flutter run

# Or build and install
flutter build apk --release
# Install APK on device and test
```

#### 5.5 Verify Features

Test these features:
- [ ] Audio loads from API
- [ ] First play downloads and caches
- [ ] Second play is instant (from cache)
- [ ] Offline playback works
- [ ] Next song preloads in background
- [ ] Play count increments

---

### Step 6: Verification & Testing (10 minutes)

#### 6.1 Backend Health Check

```bash
# Check if backend is running
curl https://app.sivakundalini.org/health

# Check audio endpoints
curl https://app.sivakundalini.org/api/audios
```

#### 6.2 Database Verification

```sql
-- Check record count
SELECT COUNT(*) as total_audios FROM audios WHERE is_active = 1;

-- Check by category
SELECT category, COUNT(*) as count FROM audios WHERE is_active = 1 GROUP BY category;

-- Check play counts
SELECT title, play_count FROM audios ORDER BY play_count DESC;
```

#### 6.3 R2 Verification

```bash
# Test if files are publicly accessible
curl -I https://pub-xxxxx.r2.dev/audio/meditation/sivoham-15min.mp3
# Should return: HTTP/2 200
```

#### 6.4 Flutter App Testing

1. **First Launch**
   - Open app
   - Navigate to music/bhajans section
   - Verify songs load from API
   - Play a song (should download)
   - Check download progress indicator

2. **Second Launch**
   - Close and reopen app
   - Play same song
   - Should play instantly (from cache)

3. **Offline Test**
   - Enable airplane mode
   - Play cached song
   - Should work offline

4. **Analytics Test**
   - Play a song
   - Check database: `SELECT play_count FROM audios WHERE id = 1;`
   - Play count should increment

---

## 🎯 Post-Deployment

### Monitor Performance

```sql
-- Check most popular songs
SELECT TOP 10 title, play_count, category 
FROM audios 
WHERE is_active = 1 
ORDER BY play_count DESC;

-- Check total plays
SELECT SUM(play_count) as total_plays FROM audios;

-- Check by category
SELECT category, SUM(play_count) as plays 
FROM audios 
GROUP BY category 
ORDER BY plays DESC;
```

### Add More Songs

```bash
# 1. Upload to R2
wrangler r2 object put sks-audio-files/audio/bhajans/new-song.mp3 --file ./new-song.mp3

# 2. Add to database
INSERT INTO audios (title, artist, audio_url, duration_seconds, category, language, order_index)
VALUES ('New Song', 'Artist', 'https://pub-xxxxx.r2.dev/audio/bhajans/new-song.mp3', 240, 'bhajan', 'telugu', 10);

# 3. Done! App will fetch it automatically
```

### Update Existing Songs

```sql
-- Update audio URL
UPDATE audios 
SET audio_url = 'https://pub-xxxxx.r2.dev/audio/bhajans/updated-song.mp3',
    updated_at = GETDATE()
WHERE id = 5;

-- Update metadata
UPDATE audios 
SET title = 'Updated Title',
    artist = 'New Artist',
    description = 'New description',
    updated_at = GETDATE()
WHERE id = 5;
```

### Deactivate Songs

```sql
-- Soft delete (hide from app)
UPDATE audios 
SET is_active = 0, 
    updated_at = GETDATE() 
WHERE id = 5;

-- Reactivate
UPDATE audios 
SET is_active = 1, 
    updated_at = GETDATE() 
WHERE id = 5;
```

---

## 🆘 Troubleshooting

### Backend Issues

**Problem: API returns 404**
```bash
# Check if routes are registered
curl http://localhost:3008/api/audios
# If 404, check server.js for: app.use('/api/audios', audioRoutes);
```

**Problem: Database connection error**
```bash
# Check database config in .env
DB_SERVER=your-server
DB_DATABASE=your-database
DB_USER=your-username
DB_PASSWORD=your-password
```

**Problem: Empty response**
```sql
-- Check if data exists
SELECT * FROM audios WHERE is_active = 1;
-- If empty, insert sample data
```

### R2 Issues

**Problem: 403 Forbidden**
- Check if public access is enabled
- Verify bucket settings → Public access → Allow Access

**Problem: 404 Not Found**
- Verify file path in R2
- Check if file was uploaded successfully
- Verify public URL format

### Flutter Issues

**Problem: Audio not loading**
```dart
// Check API response
final response = await audioRepo.fetchAllAudios();
print('Audios: ${response.length}');
// If 0, check backend API
```

**Problem: Download fails**
```dart
// Check cache service logs
// Enable debug mode in audio_cache_service.dart
debugPrint('Download URL: $audioUrl');
```

**Problem: Playback fails**
```dart
// Check audio player initialization
await EnhancedAudioPlayerService().initialize();
// Check if file exists in cache
final cacheService = AudioCacheService();
final cachedPath = await cacheService.getCachedAudioPath(audioUrl);
print('Cached path: $cachedPath');
```

---

## 📊 Success Metrics

After deployment, you should see:

- ✅ Backend API responding with 200 OK
- ✅ Database populated with audio records
- ✅ R2 files publicly accessible
- ✅ Flutter app loading songs from API
- ✅ First play downloads and caches
- ✅ Second play is instant
- ✅ Offline playback works
- ✅ Play counts incrementing

---

## 🎉 Deployment Complete!

Your dynamic audio system is now live! 🚀

### What You Achieved:

1. ✅ Scalable audio hosting with Cloudflare R2
2. ✅ Dynamic content management (no app updates needed)
3. ✅ Smart caching for offline playback
4. ✅ Analytics tracking
5. ✅ Fast, lag-free experience

### Next Steps:

1. Monitor play counts and popular songs
2. Add more audio content
3. Gather user feedback
4. Optimize based on usage patterns

---

## 📚 Reference Documentation

- **BACKEND_AUDIO_ROUTES.md** - Backend API implementation
- **MSSQL_AUDIO_SETUP.md** - Database setup details
- **AUDIO_INTEGRATION_SUMMARY.md** - System overview
- **ADD_NEW_SONG_QUICK_GUIDE.md** - Quick guide to add songs

---

## 🙏 Support

If you encounter any issues:

1. Check the troubleshooting section above
2. Review backend logs: `pm2 logs sks-mobile-backend-service`
3. Check Flutter logs: `flutter logs`
4. Verify database records: `SELECT * FROM audios;`
5. Test API endpoints with curl

---

**Happy Deploying! 🎵**
