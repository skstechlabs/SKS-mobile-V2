# Quick Start: Connect Flutter App to Classes Service

## 🚀 Quick Start (3 Steps)

### Step 1: Start Backend Service

```bash
cd s:\sks-classes-service-
npm run dev
```

✅ Service running on **http://localhost:3013**

### Step 2: Configure Flutter App

Update `.env.json` in Flutter project root:

```json
{
  "API_BASE_URL": "http://localhost:3013",
  "MSG91_WIDGET_ID": "your_widget_id",
  "MSG91_AUTH_TOKEN": "your_auth_token",
  "GOOGLE_CLIENT_ID": "your_client_id",
  "ONESIGNAL_APP_ID": "your_onesignal_id"
}
```

### Step 3: Run Flutter App

```bash
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.json
```

## ✅ Verify Connection

1. **Backend Health:** http://localhost:3013/health
2. **API Docs:** http://localhost:3013/api-docs
3. **Flutter App:** Login → Navigate to Classes/Learnings

## 📁 Files Created

### Documentation
- `CLASSES_SERVICE_INTEGRATION.md` - Complete integration guide
- `CONNECT_TO_CLASSES_SERVICE.md` - Detailed connection instructions
- `CLASSES_SERVICE_CONNECTION_CHECKLIST.md` - Step-by-step checklist
- `README_CLASSES_CONNECTION.md` - This quick start guide

### Code
- `lib/core/services/classes_service.dart` - Dedicated classes service

### Configuration
- `.env.classes-service.json` - Sample environment configuration

### Scripts
- `start-with-classes-service.bat` - Automated startup script (Windows)

## 🎯 What's Already Integrated

The Flutter app already has:
- ✅ API service with authentication
- ✅ Classes/Learnings screens
- ✅ Video player with progress tracking
- ✅ Level progression system
- ✅ Routes configured

## 📚 Backend API Endpoints

### Public (No Auth)
- `GET /health` - Health check
- `GET /api/classes` - Get all classes

### Protected (Auth Required)
- `GET /api/classes/:id` - Class details
- `POST /api/classes/:id/enroll` - Enroll in class
- `GET /api/classes/my/enrollments` - My enrollments
- `GET /api/classes/:classId/days` - Class days
- `GET /api/classes/days/:dayId/video-config` - Video config
- `POST /api/classes/days/:dayId/track` - Track progress
- `GET /api/level-progression/access` - Level access

## 🔧 Using Classes Service in Flutter

```dart
import 'package:sks_mobile_v2/core/services/classes_service.dart';

final classesService = ClassesService();

// Get all classes
final classes = await classesService.getAllClasses();

// Get level access
final levels = await classesService.getLevelAccess();

// Enroll in class
final enrollment = await classesService.enrollInClass(1);

// Get class days
final days = await classesService.getClassDays(1);

// Track video progress
final tracking = await classesService.trackVideoProgress(
  dayId: 1,
  eventType: 'progress',
  positionSeconds: 450,
  durationSeconds: 1800,
  sessionId: 'unique-session-id',
);
```

## 🐛 Common Issues

### Connection Refused
- ✅ Check backend is running: `curl http://localhost:3013/health`
- ✅ Verify `API_BASE_URL` in `.env.json`

### 401 Unauthorized
- ✅ Ensure user is logged in
- ✅ Check Firebase configuration in backend

### CORS Error (Web)
- ✅ Update `CORS_ORIGIN` in backend `.env`
- ✅ Restart backend service

## 📖 Full Documentation

For detailed information, see:
- **Integration Guide:** `CLASSES_SERVICE_INTEGRATION.md`
- **Connection Guide:** `CONNECT_TO_CLASSES_SERVICE.md`
- **Checklist:** `CLASSES_SERVICE_CONNECTION_CHECKLIST.md`
- **Backend API:** http://localhost:3013/api-docs

## 🎬 Architecture

```
Flutter App (SKS-mobile-V2)
    ↓ HTTP/JSON + Firebase Token
sks-classes-service (Port 3013)
    ↓ SQL Queries
MSSQL Database (sivoham_classes)
```

## 🔐 Authentication

All protected endpoints require Firebase ID token:
```
Authorization: Bearer <firebase-id-token>
```

The `api_service.dart` handles this automatically.

## 📊 Features

- ✅ Video streaming with Cloudflare
- ✅ Progress tracking (25%, 50%, 75%, 90%, 100%)
- ✅ Level progression system
- ✅ Security features (screen recording detection)
- ✅ Analytics and reporting
- ✅ Meditation test for Level 3

## 🚀 Next Steps

1. Start backend service
2. Configure `.env.json`
3. Run Flutter app
4. Test the connection
5. Explore the API documentation

---

**Ready to connect!** 🎉

For support, check the documentation files or backend logs.
