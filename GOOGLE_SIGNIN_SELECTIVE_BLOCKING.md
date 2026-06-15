# Google Sign-In - Selective Domain Blocking Issue

## The Mystery Solved

**Your Question:** "How come other APIs are working for audio etc but Google Sign-In is not?"

**Answer:** Your device has **selective domain blocking** - it can reach your app's servers but NOT Google's authentication servers.

## What's Working vs What's Not

### ✅ WORKING:
- `app.sivakundalini.org` - Your API server
- `pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev` - Your audio/assets CDN
- Audio playback
- API calls to your backend
- Other app features

### ❌ NOT WORKING:
- `accounts.google.com` - Google Sign-In authentication
- `imagedelivery.net` - Image CDN (from your error logs)
- Google services in general

## Root Causes for Selective Blocking

### 1. **Geographic Restrictions**
Some countries/regions block Google services while allowing other internet access:
- China (Great Firewall blocks Google)
- Some Middle Eastern countries
- Iran, North Korea, etc.

**Test:** Are you in a region that restricts Google services?

### 2. **Corporate/School/Organization Firewall**
Network administrators often block social media and Google services but allow work-related sites:
- Blocks `*.google.com`, `*.googleapis.com`
- Allows other HTTPS traffic
- Common in schools, government offices, some companies

**Test:** Are you on a work/school network?

### 3. **ISP-Level DNS Filtering**
Some Internet Service Providers block specific domains:
- Parental control services
- Government-mandated filtering
- ISP's content filtering

**Test:** Try mobile data instead of WiFi

### 4. **Device-Level Restrictions**
Some devices have restrictions:
- Parental control apps (Google Family Link, Qustodio, etc.)
- Mobile Device Management (MDM) software
- Ad blockers that over-block
- Custom DNS settings blocking Google

**Test:** Check Settings → Digital Wellbeing or Parental Controls

### 5. **Google Play Services Issue**
Google Sign-In uses Google Play Services, which runs separately from regular HTTP:
- Uses different network stack
- May be blocked separately from regular HTTPS
- Could be outdated or corrupted

**Test:** Update Google Play Services from Play Store

## Solutions I've Implemented

### 1. ✅ Updated Network Security Config
Added explicit configuration for Google domains with user certificate trust:

```xml
<domain-config cleartextTrafficPermitted="false">
    <domain includeSubdomains="true">google.com</domain>
    <domain includeSubdomains="true">googleapis.com</domain>
    <domain includeSubdomains="true">gstatic.com</domain>
    <domain includeSubdomains="true">googleusercontent.com</domain>
    <domain includeSubdomains="true">firebaseapp.com</domain>
    <domain includeSubdomains="true">imagedelivery.net</domain>
    <trust-anchors>
        <certificates src="system" />
        <certificates src="user" />
    </trust-anchors>
</domain-config>
```

This ensures Google domains get the same certificate trust as your app domains.

### 2. ✅ Network Pre-Check
The app now checks if `accounts.google.com` is reachable before attempting Google Sign-In.

## Quick Diagnostic Steps

### Step 1: Determine if it's Network-Level Blocking

```bash
# With device connected via USB:

# Test your domain (should work)
adb shell ping -c 3 app.sivakundalini.org

# Test Google domain (probably fails)
adb shell ping -c 3 accounts.google.com

# Test DNS resolution
adb shell nslookup accounts.google.com
```

### Step 2: Try Different Network

1. **Disconnect from current WiFi**
2. **Enable Mobile Data** (4G/5G from cellular provider)
3. **Try Google Sign-In again**

If it works on mobile data → Your WiFi network blocks Google

### Step 3: Check for Restrictions

```bash
# Check if device has restrictions
adb shell dumpsys device_policy

# Check DNS settings
adb shell getprop net.dns1
```

### Step 4: Clear Google Play Services

```bash
# Clear cache and data
adb shell pm clear com.google.android.gms

# Reboot device
adb reboot
```

After reboot:
1. Open Play Store
2. Search "Google Play Services"
3. Update if available
4. Try app again

## Rebuild and Test

With the network security config update:

```bash
cd "/Users/srinath/SKS Techlabs/SKS-mobile-V2"

# Clean rebuild to apply network config changes
flutter clean
flutter pub get

# Run on device
flutter run --dart-define-from-file=.env.prod.json
```

Then:
1. Tap "Test Network (Debug)" button
2. Check console output
3. Try Google Sign-In

## Alternative Solutions

### Option 1: Use Phone/OTP Sign-In Only

Your MSG91 OTP authentication works because it doesn't depend on Google services. You could:
- Remove Google Sign-In button
- Use only OTP authentication
- Add email/password authentication later

### Option 2: Use VPN to Access Google

If you're in a region that blocks Google:
1. Install a reliable VPN app
2. Connect to server in US/Europe
3. Try Google Sign-In
4. After successful login, can use app normally (token is cached)

### Option 3: Proxy Server

Set up a reverse proxy for Google authentication:
- Route Google Sign-In through your own server
- Your server forwards to Google
- Not recommended (security implications)

## Expected Test Results

### If Network-Level Blocking:
```bash
$ adb shell ping -c 3 app.sivakundalini.org
✅ 3 packets transmitted, 3 received

$ adb shell ping -c 3 accounts.google.com
❌ Unknown host or 100% packet loss
```

### If Google Play Services Issue:
```bash
$ adb shell ping -c 3 accounts.google.com
✅ 3 packets transmitted, 3 received

But Google Sign-In still fails with:
❌ [16] Account reauth failed
```

### If Working After Fix:
```
✅ Can reach accounts.google.com
✅ GoogleSignIn.instance initialized
✅ GoogleSignIn account: user@gmail.com
✅ Firebase sign-in success
```

## Next Steps

1. **Rebuild app** with new network security config:
   ```bash
   flutter clean && flutter run --dart-define-from-file=.env.prod.json
   ```

2. **Try Google Sign-In** - the network config change might fix it

3. **If still fails, try mobile data** - confirms if it's WiFi blocking

4. **Run diagnostic commands** above to identify exact cause

5. **Share results** with me:
   - Output of `adb shell ping accounts.google.com`
   - Output of "Test Network (Debug)" button
   - Does it work on mobile data vs WiFi?

## Most Likely Scenario

Based on your symptoms:
- **Your app's domains work** → Internet is fine
- **Google domains don't work** → Selective blocking

Most likely causes (in order):
1. **Corporate/School/Public WiFi firewall** → Try mobile data
2. **Geographic restrictions** → Use VPN or stick to OTP login
3. **Google Play Services corrupted** → Clear and update
4. **Device parental controls** → Check device settings

The network config update + mobile data test will pinpoint the exact issue.
