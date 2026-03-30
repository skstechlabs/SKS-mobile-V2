# Quick Test Guide - White Screen & Google Login Fix

## 🚀 Quick Start

### 1. Rebuild APK
```bash
cd SKS-mobile-V2
./rebuild-production.sh
```

### 2. Install on Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 3. Test Flow

#### Test 1: Splash to Login (White Screen Fix)
1. Open app
2. **Expected**: Splash screen shows Guruji logo with animation
3. **Expected**: After ~1.5 seconds, login screen appears
4. **Expected**: NO white screen between splash and login
5. **Expected**: Login screen shows:
   - Guruji logo at top
   - "Welcome" text
   - Phone number input field
   - "Send OTP" button
   - "OR" divider
   - "Continue with Google" button

**✅ PASS**: Login screen appears immediately after splash
**❌ FAIL**: White screen appears, or app crashes

#### Test 2: Google Login Button (Validation Fix)
1. On login screen, click "Continue with Google"
2. **Expected**: Google account picker appears
3. **Expected**: NO error about "valid mobile number required"
4. Select a Google account
5. **Expected**: Login succeeds and navigates to home/profile setup

**✅ PASS**: Google login works without phone validation error
**❌ FAIL**: Shows "valid mobile number required" error

#### Test 3: OTP Login (Validation Improvement)
1. Enter phone number: `9876543210`
2. Click "Send OTP"
3. **Expected**: OTP sent successfully
4. Enter received OTP
5. **Expected**: Login succeeds

**Test Invalid Numbers**:
- Try `123456789` (9 digits) → Should show error
- Try `0123456789` (starts with 0) → Should show error
- Try `5123456789` (starts with 5) → Should show error
- Try `9876543210` (valid) → Should work

**✅ PASS**: Validation works correctly
**❌ FAIL**: Invalid numbers are accepted or valid numbers are rejected

## 🔍 Debug Commands

### Check Environment Variables
```bash
# After opening app
adb logcat | grep "API Base URL"
# Should show: https://sivakundalini.org
```

### Monitor App Logs
```bash
adb logcat | grep -E "Flutter|SKS|Firebase"
```

### Check for Errors
```bash
adb logcat | grep -E "ERROR|Exception"
```

## ⚠️ Common Issues

### White Screen Still Appears
**Possible Causes**:
1. Firebase not initialized properly
2. Missing google-services.json
3. App crashed during initialization

**Solution**:
```bash
# Check logs for errors
adb logcat | grep -E "ERROR|Exception|Firebase"

# Reinstall app
adb uninstall com.spiritual.app
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Google Login Not Working
**Possible Causes**:
1. SHA-1 certificate not added to Firebase Console
2. Google sign-in not enabled in Firebase

**Solution**:
1. Generate SHA-1: `./generate-sha1.sh`
2. Add to Firebase Console
3. Rebuild APK
4. Reinstall

### "Session Expired" on OTP
**Possible Causes**:
1. Firebase phone auth not enabled
2. Too many requests (rate limited)

**Solution**:
1. Check Firebase Console > Authentication > Phone
2. Wait 1 hour if rate limited
3. Try different phone number

### API Calls Not Working
**Possible Causes**:
1. APK built without environment variables
2. Backend not running
3. Wrong API URL

**Solution**:
```bash
# Verify backend is running
curl https://sivakundalini.org/api/gatherings

# Check if environment variables were injected
adb logcat | grep "API Base URL"

# Rebuild with correct flag
./rebuild-production.sh
```

## ✅ Success Criteria

All tests should pass:
- [x] Splash screen navigates to login without white screen
- [x] Google login button works without phone validation error
- [x] OTP login validates phone numbers correctly
- [x] Invalid phone numbers show appropriate errors
- [x] App handles network errors gracefully
- [x] No crashes during authentication flow

## 📝 Report Issues

If any test fails, provide:
1. Which test failed
2. Error message shown (if any)
3. Logcat output: `adb logcat | grep -E "ERROR|Exception"`
4. Screenshot of the issue

## 🎯 Next Steps After Testing

Once all tests pass:
1. Test reminder notifications
2. Test profile editing
3. Test all main features
4. Deploy to production
