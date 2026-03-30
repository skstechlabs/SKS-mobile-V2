# Fix Authentication Issues - CRITICAL ⚠️

## Problem Summary

1. **OTP Login**: "Session expired" or "Network error"
2. **Google Login**: Not working at all

## Root Cause

Both issues are caused by **missing SHA-1/SHA-256 certificates** in Firebase Console. Firebase Phone Auth and Google Sign-In require these certificates to verify your app's identity.

---

## Solution: Add SHA Certificates to Firebase

### Step 1: Generate SHA-1 Certificate

#### Option A: Using Gradle (Recommended)
```bash
cd SKS-mobile-V2/android
./gradlew signingReport
```

Look for output like:
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
SHA-256: 11:22:33:44...
```

**Copy the SHA1 value** (the long string with colons)

#### Option B: Using Keytool
```bash
# For debug builds (testing)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release builds (production)
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias-name
```

### Step 2: Add SHA-1 to Firebase Console

1. Go to https://console.firebase.google.com/
2. Select project: **sks-login-mobile**
3. Click gear icon ⚙️ → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.spiritual.app`
6. Scroll to **SHA certificate fingerprints**
7. Click **Add fingerprint**
8. Paste your SHA-1 certificate
9. Click **Save**

### Step 3: Download New google-services.json

1. In Firebase Console, same page as above
2. Click **Download google-services.json** button
3. Replace the file:
   ```bash
   # Backup old file
   mv SKS-mobile-V2/android/app/google-services.json SKS-mobile-V2/android/app/google-services.json.backup
   
   # Copy new file
   cp ~/Downloads/google-services.json SKS-mobile-V2/android/app/google-services.json
   ```

### Step 4: Enable Google Sign-In in Firebase

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Google** provider
3. Click **Enable** toggle
4. Set support email (your email)
5. Click **Save**

### Step 5: Rebuild the App

```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
```

---

## Additional Fixes Applied

### 1. Increased API Timeouts ✅

**Changed**: `lib/core/services/api_service.dart`
- `connectTimeout`: 10s → 30s
- `receiveTimeout`: 10s → 30s
- Added `sendTimeout`: 30s

This fixes "Network error" issues on slow connections.

### 2. Better Error Messages ✅

**Changed**: `lib/core/services/api_service.dart`
- Added specific error codes for different failure types
- Improved user-friendly error messages
- Better timeout handling

### 3. Firebase Phone Auth Timeout ✅

**Changed**: `lib/features/auth/auth_service.dart`
- Phone verification timeout: 60 seconds (already set)
- Added auto-retrieval for Android SMS
- Added resend token support

---

## Testing After Fixes

### Test OTP Login:

1. Open app
2. Enter mobile number: `9876543210`
3. Tap "Send OTP"
4. **Expected**: "OTP sent to +91 9876543210"
5. Enter OTP from SMS
6. Tap "Verify OTP"
7. **Expected**: Login successful, navigate to profile setup or home

### Test Google Login:

1. Open app
2. Tap "Continue with Google"
3. **Expected**: Google account picker appears
4. Select your Google account
5. **Expected**: Login successful, navigate to profile setup or home

---

## Troubleshooting

### OTP Still Not Working?

**Check Firebase Console:**
1. Go to Authentication → Sign-in method
2. Ensure **Phone** provider is **Enabled**
3. Check if your phone number is in test numbers (if testing)

**Check Android Permissions:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
```

**Check Firebase Quota:**
- Firebase has daily SMS quota limits
- Check Firebase Console → Authentication → Usage
- If exceeded, wait 24 hours or upgrade plan

### Google Login Still Not Working?

**Check OAuth Client ID:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `sks-login-mobile`
3. Go to APIs & Services → Credentials
4. Find "Android client" under OAuth 2.0 Client IDs
5. Verify Package name: `com.spiritual.app`
6. Verify SHA-1 certificate matches your debug/release keystore

**Check google-services.json:**
```bash
# Verify file exists
ls -la SKS-mobile-V2/android/app/google-services.json

# Check if it contains oauth_client
grep -A 5 "oauth_client" SKS-mobile-V2/android/app/google-services.json
```

Should show:
```json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 1,
    "android_info": {
      "package_name": "com.spiritual.app",
      "certificate_hash": "YOUR_SHA1_HERE"
    }
  }
]
```

### Backend Not Reachable?

**Check Backend Status:**
```bash
curl http://sivakundalini.org/api/auth/verify
```

Should return:
```json
{"success":false,"message":"No token provided"}
```

If connection refused or timeout:
- Ensure backend is running
- Check firewall settings
- Verify domain resolves: `ping sivakundalini.org`

---

## Quick Reference

### Generate SHA-1 (Debug):
```bash
cd SKS-mobile-V2/android && ./gradlew signingReport
```

### Generate SHA-1 (Release):
```bash
keytool -list -v -keystore /path/to/release.keystore -alias your-alias
```

### Rebuild App:
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
```

### Test Backend:
```bash
curl http://sivakundalini.org/api/auth/verify
```

---

## Expected Results After Fix

### OTP Login:
1. ✅ "Send OTP" button works
2. ✅ OTP received via SMS within 30 seconds
3. ✅ OTP verification succeeds
4. ✅ User logged in and navigated to next screen
5. ✅ No "session expired" errors
6. ✅ No "network error" (unless actually offline)

### Google Login:
1. ✅ "Continue with Google" button works
2. ✅ Google account picker appears
3. ✅ Account selection succeeds
4. ✅ User logged in and navigated to next screen
5. ✅ No errors or crashes

---

## Important Notes

1. **Debug vs Release**: You need BOTH debug and release SHA-1 certificates
   - Debug: For testing during development
   - Release: For production APK

2. **Multiple Keystores**: If you have multiple developers, add all their debug SHA-1 certificates

3. **Firebase Quota**: Free tier has SMS limits (10 SMS/day for testing)
   - Add test phone numbers in Firebase Console to bypass SMS
   - Or upgrade to Blaze plan for production

4. **Google Sign-In on Web**: Requires different configuration (not covered here)

5. **Backend Must Be Running**: Ensure `http://sivakundalini.org` is accessible

---

## Summary

**Critical Steps:**
1. ✅ Generate SHA-1 certificate using `./gradlew signingReport`
2. ✅ Add SHA-1 to Firebase Console
3. ✅ Download new `google-services.json`
4. ✅ Enable Google Sign-In in Firebase
5. ✅ Rebuild app with `flutter clean && flutter build apk`

**Code Changes:**
1. ✅ Increased API timeouts (10s → 30s)
2. ✅ Better error handling
3. ✅ Improved error messages

**After these fixes, both OTP and Google login should work perfectly!** 🎉
