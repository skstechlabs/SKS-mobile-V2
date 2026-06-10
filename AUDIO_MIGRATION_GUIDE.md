# Audio System Migration Guide

## Migrating from Static Assets to Dynamic Cloudflare R2

This guide helps you migrate existing audio files from `assets/audio/` to the new dynamic system.

---

## Phase 1: Preparation (No App Changes)

### Step 1: Upload Existing Audio Files to R2

```bash
# Navigate to your audio folder
cd assets/audio

# Upload each file to R2
wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3 --file ./Sivoham_Mantra_15min_guided_Meditation.mp3
wrangler r2 object put sks-audio-files/audio/meditation/Sivoham_Mantra_10min_guided_Meditation.mp3 --file ./Sivoham_Mantra_10min_guided_Meditation.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Sri_Jeeveswarastakam_song.mp3 --file ./Sri_Jeeveswarastakam_song.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Gundello_gudi_song.mp3 --file ./Gundello_gudi_song.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Nirvana_Shatkam_song.mp3 --file ./Nirvana_Shatkam_song.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Jeeveswara_yogi_taluva_song.mp3 --file ./Jeeveswara_yogi_taluva_song.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Pralaya_kala_beekara_song.mp3 --file ./Pralaya_kala_beekara_song.mp3
wrangler r2 object put sks-audio-files/audio/bhajans/Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3 --file ./Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3
wrangler r2 object put sks-audio-files/audio/ringtones/Sivoham_ringtone.mp3 --file ./Sivoham_ringtone.mp3
wrangler r2 object put sks-audio-files/audio/meditation/Meditation_start.mp3 --file ./Meditation_start.mp3
wrangler r2 object put sks-audio-files/audio/meditation/Meditation_end.mp3 --file ./Meditation_end.mp3
```

### Step 2: Populate Database

Replace `https://pub-xxxxx.r2.dev` with your actual R2 URL:

```sql
-- Meditation Music
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Chanting (15 min)', 'Gurudev', 'Sivoham Chanting with Sivoham mantra', 'https://pub-xxxxx.r2.dev/audio/meditation/Sivoham_Mantra_15min_guided_Meditation.mp3', 900, 'meditation', 'sanskrit', 1),
('Sivoham Chanting (10 min)', 'Gurudev', 'Short Sivoham Chanting session', 'https://pub-xxxxx.r2.dev/audio/meditation/Sivoham_Mantra_10min_guided_Meditation.mp3', 600, 'meditation', 'sanskrit', 2);

-- Bhajans
INSERT INTO audios (title, artist, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sri Jeeveswarastakam', 'Sai Vijay', 'Sacred eight-verse hymn glorifying the divine qualities and spiritual teachings of Parama Pujya Sri Jeeveswara Yogi Gurudev', 'https://pub-xxxxx.r2.dev/audio/bhajans/Sri_Jeeveswarastakam_song.mp3', 309, 'bhajan', 'telugu', 1),
('Gundello Gudi', 'Divine Voices', 'Soulful Telugu devotional song celebrating the divine temple within the heart, awakening inner consciousness', 'https://pub-xxxxx.r2.dev/audio/bhajans/Gundello_gudi_song.mp3', 263, 'bhajan', 'telugu', 2),
('Nirvana Shatkam', 'Sacred Sounds', 'Timeless Advaita composition by Adi Shankaracharya declaring the pure consciousness beyond all dualities', 'https://pub-xxxxx.r2.dev/audio/bhajans/Nirvana_Shatkam_song.mp3', 347, 'bhajan', 'sanskrit', 3),
('Jeeveswara Yogi Taluva', 'Temple Bells', 'Melodious devotional tribute expressing deep reverence and gratitude to the enlightened master Sri Jeeveswara Yogi', 'https://pub-xxxxx.r2.dev/audio/bhajans/Jeeveswara_yogi_taluva_song.mp3', 372, 'bhajan', 'telugu', 4),
('Pralaya Kala Beekara', 'Aravvind Raama', 'Powerful invocation to Lord Kala Bhairava, the fierce guardian deity who destroys negativity and grants spiritual liberation', 'https://pub-xxxxx.r2.dev/audio/bhajans/Pralaya_kala_beekara_song.mp3', 238, 'bhajan', 'sanskrit', 5),
('Ni Namamalo Undhi Moksha Dwaram', 'Sacred Chants', 'Inspirational Telugu bhajan proclaiming that the gateway to liberation lies within the sacred name of the divine Guru', 'https://pub-xxxxx.r2.dev/audio/bhajans/Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3', 238, 'bhajan', 'telugu', 6);

-- Meditation Sounds
INSERT INTO audios (title, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Meditation Start', 'Meditation start sound', 'https://pub-xxxxx.r2.dev/audio/meditation/Meditation_start.mp3', 5, 'meditation_sound', 'instrumental', 1),
('Meditation End', 'Meditation end sound', 'https://pub-xxxxx.r2.dev/audio/meditation/Meditation_end.mp3', 5, 'meditation_sound', 'instrumental', 2);

-- Ringtone
INSERT INTO audios (title, description, audio_url, duration_seconds, category, language, order_index) 
VALUES
('Sivoham Ringtone', 'Sacred Sivoham mantra ringtone', 'https://pub-xxxxx.r2.dev/audio/ringtones/Sivoham_ringtone.mp3', 30, 'ringtone', 'sanskrit', 1);
```

---

## Phase 2: Update Flutter Code

### Step 1: Update Home Page to Use Dynamic Audio

Replace the static audio loading in `home_page.dart`:

```dart
// OLD CODE (Remove this)
Widget _buildMeditationMusic() {
  return GestureDetector(
    onTap: () async {
      if (AppConstants.meditationMusic.isNotEmpty) {
        await _audioService.playSong(AppConstants.meditationMusic, 0);
      }
    },
    // ...
  );
}

// NEW CODE (Add this)
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
      
      // Preload first few songs in background
      if (_meditationMusic.isNotEmpty) {
        _audioService.preloadPlaylist();
      }
    } catch (e) {
      debugPrint('Error loading audios: $e');
    } finally {
      setState(() => _isLoadingAudio = false);
    }
  }

  Widget _buildMeditationMusic() {
    if (_meditationMusic.isEmpty) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        if (_meditationMusic.isNotEmpty) {
          final isCurrentlyPlaying =
              _audioService.playlist == _meditationMusic &&
              _audioService.currentIndex == 0 &&
              _audioService.isPlaying;

          if (isCurrentlyPlaying) {
            await _audioService.pause();
          } else {
            await _audioService.playSong(_meditationMusic, 0);
          }
        }
      },
      // ... rest of UI
    );
  }

  Widget _buildBhajans() {
    if (_bhajans.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        // Header
        Text(context.tr('bhajans')),
        
        // List first 3 bhajans
        ..._bhajans.take(3).map((bhajan) => _buildBhajanCard(bhajan)),
        
        // View All button
        TextButton(
          onPressed: () => context.push('/songs'),
          child: Text(context.tr('view_all')),
        ),
      ],
    );
  }

  Widget _buildBhajanCard(AudioModel bhajan) {
    final isPlaying = _audioService.currentSong?.id == bhajan.id &&
        _audioService.isPlaying;

    return GestureDetector(
      onTap: () async {
        final index = _bhajans.indexWhere((b) => b.id == bhajan.id);
        if (index != -1) {
          if (isPlaying) {
            await _audioService.pause();
          } else {
            await _audioService.playSong(_bhajans, index);
          }
        }
      },
      child: Container(
        // ... UI for bhajan card
        child: Row(
          children: [
            // Thumbnail
            if (bhajan.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: bhajan.thumbnailUrl!,
                width: 60,
                height: 60,
              ),
            
            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bhajan.title),
                  if (bhajan.artist != null)
                    Text(bhajan.artist!),
                ],
              ),
            ),
            
            // Play/Pause icon
            Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          ],
        ),
      ),
    );
  }
}
```

### Step 2: Update All Songs Page

```dart
// lib/features/songs/all_songs_page.dart

class _AllSongsPageState extends State<AllSongsPage> {
  final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
  final AudioRepository _audioRepo = AudioRepository();
  
  List<AudioModel> _songs = [];
  bool _isLoading = true;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    
    try {
      final songs = await _audioRepo.fetchBhajans();
      
      setState(() {
        _songs = songs;
      });
      
      // Preload songs in background
      _audioService.preloadPlaylist();
    } catch (e) {
      debugPrint('Error loading songs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('all_songs'))),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_songs.length} ${context.tr('songs')}'),
        actions: [
          IconButton(
            icon: Icon(_isLooping ? Icons.repeat_one : Icons.repeat),
            onPressed: () {
              setState(() => _isLooping = !_isLooping);
              _audioService.setLoopMode(
                _isLooping ? LoopMode.all : LoopMode.off
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          final isPlaying = _audioService.currentSong?.id == song.id &&
              _audioService.isPlaying;

          return ListTile(
            leading: song.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: song.thumbnailUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.music_note),
            title: Text(song.title),
            subtitle: Text(song.artist ?? song.description ?? ''),
            trailing: isPlaying
                ? Icon(Icons.pause_circle_filled, color: AppTheme.saffron)
                : Icon(Icons.play_circle_filled),
            onTap: () async {
              if (isPlaying) {
                await _audioService.pause();
              } else {
                await _audioService.playSong(_songs, index);
              }
            },
          );
        },
      ),
    );
  }
}
```

### Step 3: Update Mini Audio Player

The mini audio player should work automatically with the new `EnhancedAudioPlayerService` since it extends the same interface.

---

## Phase 3: Testing

### Test Checklist

- [ ] Songs load from API
- [ ] Songs play correctly
- [ ] Songs cache locally after first play
- [ ] Cached songs play instantly on second play
- [ ] Background preloading works
- [ ] Mini player shows current song
- [ ] Play/pause works correctly
- [ ] Next/previous song works
- [ ] Loop mode works
- [ ] App doesn't lag during song loading

### Test Commands

```dart
// Check cache size
final cacheSize = await EnhancedAudioPlayerService().getCacheSize();
print('Cache size: $cacheSize');

// Clear cache (for testing)
await EnhancedAudioPlayerService().clearAllCache();

// Check if song is cached
final isCached = await AudioCacheService().isCached('https://...');
print('Is cached: $isCached');
```

---

## Phase 4: Cleanup (After Successful Migration)

### Step 1: Remove Static Audio Files

```bash
# Remove audio files from assets (keep only if needed for offline fallback)
rm -rf assets/audio/*.mp3
```

### Step 2: Update pubspec.yaml

```yaml
# Remove or comment out audio assets
flutter:
  assets:
    # - assets/audio/  # No longer needed
    - assets/images/
    - assets/translations/
```

### Step 3: Remove Old Constants

Update `app_constants.dart`:

```dart
// Remove these static arrays
// static const List<Map<String, String>> meditationMusic = [...];
// static const List<Map<String, String>> bhajans = [...];

// Keep only if needed for fallback
```

---

## Phase 5: Monitoring

### Monitor API Performance

```javascript
// Add logging to backend
router.get('/audios', async (req, res) => {
  const startTime = Date.now();
  
  // ... fetch audios
  
  const duration = Date.now() - startTime;
  console.log(`Fetched audios in ${duration}ms`);
  
  res.json({ success: true, data: rows, duration });
});
```

### Monitor Cache Performance

```dart
// Add analytics
class AudioAnalytics {
  static void logCacheHit(String songTitle) {
    print('Cache HIT: $songTitle');
    // Send to analytics service
  }

  static void logCacheMiss(String songTitle) {
    print('Cache MISS: $songTitle');
    // Send to analytics service
  }

  static void logDownloadTime(String songTitle, int milliseconds) {
    print('Downloaded $songTitle in ${milliseconds}ms');
    // Send to analytics service
  }
}
```

---

## Rollback Plan (If Needed)

If you encounter issues, you can quickly rollback:

1. Keep old audio files in `assets/audio/`
2. Keep old `AppConstants` arrays
3. Switch back to old `AudioPlayerService`
4. Revert code changes

---

## Benefits After Migration

✅ **Easy Song Management**: Add new songs via database, no app rebuild needed
✅ **Reduced App Size**: Audio files not bundled in APK
✅ **Faster Updates**: Update songs without releasing new app version
✅ **Better Performance**: Caching reduces data usage
✅ **Scalability**: Can handle hundreds of songs
✅ **Analytics**: Track which songs are popular
✅ **Flexibility**: Easy to add features like playlists, favorites, etc.

---

## Next Steps

1. Set up Cloudflare R2 bucket
2. Upload audio files
3. Set up database and API
4. Update Flutter code
5. Test thoroughly
6. Deploy backend API
7. Release app update
8. Monitor performance
9. Clean up old assets

Good luck with the migration! 🎵
