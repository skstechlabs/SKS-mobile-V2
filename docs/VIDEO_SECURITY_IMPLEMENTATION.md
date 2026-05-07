# Video Security Implementation

## Overview
Comprehensive security measures to prevent screen recording, screenshots, downloading, and unauthorized sharing of class videos.

## Security Layers Implemented

### 1. Android FLAG_SECURE
**Location:** `android/app/src/main/kotlin/com/spiritual/app/MainActivity.kt`

**Features:**
- Prevents screenshots on Android devices
- Blocks screen recording apps
- Prevents video from appearing in recent apps screen
- Automatically re-enabled when app resumes

**Implementation:**
```kotlin
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
)
```

### 2. Secure Screen Wrapper
**Location:** `lib/features/learnings/widgets/secure_screen_wrapper.dart`

**Features:**
- Platform channel communication for native security
- Watermark overlay on video content
- Lifecycle monitoring for security state
- Fallback to Flutter-level protection

### 3. App Lifecycle Monitoring
**Location:** `lib/features/learnings/day_video_screen.dart`

**Features:**
- Detects when app goes to background (potential recording)
- Logs suspicious activity
- Pauses video during background state
- Shows security warnings

### 4. Backend Security Logging
**Location:** `sks-backend/routes/classes-video.js`

**Endpoint:** `POST /api/classes/days/:dayId/security-event`

**Logged Events:**
- `screen_recording_detected` - Screen recording attempt
- `screenshot_detected` - Screenshot attempt
- `download_attempt` - Video download attempt
- `app_backgrounded` - App sent to background during playback

**Database Table:** `video_security_events`
```sql
CREATE TABLE video_security_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_uid VARCHAR(255) NOT NULL,
  day_id INT NOT NULL,
  class_id INT NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  session_id VARCHAR(255),
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5. Cloudflare Stream Protection
**Features:**
- DRM (Digital Rights Management) support
- Signed URLs with expiration
- Domain restrictions
- Geo-blocking capabilities
- Hotlink protection

**Configuration in backend:**
```javascript
{
  cloudflareVideoId: video.id,
  cloudflareAccountId: account.id,
  allowSkip: false,        // Prevents seeking
  allowDownload: false,    // Disables download button
}
```

### 6. WebView Security
**Location:** `lib/features/learnings/widgets/cloudflare_video_player.dart`

**Features:**
- Disables right-click context menu
- Prevents video seeking (if configured)
- Blocks download attempts
- JavaScript injection for additional controls

### 7. UI Security Warnings
**Features:**
- Prominent security warning banner
- Real-time violation alerts
- Account suspension warnings
- Legal consequences notification

## User-Facing Security Measures

### Security Warning Banner
Displayed on every video screen:
```
🔒 Protected Content
Recording, downloading, or sharing this video is strictly prohibited
```

### Violation Dialog
Shown when suspicious activity detected:
```
⚠️ Security Warning
Screen recording or screenshot detected.

Consequences:
• Immediate account suspension
• Legal action for copyright violation
• Loss of access to all courses

This incident has been logged.
```

## Admin Monitoring

### Security Dashboard Query
```sql
SELECT 
  user_uid,
  COUNT(*) as total_violations,
  SUM(CASE WHEN event_type = 'screen_recording_detected' THEN 1 ELSE 0 END) as recording_attempts,
  MAX(created_at) as last_violation
FROM video_security_events
GROUP BY user_uid
HAVING total_violations > 0
ORDER BY total_violations DESC;
```

### Real-time Alerts
Backend logs serious violations:
```javascript
console.log(`🚨 SERIOUS VIOLATION: ${eventType} by user ${uid}`);
```

## Limitations & Workarounds

### Known Limitations:
1. **iOS Screen Recording:** iOS doesn't provide API to detect screen recording
   - Mitigation: Watermarks, legal warnings, account monitoring
   
2. **External Cameras:** Cannot prevent filming screen with external camera
   - Mitigation: Watermarks with user ID, legal terms

3. **Rooted/Jailbroken Devices:** May bypass FLAG_SECURE
   - Mitigation: Backend logging, pattern detection

### Additional Recommendations:

1. **User ID Watermark:** Add dynamic watermark with user email/ID
2. **Session Tokens:** Expire video URLs after viewing session
3. **Device Fingerprinting:** Track and limit devices per account
4. **AI Detection:** Monitor for pirated content online
5. **Legal Terms:** Strong terms of service with penalties

## Setup Instructions

### 1. Database Migration
```bash
cd sks-backend
mysql -u root -p your_database < migrations/add_video_security_events_table.sql
```

### 2. Rebuild Flutter App
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
```

### 3. Test Security Features
- Try taking screenshot during video playback (should be blocked on Android)
- Check backend logs for security events
- Verify watermark appears on video

## Monitoring & Response

### Daily Monitoring:
```sql
-- Check for violations in last 24 hours
SELECT * FROM video_security_events 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY created_at DESC;
```

### Response Protocol:
1. **First Violation:** Warning email
2. **Second Violation:** 7-day suspension
3. **Third Violation:** Permanent ban + legal notice

## Future Enhancements

1. **Dynamic Watermarks:** User email/ID overlay
2. **Forensic Watermarking:** Invisible tracking codes
3. **AI Content Monitoring:** Scan web for pirated content
4. **Hardware DRM:** Widevine L1 integration
5. **Biometric Verification:** Face ID during playback
6. **Session Recording:** Record user interactions for audit

## Legal Protection

### Terms of Service Clause:
```
All video content is protected by copyright law. 
Recording, downloading, or sharing content is strictly prohibited.
Violations will result in:
- Immediate account termination
- Legal action for damages
- Criminal prosecution where applicable
```

### Copyright Notice:
```
© 2024 Siva Kundalini Spiritual. All Rights Reserved.
Unauthorized reproduction or distribution is prohibited.
```

## Support

For security concerns or to report violations:
- Email: security@sivakundalini.org
- Report violations through admin dashboard
- Emergency: Contact legal team immediately
