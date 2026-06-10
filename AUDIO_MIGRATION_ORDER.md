# 🎵 Audio System Migration - Correct Order

## ⚠️ Important: Migration Order Matters!

You **MUST** follow this exact order to avoid breaking the app:

---

## Phase 1: Backend Setup (Do This First!)

### Step 1: Deploy Backend Code
```bash
cd s:\Backup\sks-mobile-backend-service

# Verify files exist
ls routes/audio.js
grep "audioRoutes" server.js

# Commit and push
git add routes/audio.js server.js sql/create_audios_table.sql
git commit -m "Add audio API endpoints"
git push origin main

# Deploy to production
ssh your-server
cd /path/to/sks-mobile-backend-service
git pull
pm2 restart sks-mobile-backend-service
```

### Step 2: Create Database Table
```sql
-- Connect to MSSQL and run:
-- s:\Backup\sks-mobile-backend-service\sql\create_audios_table.sql

USE [your_database_name];
GO

-- Paste the entire SQL script here
```

### Step 3: Upload Audio Files to Cloudflare R2
```bash
# Install wrangler
npm install -g wrangler

# Login
wrangler login

# Create bucket (if not exists)
wrangler r2 bucket create sks-audio-files

# Upload files
wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Sivoham_Mantra_15min_guided_Meditation.mp3"

wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_10min_guided_Meditation.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Sivoham_Mantra_10min_guided_Meditation.mp3"

wrangler r2 object put sks-audio-files/audio/bhajans/Sri_Jeeveswarastakam_song.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Sri_Jeeveswarastakam_song.mp3"

wrangler r2 object put sks-audio-files/audio/bhajans/Gundello_gudi_song.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Gundello_gudi_song.mp3"

wrangler r2 object put sks-audio-files/audio/bhajans/Nirvana_Shatkam_song.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Nirvana_Shatkam_song.mp3"

wrangler r2 object put sks-audio-files/audio/bhajans/Jeeveswara_yogi_taluva_song.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Jeeveswara_yogi_taluva_song.mp3"

wrangler r2 object put sks-audio-files/audio/bhajans/Pralaya_kala_beekara_song.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Pralaya_kala_beekara_song.mp3"

wrangler r2 object put sks-audio-files/audio/bhajans/Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3 \
  --file "s:\SKS-mobile-V2\assets\audio\Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3"

# Enable public access
# Go to Cloudflare Dashboard → R2 → sks-audio-files → Settings → Public Access → Allow Access

# Get public URL (will be like: https://pub-xxxxx.r2.dev)
```

### Step 4: Insert Audio Records
```sql
-- Replace https://pub-xxxxx.r2.dev with YOUR actual R2 public URL

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
SELECT id, title, category, language, audio_url FROM audios WHERE is_active = 1;
```

### Step 5: Test Backend API
```bash
# Test all audios
curl https://app.sivakundalini.org/api/audios

# Should return JSON with your audio records
# If empty array, check database
# If 404, backend not deployed
```

---

## Phase 2: Test Flutter API Connection

### Step 1: Test API from Flutter
```bash
cd s:\SKS-mobile-V2

# Run test app
flutter run lib/test_audio_api.dart

# Click "Run API Test" button
# Should show all audios from backend
```

### Step 2: Verify Logs
```bash
# Check Flutter logs
flutter logs

# Should see:
# [AudioRepository] Fetching all audios from /api/audios
# [AudioRepository] Response status: 200
# [AudioRepository] Found X audios
```

---

## Phase 3: Update Flutter App (Only After Backend Works!)

### Step 1: Update home_page.dart

Add at the top of the class:
```dart
import '../../core/repositories/audio_repository.dart';
import '../../core/models/audio_model.dart';

class _HomePageState extends State<HomePage> {
  final AudioRepository _audioRepository = AudioRepository();
  List<AudioModel> _meditationMusic = [];
  List<AudioModel> _bhajans = [];
  bool _isLoadingAudio = true;
  
  // ... existing code ...
```

Add in `initState()`:
```dart
@override
void initState() {
  super.initState();
  _loadAudio();
  // ... existing init code ...
}

Future<void> _loadAudio() async {
  try {
    final meditation = await _audioRepository.fetchMeditationMusic();
    final bhajans = await _audioRepository.fetchBhajans();
    
    if (mounted) {
      setState(() {
        _meditationMusic = meditation;
        _bhajans = bhajans;
        _isLoadingAudio = false;
      });
    }
  } catch (e) {
    debugPrint('Error loading audio: $e');
    if (mounted) {
      setState(() => _isLoadingAudio = false);
    }
  }
}
```

Replace all `AppConstants.meditationMusic` with `_meditationMusic`
Replace all `AppConstants.bhajans` with `_bhajans`

### Step 2: Update all_songs_page.dart

Similar changes - load bhajans dynamically.

### Step 3: Remove Static Constants

Only after everything works, remove from `app_constants.dart`:
```dart
// Remove these:
// static const List<Map<String, String>> meditationMusic = [...];
// static const List<Map<String, String>> bhajans = [...];
```

### Step 4: Remove Audio Assets

Keep only:
- `assets/audio/Meditation_start.mp3`
- `assets/audio/Meditation_end.mp3`
- `assets/audio/Sivoham_ringtone.mp3`

Delete all other MP3 files.

---

## ✅ Verification Checklist

### Backend Verification
- [ ] Backend deployed and running
- [ ] Database table created
- [ ] Audio files uploaded to R2
- [ ] Audio records inserted in database
- [ ] API returns audio list: `curl https://app.sivakundalini.org/api/audios`

### Flutter Verification
- [ ] Test app works: `flutter run lib/test_audio_api.dart`
- [ ] API calls visible in logs
- [ ] Audio downloads on first play
- [ ] Audio plays from cache on second play
- [ ] Offline playback works

---

## 🚨 Common Mistakes

### ❌ Mistake 1: Updating Flutter Before Backend
**Problem:** App tries to call API that doesn't exist yet
**Solution:** Deploy backend FIRST

### ❌ Mistake 2: Removing Static Constants Too Early
**Problem:** App won't build
**Solution:** Keep static constants until dynamic loading works

### ❌ Mistake 3: Wrong R2 URL in Database
**Problem:** Audio files return 404
**Solution:** Use correct public URL from R2 settings

### ❌ Mistake 4: Database Table Not Created
**Problem:** Backend returns empty array
**Solution:** Run SQL script to create table

---

## 📊 Current Status

✅ **Backend Code:** Ready (routes/audio.js, server.js)
✅ **Flutter Code:** Ready (AudioRepository, models, services)
✅ **Static Constants:** Restored (app builds successfully)
⏳ **Backend Deployment:** Pending (your action)
⏳ **Database Setup:** Pending (your action)
⏳ **R2 Upload:** Pending (your action)
⏳ **Database Population:** Pending (your action)

---

## 🎯 What to Do Right Now

1. **Deploy backend** (most important!)
2. **Create database table**
3. **Upload files to R2**
4. **Insert records in database**
5. **Test API** with curl
6. **Test Flutter** with test app
7. **Update Flutter pages** (only after API works)

---

## 📞 Need Help?

Run the test app to see detailed logs:
```bash
flutter run lib/test_audio_api.dart
```

This will show you exactly what's happening with the API calls.

---

**Remember:** Backend FIRST, then Flutter!
