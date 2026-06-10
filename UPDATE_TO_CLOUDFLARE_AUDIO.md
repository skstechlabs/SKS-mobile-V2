# Quick Update Guide: Switch to Cloudflare Audio Loading

## What's Changing?

Your app currently loads audio files from bundled assets (`assets/audio/`). We're switching to:
- ✅ Load from Cloudflare R2 CDN dynamically
- ✅ Smart caching for offline playback
- ✅ Smaller app size (remove ~50MB of audio files)
- ✅ Easy to add new songs without app release

## Files to Update

### 1. Update `all_songs_page.dart`

**Current code uses:**
```dart
final AudioPlayerService _audioService = AudioPlayerService();
// ...
AppConstants.bhajans
```

**Change to:**
```dart
import '../../core/providers/audio_provider.dart';
import '../../core/services/enhanced_audio_player_service.dart';

final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
final AudioProvider _audioProvider = AudioProvider();

// In build method, replace AppConstants.bhajans with:
_audioProvider.bhajans
```

### 2. Update `home_page.dart`

**Replace:**
```dart
final AudioPlayerService _audioService = AudioPlayerService();
// ...
AppConstants.meditationMusic
AppConstants.bhajans
```

**With:**
```dart
import '../../core/providers/audio_provider.dart';
import '../../core/services/enhanced_audio_player_service.dart';

final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
final AudioProvider _audioProvider = AudioProvider();

// Replace:
AppConstants.meditationMusic → _audioProvider.meditations
AppConstants.bhajans → _audioProvider.bhajans
```

### 3. Update `playlist_screen.dart`

**Replace:**
```dart
final AudioPlayerService _audioService = AudioPlayerService();
```

**With:**
```dart
import '../../core/services/enhanced_audio_player_service.dart';

final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
```

### 4. Update `mini_audio_player.dart`

**Replace:**
```dart
final AudioPlayerService _audioService = AudioPlayerService();
```

**With:**
```dart
import '../services/enhanced_audio_player_service.dart';

final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
```

### 5. Update `main_scaffold.dart`

**Replace:**
```dart
final AudioPlayerService _audioService = AudioPlayerService();
```

**With:**
```dart
import '../services/enhanced_audio_player_service.dart';

final EnhancedAudioPlayerService _audioService = EnhancedAudioPlayerService();
```

## Model Compatibility

The new `AudioModel` is compatible with old code, but you'll need to adjust property access:

**Old format (Map):**
```dart
final song = {'title': 'Song Name', 'url': 'assets/...'};
print(song['title']);
```

**New format (AudioModel):**
```dart
final song = AudioModel(...);
print(song.title);
print(song.audioUrl); // Note: audioUrl, not 'url'
```

## Testing Checklist

After updating:

1. ✅ App launches without errors
2. ✅ Bhajans page loads song list
3. ✅ Meditation page loads meditation tracks
4. ✅ Tapping a song shows download progress (first time)
5. ✅ Audio plays correctly
6. ✅ Cached songs play instantly (second time)
7. ✅ Background playback works
8. ✅ Lock screen controls work

## Backend Requirements

Before testing the updated app, ensure:

1. ✅ Audio files uploaded to Cloudflare R2
2. ✅ Database populated with audio metadata
3. ✅ Backend API returns data:
   ```bash
   curl https://app.sivakundalini.org/api/audios
   ```
   Should return JSON with audio list

## Rollback

If issues occur, you can quickly rollback by:
1. Revert the above changes
2. Keep using `AudioPlayerService` and `AppConstants`
3. The backend changes don't affect old code

## Benefits After Update

- 📦 **App size reduced by ~50MB**
- 🚀 **Faster app download for users**
- 🔄 **Add new songs without app release**
- 💾 **Smart caching for offline use**
- 📊 **Track song play counts**
- 🌐 **CDN-powered streaming**

## Need Help?

- Check migration guide: `sks-mobile-backend-service/AUDIO_CLOUDFLARE_MIGRATION_GUIDE.md`
- Review AudioProvider: `lib/core/providers/audio_provider.dart`
- Check Enhanced Player: `lib/core/services/enhanced_audio_player_service.dart`
