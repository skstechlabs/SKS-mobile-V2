# Quick Fix: Authentication Issues

## Problem
- ❌ OTP Login: "Session expired" or "Network error"
- ❌ Google Login: Not working

## Solution (5 Steps)

### Step 1: Generate SHA-1
```bash
cd SKS-mobile-V2
./generate-sha1.sh
```
**Copy the SHA-1 value** (long string with colons like `AA:BB:CC:...`)

### Step 2: Add to Firebase
1. Go to https://console.firebase.google.com/
2. Select: `sks-login-mobile`
3. Click ⚙️ → Project settings
4. Find Android app → "SHA certificate fingerprints"
5. Click "Add fingerprint" → Paste SHA-1 → Save

### Step 3: Download google-services.json
1. Same page, click "Download google-services.json"
2. Replace file:
   ```bash
   cp ~/Downloads/google-services.json SKS-mobile-V2/android/app/google-services.json
   ```

### Step 4: Enable Google Sign-In
1. Firebase Console → Authentication → Sign-in method
2. Click "Google" → Enable → Set email → Save

### Step 5: Rebuild App
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release
```

## Done! ✅

Test OTP and Google login - both should work now.

---

## Code Fixes Already Applied

- ✅ Increased API timeouts (10s → 30s)
- ✅ Added retry logic for network failures
- ✅ Better error messages
- ✅ Improved error handling

---

## If Still Not Working

### Check SHA-1 Matches:
```bash
./generate-sha1.sh
```
Compare with Firebase Console.

### Check Backend:
```bash
curl http://sivakundalini.org/api/auth/verify
```
Should return: `{"success":false,"message":"No token provided"}`

### Check Firebase:
- Authentication → Sign-in method
- Ensure "Phone" and "Google" are Enabled

---

**That's it! Follow the 5 steps above and authentication will work.** 🚀
