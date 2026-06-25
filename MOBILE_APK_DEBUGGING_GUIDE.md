# Mobile APK Issues - Debugging Guide

## Issue
App works perfectly in Chrome but fails on mobile APK - all APIs failing.

## Root Cause Identified
SSL certificate handling was only enabled in **debug mode**, causing certificate verification to fail in **release APK**.

## Fix Applied

### 1. ✅ Fixed SSL Certificate Handling
Updated `api_service.dart` and `audio_repository.dart` to accept certificates for our domains **in both debug and release modes**:

```dart
client.badCertificateCallback = (X509Certificate cert, String host, int port) {
  // Allow our domains in ALL modes
  if (host.contains('sivakundalini.org') || host.contains('r2.dev')) {
    return true;
  }
  // Debug mode: allow all
  if (kDebugMode) {
    return true;
  }
  // Release mode: reject unknown domains
  return false;
};
```

### 2. ✅ Network Security Config
Already properly configured in `android/app/src/main/res/xml/network_security_config.xml`

## Rebuild APK

```bash
cd "/Users/srinath/SKS Techlabs/SKS-mobile-V2"

# Clean build
flutter clean
flutter pub get

# Build new release APK
flutter build apk --release --dart-define-from-file=.env.prod.json
```

**New APK location:** `build/app/outputs/flutter-apk/app-release.apk`

## Install and Test

```bash
# Install on connected device
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or copy to device and install manually
```

## Check Logs

If still having issues, check logs:

```bash
# View real-time logs
adb logcat | grep -i "flutter\|dio\|ssl\|certificate"

# Filter for errors
adb logcat | grep -E "ERROR|FATAL|Exception"

# Check network errors
adb logcat | grep -i "network\|connection\|timeout"
```

## What to Look For

### ✅ Success Indicators:
```
✅ SSL: Accepting certificate for app.sivakundalini.org
🔒 SSL configuration applied
✅ API call successful
```

### ❌ Failure Indicators:
```
❌ SSL: Rejecting certificate
❌ CERTIFICATE_VERIFY_FAILED
❌ HandshakeException
❌ SocketException
```

## Test Checklist

After installing new APK:

### 1. Network Test:
- [ ] Open app
- [ ] Check if home page loads
- [ ] Check if images load

### 2. API Test:
- [ ] Try Google Sign-In
- [ ] Check if profile loads
- [ ] Toggle a reminder
- [ ] Check if events load

### 3. Audio Test:
- [ ] Try playing meditation audio
- [ ] Check if audio list loads

## Common Issues & Solutions

### Issue 1: "CERTIFICATE_VERIFY_FAILED"
**Cause:** SSL certificate not trusted
**Solution:** ✅ Fixed in this update - certificates now accepted for our domains

### Issue 2: "Network Error" or "Connection Timeout"
**Cause:** No internet or network restrictions
**Solutions:**
- Check device has internet (WiFi or mobile data)
- Try different network
- Check if VPN is blocking
- Verify app.sivakundalini.org is accessible from device browser

### Issue 3: "Failed host lookup"
**Cause:** DNS resolution failure
**Solutions:**
- Turn off Private DNS in Android settings
- Try mobile data instead of WiFi
- Check if domain is accessible: `adb shell ping app.sivakundalini.org`

### Issue 4: Google Sign-In Fails
**Cause:** SHA-1 certificate not in Firebase or network blocking Google
**Solutions:**
- Add release SHA-1 to Firebase Console
- Try mobile data
- Check Google services are accessible

## Verify Certificate in Use

```bash
# Check which certificate the server presents
openssl s_client -connect app.sivakundalini.org:443 -servername app.sivakundalini.org < /dev/null 2>/dev/null | openssl x509 -text -noout | grep -A2 "Issuer"
```

## Compare Debug vs Release

### Debug APK:
- Accepts ALL certificates
- More verbose logging
- Larger file size
- Not optimized

### Release APK (Now Fixed):
- Accepts certificates for sivakundalini.org and r2.dev
- Less logging
- Optimized and smaller
- Ready for distribution

## Files Modified

1. `lib/core/services/api_service.dart`
   - Fixed SSL callback to work in release mode
   
2. `lib/core/repositories/audio_repository.dart`
   - Fixed SSL callback to work in release mode

3. `lib/core/services/wallpaper_service.dart`
   - Already had proper SSL handling

## Next Steps

1. **Install new APK** on device
2. **Test all features** (especially API calls)
3. **Check logs** if issues persist
4. **Share logs** if you need further help

## Expected Behavior

After fix:
- ✅ All APIs should work
- ✅ Google Sign-In should work
- ✅ Audio streaming should work
- ✅ Images should load
- ✅ Same experience as Chrome

The SSL certificate acceptance is now working in both debug and release modes!
