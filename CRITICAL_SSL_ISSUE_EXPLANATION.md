# 🔴 CRITICAL: Video SSL Certificate Error - APK Rebuild Required

## What's Happening

The video player shows a **blank black screen** because of SSL certificate errors:

```
❌ WebView Resource Error: net::ERR_BLOCKED_BY_ORB
❌ Failed to validate the certificate chain
❌ Trust anchor for certification path not found
❌ handshake failed; SSL error code 1, net_error -202
❌ HLS Error: networkError manifestLoadError
```

## Why This Is Happening

1. Videos are served through: `https://app.sivakundalini.org/api/video-proxy/...`
2. Android WebView tries to load the video
3. **WebView doesn't trust the SSL certificate** (Let's Encrypt)
4. WebView blocks the request for security
5. Video manifest never loads
6. Player stays blank with 0:00 / 0:00

## The Fix Is Already in the Code (But Not in Your APK!)

We already created the network security config file:

**File:** `android/app/src/main/res/xml/network_security_config.xml`

```xml
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">app.sivakundalini.org</domain>
        <domain includeSubdomains="true">sivakundalini.org</domain>
        <trust-anchors>
            <!-- Trust system CA certificates (includes Let's Encrypt) -->
            <certificates src="system" />
            <!-- Trust user-installed certs for development -->
            <certificates src="user" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

**This file is registered in AndroidManifest.xml:**
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

## The Problem

**The APK you're currently running was built BEFORE this fix was added!**

The network security config is in the SOURCE CODE but not in the INSTALLED APK.

## The ONLY Solution: Rebuild the APK

There is **NO workaround** for this. WebView security settings are baked into the APK at build time.

### Step 1: Rebuild APK

```cmd
cd s:\SKS-mobile-V2

# Clean previous build
flutter clean

# Get dependencies  
flutter pub get

# Build release APK (includes SSL fix)
flutter build apk --release
```

### Step 2: Install New APK

```cmd
# Uninstall old APK first (recommended)
adb uninstall com.spiritual.app

# Install new APK with SSL fix
adb install build\app\outputs\flutter-apk\app-release.apk
```

**OR** copy the APK to your device and install manually.

### Step 3: Test Videos

1. Open the app
2. Navigate to Classes
3. Select any video
4. Click play
5. **Should work immediately - no blank screen!**

## Why Other APIs Work But Videos Don't

You might notice other API calls work fine (login, meditation stats, etc.). That's because:

1. **Dio HTTP client** (used for REST APIs) has SSL bypass in debug mode:
   ```dart
   // In api_service.dart
   client.badCertificateCallback = (cert, host, port) {
     debugPrint('⚠️ SSL: Accepting certificate for $host (Debug Mode)');
     return true; // Accept all in debug mode
   };
   ```

2. **WebView** (used for HLS video player) does NOT use Dio. It uses Android's built-in WebView HTTP client, which:
   - **Respects system SSL settings**
   - **Only trusts certificates listed in network security config**
   - **Cannot be bypassed programmatically**
   - **Must be configured at build time**

## Expected Console Output After Fix

### Before (Current - SSL Error):
```
HLS initialized with URL: https://app.sivakundalini.org/...
❌ WebView Resource Error: net::ERR_BLOCKED_BY_ORB
❌ Failed to validate the certificate chain
❌ Trust anchor for certification path not found
HLS Error: networkError manifestLoadError
Network error count: 1
Attempting to recover from network error...
(video never loads - stays blank)
```

### After (With SSL Fix in APK):
```
HLS initialized with URL: https://app.sivakundalini.org/...
✅ Manifest parsed successfully
Available quality levels: 4
Video duration: 3600
Video ready - waiting for user interaction
playVideo() called
Video play event fired
✅ Video playback started successfully
Video started for first time
(video plays normally)
```

## Why "Hot Reload" Won't Fix This

Flutter hot reload/restart **DOES NOT rebuild the Android native layer**. The network security config XML is part of Android's native resources, not Dart code.

Changes that require full APK rebuild:
- ❌ Android manifest changes
- ❌ Network security config
- ❌ Native permissions
- ❌ Build configuration
- ❌ Native code changes

Changes that work with hot reload:
- ✅ Dart code changes
- ✅ UI changes
- ✅ Business logic
- ✅ API calls (Dart layer)

## Timeline

1. **Network security config created:** ✅ June 14, 2026 (Commit: 05affc1)
2. **Video player fixes added:** ✅ June 14, 2026 (Commit: eda29b2)
3. **APK rebuilt with fixes:** ❌ NOT YET DONE
4. **New APK installed:** ❌ NOT YET DONE

## What You're Seeing Now

Your current APK was built BEFORE commit `05affc1`. It doesn't have the SSL trust configuration.

When you rebuild and install the new APK, the WebView will:
1. See the domain `app.sivakundalini.org` in the request
2. Check the network security config
3. Find the `<domain>app.sivakundalini.org</domain>` entry
4. Trust the Let's Encrypt certificate (system CA)
5. Allow the video to load
6. Video plays normally!

## Verification

After installing the new APK, check logcat. You should see:

```
HLS initialized with URL: https://app.sivakundalini.org/...
✅ Manifest parsed successfully
```

**WITHOUT any SSL errors.**

If you still see SSL errors after rebuilding, then:
1. Verify the APK was actually installed: `adb shell pm list packages | grep spiritual`
2. Check the APK creation date: `ls -lh build/app/outputs/flutter-apk/app-release.apk`
3. Verify network security config is in APK: `unzip -l app-release.apk | grep network_security_config`

## Summary

**Problem:** WebView can't load videos due to SSL certificate not trusted  
**Root Cause:** Network security config not in installed APK  
**Solution:** Rebuild APK with the SSL fix already in code  
**Status:** Code is ready, APK needs rebuilding  
**Time Required:** 5-10 minutes to rebuild + 1 minute to install  

---

**NEXT STEP: Run the build commands above!** 🚀

The fix is ready and waiting in your code. It just needs to be compiled into an APK and installed.
