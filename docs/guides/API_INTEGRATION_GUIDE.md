# API Integration Guide

## Overview
This Flutter app is now integrated with the backend API for user authentication and profile management.

## Base URL Configuration
- Development: `http://localhost:3009` (configured in `.env.json`)
- Production: Update `API_BASE_URL` in `.env.prod.json`

## API Service Location
- **Service File**: `lib/core/services/api_service.dart`
- **Initialization**: Automatically initialized in `main.dart`

## Integrated Endpoints

### 1. POST /api/auth/login
**Purpose**: Login/Register user after Firebase authentication
**Implementation**: `lib/features/auth/login_screen.dart`
- Called after OTP verification (`_verifyOtp()`)
- Called after Google Sign-In (`_signInWithGoogle()`)

### 2. POST /api/user/profile
**Purpose**: Complete user profile
**Implementation**: `lib/features/auth/profile_setup_screen.dart`
- Called in `_submit()` method
- Saves: name, gender, DOB, address, state, pincode

### 3. GET /api/user/profile
**Purpose**: Fetch user profile
**Implementation**: `lib/features/auth/profile_service.dart`
- Use `ProfileService().fetchAndUpdateProfile()`

### 4. PATCH /api/user/profile
**Purpose**: Update specific profile fields
**Implementation**: `lib/features/auth/profile_service.dart`
- Use `ProfileService().updateProfileFields(updates)`

### 5. POST /api/user/permissions
**Purpose**: Save app permissions
**Implementation**: `lib/features/auth/permission_screen.dart`
- Called in `_requestAll()` method

## Usage Examples

### Fetch User Profile
```dart
import 'package:spiritual_app/features/auth/profile_service.dart';

final result = await ProfileService().fetchAndUpdateProfile();
if (result['success'] == true) {
  print('Profile loaded');
}
```

### Update Profile Fields
```dart
final result = await ProfileService().updateProfileFields({
  'name': 'New Name',
  'address': 'New Address',
});
```

## Authentication Flow
1. User signs in with OTP or Google
2. Firebase authenticates user
3. App calls `/api/auth/login` with Firebase ID token
4. Backend returns user data and `is_new_user` flag
5. App navigates to profile setup if needed
6. Profile completion calls `/api/user/profile`
7. Permissions screen calls `/api/user/permissions`
8. User navigates to home screen

## Error Handling
All API calls return `{'success': bool, 'message': string}` format
Errors are displayed via SnackBar to the user

## Testing
Run the app with development environment:
```bash
flutter run --dart-define-from-file=.env.json
```
