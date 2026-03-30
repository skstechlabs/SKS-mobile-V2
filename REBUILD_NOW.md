# REBUILD APK NOW - Fix Continuous Loading

## The Issue
App stuck loading because of HTTP vs HTTPS mismatch.

## The Fix
Changed `http://` to `https://` in `.env.prod.json`

## Rebuild Commands

```bash
cd SKS-mobile-V2

# Quick rebuild (use script)
./rebuild-production.sh

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Done! ✅

The app will now work correctly with HTTPS backend.

---

## Manual Commands (if script doesn't work)

```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env.prod.json
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Verify Backend

```bash
curl https://sivakundalini.org/api/gatherings
```

Should return JSON data (not error).

---

**That's it! Rebuild and install the APK.** 🚀
