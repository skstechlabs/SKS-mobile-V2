# Audio System Migration - Step by Step

## Current Status

✅ Backend routes created (`routes/audio.js`)
✅ Database schema created (`sql/create_audios_table.sql`)
✅ Flutter models and services created
✅ AudioRepository updated to use public API (no auth)
⚠️ Need to update pages to use dynamic audio
⚠️ Need to populate database with audio records
⚠️ Need to upload audio files to Cloudflare R2

---

## Step 1: Deploy Backend (REQUIRED FIRST)

### 1.1 Create Database Table

```sql
-- Connect to your MSSQL database and run:
USE [your_database_name];
GO

-- Run the complete script from:
-- s:\Backup\sks-mobile-backend-service\sql\create_audios_table.sql
```

### 1.2 Test Backend Locally

```bash
cd s:\Backup\sks-mobile-backend-service
npm start

# In another terminal, test:
curl http://localhost:3008/api/audios
# Should return: {"success":true,"data":[],"count":0}
```

### 1.3 Upload Audio Files to Cloudflare R2

**Option A: Using Wrangler CLI**
```bash
# Install wrangler
npm install -g wrangler

# Login
wrangler login

# Upload files
wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3 --file "s:\SKS-mobile-V2\assets\audio\Sivoham_Mantra_15min_guided_Meditation.mp3"
wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_10min_guided_Meditation.mp3 --file "s:\SKS-mobile-V2\assets\audio\Sivoham_Mantra_10min_guided_Meditation.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/Sri_Jeeveswarastakam_song.mp3 --file "s:\SKS-mobile-V2\assets\audio\Sri_Jeeveswarastakam_song.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/Gundello_gudi_song.mp3 --file "s:\SKS-mobile-V2\assets\audio\Gundello_gudi_song.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/Nirvana_Shatkam_song.mp3 --file "s:\SKS-mobile-V2\assets\audio\Nirvana_Shatkam_song.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/Jeeveswara_yogi_taluva_song.mp3 --file "s:\SKS-mobile-V2\assets\audio\Jeeveswara_yogi_taluva_song.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/Pralaya_kala_beekara_song.mp3 --file "s:\SKS-mobile-V2\assets\audio\Pralaya_kala_beekara_song.mp3"
wrangler r2 object put sks-audio-files/audio/bhajans/Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3 --file "s:\SKS-mobile-V2\assets\audio\Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3"
```

**Option B: Using Cloudflare Dashboard**
1. Go to Cloudflare Dashboard → R2
2. Open `sks-audio-files` bucket
3. Upload files manually

### 1.4 Insert Audio Records into Database

Replace `https://pub-xxxxx.r2.dev` with your actual R2 public URL:

```sql
USE [your_database_name];
GO

-- Meditation Music
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Sivoham Chanting with Sivoham mantra', 'https://pub-xxxxx.r2.dev/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham Chanting session', 'https://pub-xxxxx.r2.dev/audio/meditation/Sivoham_Mantra_10min_guided_Meditation.mp3', 600, 'meditation', 'sanskrit', 2);

-- Bhajans
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn glorifying Gurudev', 'https://pub-xxxxx.r2.dev/audio/bhajans/Sri_Jeeveswarastakam_song.mp3', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song', 'https://pub-xxxxx.r2.dev/audio/bhajans/Gundello_gudi_song.mp3', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition', 'https://pub-xxxxx.r2.dev/audio/bhajans/Nirvana_Shatkam_song.mp3', 347, 'bhajan', 'sanskrit', 3),
('Jeeveswara Yogi Taluva', 'Temple Bells', 'Melodious devotional tribute', 'https://pub-xxxxx.r2.dev/audio/bhajans/Jeeveswara_yogi_taluva_song.mp3', 372, 'bhajan', 'telugu', 4),
('Pralaya Kala Beekara', 'Aravvind Raama', 'Powerful invocation to Lord Kala Bhairava', 'https://pub-xxxxx.r2.dev/audio/bhajans/Pralaya_kala_beekara_song.mp3', 238, 'bhajan', 'telugu', 5),
('Ni Namamalo Undhi Moksha Dwaram', 'Sacred Chants', 'Gateway to liberation', 'https://pub-xxxxx.r2.dev/audio/bhajans/Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3', 238, 'bhajan', 'telugu', 6);
GO

-- Verify
SELECT id, title, category, language FROM audios WHERE is_active = 1;
```

### 1.5 Test Backend API

```bash
# Test all audios
curl http://localhost:3008/api/audios

# Test bhajans
curl http://localhost:3008/api/audios/category/bhajan

# Test meditation
curl http://localhost:3008/api/audios/category/meditation
```

### 1.6 Deploy to Production

```bash
cd s:\Backup\sks-mobile-backend-service
git add .
git commit -m "Add audio API endpoints"
git push origin main

# SSH to production and restart service
ssh your-server
cd /path/to/sks-mobile-backend-service
git pull
pm2 restart sks-mobile-backend-service
```

### 1.7 Test Production API

```bash
curl https://app.sivakundalini.org/api/audios
curl https://app.sivakundalini.org/api/audios/category/bhajan
```

---

## Step 2: Update Flutter App

### 2.1 Run Flutter Pub Get

```bash
cd s:\SKS-mobile-V2
flutter pub get
```

### 2.2 Test API Connection

Create a test file to verify the API is working:

```dart
// test_audio_api.dart
import 'package:flutter/material.dart';
import 'core/repositories/audio_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final audioRepo = AudioRepository();
  
  print('Testing audio API...');
  
  // Test all audios
  final allAudios = await audioRepo.fetchAllAudios();
  print('All audios: ${allAudios.length}');
  for (var audio in allAudios) {
    print('  - ${audio.title} (${audio.category})');
  }
  
  // Test bhajans
  final bhajans = await audioRepo.fetchBhajans();
  print('Bhajans: ${bhajans.length}');
  
  // Test meditation
  final meditation = await audioRepo.fetchMeditationMusic();
  print('Meditation: ${meditation.length}');
}
```

Run it:
```bash
flutter run test_audio_api.dart
```

### 2.3 Remove Audio Assets from pubspec.yaml

The audio files in `assets/audio/` are no longer needed (except for meditation start/end sounds and ringtone).

Keep only:
- `assets/audio/Meditation_start.mp3`
- `assets/audio/Meditation_end.mp3`
- `assets/audio/Sivoham_ringtone.mp3`

Remove from assets folder:
- All bhajan MP3 files
- Meditation guided meditation MP3 files

---

## Step 3: Update Pages to Use Dynamic Audio

### Files that need updating:

1. **`lib/features/home/home_page.dart`**
   - Replace `AppConstants.meditationMusic` with `AudioRepository().fetchMeditationMusic()`
   - Replace `AppConstants.bhajans` with `AudioRepository().fetchBhajans()`

2. **`lib/features/songs/all_songs_page.dart`**
   - Replace `AppConstants.bhajans` with `AudioRepository().fetchBhajans()`

### Example Update for home_page.dart:

```dart
class _HomePageState extends State<HomePage> {
  final AudioRepository _audioRepository = AudioRepository();
  List<AudioModel> _meditationMusic = [];
  List<AudioModel> _bhajans = [];
  bool _isLoadingAudio = true;
  
  @override
  void initState() {
    super.initState();
    _loadAudio();
  }
  
  Future<void> _loadAudio() async {
    setState(() => _isLoadingAudio = true);
    
    final meditation = await _audioRepository.fetchMeditationMusic();
    final bhajans = await _audioRepository.fetchBhajans();
    
    setState(() {
      _meditationMusic = meditation;
      _bhajans = bhajans;
      _isLoadingAudio = false;
    });
  }
  
  // Then use _meditationMusic and _bhajans instead of AppConstants
}
```

---

## Step 4: Test Everything

### 4.1 Test on Device

```bash
flutter run --dart-define-from-file=.env.json
```

### 4.2 Verify Features

- [ ] App loads without errors
- [ ] Home page shows meditation music
- [ ] Home page shows bhajans
- [ ] Clicking play downloads audio (first time)
- [ ] Download progress shows
- [ ] Audio plays after download
- [ ] Second play is instant (from cache)
- [ ] Offline mode works (airplane mode)
- [ ] All Songs page loads bhajans
- [ ] Play counts increment in database

### 4.3 Check Logs

```bash
# Flutter logs
flutter logs

# Backend logs (production)
pm2 logs sks-mobile-backend-service
```

---

## Step 5: Clean Up

### 5.1 Remove Old Audio Files

After verifying everything works:

```bash
# Remove old audio files (keep meditation sounds and ringtone)
cd s:\SKS-mobile-V2\assets\audio
# Delete all bhajan MP3 files
# Delete guided meditation MP3 files
# Keep: Meditation_start.mp3, Meditation_end.mp3, Sivoham_ringtone.mp3
```

### 5.2 Update pubspec.yaml

Remove references to deleted audio files.

---

## Troubleshooting

### Backend not responding

```bash
# Check if backend is running
curl https://app.sivakundalini.org/health

# Check audio endpoint
curl https://app.sivakundalini.org/api/audios

# Check backend logs
pm2 logs sks-mobile-backend-service
```

### Flutter app not loading audio

```dart
// Add debug logging in AudioRepository
debugPrint('[AudioRepository] Fetching audios from: ${_dio.options.baseUrl}/api/audios');
```

### Database empty

```sql
-- Check if records exist
SELECT COUNT(*) FROM audios WHERE is_active = 1;

-- If 0, insert sample data
```

### R2 files not accessible

```bash
# Test file accessibility
curl -I https://pub-xxxxx.r2.dev/audio/bhajans/Sri_Jeeveswarastakam_song.mp3

# Should return: HTTP/2 200
```

---

## Summary

1. ✅ Backend code is ready
2. ✅ Flutter code is ready
3. ⏳ Need to deploy backend
4. ⏳ Need to upload files to R2
5. ⏳ Need to populate database
6. ⏳ Need to update Flutter pages
7. ⏳ Need to test everything

**Next Action:** Deploy backend and populate database first, then update Flutter pages.
