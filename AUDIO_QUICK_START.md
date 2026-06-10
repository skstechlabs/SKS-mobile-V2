# 🚀 Quick Start: Dynamic Audio System

Get the dynamic audio system up and running in **30 minutes**!

---

## Prerequisites

- ✅ Flutter project (already set up)
- ✅ Node.js backend (or create new)
- ✅ MySQL/PostgreSQL database
- ✅ Cloudflare account

---

## Step 1: Install Dependencies (2 minutes)

```bash
cd s:\SKS-mobile-V2
flutter pub get
```

Dependencies already added to `pubspec.yaml`:
- ✅ `http: ^1.1.0`
- ✅ `crypto: ^3.0.3`
- ✅ `path_provider: ^2.1.1`
- ✅ `just_audio: ^0.9.36`
- ✅ `audio_service: ^0.18.12`

---

## Step 2: Set Up Cloudflare R2 (5 minutes)

### Create Bucket
1. Go to https://dash.cloudflare.com/
2. Click **R2** in sidebar
3. Click **Create Bucket**
4. Name: `sks-audio-files`
5. Click **Create**

### Enable Public Access
1. Go to bucket **Settings**
2. Click **Public Access**
3. Enable **Allow Public Access**
4. Copy your public URL: `https://pub-xxxxx.r2.dev`

### Get API Credentials
1. Go to **R2** → **Manage R2 API Tokens**
2. Click **Create API Token**
3. Name: `sks-audio-upload`
4. Permissions: **Object Read & Write**
5. Save **Access Key ID** and **Secret Access Key**

---

## Step 3: Set Up Database (3 minutes)

### Create Table

```sql
CREATE TABLE audios (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255),
    description TEXT,
    audio_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    duration_seconds INTEGER NOT NULL,
    category VARCHAR(50) NOT NULL,
    lyrics TEXT,
    language VARCHAR(50) NOT NULL,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    play_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_language (language),
    INDEX idx_is_active (is_active)
);
```

---

## Step 4: Upload Audio Files (5 minutes)

### Install Wrangler CLI
```bash
npm install -g wrangler
wrangler login
```

### Upload Files
```bash
cd assets/audio

# Upload meditation music
wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3 --file ./Sivoham_Mantra_15min_guided_Meditation.mp3

# Upload bhajans
wrangler r2 object put sks-audio-files/audio/bhajans/Sri_Jeeveswarastakam_song.mp3 --file ./Sri_Jeeveswarastakam_song.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Gundello_gudi_song.mp3 --file ./Gundello_gudi_song.mp3

# ... upload rest of files
```

**Or use the bulk upload script** (see `AUDIO_MIGRATION_GUIDE.md`)

---

## Step 5: Populate Database (3 minutes)

Replace `https://pub-xxxxx.r2.dev` with your actual R2 URL:

```sql
-- Meditation Music
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Sivoham Chanting with Sivoham mantra', 'https://pub-xxxxx.r2.dev/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham Chanting session', 'https://pub-xxxxx.r2.dev/audio/meditation/Sivoham_Mantra_10min_guided_Meditation.mp3', 600, 'meditation', 'sanskrit', 2);

-- Bhajans
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn', 'https://pub-xxxxx.r2.dev/audio/bhajans/Sri_Jeeveswarastakam_song.mp3', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song', 'https://pub-xxxxx.r2.dev/audio/bhajans/Gundello_gudi_song.mp3', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition', 'https://pub-xxxxx.r2.dev/audio/bhajans/Nirvana_Shatkam_song.mp3', 347, 'bhajan', 'sanskrit', 3);
```

---

## Step 6: Set Up Backend API (5 minutes)

### Create API Routes

Create `routes/audio.js` in your backend:

```javascript
const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Get all audios
router.get('/audios', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM audios WHERE is_active = TRUE ORDER BY order_index ASC'
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch audios' });
  }
});

// Get audios by category
router.get('/audios/category/:category', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM audios WHERE category = ? AND is_active = TRUE ORDER BY order_index ASC',
      [req.params.category]
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch audios' });
  }
});

module.exports = router;
```

### Add to server.js

```javascript
const audioRoutes = require('./routes/audio');
app.use('/api', audioRoutes);
```

### Test API

```bash
curl http://localhost:3000/api/audios
curl http://localhost:3000/api/audios/category/bhajan
```

---

## Step 7: Initialize Services in Flutter (2 minutes)

Update `lib/main.dart`:

```dart
import 'core/services/audio_cache_service.dart';
import 'core/services/enhanced_audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio services
  await AudioCacheService().initialize();
  await EnhancedAudioPlayerService().initialize();
  
  // ... rest of initialization
  
  runApp(MyApp());
}
```

---

## Step 8: Update Home Page (5 minutes)

Update `lib/features/home/home_page.dart`:

```dart
import '../../core/services/enhanced_audio_player_service.dart';
import '../../core/repositories/audio_repository.dart';
import '../../core/models/audio_model.dart';

class _HomePageState extends State<HomePage> {
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
  final AudioRepository _audioRepo = AudioRepository();
  
  List<AudioModel> _meditationMusic = [];
  List<AudioModel> _bhajans = [];
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _loadAudios();
  }

  Future<void> _loadAudios() async {
    setState(() => _isLoadingAudio = true);
    
    try {
      final meditation = await _audioRepo.fetchMeditationMusic();
      final bhajans = await _audioRepo.fetchBhajans();
      
      setState(() {
        _meditationMusic = meditation;
        _bhajans = bhajans;
      });
      
      // Preload in background
      if (_meditationMusic.isNotEmpty) {
        _audioService.preloadPlaylist();
      }
    } catch (e) {
      debugPrint('Error loading audios: $e');
    } finally {
      setState(() => _isLoadingAudio = false);
    }
  }

  // Update your existing _buildMeditationMusic() and _buildBhajans() methods
  // to use _meditationMusic and _bhajans lists
}
```

---

## Step 9: Test Everything (5 minutes)

### Run the App

```bash
flutter run
```

### Test Checklist

- [ ] App starts without errors
- [ ] Songs load from API
- [ ] Can play a song
- [ ] Song caches after first play
- [ ] Second play is instant (from cache)
- [ ] Mini player shows current song
- [ ] Play/pause works
- [ ] Next/previous works

### Debug Commands

```dart
// Check if song is cached
final isCached = await AudioCacheService().isCached('https://...');
print('Is cached: $isCached');

// Check cache size
final cacheSize = await EnhancedAudioPlayerService().getCacheSize();
print('Cache size: $cacheSize');

// Clear cache (for testing)
await EnhancedAudioPlayerService().clearAllCache();
```

---

## 🎉 Done!

You now have a fully functional dynamic audio system!

### What You Achieved

✅ Audio files stored in Cloudflare R2
✅ Metadata in database
✅ Local caching for offline playback
✅ Fast, lag-free playback
✅ Easy to add new songs

### Next Steps

1. **Add More Songs**: Follow `ADD_NEW_SONG_QUICK_GUIDE.md`
2. **Optimize**: Enable CDN, add Redis caching
3. **Monitor**: Track performance and usage
4. **Enhance**: Add playlists, favorites, search

---

## 🆘 Troubleshooting

### Songs not loading?
- Check API is running: `curl http://localhost:3000/api/audios`
- Check database connection
- Check CORS settings

### Songs not playing?
- Check R2 public access is enabled
- Verify audio URLs are accessible
- Check network connectivity

### Cache not working?
- Check storage permissions
- Verify path_provider initialization
- Clear and rebuild cache

---

## 📚 Full Documentation

For detailed information, see:
- **Setup Guide**: `AUDIO_SYSTEM_SETUP.md`
- **Migration Guide**: `AUDIO_MIGRATION_GUIDE.md`
- **Quick Add Song**: `ADD_NEW_SONG_QUICK_GUIDE.md`
- **Checklist**: `AUDIO_IMPLEMENTATION_CHECKLIST.md`
- **Summary**: `DYNAMIC_AUDIO_SYSTEM_SUMMARY.md`

---

## 💡 Pro Tips

1. **Start Small**: Test with 2-3 songs first
2. **Monitor Costs**: Track R2 bandwidth usage
3. **Preload Smart**: Preload popular songs
4. **Cache Management**: Add cache settings in app
5. **User Feedback**: Collect and iterate

---

**Congratulations! Your dynamic audio system is live! 🎵**

Need help? Check the documentation or contact the dev team.
