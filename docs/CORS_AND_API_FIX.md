# CORS and API Path Fix

## Issues Fixed

### 1. API Base URL Missing `/api` Prefix
**Problem**: Mobile app was calling `https://sivakundalini.org/classes/1/days` instead of `https://sivakundalini.org/api/classes/1/days`

**Fix**: Updated `api_service.dart` to automatically append `/api` to base URL if not present

### 2. CORS Already Working
**Status**: ✅ Backend CORS is properly configured
- Allows all origins (`Access-Control-Allow-Origin: *`)
- Allows all methods (GET, POST, PUT, DELETE, PATCH, OPTIONS)
- Allows required headers (Authorization, Content-Type, etc.)

## Changes Made

### File: `SKS-mobile-V2/lib/core/services/api_service.dart`

```dart
void initialize() {
  // Ensure base URL ends with /api
  String baseUrl = AppEnv.apiBaseUrl.isNotEmpty 
      ? AppEnv.apiBaseUrl 
      : 'https://sivakundalini.org';
  
  // Add /api if not present
  if (!baseUrl.endsWith('/api')) {
    baseUrl = '$baseUrl/api';
  }
  
  _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    // ...
  ));
}
```

## Testing

### Test CORS (Already Working)
```bash
cd sks-backend
./test-cors.sh
```

### Rebuild Mobile App
```bash
cd SKS-mobile-V2
./rebuild-production.sh
```

## What Should Work Now

1. ✅ CORS headers present for all origins
2. ✅ API calls use correct path: `/api/classes/1/days`
3. ✅ JSON response parsing with fallback
4. ⚠️ Database migration still needs to be run

## Next Steps

1. Run database migration:
   ```bash
   cd sks-backend
   node run-migration.js
   ```

2. Rebuild mobile app:
   ```bash
   cd SKS-mobile-V2
   ./rebuild-production.sh
   ```

3. Test on Flutter Web:
   ```bash
   flutter run -d chrome --dart-define-from-file=.env.prod.json
   ```
