# Classes Video Streaming System - Implementation Guide

## Overview

Comprehensive video streaming system for online classes with:
- 4 Levels, each with 3 days
- Cloudflare Stream integration
- 24-hour day unlocking mechanism
- Progress tracking and analytics
- Database-driven configuration
- Video protection (no download, no skip)

## Architecture

### Database Schema

#### Tables Created:
1. `class_days` - Video content for each day
2. `user_class_enrollments` - User enrollment tracking
3. `user_day_progress` - Day-by-day progress
4. `video_watch_events` - Detailed video interaction logs
5. `video_analytics_summary` - Aggregated metrics

### Key Features:

1. **24-Hour Unlock Mechanism**:
   - Day 1 unlocks immediately upon enrollment
   - Each subsequent day unlocks 24 hours after completing previous day
   - Stored procedure `unlock_next_day_if_eligible` handles automatic unlocking

2. **Progress Tracking**:
   - Real-time position tracking
   - Completion percentage calculation
   - Watch time accumulation
   - Event logging (play, pause, seek, complete)

3. **Video Protection**:
   - Disable video seeking (configurable per day)
   - Disable video download (configurable per day)
   - Completion criteria (default: 90% watch time)

4. **Database-Driven Configuration**:
   - Video URLs stored in database
   - Completion criteria configurable
   - Allow skip/download configurable per day
   - All settings in database, no hardcoding

## Setup Instructions

### 1. Database Setup

Run the migration script:
```bash
mysql -u root -p sks_db < sks-backend/database/migrations/create_classes_video_system.sql
```

This will:
- Create all required tables
- Insert sample data for 4 levels × 3 days
- Create stored procedures
- Create views for easy querying

### 2. Backend Setup

The backend routes are already integrated in `server.js`:
```javascript
const classesVideoRoutes = require('./routes/classes-video');
app.use('/api/classes', classesVideoRoutes);
```

### 3. Mobile App Setup

#### Add Dependencies:
```bash
cd SKS-mobile-V2
flutter pub get
```

Dependencies added:
- `webview_flutter: ^4.4.2` (already present)
- `uuid: ^4.5.1` (added)

#### Update Router:

Add routes to `lib/core/router.dart`:
```dart
GoRoute(
  path: '/classes/:classId/days',
  builder: (context, state) {
    final classId = int.parse(state.pathParameters['classId']!);
    return ClassDaysScreen(classId: classId);
  },
),
GoRoute(
  path: '/classes/days/:dayId/video',
  builder: (context, state) {
    final dayId = int.parse(state.pathParameters['dayId']!);
    final dayTitle = state.uri.queryParameters['title'] ?? 'Video';
    final dayNumber = int.parse(state.uri.queryParameters['dayNumber'] ?? '1');
    return DayVideoScreen(
      dayId: dayId,
      dayTitle: dayTitle,
      dayNumber: dayNumber,
    );
  },
),
```

## API Endpoints

### 1. Enroll in Class
```
POST /api/classes/:classId/enroll
Authorization: Bearer <firebase_token>
```

Response:
```json
{
  "success": true,
  "message": "Successfully enrolled in class"
}
```

### 2. Get Class Days with Unlock Status
```
GET /api/classes/:classId/days
Authorization: Bearer <firebase_token>
```

Response:
```json
{
  "success": true,
  "days": [
    {
      "id": 1,
      "dayNumber": 1,
      "title": "Day 1: Introduction",
      "description": "...",
      "cloudflareVideoId": "53a2449734925b7b5a41ac0f06099251",
      "videoDurationSeconds": 1800,
      "isUnlocked": true,
      "isCompleted": false,
      "unlockStatus": "unlocked",
      "hoursUntilUnlock": null
    },
    {
      "id": 2,
      "dayNumber": 2,
      "title": "Day 2: Techniques",
      "isUnlocked": false,
      "unlockStatus": "locked",
      "hoursUntilUnlock": 18
    }
  ]
}
```

### 3. Get Video Configuration
```
GET /api/classes/days/:dayId/video-config
Authorization: Bearer <firebase_token>
```

Response:
```json
{
  "success": true,
  "videoConfig": {
    "cloudflareVideoId": "53a2449734925b7b5a41ac0f06099251",
    "cloudflareAccountId": "customer-7cfnr6ncaaqevxfc",
    "allowSkip": false,
    "allowDownload": false,
    "videoDurationSeconds": 1800,
    "completionPercentageRequired": 90,
    "lastPositionSeconds": 450,
    "iframeUrl": "https://customer-7cfnr6ncaaqevxfc.cloudflarestream.com/53a2449734925b7b5a41ac0f06099251/iframe",
    "playerUrl": "https://customer-7cfnr6ncaaqevxfc.cloudflarestream.com/53a2449734925b7b5a41ac0f06099251/watch"
  }
}
```

### 4. Mark Day as Started
```
POST /api/classes/days/:dayId/start
Authorization: Bearer <firebase_token>
```

### 5. Track Video Progress
```
POST /api/classes/days/:dayId/track
Authorization: Bearer <firebase_token>

Body:
{
  "eventType": "progress",  // play, pause, seek, complete, progress
  "positionSeconds": 450,
  "durationSeconds": 1800,
  "sessionId": "uuid-v4",
  "deviceInfo": {
    "platform": "android",
    "userAgent": "Flutter Mobile App"
  }
}
```

### 6. Get User Progress
```
GET /api/classes/:classId/progress
Authorization: Bearer <firebase_token>
```

Response:
```json
{
  "success": true,
  "progress": {
    "classId": 1,
    "level": "Level 1",
    "classTitle": "Brahmarandhra Opening",
    "currentDay": 2,
    "totalDays": 3,
    "daysCompleted": 1,
    "avgCompletionPercentage": 95.5,
    "totalWatchTimeSeconds": 1850
  }
}
```

## Cloudflare Stream Integration

### Video Player Implementation

The `CloudflareVideoPlayer` widget uses WebView to embed Cloudflare Stream iframe:

```dart
CloudflareVideoPlayer(
  videoId: '53a2449734925b7b5a41ac0f06099251',
  accountId: 'customer-7cfnr6ncaaqevxfc',
  lastPositionSeconds: 450,
  allowSkip: false,
  onStart: () => _markDayAsStarted(),
  onProgress: (position, duration, eventType) => _trackProgress(position, duration, eventType),
  onComplete: () => _handleCompletion(),
)
```

### Features:
- Auto-resume from last position
- Disable seeking if `allowSkip = false`
- Disable download/right-click
- Real-time progress tracking
- Event logging (play, pause, complete)

## Configuration

### Update Cloudflare Video IDs

To use your own videos, update the database:

```sql
UPDATE class_days 
SET cloudflare_video_id = 'YOUR_VIDEO_ID'
WHERE class_id = 1 AND day_number = 1;
```

### Update Cloudflare Account ID

```sql
UPDATE classes 
SET cloudflare_account_id = 'YOUR_ACCOUNT_ID'
WHERE id = 1;
```

### Configure Completion Criteria

```sql
UPDATE class_days 
SET completion_percentage_required = 95,  -- Require 95% watch time
    min_watch_time_seconds = 1620,        -- Minimum 27 minutes
    allow_skip = FALSE,                    -- Disable seeking
    allow_download = FALSE                 -- Disable download
WHERE id = 1;
```

### Configure Class-Level Criteria

```sql
UPDATE classes 
SET completion_criteria = JSON_OBJECT(
  'min_completion_percentage', 90,
  'require_all_days', true,
  'min_watch_time_per_day', 0.9
)
WHERE id = 1;
```

## Testing

### 1. Test Enrollment
```bash
curl -X POST http://localhost:3012/api/classes/1/enroll \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
```

### 2. Test Day Unlock Status
```bash
curl http://localhost:3012/api/classes/1/days \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
```

### 3. Test Video Config
```bash
curl http://localhost:3012/api/classes/days/1/video-config \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
```

### 4. Test Progress Tracking
```bash
curl -X POST http://localhost:3012/api/classes/days/1/track \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "progress",
    "positionSeconds": 900,
    "durationSeconds": 1800,
    "sessionId": "test-session-123"
  }'
```

## Analytics

### View User Progress
```sql
SELECT * FROM v_user_class_progress 
WHERE user_uid = 'USER_UID';
```

### View Day Unlock Status
```sql
SELECT * FROM v_user_day_unlock_status 
WHERE user_uid = 'USER_UID' AND class_id = 1;
```

### View Video Watch Events
```sql
SELECT 
  event_type,
  position_seconds,
  created_at
FROM video_watch_events
WHERE user_uid = 'USER_UID' AND day_id = 1
ORDER BY created_at DESC
LIMIT 50;
```

### Get Analytics Summary
```sql
SELECT 
  c.level,
  cd.day_number,
  cd.title,
  COUNT(DISTINCT vwe.user_uid) AS unique_viewers,
  AVG(udp.completion_percentage) AS avg_completion,
  SUM(udp.watch_time_seconds) AS total_watch_time
FROM class_days cd
JOIN classes c ON cd.class_id = c.id
LEFT JOIN video_watch_events vwe ON cd.id = vwe.day_id
LEFT JOIN user_day_progress udp ON cd.id = udp.day_id
WHERE c.id = 1
GROUP BY c.level, cd.day_number, cd.title;
```

## Mobile App Usage

### 1. Update Learnings Page

The learnings page now needs to navigate to class days:

```dart
_buildDayTile(context, 'Day 1', classId: 1, dayNumber: 1)
```

### 2. Navigate to Video
```dart
context.push(
  '/classes/days/$dayId/video?title=${Uri.encodeComponent(dayTitle)}&dayNumber=$dayNumber'
);
```

## Security Considerations

1. **Authentication**: All endpoints require Firebase token
2. **Authorization**: Users can only access days they've unlocked
3. **Video Protection**: 
   - Seeking disabled by default
   - Download disabled
   - Right-click disabled
4. **Rate Limiting**: Consider adding rate limits for tracking endpoints
5. **Session Validation**: Session IDs prevent duplicate tracking

## Performance Optimization

1. **Progress Tracking**: Only track every 5 seconds to reduce API calls
2. **Database Indexes**: All foreign keys and frequently queried columns indexed
3. **Views**: Pre-computed views for common queries
4. **Caching**: Consider caching video config for 5 minutes

## Troubleshooting

### Video Not Playing
- Check Cloudflare video ID is correct
- Verify Cloudflare account ID
- Check network connectivity
- Verify video is published in Cloudflare Stream

### Day Not Unlocking
- Check previous day is completed
- Verify 24 hours have passed since completion
- Run stored procedure manually: `CALL unlock_next_day_if_eligible('USER_UID', CLASS_ID);`

### Progress Not Tracking
- Check Firebase token is valid
- Verify day is unlocked
- Check network logs for API errors
- Verify session ID is being sent

## Next Steps

1. ✅ Database schema created
2. ✅ Backend APIs implemented
3. ✅ Mobile app video player created
4. ⏳ Update learnings page to use new system
5. ⏳ Test end-to-end flow
6. ⏳ Add analytics dashboard (admin)
7. ⏳ Add push notifications for day unlocks

## Files Created

### Backend:
- `sks-backend/database/migrations/create_classes_video_system.sql`
- `sks-backend/routes/classes-video.js`

### Mobile App:
- `SKS-mobile-V2/lib/features/learnings/widgets/cloudflare_video_player.dart`
- `SKS-mobile-V2/lib/features/learnings/day_video_screen.dart`

### Documentation:
- `SKS-mobile-V2/CLASSES_VIDEO_STREAMING_IMPLEMENTATION.md` (this file)

## Support

For issues or questions:
1. Check database logs: `SELECT * FROM video_watch_events ORDER BY created_at DESC LIMIT 100;`
2. Check backend logs: `pm2 logs sks-backend`
3. Check mobile app logs: `flutter logs`
