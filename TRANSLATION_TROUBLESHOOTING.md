# Translation System - Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: Still Seeing Translation Keys Instead of Text

**Symptoms:**
- App shows "app_full_name" instead of "Siva Kundalini Sadhana"
- Keys like "home", "profile", "classes" appear as-is

**Solution:**
```bash
# You MUST do a full rebuild after pubspec.yaml changes
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter run -d android  # or your device
```

**Why:** Hot reload/restart does NOT work for asset changes. Full rebuild required.

---

### Issue 2: "AssetManifest.bin.json" Error on Flutter Web

**Symptoms:**
```
Unable to load asset: "AssetManifest.bin.json"
The asset does not exist or has empty data
```

**Solution:**
1. Verify `pubspec.yaml` has `assets/translations/` declared
2. Run full rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```
3. If still failing, test on Android/iOS instead (more reliable)

**Why:** Flutter Web has stricter asset loading. Android/iOS recommended for production.

---

### Issue 3: Router Error When Changing Language

**Symptoms:**
```
DartError: Assertion failed: index != -1 is not true
go_router/src/match.dart
```

**Solution:**
Already fixed! The language selection screen now uses `context.go('/profile')` instead of `context.pop()`.

If you still see this:
1. Make sure you pulled the latest code
2. Rebuild the app completely

---

### Issue 4: Language Not Persisting After App Restart

**Symptoms:**
- Select Telugu, restart app, back to English

**Solution:**
Check SharedPreferences is working:
```dart
// In LocalizationService
final prefs = await SharedPreferences.getInstance();
await prefs.setString('selected_language', languageCode);
```

**Debug:**
```bash
# Android
adb shell run-as com.your.app ls /data/data/com.your.app/shared_prefs/

# iOS - check in Xcode device logs
```

---

### Issue 5: Some Screens Still Show English

**Symptoms:**
- Language selection works
- Some screens show translations, others don't

**Solution:**
Those screens need migration to use `context.tr()`:

**Before:**
```dart
Text('Home')  // ❌ Hardcoded
```

**After:**
```dart
Text(context.tr('home'))  // ✅ Translated
```

**Check:** Search for hardcoded strings in your screens.

---

### Issue 6: Missing Translation Key Warning

**Symptoms:**
```
⚠️  Missing translation for key: my_new_key
```

**Solution:**
Add the key to ALL three translation files:

1. `assets/translations/en.json`:
   ```json
   "my_new_key": "My New Text"
   ```

2. `assets/translations/te.json`:
   ```json
   "my_new_key": "నా కొత్త టెక్స్ట్"
   ```

3. `assets/translations/hi.json`:
   ```json
   "my_new_key": "मेरा नया टेक्स्ट"
   ```

4. Rebuild: `flutter clean && flutter pub get && flutter run`

---

### Issue 7: Language Selection Screen Not Showing on First Launch

**Symptoms:**
- App goes straight to login/home
- No language selection

**Solution:**
Check splash screen logic:

```dart
// In splash_screen.dart
final isLanguageSelected = await LocalizationService.isLanguageSelected();

if (!isLanguageSelected) {
  context.go('/language-selection');  // Should show language screen
} else {
  // Continue to next screen
}
```

**Debug:**
Clear app data to simulate first launch:
```bash
# Android
adb shell pm clear com.your.app

# iOS
Uninstall and reinstall app
```

---

### Issue 8: Translations Work on Android but Not Web

**Symptoms:**
- Android: ✅ Translations work
- Web: ❌ Shows keys

**Solution:**
This is expected! Flutter Web has different asset loading:

1. Always do `flutter clean` before web builds
2. Check browser console for asset errors
3. **Recommendation:** Use Android/iOS for production

**Web-specific rebuild:**
```bash
flutter clean
flutter pub get
flutter build web --release
flutter run -d chrome
```

---

## Verification Commands

### Check Translation Files Exist
```bash
ls -la assets/translations/
# Should show: en.json, te.json, hi.json
```

### Validate JSON Syntax
```bash
python3 -m json.tool assets/translations/en.json
python3 -m json.tool assets/translations/te.json
python3 -m json.tool assets/translations/hi.json
```

### Count Translation Keys
```bash
python3 -c "import json; print(len(json.load(open('assets/translations/en.json'))))"
# Should output: 189
```

### Check pubspec.yaml
```bash
grep -A 5 "assets:" pubspec.yaml
# Should include: - assets/translations/
```

---

## Debug Logging

The LocalizationService has extensive logging. Check console for:

```
🌐 Initializing LocalizationService...
📱 Saved language from prefs: te
🔄 Loading language: te
📂 Loading translation file: assets/translations/te.json
✅ Translation file loaded, parsing JSON...
✅ Loaded 189 translation keys for te
✅ Language changed to: te
```

If you see:
```
❌ Failed to load even default language!
```

Then assets are not bundled. Run `flutter clean && flutter pub get`.

---

## Quick Fix Checklist

When translations don't work:

1. [ ] Verify `assets/translations/` in pubspec.yaml
2. [ ] Run `flutter clean`
3. [ ] Run `flutter pub get`
4. [ ] Do FULL rebuild (not hot reload)
5. [ ] Check console logs for asset errors
6. [ ] Test on Android/iOS (not just Web)
7. [ ] Verify all 3 JSON files exist and are valid
8. [ ] Check that screens use `context.tr()` not hardcoded strings

---

## Getting Help

If issues persist:

1. Check console logs for specific errors
2. Verify all files from TRANSLATION_FIX_SUMMARY.md
3. Ensure you did a FULL rebuild (not hot reload)
4. Test on physical device (not just emulator/web)
5. Check that LocalizationService is initialized in main.dart

---

**Last Updated**: 2026-04-07
**Related Docs**: 
- TRANSLATION_FIX_SUMMARY.md
- TRANSLATION_ASSET_FIX.md
- rebuild_app.sh
