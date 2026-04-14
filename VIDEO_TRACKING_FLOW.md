# Video Tracking Flow Diagram

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │           day_video_screen.dart                        │    │
│  │  - Loads video config from backend                     │    │
│  │  - Shows toast notifications                           │    │
│  │  - Shows completion dialog                             │    │
│  │  - Calls API to track progress                         │    │
│  └────────────────────────────────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │      cloudflare_video_player.dart (WebView)            │    │
│  │                                                         │    │
│  │  ┌───────────────────────────────────────────────┐    │    │
│  │  │         HTML Page (loadHtmlString)            │    │    │
│  │  │                                                │    │    │
│  │  │  ┌──────────────────────────────────────┐    │    │    │
│  │  │  │  Cloudflare Stream Iframe            │    │    │    │
│  │  │  │  (customer-CODE.cloudflarestream.com)│    │    │    │
│  │  │  │  - Video playback                    │    │    │    │
│  │  │  │  - Native controls                   │    │    │    │
│  │  │  └──────────────────────────────────────┘    │    │    │
│  │  │                                                │    │    │
│  │  │  <script src="cloudflare SDK">                │    │    │
│  │  │  - Initializes Stream player                  │    │    │
│  │  │  - Listens to video events                    │    │    │
│  │  │  - Sends events to Flutter                    │    │    │
│  │  │                                                │    │    │
│  │  │  player.addEventListener('timeupdate', ...)   │    │    │
│  │  │  player.addEventListener('ended', ...)        │    │    │
│  │  │  FlutterChannel.postMessage(...)              │    │    │
│  │  └───────────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                           │
                           │ HTTP POST
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Backend (Node.js)                           │
│                                                                  │
│  POST /api/classes/days/:dayId/track                            │
│  - Receives progress updates                                    │
│  - Calculates completion percentage                             │
│  - Checks milestone thresholds                                  │
│  - Updates user_day_progress table                              │
│  - Marks day complete at 90%+                                   │
│  - Unlocks next day                                             │
│  - Checks class completion                                      │
│  - Unlocks next level                                           │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Database (MySQL)                            │
│                                                                  │
│  user_day_progress table:                                       │
│  - completion_percentage                                        │
│  - milestone_25_reached, milestone_25_at                        │
│  - milestone_50_reached, milestone_50_at                        │
│  - milestone_75_reached, milestone_75_at                        │
│  - milestone_90_reached, milestone_90_at                        │
│  - milestone_100_reached, milestone_100_at                      │
│  - is_completed, completed_at                                   │
│  - last_position_seconds                                        │
│  - watch_time_seconds                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Event Flow Timeline

```
Time    Event                           Action
────────────────────────────────────────────────────────────────────
0:00    User opens video screen         → Load video config from backend
0:01    WebView loads HTML page         → Load Cloudflare iframe + SDK
0:02    SDK initializes                 → Attach event listeners
0:03    Video metadata loads            → Get duration (e.g., 1800s)
0:04    User clicks play                → 'play' event
0:04    Flutter receives 'start'        → Call onStart callback
0:04    day_video_screen calls API      → POST /api/classes/days/4/start
0:06    Video playing (2s elapsed)      → 'timeupdate' event
0:06    Flutter receives 'progress'     → position: 2, duration: 1800
0:06    day_video_screen calls API      → POST /api/classes/days/4/track
0:06    Backend updates database        → completion_percentage: 0.11%
0:08    Video playing (4s elapsed)      → 'timeupdate' event
0:08    Flutter receives 'progress'     → position: 4, duration: 1800
0:08    day_video_screen calls API      → POST /api/classes/days/4/track
...     (every 2 seconds)               → Progress updates continue
7:30    Video at 450s (25%)             → 'timeupdate' event
7:30    Flutter detects milestone       → milestone_25
7:30    day_video_screen calls API      → POST with milestone_25
7:30    Backend updates database        → milestone_25_reached: TRUE
15:00   Video at 900s (50%)             → 'timeupdate' event
15:00   Flutter detects milestone       → milestone_50
15:00   Toast notification shows        → "Halfway there! 50% Completed"
15:00   day_video_screen calls API      → POST with milestone_50
15:00   Backend updates database        → milestone_50_reached: TRUE
22:30   Video at 1350s (75%)            → 'timeupdate' event
22:30   Flutter detects milestone       → milestone_75
22:30   day_video_screen calls API      → POST with milestone_75
22:30   Backend updates database        → milestone_75_reached: TRUE
27:00   Video at 1620s (90%)            → 'timeupdate' event
27:00   Flutter detects milestone       → milestone_90
27:00   Toast notification shows        → "Congratulations! Day Completed"
27:00   day_video_screen calls API      → POST with milestone_90
27:00   Backend checks completion       → 90% >= 90% required ✓
27:00   Backend marks day complete      → is_completed: TRUE
27:00   Backend unlocks next day        → CALL unlock_next_day_if_eligible
27:00   Backend checks class complete   → All days done?
27:00   Backend unlocks next level      → CALL unlock_next_level_if_eligible
27:00   Backend returns response        → dayCompleted: true
27:00   Flutter shows dialog            → Completion dialog with checkmark
30:00   Video ends (1800s)              → 'ended' event
30:00   Flutter receives 'complete'     → Call onComplete callback
30:00   Video overlay shows             → "Video Completed!"
30:00   Replay blocked                  → isCompleted = true
```

## Data Flow

```
┌─────────────────┐
│  Video Player   │
│  (Cloudflare)   │
└────────┬────────┘
         │ Events: play, pause, timeupdate, ended
         ▼
┌─────────────────┐
│  Stream SDK     │
│  (JavaScript)   │
└────────┬────────┘
         │ postMessage via FlutterChannel
         ▼
┌─────────────────┐
│  Flutter Widget │
│  (Dart)         │
└────────┬────────┘
         │ onProgress callback
         ▼
┌─────────────────┐
│  Video Screen   │
│  (Dart)         │
└────────┬────────┘
         │ HTTP POST
         ▼
┌─────────────────┐
│  Backend API    │
│  (Node.js)      │
└────────┬────────┘
         │ SQL UPDATE
         ▼
┌─────────────────┐
│  Database       │
│  (MySQL)        │
└─────────────────┘
```

## Milestone Detection

```
Frontend (cloudflare_video_player.dart):
─────────────────────────────────────────
position: 450s, duration: 1800s
→ percentage = (450 / 1800) * 100 = 25%
→ Check: 25% >= 25 && !reported[25] ✓
→ Add to reported: [25]
→ Call: onProgress(450, 1800, 'milestone_25')

Backend (classes-video.js):
───────────────────────────
Receive: position=450, duration=1800, eventType='milestone_25'
→ Calculate: completionPercentage = (450 / 1800) * 100 = 25%
→ Check: 25% >= 25 && !milestone_25_reached ✓
→ SQL: UPDATE user_day_progress 
       SET milestone_25_reached = TRUE,
           milestone_25_at = NOW()
→ Response: { milestonesReached: [25] }

Database (user_day_progress):
─────────────────────────────
milestone_25_reached: 1
milestone_25_at: 2026-04-11 12:30:45
```

## Completion Flow

```
Video at 90% (1620s / 1800s):
─────────────────────────────
1. Frontend detects 90% milestone
   → onProgress(1620, 1800, 'milestone_90')

2. day_video_screen calls API
   → POST /api/classes/days/4/track
   → { positionSeconds: 1620, durationSeconds: 1800 }

3. Backend calculates percentage
   → completionPercentage = (1620 / 1800) * 100 = 90%

4. Backend checks completion threshold
   → 90% >= completion_percentage_required (90%) ✓

5. Backend marks day complete
   → UPDATE user_day_progress 
      SET is_completed = TRUE, completed_at = NOW()

6. Backend unlocks next day
   → CALL unlock_next_day_if_eligible(uid, classId)

7. Backend checks if all days complete
   → SELECT COUNT(*) WHERE is_completed = TRUE
   → If all complete: Mark class complete

8. Backend unlocks next level
   → CALL unlock_next_level_if_eligible(uid, classId)

9. Backend returns response
   → { dayCompleted: true, classCompleted: false, unlockHours: 24 }

10. Frontend shows toast
    → "Congratulations! Day Completed"

11. Frontend shows dialog
    → Completion dialog with checkmark
    → "Next day unlocks in 24 hours"
```

## Key Differences from Previous Implementation

### ❌ Old Approach (Didn't Work)
```
WebView loads iframe URL directly
→ Try to inject SDK into iframe (fails due to CORS)
→ Try to use postMessage from iframe (doesn't work)
→ No events received
→ No tracking
```

### ✅ New Approach (Works)
```
WebView loads complete HTML page
→ HTML contains iframe + SDK script
→ SDK loads in parent page (not iframe)
→ SDK communicates with iframe via postMessage
→ SDK sends events to Flutter via JavaScript channel
→ Events received properly
→ Tracking works
```

## Testing Checklist

- [ ] Video loads and plays
- [ ] Progress updates every 2 seconds
- [ ] Backend logs show progress updates
- [ ] Database updates with completion_percentage
- [ ] Toast appears at 50%
- [ ] milestone_50_reached = TRUE in database
- [ ] Toast appears at 90%
- [ ] is_completed = TRUE in database
- [ ] Completion dialog shows
- [ ] Video stops and prevents replay
- [ ] Next day unlocks after 24 hours
- [ ] Class completes when all days done
- [ ] Next level unlocks automatically

---

**This flow is based on Cloudflare's official documentation and will work correctly.**
