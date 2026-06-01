# Rebuild Instructions After Configuration Changes

## What Changed
1. ✅ Updated `.env.json` with local backend URL (`http://10.0.2.2:3000`)
2. ✅ Fixed GOOGLE_CLIENT_ID in `.env.json`
3. ⚠️ Need to add debug SHA-1 to Firebase Console

## Steps to Rebuild

### 1. Clean Build
```bash
flutter clean
flutter pub get
```

### 2. Run with Environment Variables
```bash
flutter run --dart-define-from-file=.env.json
```

### 3. For Physical Device
If testing on a physical device, update `.env.json`:
```json
"API_BASE_URL": "http://192.168.0.3:3000"
```
Then rebuild.

## Verify Backend is Running

Check all services are online:
```powershell
pm2 list
```

Should show:
- ✅ api-gateway (port 3000)
- ✅ google-login-service (port 4000)
- ✅ otp-login-service (port 4001)
- ✅ notification-service (port 3007)
- ✅ classes-service (port 3014)
- ✅ mobile-backend-service (port 3013)

## Test Backend Connectivity

From your device/emulator, test if backend is reachable:
```bash
# For emulator
curl http://10.0.2.2:3000/health

# For physical device
curl http://192.168.0.3:3000/health
```

## Fix Google Sign-In SHA-1

### Get Debug SHA-1
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Add to Firebase Console
1. Go to: https://console.firebase.google.com/project/sks-login-mobile/settings/general
2. Click your Android app (com.spiritual.app)
3. Click "Add fingerprint"
4. Paste the SHA1 from above
5. Download new `google-services.json`
6. Replace `android/app/google-services.json`
7. Rebuild app

## Expected Results

After these changes:
- ✅ No more "Failed host lookup" errors
- ✅ Backend API calls work
- ✅ Firebase token refresh works
- ✅ Google Sign-In works (after SHA-1 fix)

## Troubleshooting

### Still getting network errors?
1. Check firewall isn't blocking port 3000
2. Verify backend services are running: `pm2 list`
3. Test backend directly: `curl http://localhost:3000/health`

### Google Sign-In still failing?
1. Verify SHA-1 is added to Firebase Console
2. Check package name matches: `com.spiritual.app`
3. Verify `google-services.json` is up to date
4. Clean and rebuild: `flutter clean && flutter run`

### Device can't reach backend?
1. Ensure device and computer are on same WiFi network
2. Check computer's firewall allows incoming connections on port 3000
3. Use computer's IP address (not localhost) for physical devices
