# SKS Classes Service Connection Checklist

## Overview

This checklist helps you connect the **SKS-mobile-V2** Flutter frontend to the **sks-classes-service** backend.

---

## Prerequisites

### Required Software

- [ ] **Node.js** (v16 or higher) - For backend service
- [ ] **Flutter** (v3.0 or higher) - For mobile app
- [ ] **MSSQL Server** - For database
- [ ] **Git** - For version control

### Check Installations

```bash
# Check Node.js
node --version

# Check npm
npm --version

# Check Flutter
flutter --version

# Check Git
git --version
```

---

## Backend Setup (sks-classes-service)

### 1. Navigate to Backend Directory

```bash
cd s:\sks-classes-service-
```

### 2. Install Dependencies

```bash
npm install
```

Expected output: Dependencies installed successfully

### 3. Configure Environment

- [ ] Copy `.env.example` to `.env`
- [ ] Update database credentials:
  ```env
  DB_HOST=localhost
  DB_PORT=1433
  DB_USER=sa
  DB_PASSWORD=your_password
  DB_NAME=sivoham_classes
  ```
- [ ] Update Firebase Admin SDK credentials
- [ ] Update Cloudflare Stream credentials (if using video)
- [ ] Update OneSignal credentials (if using notifications)
- [ ] Set CORS origin:
  ```env
  CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:19006
  ```

### 4. Setup Database

```bash
# Run database automation script
npm run db:setup
```

Expected output: Database and tables created successfully

### 5. Start Backend Service

```bash
# Development mode (with auto-reload)
npm run dev

# OR Production mode
npm start
```

Expected output:
```
✅ SKS Classes Service running on port 3013
📋 Routes: /api/classes, /api/level-progression
📚 API Documentation: http://localhost:3013/api-docs
🗄️  Database: MSSQL sivoham_classes@localhost
```

### 6. Verify Backend

- [ ] Open http://localhost:3013/health in browser
- [ ] Should see: `{"success":true,"service":"sks-classes-service","status":"healthy"}`
- [ ] Open http://localhost:3013/api-docs
- [ ] Should see Swagger UI with API documentation

---

## Frontend Setup (SKS-mobile-V2)

### 1. Navigate to Frontend Directory

```bash
cd s:\SKS-mobile-V2
```

### 2. Install Dependencies

```bash
flutter pub get
```

Expected output: Dependencies installed successfully

### 3. Configure Environment

#### Option A: Use Pre-configured File

- [ ] Copy `.env.classes-service.json` to `.env.json`
- [ ] Update the values:
  ```json
  {
    "MSG91_WIDGET_ID": "your_actual_widget_id",
    "MSG91_AUTH_TOKEN": "your_actual_auth_token",
    "API_BASE_URL": "http://localhost:3013",
    "GOOGLE_CLIENT_ID": "your_actual_client_id",
    "ONESIGNAL_APP_ID": "your_actual_onesignal_id"
  }
  ```

#### Option B: Create New File

- [ ] Create `.env.json` in project root
- [ ] Add configuration (see above)

**CRITICAL:** Ensure `API_BASE_URL` is set to `http://localhost:3013`

### 4. Verify Classes Service Integration

- [ ] Check if `lib/core/services/classes_service.dart` exists
- [ ] Check if `lib/features/learnings/` directory exists
- [ ] Check if routes are configured in `lib/core/router.dart`

### 5. Run Flutter App

```bash
# For mobile/desktop
flutter run --dart-define-from-file=.env.json

# For web
flutter run -d chrome --dart-define-from-file=.env.json

# For specific device
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env.json
```

Expected output: App starts successfully

---

## Testing the Connection

### 1. Backend Health Check

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

Expected response:
```json
{
  "success": true,
  "classes": [...]
}
```

### 3. Test from Flutter App

- [ ] Launch the Flutter app
- [ ] Login with Google or Phone
- [ ] Navigate to **Classes** or **Learnings** section
- [ ] Check console output for:
  ```
  📚 Fetching level access...
  ✅ Level access loaded
  ```

### 4. Test Video Playback (if applicable)

- [ ] Select a class
- [ ] View class days
- [ ] Click on a day to play video
- [ ] Verify video loads and plays
- [ ] Check console for tracking events:
  ```
  📹 Tracking video: start at 0s
  ✅ Video progress tracked
  ```

---

## Automated Start (Windows)

### Use the Batch Script

```bash
cd s:\SKS-mobile-V2
start-with-classes-service.bat
```

This script will:
1. Check prerequisites
2. Start backend service in a new window
3. Wait for service to initialize
4. Start Flutter app with correct configuration

---

## Troubleshooting

### Backend Issues

#### Port Already in Use

**Problem:** `EADDRINUSE: Port 3013 is already in use`

**Solution:**
```bash
# Find process using port 3013
netstat -ano | findstr :3013

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Or change port in .env
PORT=3014
```

#### Database Connection Error

**Problem:** `Failed to connect to database`

**Solution:**
- [ ] Verify MSSQL is running
- [ ] Check credentials in `.env`
- [ ] Test connection:
  ```bash
  sqlcmd -S localhost -U sa -P your_password
  ```
- [ ] Verify database exists:
  ```sql
  SELECT name FROM sys.databases WHERE name = 'sivoham_classes';
  ```

#### Firebase Auth Error

**Problem:** `Firebase Admin SDK not initialized`

**Solution:**
- [ ] Verify Firebase credentials in `.env`
- [ ] Check `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL`
- [ ] Ensure private key is properly formatted with `\n` for line breaks

### Frontend Issues

#### Connection Refused

**Problem:** `DioException: Connection refused`

**Solution:**
- [ ] Verify backend is running: `curl http://localhost:3013/health`
- [ ] Check `API_BASE_URL` in `.env.json` is `http://localhost:3013`
- [ ] Restart Flutter app

#### 401 Unauthorized

**Problem:** API returns 401 error

**Solution:**
- [ ] Ensure user is logged in
- [ ] Check Firebase token is being sent
- [ ] Verify token in console output
- [ ] Check backend Firebase configuration

#### CORS Error (Web Only)

**Problem:** `CORS policy: No 'Access-Control-Allow-Origin' header`

**Solution:**
- [ ] Update `CORS_ORIGIN` in backend `.env`:
  ```env
  CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:19006
  ```
- [ ] Restart backend service

#### Environment Variables Not Loaded

**Problem:** `API_BASE_URL is EMPTY!`

**Solution:**
- [ ] Verify `.env.json` exists in project root
- [ ] Check file format is valid JSON
- [ ] Run with `--dart-define-from-file=.env.json` flag
- [ ] Check console output for environment checker logs

---

## Verification Checklist

### Backend Verification

- [ ] Backend service starts without errors
- [ ] Health endpoint returns success
- [ ] Swagger UI loads at http://localhost:3013/api-docs
- [ ] Database connection is successful
- [ ] Can query `/api/classes` endpoint

### Frontend Verification

- [ ] Flutter app starts without errors
- [ ] Environment variables are loaded
- [ ] User can login (Google or Phone)
- [ ] Classes/Learnings page loads
- [ ] Level access is displayed
- [ ] Can view class details
- [ ] Can view class days
- [ ] Video player loads (if applicable)
- [ ] Progress tracking works

### Integration Verification

- [ ] API calls from Flutter reach backend
- [ ] Backend logs show incoming requests
- [ ] Authentication tokens are valid
- [ ] Data is returned correctly
- [ ] Error handling works properly

---

## API Endpoints Reference

### Public Endpoints (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/classes` | Get all classes |

### Protected Endpoints (Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/classes/:id` | Get class details |
| POST | `/api/classes/:id/enroll` | Enroll in class |
| GET | `/api/classes/my/enrollments` | Get user enrollments |
| GET | `/api/classes/:classId/days` | Get class days |
| GET | `/api/classes/:classId/progress` | Get class progress |
| POST | `/api/classes/days/:dayId/start` | Start a day |
| POST | `/api/classes/days/:dayId/track` | Track video progress |
| GET | `/api/classes/days/:dayId/video-config` | Get video config |
| POST | `/api/classes/days/:dayId/security-event` | Log security event |
| GET | `/api/level-progression/access` | Get level access |
| POST | `/api/level-progression/meditation-test` | Submit meditation test |

---

## Documentation Links

- **Backend API Docs:** http://localhost:3013/api-docs
- **Backend README:** `s:\sks-classes-service-\API_README.md`
- **Integration Guide:** `s:\SKS-mobile-V2\CLASSES_SERVICE_INTEGRATION.md`
- **Connection Guide:** `s:\SKS-mobile-V2\CONNECT_TO_CLASSES_SERVICE.md`

---

**Status:** Ready for Connection ✅

**Last Updated:** 2024
