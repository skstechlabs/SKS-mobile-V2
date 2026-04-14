# 📋 Rebuild Checklist - Translation Fix

## Before You Start

- [ ] Save any unsaved work
- [ ] Close the running app (if any)
- [ ] Have your device/emulator ready

## Step 1: Clean Build Cache

```bash
cd SKS-mobile-V2
flutter clean
```

**Expected Output:**
```
Deleting build...
Deleting .dart_tool...
Deleting .flutter-plugins
Deleting .flutter-plugins-dependencies
```

**Status:** [ ] Complete

---

## Step 2: Get Dependencies

```bash
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in SKS-mobile-V2...
Resolving dependencies...
Got dependencies!
```

**Status:** [ ] Complete

---

## Step 3: Verify Assets Declaration

```bash
grep -A 5 "assets:" pubspec.yaml
```

**Expected Output Should Include:**
```yaml
assets:
  - assets/images/
  - assets/images/daily_wisdom_images/
  - assets/images/chakras/
  - assets/images/recentGatherings/
  - assets/translations/  ← This line MUST be present
```

**Status:** [ ] Verified

---

## Step 4: Verify Translation Files Exist

```bash
ls -la assets/translations/
```

**Expected Output:**
```
en.json
te.json
hi.json
```

**Status:** [ ] Verified

---

## Step 5: Validate JSON Files

```bash
python3 -m json.tool assets/translations/en.json > /dev/null && echo "✅ en.json valid"
python3 -m json.tool assets/translations/te.json > /dev/null && echo "✅ te.json valid"
python3 -m json.tool assets/translations/hi.json > /dev/null && echo "✅ hi.json valid"
```

**Expected Output:**
```
✅ en.json valid
✅ te.json valid
✅ hi.json valid
```

**Status:** [ ] Verified

---

## Step 6: Run the App

### For Android:
```bash
flutter run -d android
```

### For iOS:
```bash
flutter run -d ios
```

### For Web (not recommended for production):
```bash
flutter run -d chrome
```

### For macOS:
```bash
flutter run -d macos
```

**Status:** [ ] App Running

---

## Step 7: Test Language Selection

### First Launch Test
- [ ] App shows splash screen
- [ ] Language selection screen appears
- [ ] Can see three language options:
  - [ ] English
  - [ ] తెలుగు (Telugu)
  - [ ] हिंदी (Hindi)
- [ ] Select Telugu
- [ ] Click "Continue"
- [ ] App navigates to next screen

### Verify Translations
- [ ] Bottom navigation shows Telugu text (not keys)
- [ ] Check for: "హోమ్", "తరగతులు", "సంప్రదించండి", "ఈవెంట్స్"
- [ ] Profile screen shows Telugu text
- [ ] No keys like "home", "classes" visible

**Status:** [ ] Language Selection Works

---

## Step 8: Test Language Change

- [ ] Go to Profile screen
- [ ] Tap Settings (or language change option)
- [ ] Navigate to "Change Language"
- [ ] Select Hindi
- [ ] App updates immediately to Hindi
- [ ] Bottom navigation shows: "होम", "कक्षाएं", "संपर्क", "इवेंट्स"
- [ ] Navigate back to Profile
- [ ] No router errors

**Status:** [ ] Language Change Works

---

## Step 9: Test Language Persistence

- [ ] Close the app completely
- [ ] Restart the app
- [ ] App should still be in Hindi (last selected language)
- [ ] No language selection screen on restart
- [ ] All text still in Hindi

**Status:** [ ] Persistence Works

---

## Step 10: Test All Languages

### English
- [ ] Change to English
- [ ] Verify: "Home", "Classes", "Contact", "Events"
- [ ] All screens show English text

### Telugu
- [ ] Change to Telugu
- [ ] Verify: "హోమ్", "తరగతులు", "సంప్రదించండి", "ఈవెంట్స్"
- [ ] All screens show Telugu text

### Hindi
- [ ] Change to Hindi
- [ ] Verify: "होम", "कक्षाएं", "संपर्क", "इवेंट्स"
- [ ] All screens show Hindi text

**Status:** [ ] All Languages Work

---

## Step 11: Check Console Logs

Look for these success messages:
```
✅ Localization Service initialized successfully
✅ Language changed to: te
✅ Loaded 189 translation keys for te
```

Should NOT see:
```
❌ Failed to load even default language!
⚠️  Missing translation for key: xxx
Unable to load asset: "AssetManifest.bin.json"
```

**Status:** [ ] No Errors in Console

---

## Step 12: Test Navigation

- [ ] Navigate to Home
- [ ] Navigate to Learnings/Classes
- [ ] Navigate to Contact
- [ ] Navigate to Events
- [ ] Navigate to Profile
- [ ] Open Settings → Change Language
- [ ] Go back to Profile
- [ ] No router assertion errors

**Status:** [ ] Navigation Works

---

## Step 13: Test Edge Cases

### Clear App Data (Simulate First Install)
```bash
# Android
adb shell pm clear com.your.app.package

# iOS - Uninstall and reinstall
```

- [ ] Launch app
- [ ] Language selection screen appears
- [ ] Select language
- [ ] Language persists

### Rapid Language Changes
- [ ] Change language 5 times quickly
- [ ] No crashes
- [ ] UI updates correctly each time

**Status:** [ ] Edge Cases Pass

---

## Final Verification

### ✅ Success Criteria
- [ ] No "AssetManifest.bin.json" errors
- [ ] No translation keys showing (like "home", "profile")
- [ ] All three languages work correctly
- [ ] Language selection on first launch
- [ ] Language change in settings
- [ ] Language persists across restarts
- [ ] Navigation works without errors
- [ ] Console shows no critical errors

### ❌ If Any Failures
See **TRANSLATION_TROUBLESHOOTING.md** for solutions

---

## Completion Status

**Date Tested:** _______________
**Tested By:** _______________
**Device/Platform:** _______________
**Result:** [ ] PASS  [ ] FAIL

### Notes:
```
_________________________________________________
_________________________________________________
_________________________________________________
```

---

## Quick Reference

### If Something Goes Wrong

1. **Still seeing keys instead of translations?**
   - Did you run `flutter clean`?
   - Did you do a FULL rebuild (not hot reload)?
   - Check console for asset loading errors

2. **AssetManifest.bin.json error?**
   - Verify `assets/translations/` in pubspec.yaml
   - Run `flutter clean && flutter pub get`
   - Try on Android/iOS instead of web

3. **Router errors?**
   - Make sure you pulled latest code
   - Check language_selection_screen.dart uses `context.go()`

4. **Language not persisting?**
   - Check SharedPreferences permissions
   - Clear app data and test again

### Get Help
- **Troubleshooting:** TRANSLATION_TROUBLESHOOTING.md
- **Full Guide:** TRANSLATION_SYSTEM_COMPLETE.md
- **Quick Reference:** TRANSLATION_QUICK_REFERENCE.md

---

**Checklist Version:** 1.0.0
**Last Updated:** 2026-04-07
