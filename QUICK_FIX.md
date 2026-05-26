# Quick Fix - Google Login Issue

## Error
```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```

## Cause
Firebase not initialized in mobile app (client-side issue, not backend)

## Fix (3 Steps)

### Step 1: Run Fix Script
```bash
cd s:\SKS-mobile-V2
fix-firebase.bat
```

### Step 2: Rebuild App
```bash
flutter run
```

### Step 3: Test
- Open app
- Click "Login with Google"
- Should work now ✅

---

## Manual Fix (If Script Fails)

```bash
flutter clean
flutter pub get
cd android
gradlew clean
cd ..
flutter run
```

---

## Expected Output (Success)

```
I/flutter: ✅ Firebase initialized successfully
I/flutter: ✅ GoogleSignIn.instance initialized
I/flutter: ✅ GoogleSignIn account: user@example.com
I/flutter: ✅ Firebase sign-in success: user@example.com
```

---

## Still Not Working?

### Check SHA-1 Certificate
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

If SHA-1 doesn't match google-services.json:
1. Add SHA-1 to Firebase Console
2. Download new google-services.json
3. Replace file in `android/app/`
4. Rebuild app

---

## Backend Status
✅ All backend services working
✅ API Gateway: port 3012
✅ Google Login Service: port 3010
✅ Endpoints responding correctly

**Issue is in mobile app, not backend!**

---

## Need Help?
See detailed guide: `FIREBASE_FIX_GUIDE.md`
