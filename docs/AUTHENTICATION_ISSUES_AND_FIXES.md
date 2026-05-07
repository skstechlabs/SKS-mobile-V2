# Authentication Issues & Fixes - Critical

## Issues Identified

### 1. OTP Login - "Session Expired" / Network Error ❌
**Root Causes:**
- Firebase Phone Auth requires proper Android SHA-1/SHA-256 certificate configuration
- Debug and release builds use different certificates
- Google Cloud Console must have correct SHA certificates registered
- Network timeouts (10 seconds) too short for slow connections

### 2. Google Login - Not Working ❌
**Root Causes:**
- Missing SHA-1/SHA-256 certificates in Firebase Console
- Google Sign-In requires OAuth 2.0 Client ID for Android
- Debug keystore SHA-1 different from release keystore SHA-1
- `google-services.json` may not have correct OAuth client configuration

---

## Critical Fixes Required

### Fix 1: Generate and Register SHA Certificates

#### Step 1: Generate Debug SHA-1
```bash
cd SKS-mobile-V2/android
./gradlew signingReport
```

Or using keytool:
```bash
# Debug keystore (default location)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Step 2: Generate Release SHA-1
```bash
# If you have a release keystore
keytool -list -v -keystore /path/to/your/release-keystore.jks -alias your-key-alias
```

#### Step 3: Add SHA Certificates to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `sks-login-mobile`
3. Go to Project Settings → Your Apps → Android App
4. Scroll to "SHA certificate fingerprints"
5. Click "Add fingerprint"
6. Add BOTH:
   - Debug SHA-1 (for testing)
   - Release SHA-1 (for production APK)
   - Debug SHA-256 (optional but recommended)
   - Release SHA-256 (optional but recommended)

#### Step 4: Download New google-services.json

1. After adding SHA certificates, download new `google-services.json`
2. Replace `SKS-mobile-V2/android/app/google-services.json`
3. Rebuild the app

---

### Fix 2: Increase API Timeouts

**Problem**: 10-second timeout too short for slow networks

**Solution**: Increase timeouts in API service

**File**: `lib/core/services/api_service.dart`

Change from:
```dart
connectTimeout: const Duration(seconds: 10),
receiveTimeout: const Duration(seconds: 10),
```

To:
```dart
connectTimeout: const Duration(seconds: 30),
receiveTimeout: const Duration(seconds: 30),
```

---

### Fix 3: Add Better Error Handling for OTP

**Problem**: Generic error messages don't help users understand the issue

**Solution**: Add detailed error logging and user-friendly messages

---

### Fix 4: Verify Backend Mobile Number Format

**Problem**: Backend expects specific mobile format, app may send wrong format

**Current Backend Validation**:
```javascript
if (!mobile || !/^\+?[1-9]\d{1,14}$/.test(mobile)) {
  return res.status(400).json({ 
    success: false, 
    message: 'Valid mobile number is required',
    error_code: 'INVALID_MOBILE'
  });
}
```

**App sends**: `+91XXXXXXXXXX` (with +91 prefix)
**Backend expects**: International format with + prefix

This should work, but let's verify the exact format being sent.

---

### Fix 5: Add Retry Logic for Network Errors

**Problem**: Single network failure causes complete login failure

**Solution**: Add automatic retry with exponential backoff

---

## Implementation

### 1. Update API Service Timeouts
