# API Service Documentation

## ApiService Class

Singleton service for making authenticated API calls to the backend.

### Methods

#### `initialize()`
Initializes Dio client with base URL and interceptors.
Called automatically in `main.dart`.

#### `login()`
```dart
Future<Map<String, dynamic>> login({
  required String authProvider, // 'phone' | 'google'
  required String mobile,
  String? email,
  String? name,
  String? photo,
})
```
Calls POST /api/auth/login after Firebase authentication.

#### `completeProfile()`
```dart
Future<Map<String, dynamic>> completeProfile({
  required String name,
  required String gender,
  required String dateOfBirth,
  required String address,
  required String state,
  required String pincode,
})
```
Calls POST /api/user/profile to save profile data.

#### `getProfile()`
```dart
Future<Map<String, dynamic>> getProfile()
```
Calls GET /api/user/profile to fetch user data.

#### `updateProfile()`
```dart
Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates)
```
Calls PATCH /api/user/profile to update specific fields.

#### `savePermissions()`
```dart
Future<Map<String, dynamic>> savePermissions({
  required bool camera,
  required bool microphone,
  required bool notifications,
})
```
Calls POST /api/user/permissions to save granted permissions.

### Authentication
All API calls automatically include Firebase ID token in Authorization header.

### Error Handling
Returns `{'success': false, 'message': 'error description'}` on failure.
