# Multi-Language Video System - Implementation Guide

## ✅ Implementation Status: COMPLETE

The multi-language video system is **fully implemented** in both backend and mobile app.

---

## 📋 Overview

The system allows users to:
1. Select their preferred language during onboarding
2. Change language anytime from settings
3. Watch videos in their selected language
4. Seamlessly switch between languages

---

## 🏗️ Architecture

### Backend (Node.js + MSSQL)
- **API Version**: V2 (`/api/classes-v2/*`)
- **Database**: Multi-language support with `language` column in `class_days` table
- **Caching**: Redis caching for language preferences and video configs
- **Storage**: Cloudflare R2 with language-specific folders

### Mobile App (Flutter)
- **Language Service**: `LocalizationService` manages UI language + syncs with backend
- **API Integration**: All video-related endpoints pass `language` parameter
- **Screens Updated**: 
  - `day_video_screen.dart` - Video playback with language
  - `class_days_list_screen.dart` - Days list with language
  - `language_selection_screen.dart` - Language picker

---

## 🔄 How It Works

### 1. Language Selection Flow

```
User Opens App
    ↓
First Time? → Language Selection Screen
    ↓
User Selects Language (e.g., Telugu)
    ↓
LocalizationService.changeLanguage('te')
    ↓
├─ Save to SharedPreferences (local)
├─ Load UI translations (assets/translations/te.json)
└─ Sync with Backend API (POST /api/classes-v2/user/language)
    ↓
Backend Updates Database + Redis Cache
```

### 2. Video Playback Flow

```
User Opens Video
    ↓
day_video_screen.dart loads
    ↓
Get current language from LocalizationService
    ↓
API Call: GET /api/classes-v2/days/:dayId/video-config?language=te
    ↓
Backend Queries Database
    ↓
├─ Checks user_language_preferences table
├─ Gets video from class_days WHERE language='te'
└─ Returns HLS URL: classes/videos/{classId}/{dayNumber}/te/master.m3u8
    ↓
Video Player Loads Language-Specific Video
```

### 3. Language Change Flow

```
User Goes to Settings → Language
    ↓
Selects New Language (e.g., Hindi)
    ↓
LocalizationService.changeLanguage('hi')
    ↓
├─ Update UI immediately
├─ Save to SharedPreferences
└─ Sync with Backend API
    ↓
Backend Clears Redis Cache for User
    ↓
Next Video Load → Fetches Hindi Video
```

---

## 📁 File Structure

### Backend Files
```
sks-classes-service/
├── routes/
│   └── classes-video-v2.js          # V2 API with language support
├── migrations/
│   └── add_multi_language_support.sql  # Database schema
└── MULTI_LANGUAGE_VIDEO_SYSTEM.md   # Backend documentation
```

### Mobile App Files
```
SKS-mobile-V2/
├── lib/
│   ├── core/
│   │   └── services/
│   │       ├── api_service.dart           # Added language API methods
│   │       └── localization_service.dart  # Updated to sync with backend
│   └── features/
│       ├── learnings/
│       │   ├── day_video_screen.dart      # Passes language parameter
│       │   └── class_days_list_screen.dart # Passes language parameter
│       └── language/
│           └── language_selection_screen.dart # Language picker
└── assets/
    └── translations/
        ├── en.json  # English UI translations
        ├── te.json  # Telugu UI translations
        └── hi.json  # Hindi UI translations
```

---

## 🔧 Code Changes Made

### 1. ApiService - Added Language Methods

**File**: `lib/core/services/api_service.dart`

```dart
// ── 34. POST /api/classes-v2/user/language - Set user's language preference ─
Future<Map<String, dynamic>> setUserLanguage(String languageCode) async {
  final response = await _dio.post(
    '/api/classes-v2/user/language',
    options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    data: {'language': languageCode},
  );
  return response.data as Map<String, dynamic>;
}

// ── 35. GET /api/classes-v2/user/language - Get user's language preference ─
Future<Map<String, dynamic>> getUserLanguage() async {
  final response = await _dio.get(
    '/api/classes-v2/user/language',
    options: Options(headers: {'Authorization': 'Bearer $idToken'}),
  );
  return response.data as Map<String, dynamic>;
}
```

### 2. LocalizationService - Backend Sync

**File**: `lib/core/services/localization_service.dart`

```dart
Future<void> changeLanguage(String languageCode, {bool savePreference = true}) async {
  await _loadLanguage(languageCode);
  _currentLocale = Locale(languageCode);

  if (savePreference) {
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // 🆕 Sync with backend API
    try {
      debugPrint('🌐 Syncing language preference with backend: $languageCode');
      final response = await _apiService.setUserLanguage(languageCode);
      if (response['success'] == true) {
        debugPrint('✅ Language preference synced with backend');
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing language with backend (non-critical): $e');
      // Don't fail the language change if backend sync fails
    }
  }

  notifyListeners();
}
```

### 3. Video Screen - Pass Language Parameter

**File**: `lib/features/learnings/day_video_screen.dart`

```dart
Future<void> _loadVideoConfig() async {
  // 🆕 Get user's current language preference
  final currentLanguage = LocalizationService().currentLocale.languageCode;
  debugPrint('🌐 Using language: $currentLanguage');
  
  final response = await _apiService.get(
    '/api/classes-v2/days/${widget.dayId}/video-config',
    queryParameters: {'language': currentLanguage},  // 🆕 Pass language
  );
  
  // ... rest of the code
}
```

### 4. Days List Screen - Pass Language Parameter

**File**: `lib/features/learnings/class_days_list_screen.dart`

```dart
Future<void> _loadDays() async {
  // 🆕 Get user's current language preference
  final currentLanguage = LocalizationService().currentLocale.languageCode;
  debugPrint('🌐 Using language: $currentLanguage');
  
  final response = await _apiService.get(
    '/api/classes-v2/${widget.classId}/days',
    queryParameters: {'language': currentLanguage},  // 🆕 Pass language
  );
  
  // ... rest of the code
}
```

---

## 🌐 Supported Languages

| Code | Language | UI Translations | Video Support |
|------|----------|----------------|---------------|
| `en` | English  | ✅ Yes         | ✅ Yes        |
| `te` | Telugu   | ✅ Yes         | ✅ Yes        |
| `hi` | Hindi    | ✅ Yes         | ✅ Yes        |

---

## 📊 Database Schema

### Tables Involved

1. **`class_days`** - Stores videos with language
   ```sql
   - id (PK)
   - class_id
   - day_number
   - language (en/te/hi)
   - hls_master_playlist_url
   - hls_base_path
   - UNIQUE CONSTRAINT (class_id, day_number, language)
   ```

2. **`user_language_preferences`** - Stores user preferences
   ```sql
   - user_uid (PK)
   - preferred_language (en/te/hi)
   - created_at
   - updated_at
   ```

3. **`video_languages`** - Master list of supported languages
   ```sql
   - language_code (PK)
   - language_name
   - is_active
   ```

---

## 🎯 API Endpoints

### V2 Endpoints (Multi-Language)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/classes-v2/user/language` | Set user's language preference |
| `GET` | `/api/classes-v2/user/language` | Get user's language preference |
| `GET` | `/api/classes-v2/:classId/days?language=te` | Get class days with language |
| `GET` | `/api/classes-v2/days/:dayId/video-config?language=te` | Get video config with language |

### Request Examples

**Set Language:**
```bash
POST /api/classes-v2/user/language
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "language": "te"
}
```

**Get Video Config:**
```bash
GET /api/classes-v2/days/123/video-config?language=te
Authorization: Bearer <firebase-token>
```

**Response:**
```json
{
  "success": true,
  "videoConfig": {
    "streamingType": "hls",
    "hlsUrl": "https://r2.sivakundalini.org/classes/videos/1/1/te/master.m3u8",
    "language": "te",
    "videoDurationSeconds": 1800,
    "thumbnailUrl": "https://r2.sivakundalini.org/classes/videos/1/1/te/thumbnail.jpg"
  }
}
```

---

## 📦 Video Storage Structure

Videos are organized by language in Cloudflare R2:

```
classes/
└── videos/
    └── {classId}/
        └── {dayNumber}/
            ├── en/
            │   ├── master.m3u8
            │   ├── 360p/
            │   ├── 480p/
            │   ├── 720p/
            │   └── thumbnail.jpg
            ├── te/
            │   ├── master.m3u8
            │   ├── 360p/
            │   ├── 480p/
            │   ├── 720p/
            │   └── thumbnail.jpg
            └── hi/
                ├── master.m3u8
                ├── 360p/
                ├── 480p/
                ├── 720p/
                └── thumbnail.jpg
```

---

## 🚀 Adding New Language

### Step 1: Add to Database

```sql
-- Add language to master list
INSERT INTO video_languages (language_code, language_name, is_active)
VALUES ('ta', 'Tamil', 1);
```

### Step 2: Add UI Translations

Create `assets/translations/ta.json`:
```json
{
  "app_name": "சிவகுண்டலினி",
  "welcome": "வரவேற்கிறோம்",
  "language_selection_title": "உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்"
}
```

### Step 3: Update Flutter App

**File**: `lib/core/services/localization_service.dart`
```dart
static const List<Locale> supportedLocales = [
  Locale('en'),
  Locale('te'),
  Locale('hi'),
  Locale('ta'),  // 🆕 Add Tamil
];

static const Map<String, String> languageNames = {
  'en': 'English',
  'te': 'తెలుగు (Telugu)',
  'hi': 'हिंदी (Hindi)',
  'ta': 'தமிழ் (Tamil)',  // 🆕 Add Tamil
};
```

### Step 4: Upload Videos

Upload videos to R2 with language folder:
```
classes/videos/1/1/ta/master.m3u8
classes/videos/1/1/ta/360p/...
classes/videos/1/1/ta/thumbnail.jpg
```

### Step 5: Add Database Records

```sql
INSERT INTO class_days (
  class_id, day_number, language, title, description,
  hls_master_playlist_url, hls_base_path,
  video_duration_seconds, is_active
)
VALUES (
  1, 1, 'ta', 'Day 1 - Introduction', 'Tamil version',
  'https://r2.sivakundalini.org/classes/videos/1/1/ta/master.m3u8',
  'classes/videos/1/1/ta',
  1800, 1
);
```

---

## 🧪 Testing

### Test Language Selection
1. Open app (first time)
2. Language selection screen should appear
3. Select Telugu
4. UI should change to Telugu
5. Check backend: `SELECT * FROM user_language_preferences WHERE user_uid = 'xxx'`
6. Should show `preferred_language = 'te'`

### Test Video Playback
1. Navigate to a class
2. Open a video
3. Check browser console: Should see `🌐 Using language: te`
4. Video should load Telugu version
5. Check network tab: Should request `.../te/master.m3u8`

### Test Language Change
1. Go to Settings → Language
2. Change to Hindi
3. UI should update immediately
4. Go back to video
5. Should now load Hindi version

---

## 🐛 Troubleshooting

### Issue: Video not loading after language change

**Solution**: Clear Redis cache
```bash
# On backend server
redis-cli
> DEL user:language:USER_UID
> DEL video:config:DAY_ID:LANGUAGE
> DEL class:days:CLASS_ID:USER_UID:LANGUAGE
```

### Issue: Language preference not syncing

**Check**:
1. Network tab - Is API call being made?
2. Backend logs - Is request reaching server?
3. Database - Is record being created?

**Debug**:
```dart
// In LocalizationService.changeLanguage()
debugPrint('🌐 Syncing language preference with backend: $languageCode');
```

### Issue: Wrong language video playing

**Check**:
1. User's language preference in database
2. Video config API response
3. HLS URL in response

**Verify**:
```sql
-- Check user preference
SELECT * FROM user_language_preferences WHERE user_uid = 'xxx';

-- Check available videos
SELECT language, hls_master_playlist_url 
FROM class_days 
WHERE class_id = 1 AND day_number = 1;
```

---

## 📈 Performance

### Caching Strategy

1. **User Language Preference**: Cached in Redis for 24 hours
2. **Video Config**: Cached in Redis for 1 hour
3. **Class Days List**: Cached in Redis for 5 minutes

### Cache Keys
```
user:language:{user_uid}
video:config:{day_id}:{language}
class:days:{class_id}:{user_uid}:{language}
```

---

## ✅ Checklist

- [x] Backend V2 API implemented
- [x] Database schema with language support
- [x] Redis caching for language preferences
- [x] Mobile app API methods added
- [x] LocalizationService syncs with backend
- [x] Video screen passes language parameter
- [x] Days list screen passes language parameter
- [x] Language selection screen functional
- [x] Documentation created

---

## 📚 Related Documentation

- Backend: `s:\Backup\sks-classes-service\MULTI_LANGUAGE_VIDEO_SYSTEM.md`
- Database: `s:\Backup\sks-classes-service\migrations\add_multi_language_support.sql`
- API Routes: `s:\Backup\sks-classes-service\routes\classes-video-v2.js`

---

## 🎉 Summary

The multi-language video system is **fully operational**. Users can:

✅ Select language during onboarding  
✅ Change language anytime from settings  
✅ Watch videos in their preferred language  
✅ Seamlessly switch between languages  
✅ System automatically syncs preferences with backend  
✅ Videos load from language-specific folders in R2  

**Everything is working smoothly!** 🚀
