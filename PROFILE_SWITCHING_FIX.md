# Profile Switching & Meditation Timer Fixes

## Issues Fixed

### 1. Profile Switching Not Reflecting in UI
**Problem**: When switching profiles, the profile screen and manage profiles screen were not updating to show the new profile's data.

**Solution**: 
- Added `WidgetsBinding.instance.addPostFrameCallback()` in the build method to reload data after navigation
- This ensures profile data is refreshed whenever the screen is rebuilt (e.g., after returning from another screen)
- Added duplicate load prevention to avoid multiple simultaneous API calls
- Added profile UID tracking to detect when profile actually changes

**Files Modified**:
- `lib/features/profile/profile_screen.dart` - Added auto-reload on widget rebuild
- `lib/features/profile/profiles_list_screen.dart` - Added auto-reload on widget rebuild
- `lib/features/profile/profile_selection_screen.dart` - Fixed dialog context handling

### 2. Meditation Timer Music Pause
**Problem**: When pausing the timer immediately after starting, the music would continue playing.

**Solution**: 
- Added audio pause logic in `_pauseTimer()` method
- Checks if audio is playing and pauses it when timer is paused

**Files Modified**:
- `lib/features/meditation/meditation_timer_page.dart` - Added `_audioPlayer.pause()` in pause method

### 3. Meditation Timer Box Shadow
**Problem**: Box shadow around the circle image should not appear when timer is running.

**Solution**: 
- Made box shadow conditional based on `_isRunning` state
- Shadow only appears when timer is not running
- Creates a cleaner, more focused meditation experience during active sessions

**Files Modified**:
- `lib/features/meditation/meditation_timer_page.dart` - Conditional box shadow rendering

### 4. Meditation Timer Image Zooming
**Problem**: Guruji meditation image was zooming in and not showing the full image.

**Status**: Already fixed in previous iteration - using `BoxFit.contain` instead of `BoxFit.cover`

### 5. Timer Start/Stop Behavior
**Problem**: Timer should start immediately without waiting for sound, stop immediately, and show save dialog only after end music completes.

**Status**: Already fixed in previous iteration:
- Timer starts immediately (sound plays in background with "fire and forget")
- Timer stops immediately
- End sound plays and waits for completion before showing save dialog
- Same sound file (`Meditation_start.mp3`) used for both start and end

## How It Works

### Profile Data Scoping
- Backend uses `current_profile_uid` to scope all data (meditation sessions, classes, events)
- When `switchProfile()` API is called, backend updates the current profile
- All subsequent API calls automatically use the new profile's data

### UI Updates
- Profile screens now use `WidgetsBinding.instance.addPostFrameCallback()` to reload data after each build
- This is triggered when returning from navigation (e.g., after switching profiles)
- Duplicate load prevention ensures only one API call happens at a time
- Users see updated profile information automatically

### Meditation Timer Flow
1. User clicks Start → Timer starts immediately, sound plays in background
2. User clicks Pause → Timer pauses immediately, music also pauses
3. User clicks Stop → Timer stops immediately, end sound plays
4. After end sound completes → Save dialog appears
5. For logged-in users → Auto-save with confirmation
6. For non-logged-in users → Prompt to login

### Visual Feedback
- Box shadow appears around meditation image when timer is idle
- Box shadow disappears when timer is running for cleaner focus
- Breathing animation continues during meditation

## Testing Checklist

- [x] Switch profiles from profile selection screen
- [x] Verify profile screen shows correct profile data after switch
- [x] Verify manage profiles screen shows correct active profile
- [x] Meditation timer starts immediately on click
- [x] Meditation timer pauses immediately and music stops
- [x] Meditation timer stops immediately on click
- [x] Box shadow disappears when timer is running
- [x] Guruji image shows full picture without zooming
- [x] Save dialog appears after end music completes
- [x] All meditation data is scoped to selected profile

## Technical Details

### Profile Reload Mechanism
```dart
@override
Widget build(BuildContext context) {
  // Reload profile when widget rebuilds (e.g., after navigation)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && !_isLoading) {
      _loadProfile();
    }
  });
  
  return Scaffold(...);
}
```

This approach:
- Triggers after the widget is fully built
- Checks if widget is still mounted to avoid errors
- Prevents duplicate loads with `_isLoading` flag
- Works seamlessly with navigation flow

### Audio Pause on Timer Pause
```dart
void _pauseTimer() {
  if (!_isRunning) return;
  
  setState(() {
    _isRunning = false;
  });
  
  _timer?.cancel();
  
  // Pause the audio if it's playing
  if (_audioPlayer.playing) {
    _audioPlayer.pause();
  }
}
```

### Conditional Box Shadow
```dart
decoration: BoxDecoration(
  shape: BoxShape.circle,
  boxShadow: _isRunning ? [] : [
    BoxShadow(
      color: AppTheme.saffron.withValues(alpha: 0.4),
      blurRadius: 40,
      spreadRadius: 10,
    ),
    // ... more shadows
  ],
),
```

### Benefits
- Simple implementation without complex state management
- Works with existing navigation flow
- Automatic data refresh when needed
- Better user experience with immediate feedback
- Cleaner meditation interface during active sessions

