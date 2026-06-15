# Google Sign-In Failing on Real Device - Diagnostic & Fix

## Current Status

✅ **SHA-1 Certificates ARE Already Added**
Your `google-services.json` already contains three OAuth clients with proper SHA-1 fingerprints:
- Debug: `e86a515c68af408a6148871ef70b4b48ab5fc78a`
- Release: `ffe75b3eee2c36546c8e4037788af066ba1e4e7d`
- Additional: `52a1d092cc714eaa4752530e972eff44866a1022`

## Problem Analysis

Looking at your error logs, the **real issue is network connectivity**:

```
ClientException with SocketException: Failed host lookup: 'imagedelivery.net'
(OS Error: No address associated with hostname, errno = 7)

Account reauth failed [16]

OneSignal: device is offline. Throwable: java.net.UnknownHostException
```

**This indicates DNS resolution is failing** - your device cannot resolve domain names to IP addresses.

## Root Causes (Most Likely)

### 1. **WiFi/Network Issue**
- Device connected to WiFi but has no actual internet
- WiFi requires captive portal login (hotel/cafe WiFi)
- Router DNS settings are broken
- Mobile data disabled and WiFi is fake/limited

### 2. **VPN or Proxy Blocking**
- VPN blocking Google services
- Corporate/School network restrictions
- DNS filtering/parental controls
- Ad blocker blocking domains

### 3. **Google Play Services Issues**
- Google Play Services not updated
- Google Play Services cache corrupted
- Device region/country restrictions

### 4. **App-Specific Network Issues**
- App's network permission not granted at runtime
- Android battery optimization killing network
- App data corrupted

## Step-by-Step Fix

### Step 1: Verify Real Internet Connection

```bash
# On your Mac/PC, with device connected via USB:
adb shell ping -c 4 8.8.8.8
```

✅ **If ping works**: Internet is OK, DNS might be the issue
❌ **If ping fails**: No internet connection

```bash
# Test DNS resolution:
adb shell nslookup google.com
adb shell nslookup imagedelivery.net
```

✅ **If DNS works**: Shows IP addresses
❌ **If DNS fails**: "can't resolve" or timeout

### Step 2: Fix Network on Device

**Try these in order:**

1. **Disconnect and reconnect WiFi**
   - Settings → WiFi → Turn OFF
   - Wait 5 seconds
   - Turn ON and reconnect

2. **Use mobile data instead**
   - Turn OFF WiFi
   - Enable Mobile Data
   - Test Google Sign-In

3. **Forget and re-add WiFi**
   - Settings → WiFi → Your Network → Forget
   - Reconnect and re-enter password

4. **Check for captive portal**
   - Open Chrome on device
   - Try to load google.com
   - If redirected to login page → complete login
   - Try app again

5. **Disable VPN if active**
   - Settings → Network & Internet → VPN
   - Disconnect any active VPNs
   - Test app again

6. **Reset network settings** (last resort)
   - Settings → System → Reset → Reset WiFi, mobile & Bluetooth
   - ⚠️ Will forget all WiFi passwords

### Step 3: Fix Google Play Services

```bash
# Clear Google Play Services cache:
adb shell pm clear com.google.android.gms

# Restart device:
adb reboot
```

After reboot:
1. Open **Play Store** app on device
2. Update **Google Play Services** if update available
3. Update **Google Play Store** itself
4. Test your app again

### Step 4: Clear App Data and Reinstall

```bash
# Clear app cache and data:
adb shell pm clear com.spiritual.app

# Uninstall app:
adb uninstall com.spiritual.app

# Clean rebuild:
cd "/Users/srinath/SKS Techlabs/SKS-mobile-V2"
flutter clean
flutter pub get

# Reinstall on device:
flutter run --dart-define-from-file=.env.prod.json --release
```

### Step 5: Test Network in App

Add this temporary diagnostic widget to your login screen to verify network:

```dart
// Test network connectivity
Future<void> _testNetwork() async {
  try {
    final response = await http.get(Uri.parse('https://www.google.com'));
    print('✅ Network test: ${response.statusCode}');
    
    final dns = await InternetAddress.lookup('google.com');
    print('✅ DNS test: ${dns.first.address}');
  } catch (e) {
    print('❌ Network test failed: $e');
  }
}
```

### Step 6: Verify Firebase Configuration

Double-check Firebase Console:

1. Go to: https://console.firebase.google.com/project/sks-login-mobile/settings/general
2. Verify Android app: `com.spiritual.app`
3. Confirm SHA-1 fingerprints are listed:
   - `E8:6A:51:5C:68:AF:40:8A:61:48:87:1E:F7:0B:4B:48:AB:5F:C7:8A`
   - `FF:E7:5B:3E:EE:2C:36:54:6C:8E:40:37:78:8A:F0:66:BA:1E:4E:7D`
4. If missing, add them and download NEW `google-services.json`

### Step 7: Test on Different Network

To isolate the issue:

1. **Try mobile hotspot from another phone**
2. **Try different WiFi network** (neighbor, coffee shop)
3. **Try mobile data only** (disable WiFi)

If works on different network → Original network has restrictions

## Alternative: Use Phone Sign-In Instead

If Google Sign-In continues failing due to network restrictions, consider adding Firebase Phone Authentication as backup:

```yaml
# pubspec.yaml
dependencies:
  firebase_auth: ^4.15.0  # Already have this
```

Update auth options in your login screen to offer both methods.

## Quick Test Commands

```bash
# 1. Check device connection
flutter devices

# 2. Check internet on device
adb shell ping -c 3 8.8.8.8

# 3. Check DNS
adb shell nslookup google.com

# 4. Clear Google Play Services
adb shell pm clear com.google.android.gms

# 5. Clear app and reinstall
flutter clean && flutter run --dart-define-from-file=.env.prod.json --release

# 6. View real-time logs
flutter logs
```

## Expected Success Indicators

When working properly, you should see:

```
✅ GoogleSignIn.instance initialized
✅ GoogleSignIn account: user@gmail.com
✅ idToken: present
✅ Firebase sign-in success: user@gmail.com
```

You should NOT see:

```
❌ Failed host lookup
❌ No address associated with hostname
❌ Account reauth failed [16]
❌ device is offline
```

## If Nothing Works

1. **Test on a different device** - rules out device-specific issues
2. **Test on a different network** - rules out network restrictions
3. **Check Google Cloud Console** for OAuth client configuration:
   - https://console.cloud.google.com/apis/credentials?project=sks-login-mobile
4. **Verify package name** matches everywhere:
   - `android/app/build.gradle`: `applicationId "com.spiritual.app"`
   - Firebase Console: `com.spiritual.app`
   - google-services.json: `"package_name": "com.spiritual.app"`

## Contact for More Help

If issue persists after all steps:

1. Share output of these commands:
   ```bash
   adb shell ping -c 3 8.8.8.8
   adb shell nslookup google.com
   flutter doctor -v
   ```

2. Try installing a simple browser app to verify device internet works

3. Check if device has any MDM (Mobile Device Management) or parental controls that might block Google services
