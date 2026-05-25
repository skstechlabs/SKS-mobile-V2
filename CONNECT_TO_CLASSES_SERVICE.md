# Connect Flutter App to Classes Service

## Quick Start

### Option 1: Automated Start (Windows)

Run the batch script that starts both services:

```bash
cd s:\SKS-mobile-V2
start-with-classes-service.bat
```

This will:
1. Start the classes service on port 3013
2. Start the Flutter app with correct configuration

### Option 2: Manual Start

#### Step 1: Start the Backend Service

```bash
cd s:\sks-classes-service-

# Install dependencies (first time only)
npm install

# Start the service
npm run dev
```

The service will start on **http://localhost:3013**

#### Step 2: Configure Flutter Environment

Create `.env.json` in the Flutter project root:

```json
{
  "MSG91_WIDGET_ID": "your_msg91_widget_id",
  "MSG91_AUTH_TOKEN": "your_msg91_auth_token",
  "API_BASE_URL": "http://localhost:3013",
  "GOOGLE_CLIENT_ID": "your_google_client_id",
  "ONESIGNAL_APP_ID": "your_onesignal_app_id"
}
```

**Important:** Set `API_BASE_URL` to `http://localhost:3013` to connect to the classes service.

#### Step 3: Run the Flutter App

```bash
cd s:\SKS-mobile-V2

# For mobile/desktop
flutter run --dart-define-from-file=.env.json

# For web
flutter run -d chrome --dart-define-from-file=.env.json
```

## Verify Connection

### 1. Check Backend Health

Open in browser: http://localhost:3013/health

Expected response:
```json
{
  "success": true,
  "service": "sks-classes-service",
  "status": "healthy"
}
```

### 2. Check API Documentation

Open in browser: http://localhost:3013/api-docs

You should see the Swagger UI with all available endpoints.

### 3. Test from Flutter App

1. Run the Flutter app
2. Login with Google or Phone
3. Navigate to **Classes/Learnings** section
4. Check the console for API calls:
   - You should see: `📚 Fetching level access...`
   - Followed by: `✅ Level access loaded`

## Architecture

```
Flutter App (Port varies)
    ↓
API_BASE_URL: http://localhost:3013
    ↓
sks-classes-service (Port 3013)
    ↓
MSSQL Database (sivoham_classes)
```

## Available Services

### Classes Service (Port 3013)

**Endpoints:**
- `GET /api/classes` - Get all classes
- `GET /api/classes/:id` - Get class details
- `POST /api/classes/:id/enroll` - Enroll in class
- `GET /api/classes/my/enrollments` - Get enrollments
- `GET /api/classes/:classId/days` - Get class days
- `GET /api/classes/days/:dayId/video-config` - Get video config
- `POST /api/classes/days/:dayId/track` - Track progress
- `GET /api/level-progression/access` - Get level access

**Documentation:** http://localhost:3013/api-docs

## Using the Classes Service in Flutter

### Import the Service

```dart
import 'package:sks_mobile_v2/core/services/classes_service.dart';
```

### Example Usage

```dart
final classesService = ClassesService();

// Get all classes
final classes = await classesService.getAllClasses();
if (classes['success'] == true) {
  final classList = classes['classes'] as List;
  print('Found ${classList.length} classes');
}

// Get level access
final levelAccess = await classesService.getLevelAccess();
if (levelAccess['success'] == true) {
  final levels = levelAccess['levels'] as List;
  print('User has access to ${levels.length} levels');
}

// Enroll in a class
final enrollment = await classesService.enrollInClass(1);
if (enrollment['success'] == true) {
  print('Successfully enrolled!');
}

// Get class days
final days = await classesService.getClassDays(1);
if (days['success'] == true) {
  final daysList = days['days'] as List;
  print('Class has ${daysList.length} days');
}

// Track video progress
final tracking = await classesService.trackVideoProgress(
  dayId: 1,
  eventType: 'progress',
  positionSeconds: 450,
  durationSeconds: 1800,
  sessionId: 'unique-session-id',
);
```

## Existing Integration

The Flutter app already has classes integration in these files:

### Screens
- `lib/features/learnings/learnings_page.dart` - Classes list page
- `lib/features/learnings/class_days_list_screen.dart` - Class days list
- `lib/features/learnings/day_video_screen.dart` - Video player

### Services
- `lib/core/services/api_service.dart` - Generic API service
- `lib/core/services/classes_service.dart` - **NEW** Dedicated classes service

### Routes
- `/classes/:classId/days` - Class days route
- `/classes/days/:dayId/video` - Video player route

## Configuration Files

### Backend Configuration

File: `s:\sks-classes-service-\.env`

```env
NODE_ENV=development
PORT=3013
DB_HOST=localhost
DB_NAME=sivoham_classes
# ... other settings
```

### Frontend Configuration

File: `s:\SKS-mobile-V2\.env.json`

```json
{
  "API_BASE_URL": "http://localhost:3013",
  "MSG91_WIDGET_ID": "...",
  "MSG91_AUTH_TOKEN": "...",
  "GOOGLE_CLIENT_ID": "...",
  "ONESIGNAL_APP_ID": "..."
}
```

## Troubleshooting

### Problem: "Connection refused" or "Network error"

**Solution:**
1. Check if backend is running: `curl http://localhost:3013/health`
2. Verify `API_BASE_URL` in `.env.json` is `http://localhost:3013`
3. Check backend logs for errors

### Problem: "401 Unauthorized"

**Solution:**
1. Ensure user is logged in
2. Check Firebase token is being sent
3. Verify Firebase Admin SDK is configured in backend `.env`

### Problem: "CORS error" (Web only)

**Solution:**
1. Update `CORS_ORIGIN` in backend `.env`:
   ```env
   CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:19006
   ```
2. Restart backend service

### Problem: Backend not starting

**Solution:**
1. Check if port 3013 is already in use:
   ```bash
   netstat -ano | findstr :3013
   ```
2. Kill the process or change port in backend `.env`
3. Check database connection in backend `.env`

### Problem: Database connection error

**Solution:**
1. Ensure MSSQL is running
2. Check database credentials in backend `.env`
3. Verify database `sivoham_classes` exists
4. Run database setup: `npm run db:setup`

## Testing Checklist

- [ ] Backend service starts successfully
- [ ] Health check returns success: http://localhost:3013/health
- [ ] Swagger docs load: http://localhost:3013/api-docs
- [ ] Flutter app starts with `.env.json` configuration
- [ ] User can login (Google or Phone)
- [ ] Classes/Learnings page loads
- [ ] Level access is displayed
- [ ] Can view class days
- [ ] Can play videos
- [ ] Video progress is tracked

## Production Deployment

### Backend

1. Update `.env` for production:
   ```env
   NODE_ENV=production
   PORT=3013
   DB_HOST=your-production-db-host
   CORS_ORIGIN=https://your-app-domain.com
   ```

2. Start with PM2:
   ```bash
   npm run pm2:deploy
   ```

### Frontend

1. Create `.env.prod.json`:
   ```json
   {
     "API_BASE_URL": "https://your-api-domain.com:3013",
     "MSG91_WIDGET_ID": "...",
     "MSG91_AUTH_TOKEN": "...",
     "GOOGLE_CLIENT_ID": "...",
     "ONESIGNAL_APP_ID": "..."
   }
   ```

2. Build for production:
   ```bash
   flutter build apk --dart-define-from-file=.env.prod.json
   ```

## API Documentation

For complete API documentation, see:
- **Swagger UI:** http://localhost:3013/api-docs
- **Backend README:** `s:\sks-classes-service-\API_README.md`
- **Integration Guide:** `s:\SKS-mobile-V2\CLASSES_SERVICE_INTEGRATION.md`

## Support

For issues or questions:
- Check backend logs in the terminal
- Check Flutter console for debug prints
- Review Swagger documentation
- Check the integration guide

---

**Last Updated:** 2024
