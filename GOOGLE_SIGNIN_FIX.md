# Google Sign-In Fix Guide

## Problem
Google Sign-In fails with "Account reauth failed" error.

## Root Cause
The app's SHA-1 certificate fingerprint is not registered in Firebase Console.

## Your SHA-1 Fingerprints

### Debug Certificate (for development):
```
E8:6A:51:5C:68:AF:40:8A:61:48:87:1E:F7:0B:4B:48:AB:5F:C7:8A
```

### Release Certificate (for production):
```
FF:E7:5B:3E:EE:2C:36:54:6C:8E:40:37:78:8A:F0:66:BA:1E:4E:7D
```

## Fix Steps

### 1. Add SHA-1 to Firebase Console

1. Go to: https://console.firebase.google.com
2. Select project: **sks-login-mobile**
3. Click ⚙️ Settings → **Project Settings**
4. Scroll to **Your apps** section
5. Find your Android app: **com.spiritual.app**
6. Scroll to **SHA certificate fingerprints**
7. Click **Add fingerprint**
8. Add the DEBUG fingerprint:
   ```
   E8:6A:51:5C:68:AF:40:8A:61:48:87:1E:F7:0B:4B:48:AB:5F:C7:8A
   ```
9. Click **Add fingerprint** again
10. Add the RELEASE fingerprint:
    ```
    FF:E7:5B:3E:EE:2C:36:54:6C:8E:40:37:78:8A:F0:66:BA:1E:4E:7D
    ```

### 2. Download Updated Config

1. After adding SHA-1, download the new `google-services.json`
2. Replace the file at: `android/app/google-services.json`

### 3. Rebuild App

```bash
cd "/Users/srinath/SKS Techlabs/SKS-mobile-V2"
flutter clean
flutter run --dart-define-from-file=.env.prod.json
```

### 4. Wait & Test

- Wait 5-10 minutes for Google's servers to update
- Try Google Sign-In again
- It should work now!

## Verify SHA-1 is Added

To check if your SHA-1 is registered:

1. Go to Firebase Console
2. Project Settings → Your apps → Android app
3. Check "SHA certificate fingerprints" section
4. You should see both fingerprints listed

## Alternative: Google Cloud Console

If Firebase Console doesn't work, try Google Cloud Console:

1. Go to: https://console.cloud.google.com
2. Select project: **sks-login-mobile**
3. Go to **APIs & Services** → **Credentials**
4. Find your **Android client** (OAuth 2.0 Client ID)
5. Edit it and add SHA-1 fingerprints there

## Common Issues

### Issue: SHA-1 added but still failing
**Solution:** Wait 10-15 minutes and clear app data:
```bash
adb shell pm clear com.spiritual.app
```

### Issue: Wrong package name
**Solution:** Verify package name matches:
- App: `com.spiritual.app`
- Firebase: Must match exactly

### Issue: Multiple Google accounts on device
**Solution:** Try with a single Google account on the device

## Test on Real Device

Make sure you're testing on a **real Android device** with:
- ✅ Internet connection (WiFi or mobile data)
- ✅ Google account added to device
- ✅ Google Play Services installed and updated

## Additional Debug

To see more detailed errors:
```bash
flutter run --dart-define-from-file=.env.prod.json --verbose
```

Then check logcat for Google Sign-In errors:
```bash
adb logcat | grep -i "google\|auth"
```

## Contact

If issues persist after adding SHA-1:
1. Double-check SHA-1 is correctly entered (no spaces, correct format)
2. Verify package name matches in Firebase
3. Wait 15+ minutes for propagation
4. Try with a fresh Firebase project if needed
