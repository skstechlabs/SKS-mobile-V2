# SKS Classes Service Integration Guide

## Overview

This guide explains how to connect the SKS-mobile-V2 Flutter app to the sks-classes-service backend.

## Backend Service Details

**Service Name:** sks-classes-service  
**Default Port:** 3013  
**Base URL:** `http://localhost:3013`  
**API Documentation:** http://localhost:3013/api-docs (Swagger UI)

### Available Endpoints

#### Public Endpoints (No Auth Required)
- `GET /health` - Health check
- `GET /api/classes` - Get all classes

#### Protected Endpoints (Firebase Auth Required)
- `GET /api/classes/:id` - Get class details
- `POST /api/classes/:id/enroll` - Enroll in class
- `GET /api/classes/my/enrollments` - Get user enrollments
- `GET /api/classes/:classId/days` - Get class days with progress
- `GET /api/classes/:classId/progress` - Get class progress
- `POST /api/classes/days/:dayId/start` - Start a day
- `POST /api/classes/days/:dayId/track` - Track video progress
- `GET /api/classes/days/:dayId/video-config` - Get video configuration
- `POST /api/classes/days/:dayId/security-event` - Log security events
- `GET /api/classes/analytics/summary` - Get analytics
- `GET /api/level-progression/access` - Get level access status
- `POST /api/level-progression/meditation-test` - Submit meditation test

## Frontend Integration Status

### ✅ Already Integrated

The Flutter app already has classes integration in the following files:

1. **API Service** (`lib/core/services/api_service.dart`)
   - Generic `get()` and `post()` methods support classes endpoints
   - Firebase authentication token handling

2. **Screens**
   - `lib/features/learnings/learnings_page.dart` - Classes list
   - `lib/features/learnings/class_days_list_screen.dart` - Class days
   - `lib/features/learnings/day_video_screen.dart` - Video player

3. **Routes** (`lib/core/router.dart`)
   - `/classes/:classId/days` - Class days route
   - `/classes/days/:dayId/video` - Video player route

4. **Existing API Calls**
   - `GET /api/classes/:classId/days`
   - `POST /api/classes/:classId/enroll`
   - `GET /api/classes/days/:dayId/video-config`
   - `POST /api/classes/days/:dayId/start`
   - `POST /api/classes/days/:dayId/track`
   - `POST /api/classes/days/:dayId/security-event`

## Setup Instructions

### 1. Start the Backend Service

```bash
cd s:\sks-classes-service-

# Install dependencies (first time only)
npm install

# Start in development mode
npm run dev

# Or start in production mode
npm start
```

The service will start on port 3013 by default.

### 2. Configure Flutter Environment

Create or update your `.env.json` file in the Flutter project root:

```json
{
  "MSG91_WIDGET_ID": "your_msg91_widget_id",
  "MSG91_AUTH_TOKEN": "your_msg91_auth_token",
  "API_BASE_URL": "http://localhost:3013",
  "GOOGLE_CLIENT_ID": "your_google_client_id",
  "ONESIGNAL_APP_ID": "your_onesignal_app_id"
}
```

**Important:** The `API_BASE_URL` should point to your classes service:
- **Development:** `http://localhost:3013`
- **Production:** `http://your-server-ip:3013`

### 3. Run the Flutter App

```bash
cd s:\SKS-mobile-V2

# Run with environment configuration
flutter run --dart-define-from-file=.env.json

# Or for web
flutter run -d chrome --dart-define-from-file=.env.json
```

## Adding New Classes Service Methods

If you need to add more classes-specific methods to the Flutter app, add them to `lib/core/services/api_service.dart`:

```dart
// Example: Get all classes
Future<Map<String, dynamic>> getAllClasses() async {
  try {
    final response = await _dio.get('/api/classes');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}

// Example: Get class details
Future<Map<String, dynamic>> getClassDetails(int classId) async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.get(
      '/api/classes/$classId',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}

// Example: Get my enrollments
Future<Map<String, dynamic>> getMyEnrollments() async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.get(
      '/api/classes/my/enrollments',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}

// Example: Get level access
Future<Map<String, dynamic>> getLevelAccess() async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.get(
      '/api/level-progression/access',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}

// Example: Submit meditation test
Future<Map<String, dynamic>> submitMeditationTest({
  required int score,
  required int totalQuestions,
  required Map<String, dynamic> answers,
}) async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.post(
      '/api/level-progression/meditation-test',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      data: {
        'score': score,
        'total_questions': totalQuestions,
        'answers': answers,
      },
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}
```

## Testing the Integration

### 1. Test Backend Health

```bash
curl http://localhost:3013/health
```

Expected response:
```json
{
  "success": true,
  "service": "sks-classes-service",
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 2. Test Public Endpoint

```bash
curl http://localhost:3013/api/classes
```

### 3. Test Protected Endpoint

You'll need a Firebase ID token. Get it from the Flutter app after login:

```dart
final user = FirebaseAuth.instance.currentUser;
final token = await user?.getIdToken();
print('Token: $token');
```

Then test with curl:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3013/api/classes/1
```

### 4. Test from Flutter App

1. Run the Flutter app
2. Login with Google or Phone
3. Navigate to the Classes/Learnings section
4. Check the console for API calls and responses

## Troubleshooting

### Issue: Connection Refused

**Problem:** Flutter app can't connect to backend  
**Solution:** 
- Ensure backend is running: `npm run dev` in sks-classes-service
- Check the port (default: 3013)
- Verify `API_BASE_URL` in `.env.json`

### Issue: 401 Unauthorized

**Problem:** API returns 401 error  
**Solution:**
- Ensure user is logged in
- Check Firebase token is being sent
- Verify Firebase Admin SDK is configured in backend `.env`

### Issue: CORS Error

**Problem:** Browser blocks requests  
**Solution:**
- Update `CORS_ORIGIN` in backend `.env` file
- Add your Flutter web URL (e.g., `http://localhost:8080`)

### Issue: Timeout Errors

**Problem:** Requests timeout  
**Solution:**
- Check network connectivity
- Increase timeout in `api_service.dart` (already set to 30s)
- Check backend logs for slow queries

## Architecture Overview

```
┌─────────────────────────────────────┐
│   SKS-mobile-V2 (Flutter App)       │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  lib/core/services/          │  │
│  │  - api_service.dart          │  │
│  │  - Dio HTTP client           │  │
│  │  - Firebase Auth tokens      │  │
│  └──────────────────────────────┘  │
│              │                      │
│              │ HTTP/JSON            │
│              │ Bearer Token         │
└──────────────┼──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  sks-classes-service (Node.js)      │
│  Port: 3013                         │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Express.js REST API         │  │
│  │  - Firebase Auth Middleware  │  │
│  │  - Classes Routes            │  │
│  │  - Video Streaming Routes    │  │
│  │  - Level Progression Routes  │  │
│  └──────────────────────────────┘  │
│              │                      │
│              │ SQL Queries          │
│              ▼                      │
│  ┌──────────────────────────────┐  │
│  │  MSSQL Database              │  │
│  │  - classes                   │  │
│  │  - class_days                │  │
│  │  - class_enrollments         │  │
│  │  - day_progress              │  │
│  │  - level_access              │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Key Features

### 1. Video Streaming
- Cloudflare Stream integration
- Progress tracking with milestones (25%, 50%, 75%, 90%, 100%)
- Session management
- Watch time tracking
- Last position resume

### 2. Level Progression
- 4 levels with sequential unlocking
- Time-based level unlocking
- Meditation test requirement for Level 3
- Automatic progression tracking

### 3. Security Features
- Screen recording detection
- Download prevention
- Skip prevention (configurable per day)
- Session tracking
- Security event logging

### 4. Analytics
- Unique viewer counts
- Completion rates
- Average completion percentage
- Total watch time
- Event tracking

## Environment Variables

### Backend (.env in sks-classes-service)

```env
# Server Configuration
NODE_ENV=development
PORT=3013

# MSSQL Database
DB_HOST=localhost
DB_PORT=1433
DB_USER=sa
DB_PASSWORD=your_password
DB_NAME=sivoham_classes
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your_project.iam.gserviceaccount.com

# Cloudflare Stream
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_API_TOKEN=your_api_token
CLOUDFLARE_STREAM_CUSTOMER_CODE=your_customer_code

# OneSignal
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_rest_api_key

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:19006,http://localhost:8080
```

### Frontend (.env.json in SKS-mobile-V2)

```json
{
  "MSG91_WIDGET_ID": "your_msg91_widget_id",
  "MSG91_AUTH_TOKEN": "your_msg91_auth_token",
  "API_BASE_URL": "http://localhost:3013",
  "GOOGLE_CLIENT_ID": "your_google_client_id",
  "ONESIGNAL_APP_ID": "your_onesignal_app_id"
}
```

## Next Steps

1. ✅ Backend service is ready (sks-classes-service)
2. ✅ Frontend has basic integration
3. 🔄 Configure environment variables
4. 🔄 Start backend service
5. 🔄 Run Flutter app with correct API_BASE_URL
6. 🔄 Test the integration

## Support

For issues or questions:
- Check backend logs: `npm run dev` output
- Check Flutter console: Debug prints show API calls
- Review Swagger docs: http://localhost:3013/api-docs
- Check backend API documentation: `s:\sks-classes-service-\API_README.md`

---

**Last Updated:** 2024
