# Translation System - Quick Reference Card

## 🚀 Quick Start

### Use Translation in Code
```dart
// Import is automatic via extension
Text(context.tr('home'))
Text(context.tr('welcome'))
```

### Change Language Programmatically
```dart
await LocalizationService().changeLanguage('te');  // Telugu
await LocalizationService().changeLanguage('hi');  // Hindi
await LocalizationService().changeLanguage('en');  // English
```

### Get Current Language
```dart
final currentLang = LocalizationService().currentLocale.languageCode;
// Returns: 'en', 'te', or 'hi'
```

## 📝 Common Translation Keys

### Navigation
```dart
context.tr('home')           // Home
context.tr('learnings')      // Learnings
context.tr('classes')        // Classes
context.tr('contact')        // Contact
context.tr('events')         // Events
context.tr('profile')        // Profile
```

### Actions
```dart
context.tr('continue')       // Continue
context.tr('save')           // Save
context.tr('cancel')         // Cancel
context.tr('ok')             // OK
context.tr('yes')            // Yes
context.tr('no')             // No
context.tr('retry')          // Retry
context.tr('confirm')        // Confirm
```

### Common UI
```dart
context.tr('loading')        // Loading...
context.tr('error')          // Error
context.tr('success')        // Success
context.tr('search')         // Search
context.tr('filter')         // Filter
context.tr('view_all')       // View All
context.tr('see_more')       // See More
```

### Profile
```dart
context.tr('name')           // Name
context.tr('email')          // Email
context.tr('mobile')         // Mobile
context.tr('gender')         // Gender
context.tr('address')        // Address
context.tr('edit_profile')   // Edit Profile
```

### Settings
```dart
context.tr('settings')       // Settings
context.tr('language')       // Language
context.tr('change_language') // Change Language
context.tr('logout')         // Logout
```

## 🔧 Adding New Translation

### 1. Add to en.json
```json
{
  "my_key": "My English Text"
}
```

### 2. Add to te.json
```json
{
  "my_key": "నా తెలుగు టెక్స్ట్"
}
```

### 3. Add to hi.json
```json
{
  "my_key": "मेरा हिंदी टेक्स्ट"
}
```

### 4. Use in Code
```dart
Text(context.tr('my_key'))
```

### 5. Rebuild
```bash
flutter clean && flutter pub get && flutter run
```

## 🐛 Quick Fixes

### Keys Showing Instead of Text?
```bash
cd SKS-mobile-V2
flutter clean
flutter pub get
flutter run -d android
```

### Asset Loading Error?
Check `pubspec.yaml` has:
```yaml
assets:
  - assets/translations/
```

### Language Not Changing?
Verify you're using:
```dart
Text(context.tr('key'))  // ✅ Correct
Text('Hardcoded')        // ❌ Wrong
```

## 📱 Language Codes

| Code | Language | Native Name |
|------|----------|-------------|
| en   | English  | English     |
| te   | Telugu   | తెలుగు      |
| hi   | Hindi    | हिंदी       |

## 🎯 Best Practices

### ✅ DO
```dart
// Use translation keys
Text(context.tr('welcome'))

// Store in variables if reused
final welcomeText = context.tr('welcome');

// Use in widgets
AppBar(title: Text(context.tr('home')))
```

### ❌ DON'T
```dart
// Don't hardcode
Text('Welcome')  // ❌

// Don't forget to rebuild after adding keys
// Hot reload won't work for new translations

// Don't test only on web
// Use Android/iOS for production testing
```

## 🔍 Debug Logging

Check console for:
```
✅ Localization Service initialized successfully
✅ Language changed to: te
✅ Loaded 189 translation keys for te
```

If you see:
```
❌ Failed to load even default language!
⚠️  Missing translation for key: my_key
```

Then rebuild or add missing key.

## 📂 File Locations

```
assets/translations/
├── en.json  (189 keys)
├── te.json  (189 keys)
└── hi.json  (189 keys)

lib/core/services/
└── localization_service.dart

lib/features/language/
└── language_selection_screen.dart
```

## 🚨 Emergency Checklist

If translations break:
1. [ ] Check `assets/translations/` in pubspec.yaml
2. [ ] Run `flutter clean`
3. [ ] Run `flutter pub get`
4. [ ] Full rebuild (not hot reload)
5. [ ] Check console logs
6. [ ] Test on Android/iOS (not web)

## 📞 Quick Commands

```bash
# Rebuild app
./rebuild_app.sh

# Or manually
flutter clean && flutter pub get && flutter run

# Validate JSON
python3 -m json.tool assets/translations/en.json

# Count keys
python3 -c "import json; print(len(json.load(open('assets/translations/en.json'))))"

# Check pubspec
grep -A 5 "assets:" pubspec.yaml
```

## 🎓 Examples

### Simple Text
```dart
Text(context.tr('home'))
```

### With Style
```dart
Text(
  context.tr('welcome'),
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
)
```

### In Button
```dart
ElevatedButton(
  onPressed: () {},
  child: Text(context.tr('continue')),
)
```

### In AppBar
```dart
AppBar(
  title: Text(context.tr('profile')),
)
```

### In Dialog
```dart
AlertDialog(
  title: Text(context.tr('confirm')),
  content: Text(context.tr('are_you_sure')),
  actions: [
    TextButton(
      onPressed: () {},
      child: Text(context.tr('yes')),
    ),
    TextButton(
      onPressed: () {},
      child: Text(context.tr('no')),
    ),
  ],
)
```

## 📊 All 189 Keys Available

See `TRANSLATION_SYSTEM_COMPLETE.md` for full list of keys organized by category.

---

**Quick Help**: See `TRANSLATION_TROUBLESHOOTING.md` for detailed solutions
**Full Guide**: See `TRANSLATION_SYSTEM_COMPLETE.md` for comprehensive documentation
