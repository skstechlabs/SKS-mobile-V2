# Video Playback Flow - Where Videos Are Played

## User Journey: From Class Selection to Video Playback

### Step-by-Step Flow

1. **User Opens App** → Home Screen

2. **Navigate to Classes** → Classes List Screen
   - Shows all available classes (Level 1, Level 2, etc.)

3. **Select a Class** → Class Days List Screen
   - File: `lib/features/learnings/class_days_list_screen.dart`
   - Shows all days in the selected class (Day 1, Day 2, Day 3, etc.)
   - Each day card shows:
     - Lock status (locked/unlocked)
     - Completion status
     - Hours until unlock (if locked)
     - Watch progress percentage

4. **Tap on Unlocked Day** → Day Video Screen
   - File: `lib/features/learnings/day_video_screen.dart`
   - This is where the video plays!
   - Navigation code (line 360-367 in `class_days_list_screen.dart`):
   ```dart
   onTap: isUnlocked
       ? () {
           final dayId = day['id']?.toString() ?? '0';
           final dayNumber = day['dayNumber']?.toString() ?? '1';
           final title = day['title']?.toString() ?? 'Video';
           
           context.push(
             '/classes/days/$dayId/video?title=${Uri.encodeComponent(title)}&dayNumber=$dayNumber',
           );
         }
       : null,
   ```

5. **Video Loads and Plays**
   - `DayVideoScreen` loads video configuration from API
   - Creates `CloudflareVideoPlayer` widget
   - File: `lib/features/learnings/widgets/cloudflare_video_player.dart`
   - Video auto-plays with sound (after our fix!)

---

## Where Video is Played

### Main Video Screen
**File**: `SKS-mobile-V2/lib/features/learnings/day_video_screen.dart`

**Key Components**:

1. **Video Player Widget** (line 425):
```dart
CloudflareVideoPlayer(
  videoId: _videoConfig!['cloudflareVideoId']?.toString() ?? '',
  accountId: _videoConfig!['cloudflareAccountId']?.toString() ?? '',
  lastPositionSeconds: _parseIntSafely(_videoConfig!['lastPositionSeconds']),
  allowSkip: _videoConfig!['allowSkip'] == true,
  onStart: _markDayAsStarted,
  onProgress: _trackProgress,
  onComplete: () {
    _trackProgress(videoDuration, videoDuration, 'complete');
  },
)
```

2. **Video Configuration API Call** (line 138):
```dart
final response = await _apiService.get(
  '/api/classes/days/${widget.dayId}/video-config',
);
```

3. **Progress Tracking** (line 189):
```dart
await _apiService.post(
  '/api/classes/days/${widget.dayId}/track',
  {
    'eventType': eventType,
    'positionSeconds': positionSeconds,
    'durationSeconds': durationSeconds,
    'sessionId': _sessionId,
  },
);
```

---

## Video Player Implementation

### Cloudflare Video Player Widget
**File**: `SKS-mobile-V2/lib/features/learnings/widgets/cloudflare_video_player.dart`

**How It Works**:

1. **Creates Cloudflare Stream Iframe** (line 63-70):
```dart
final iframeUrl = 'https://${widget.accountId}.cloudflarestream.com/${widget.videoId}/iframe'
    '?preload=true'
    '&autoplay=true'      // ✅ Auto-plays with sound
    '&loop=false'
    '&muted=false'        // ✅ Sound is unmuted
    '&controls=true'
    '&defaultTextTrack=en'
    '${widget.lastPositionSeconds > 0 ? '&startTime=${widget.lastPositionSeconds}' : ''}';
```

2. **Loads in WebView** (line 72-115):
```dart
_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(Colors.black)
  ..addJavaScriptChannel('VideoEvents', ...)
  ..loadRequest(Uri.parse(iframeUrl));
```

3. **Tracks Video Events**:
   - `play` - Video started playing
   - `pause` - Video paused
   - `timeupdate` - Progress update (every 2 seconds)
   - `ended` - Video completed
   - `seeked` - User tried to skip (blocked if `allowSkip=false`)

---

## Backend API Endpoints

### 1. Get Video Configuration
**Endpoint**: `GET /api/classes/days/:dayId/video-config`

**File**: `sks-backend/routes/classes-video.js`

**Returns**:
```json
{
  "success": true,
  "videoConfig": {
    "cloudflareVideoId": "abc123...",
    "cloudflareAccountId": "xyz789...",
    "videoDurationSeconds": 1800,
    "lastPositionSeconds": 450,
    "allowSkip": false,
    "isCompleted": false
  }
}
```

### 2. Track Video Progress
**Endpoint**: `POST /api/classes/days/:dayId/track`

**File**: `sks-backend/routes/classes-video.js`

**Request Body**:
```json
{
  "eventType": "progress",
  "positionSeconds": 450,
  "durationSeconds": 1800,
  "sessionId": "uuid-here"
}
```

### 3. Mark Day as Started
**Endpoint**: `POST /api/classes/days/:dayId/start`

**File**: `sks-backend/routes/classes-video.js`

---

## Video Playback Features

### Security Features

1. **Screen Recording Detection**
   - Monitors app lifecycle for background events
   - Shows warning if screen recording detected
   - Logs security events to backend

2. **Secure Mode**
   - Prevents screenshots (Android)
   - Hides app content in recent apps
   - Immersive mode during playback

3. **Skip Prevention**
   - JavaScript injection prevents seeking forward
   - Only allows seeking backward
   - Configurable per video (`allowSkip` flag)

4. **Context Menu Disabled**
   - Right-click disabled
   - Prevents download attempts

### Progress Tracking

1. **Auto-Save Progress**
   - Saves position every 2 seconds
   - Resumes from last position on return
   - Tracks total watch time

2. **Completion Detection**
   - Marks day as completed when video ends
   - Shows completion dialog
   - Unlocks next day after configured hours

3. **Session Tracking**
   - Unique session ID per viewing
   - Tracks device info
   - Prevents multiple simultaneous sessions

---

## Video Playback States

### 1. Loading State
- Shows loading spinner
- Fetching video configuration from API
- Initializing Cloudflare Stream player

### 2. Playing State
- Video is playing with sound
- Progress bar updates every 2 seconds
- Events tracked and sent to backend

### 3. Paused State
- User paused the video
- Progress saved
- Can resume from same position

### 4. Completed State
- Video finished playing
- Completion dialog shown
- Next day unlock timer starts

### 5. Error State
- Video failed to load
- Shows error message
- Retry button available

---

## Navigation Flow Diagram

```
Home Screen
    ↓
Classes List Screen
    ↓
[User selects a class]
    ↓
Class Days List Screen (class_days_list_screen.dart)
    ↓
[User taps on unlocked day]
    ↓
Day Video Screen (day_video_screen.dart) ← VIDEO PLAYS HERE!
    ↓
[Uses CloudflareVideoPlayer widget]
    ↓
Cloudflare Video Player (cloudflare_video_player.dart)
    ↓
[Loads Cloudflare Stream iframe in WebView]
    ↓
Video plays with sound unmuted ✅
```

---

## Key Files Summary

### Mobile App (Flutter)

1. **Class Days List Screen**
   - `lib/features/learnings/class_days_list_screen.dart`
   - Shows all days in a class
   - Handles navigation to video screen

2. **Day Video Screen** ⭐ (Main video screen)
   - `lib/features/learnings/day_video_screen.dart`
   - Loads video configuration
   - Displays video player
   - Tracks progress
   - Handles completion

3. **Cloudflare Video Player Widget**
   - `lib/features/learnings/widgets/cloudflare_video_player.dart`
   - WebView-based video player
   - Cloudflare Stream integration
   - Event tracking
   - Skip prevention

4. **Secure Screen Wrapper**
   - `lib/features/learnings/widgets/secure_screen_wrapper.dart`
   - Prevents screenshots
   - Screen recording detection

### Backend (Node.js)

1. **Classes Video Routes**
   - `sks-backend/routes/classes-video.js`
   - Video configuration endpoint
   - Progress tracking endpoint
   - Completion handling
   - Day unlock logic

---

## Answer to Your Question

**"Tell me where are we saying play this video in this Day?"**

The video is played in:

1. **Screen**: `lib/features/learnings/day_video_screen.dart` (line 425)
2. **Widget**: `CloudflareVideoPlayer` widget
3. **Triggered by**: User tapping on an unlocked day in `class_days_list_screen.dart` (line 360)
4. **Navigation**: `context.push('/classes/days/$dayId/video?...')` (line 366)
5. **Auto-play**: Set in `cloudflare_video_player.dart` line 67 with `autoplay=true&muted=false`

The video automatically starts playing with sound when the `DayVideoScreen` loads, thanks to the `autoplay=true` parameter we just fixed!

---

**Last Updated**: April 10, 2026
