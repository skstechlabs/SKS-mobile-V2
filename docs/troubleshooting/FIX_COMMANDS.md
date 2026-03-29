# 🚀 Quick Fix Commands

## Problem 1: OneSignal Plugin Exception

### Solution: Clean Rebuild

```bash
# Stop the running app first (Ctrl+C in terminal)

# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Run the app (this will rebuild native code)
flutter run
```

**Why?** OneSignal requires native platform code that only gets compiled during a full build, not during hot reload.

---

## Problem 2: Login Loop After Google Sign-In

### Solution: Already Fixed in Code

The code has been updated to handle Google redirect properly. Just rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

**What was fixed?**
- Login screen now checks for existing Firebase user on mount
- Automatically calls backend API when user exists
- Properly navigates based on profile status

---

## Testing Steps

### 1. Clean Rebuild (Required)
```bash
flutter clean
flutter pub get
flutter run
```

### 2. Test Notification Permission
1. Open app
2. Login or skip
3. Click "Allow Notifications"
4. Should work without "Missing Plugin Exception"

### 3. Test Google Sign-In
1. Click "Continue with Google"
2. Grant permission
3. Should navigate to profile setup or home
4. Should NOT loop back to login

### 4. Test Notifications
1. Send test notification from OneSignal dashboard
2. Tap bell icon in app
3. Should see notification in list

---

## If Still Having Issues

### Issue: Plugin Exception Persists

Try deeper clean:
```bash
flutter clean
rm -rf build/
rm -rf android/build/
rm -rf android/app/build/
flutter pub get
flutter run
```

### Issue: Login Loop Persists

Check console logs for:
```
🔍 Checking existing user: [user_id]
📡 Backend response: {...}
```

If you see errors, share them for further debugging.

### Issue: Backend 503 Error

This is expected - backend needs Firebase Admin SDK setup.

**Workaround**: Use skip login (guest mode) for now.

**Fix**: Configure Firebase Admin SDK on backend server.
See [BACKEND_FIREBASE_SETUP.md](BACKEND_FIREBASE_SETUP.md)

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `flutter clean` | Remove build cache |
| `flutter pub get` | Install dependencies |
| `flutter run` | Build and run app |
| `flutter run -v` | Run with verbose logs |
| `R` (in terminal) | Hot restart (capital R) |
| `r` (in terminal) | Hot reload (lowercase r) |

---

## Expected Console Output (Success)

```
✅ OneSignal initialized successfully with App ID: 3586ffae-bd5f-4475-91c0-6dd24a129a05
✅ Notification permission granted
🔍 Checking existing user: [user_id]
📡 Backend response: {success: true, user: {...}}
✅ OneSignal external user ID set: [user_id]
✅ OneSignal tags set: {auth_provider: google, email: user@example.com}
```

---

## Next Steps After Rebuild

1. ✅ Test notification permission
2. ✅ Test Google sign-in flow
3. ✅ Send test notification from OneSignal
4. ✅ Verify notification appears in app

---

**Ready?** Run these commands now:

```bash
flutter clean && flutter pub get && flutter run
```
