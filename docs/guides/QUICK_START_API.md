# Quick Start: Backend API Integration

## Prerequisites
1. Backend server running on `http://localhost:3009`
2. Firebase project configured
3. Flutter environment set up

## Step 1: Start Backend Server
```bash
cd backend
npm start
```

## Step 2: Run Flutter App
```bash
flutter run --dart-define-from-file=.env.json
```

## Step 3: Test Authentication Flow

### Test Phone Login
1. Open app → Click "Send OTP"
2. Enter phone number (e.g., 9876543210)
3. Enter OTP from Firebase
4. App calls `/api/auth/login` automatically
5. Complete profile form
6. App calls `/api/user/profile` automatically
7. Grant permissions
8. App calls `/api/user/permissions` automatically

### Test Google Login
1. Open app → Click "Continue with Google"
2. Select Google account
3. App calls `/api/auth/login` automatically
4. Complete profile if needed
5. Grant permissions

## Verify Backend Integration

### Check Backend Logs
You should see:
```
POST /api/auth/login - 200
POST /api/user/profile - 200
POST /api/user/permissions - 200
```

### Check Database
User data should be saved with:
- uid (Firebase UID)
- mobile
- email (if Google)
- name
- profile fields
- permissions

## Troubleshooting

### "Network error" message
- Ensure backend is running on port 3009
- Check `API_BASE_URL` in `.env.json`
- Verify Firebase ID token is valid

### "Unauthorized" error
- Check Firebase authentication is working
- Verify ID token is being sent in headers
- Check backend Firebase admin SDK configuration

### Profile not saving
- Check backend logs for errors
- Verify all required fields are filled
- Check network connectivity

## API Service Usage in Code

```dart
// Import the service
import 'package:spiritual_app/core/services/api_service.dart';

// Use in your code
final apiService = ApiService();

// Login after Firebase auth
final result = await apiService.login(
  authProvider: 'phone',
  mobile: '+919876543210',
);

// Complete profile
final profileResult = await apiService.completeProfile(
  name: 'John Doe',
  gender: 'Male',
  dateOfBirth: '01/01/1990',
  address: '123 Main St',
  state: 'Telangana',
  pincode: '500001',
);

// Save permissions
final permResult = await apiService.savePermissions(
  camera: true,
  microphone: true,
  notifications: true,
);
```

## Production Deployment

1. Update `.env.prod.json`:
```json
{
  "API_BASE_URL": "https://your-production-api.com"
}
```

2. Build and run:
```bash
flutter run --dart-define-from-file=.env.prod.json --release
```
