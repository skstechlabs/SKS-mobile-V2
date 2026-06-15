# Google Sign-In on Real Device - Action Plan

## Quick Summary

Your **SHA-1 certificates are already properly configured** in Firebase (verified in `google-services.json`). The problem is **network connectivity** on your real device - DNS resolution is failing for multiple domains including `accounts.google.com`, `imagedelivery.net`, and others.

## What I've Done

### 1. ✅ Added Network Diagnostic Tool
- Created `/lib/core/utils/network_diagnostic.dart`
- Tests internet connectivity, DNS resolution, HTTPS connections
- Identifies exactly what's blocking network access

### 2. ✅ Enhanced Login Screen
- Added automatic network check before Google Sign-In
- Shows clear error message if Google servers unreachable
- Added "Test Network (Debug)" button (only visible in debug mode)
- Located: `/lib/features/auth/login_screen.dart`

### 3. ✅ Created Comprehensive Fix Guides
- `GOOGLE_SIGNIN_REAL_DEVICE_FIX.md` - Detailed troubleshooting steps
- `GOOGLE_SIGNIN_FIX.md` - Original SHA-1 configuration guide
- Both available in project root

## What You Need To Do Now

### Step 1: Rebuild and Run App

```bash
cd "/Users/srinath/SKS Techlabs/SKS-mobile-V2"

# Clean build
flutter clean
flutter pub get

# Run on real device with production config
flutter run --dart-define-from-file=.env.prod.json
```

### Step 2: Test Network Diagnostics

When app opens on login screen:

1. Look for **"Test Network (Debug)"** button at bottom (only visible in debug builds)
2. Tap the button
3. Check **Flutter console output** for detailed diagnostic report

The diagnostic will tell you:
- ✅/❌ Raw internet connectivity
- ✅/❌ DNS resolution for critical domains
- ✅/❌ HTTPS requests to Google, Firebase, imagedelivery.net
- ✅/❌ Access to accounts.google.com (required for Google Sign-In)

### Step 3: Fix Network Based on Results

#### If "No internet connection":
```bash
# On device:
Settings → WiFi → Turn OFF, then ON
# Or switch to Mobile Data
```

#### If "DNS resolution failing":
- **Try mobile data instead of WiFi**
- WiFi may have DNS issues or captive portal
- Check if connected to restricted network (school/work)

#### If "Google services blocked":
- Disable VPN if active
- Check for ad blockers or firewall apps
- Try different WiFi network
- Use mobile data hotspot from another phone

### Step 4: Try Google Sign-In

After network is confirmed working:

1. Tap "Continue with Google" button
2. If network check fails, you'll see:
   > "Cannot reach Google servers. Check your internet connection."
3. Fix network, then try again

### Step 5: If Still Failing, Collect Diagnostic Info

```bash
# Run these commands with device connected:

# 1. Test basic connectivity
adb shell ping -c 3 8.8.8.8

# 2. Test DNS resolution
adb shell nslookup google.com
adb shell nslookup accounts.google.com

# 3. View live logs
flutter logs
```

Share the output with me for further investigation.

## Expected Behavior When Working

### Success Indicators (in console):
```
✅ RAW CONNECTIVITY: Can reach internet (Google DNS)
✅ DNS RESOLUTION: 5/5 domains resolved
✅ HTTP/HTTPS TESTS: 4/4 requests successful
✅ CRITICAL DOMAINS: 4/4 accessible
✅ OVERALL: Network is working properly
   → Google Sign-In should work

✅ GoogleSignIn.instance initialized
✅ GoogleSignIn account: user@gmail.com
✅ idToken: present
✅ Firebase sign-in success: user@gmail.com
```

### Failure Indicators (what you're seeing now):
```
❌ DNS RESOLUTION: Failed to resolve accounts.google.com
❌ HTTP/HTTPS TESTS: Failed host lookup
❌ OVERALL: Network has issues

❌ GoogleSignInException: [16] Account reauth failed
ClientException with SocketException: Failed host lookup: 'imagedelivery.net'
```

## Common Network Issues and Solutions

### Issue 1: Captive Portal (Hotel/Cafe WiFi)
**Symptoms:** Connected to WiFi but no internet
**Fix:** 
1. Open Chrome browser on device
2. Try to load google.com
3. Complete login/agreement page if shown
4. Test app again

### Issue 2: VPN Blocking
**Symptoms:** DNS resolution fails, "device is offline"
**Fix:**
1. Settings → Network & Internet → VPN
2. Disconnect any active VPNs
3. Test app again

### Issue 3: Corrupted Google Play Services
**Symptoms:** "[16] Account reauth failed"
**Fix:**
```bash
adb shell pm clear com.google.android.gms
adb reboot
# After reboot, open Play Store and update Google Play Services
```

### Issue 4: Network Restrictions (School/Work/Parental Controls)
**Symptoms:** Some domains work, Google services blocked
**Fix:**
- Use mobile data instead of WiFi
- Try from home network
- Check with network administrator

## Quick Test Commands

```bash
# 1. Check device is connected
flutter devices

# 2. Quick network test on device
adb shell ping -c 3 google.com

# 3. Quick DNS test
adb shell nslookup accounts.google.com

# 4. Clear Google Play Services (if needed)
adb shell pm clear com.google.android.gms

# 5. Clear app and reinstall
flutter clean
flutter run --dart-define-from-file=.env.prod.json
```

## Verify Firebase Configuration (If Network is OK)

If network diagnostics show ✅ all green but Google Sign-In still fails:

1. Go to: https://console.firebase.google.com/project/sks-login-mobile/settings/general
2. Find Android app: **com.spiritual.app**
3. Check SHA-1 fingerprints section shows:
   - `E8:6A:51:5C:68:AF:40:8A:61:48:87:1E:F7:0B:4B:48:AB:5F:C7:8A` (debug)
   - `FF:E7:5B:3E:EE:2C:36:54:6C:8E:40:37:78:8A:F0:66:BA:1E:4E:7D` (release)
4. If missing, add them and download new `google-services.json`
5. Replace the file and rebuild app

## Files Modified

1. ✅ `/lib/features/auth/login_screen.dart`
   - Added network diagnostic button (debug mode only)
   - Added pre-check before Google Sign-In
   
2. ✅ `/lib/core/utils/network_diagnostic.dart` (NEW)
   - Comprehensive network diagnostic tool
   - Tests connectivity, DNS, HTTPS, critical domains

3. ✅ `GOOGLE_SIGNIN_REAL_DEVICE_FIX.md` (NEW)
   - Detailed troubleshooting guide
   - Step-by-step solutions for each issue type

4. ✅ `GOOGLE_SIGNIN_ACTION_PLAN.md` (THIS FILE)
   - Quick action plan
   - What to do next

## Next Steps

1. **Rebuild app** with the new diagnostic tool
2. **Run on real device**
3. **Tap "Test Network (Debug)"** button on login screen
4. **Check console output** to see what's failing
5. **Fix the network issue** based on diagnostic results
6. **Try Google Sign-In** again

The diagnostic tool will pinpoint the exact problem so we can fix it quickly.

## Need Help?

If you run the network diagnostic and share the output with me, I can tell you exactly what's wrong and how to fix it.

The most likely issues are:
1. **WiFi has no internet** → Switch to mobile data
2. **Captive portal** → Open browser and complete login
3. **VPN blocking** → Disable VPN
4. **Network restrictions** → Use different network
