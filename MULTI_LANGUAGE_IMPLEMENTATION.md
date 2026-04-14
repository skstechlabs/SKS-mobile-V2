# Multi-Language Implementation Guide

## Overview
The SKS mobile app now supports three languages:
- **English** (en)
- **తెలుగు Telugu** (te)
- **हिंदी Hindi** (hi)

## Features Implemented

### 1. Language Selection Screen
- Appears after splash screen for first-time users
- Beautiful UI with animated transitions
- Shows language options with flags and native names
- Can be accessed from profile settings to change language anytime

### 2. Translation System
- All translations stored in JSON files
- No hardcoded strings in the app
- Easy to add new languages
- Automatic language persistence

### 3. Profile Integration
- Language selection option added to profile settings
- Users can change language anytime from their profile
- Changes apply immediately across the entire app

## File Structure

```
SKS-mobile-V2/
├── assets/
│   └── translations/
│       ├── en.json          # English translations
│       ├── te.json          # Telugu translations
│       └── hi.json          # Hindi translations
├── lib/
│   ├── core/
│   │   └── services/
│   │       └── localization_service.dart  # Localization service
│   └── features/
│       └── language/
│           └── language_selection_screen.dart  # Language selection UI
```

## How to Use Translations in Code

### Method 1: Using Context Extension (Recommended)
```dart
import '../../core/services/localization_service.dart';

// In your widget
Text(context.tr('welcome'))
Text(context.tr('login_title'))
Text(context.tr('continue'))
```

### Method 2: Using Service Directly
```dart
final localization = LocalizationService();
String text = localization.translate('welcome');
```

## Adding New Translations

### Step 1: Add to JSON Files
Add the new key-value pair to all three translation files:

**en.json:**
```json
{
  "new_key": "New Text in English"
}
```

**te.json:**
```json
{
  "new_key": "తెలుగులో కొత్త టెక్స్ట్"
}
```

**hi.json:**
```json
{
  "new_key": "हिंदी में नया टेक्स्ट"
}
```

### Step 2: Use in Code
```dart
Text(context.tr('new_key'))
```

## Available Translation Keys

### Common
- `app_name`, `welcome`, `continue`, `skip`, `save`, `cancel`, `ok`, `yes`, `no`
- `loading`, `error`, `success`, `retry`

### Language Selection
- `language_selection_title`, `language_selection_subtitle`
- `english`, `telugu`, `hindi`
- `select_language`, `change_language`

### Authentication
- `login_title`, `login_subtitle`, `mobile_number`, `send_otp`, `verify_otp`
- `enter_otp`, `resend_otp`, `login_with_google`, `or`

### Profile
- `profile`, `edit_profile`, `personal_information`
- `name`, `email`, `mobile`, `gender`, `date_of_birth`
- `address`, `state`, `pincode`
- `male`, `female`, `other`

### Navigation
- `home`, `learnings`, `guruji_connect`, `events`, `notifications`

### Features
- `daily_wisdom`, `meditation_timer`, `reminders`, `my_progress`
- `classes`, `songs`, `benefits`, `chakras`, `kundalini_science`, `guru_journey`

### Settings
- `settings`, `language`, `wallpaper_settings`, `ringtone_settings`
- `manage_profiles`, `help_support`, `logout`, `logout_confirmation`

### Meditation
- `meditation_start`, `meditation_pause`, `meditation_resume`, `meditation_stop`
- `meditation_duration`, `meditation_history`

### Reminders
- `add_reminder`, `edit_reminder`, `reminder_title`, `reminder_time`
- `reminder_repeat`, `reminder_daily`, `reminder_weekly`, `reminder_custom`

### Notifications
- `notification_title`, `no_notifications`, `mark_as_read`, `delete`

### Common Actions
- `search`, `filter`, `sort`, `view_all`, `see_more`, `see_less`
- `share`, `download`, `play`, `pause`, `next`, `previous`

### Levels & Time
- `level`, `beginner`, `intermediate`, `advanced`
- `day`, `days`, `week`, `weeks`, `month`, `months`, `year`, `years`

### Progress
- `total_time`, `sessions`, `streak`, `achievements`

### Errors
- `error_loading`, `error_network`, `error_server`, `error_unknown`

### Misc
- `feature_coming_soon`, `update_available`, `update_now`, `update_later`
- `not_logged_in`, `please_login`, `login`

## User Flow

### First Time User
1. **Splash Screen** → Shows app logo with loading
2. **Language Selection** → User selects preferred language
3. **Login Screen** → User logs in (all text in selected language)
4. **App** → All screens show content in selected language

### Returning User
1. **Splash Screen** → Shows app logo with loading
2. **App** → Automatically loads saved language preference
3. **Profile Settings** → Can change language anytime

## Technical Details

### LocalizationService
- Singleton service managing app language
- Stores language preference in SharedPreferences
- Notifies listeners when language changes
- Supports hot reload of translations

### Language Persistence
- Language choice saved to device storage
- Persists across app restarts
- First-time users see language selection
- Returning users skip language selection

### Supported Locales
```dart
static const List<Locale> supportedLocales = [
  Locale('en'), // English
  Locale('te'), // Telugu
  Locale('hi'), // Hindi
];
```

## Adding a New Language

### Step 1: Create Translation File
Create `assets/translations/[language_code].json` with all translations

### Step 2: Update LocalizationService
Add the new locale to `supportedLocales`:
```dart
static const List<Locale> supportedLocales = [
  Locale('en'),
  Locale('te'),
  Locale('hi'),
  Locale('ta'), // Tamil (example)
];
```

Add language name to `languageNames`:
```dart
static const Map<String, String> languageNames = {
  'en': 'English',
  'te': 'తెలుగు (Telugu)',
  'hi': 'हिंदी (Hindi)',
  'ta': 'தமிழ் (Tamil)', // example
};
```

### Step 3: Update Language Selection Screen
Add the new language option in the UI

### Step 4: Update pubspec.yaml
Ensure the translations folder is included in assets

## Testing

### Test Language Selection
1. Clear app data
2. Launch app
3. Verify language selection screen appears
4. Select each language and verify UI updates
5. Navigate through app and verify all text is translated

### Test Language Change
1. Login to app
2. Go to Profile → Change Language
3. Select different language
4. Verify entire app updates immediately
5. Restart app and verify language persists

### Test Missing Translations
If a translation key is missing, the key itself will be displayed (e.g., "welcome" instead of translated text)

## Best Practices

1. **Always use translation keys** - Never hardcode strings
2. **Keep keys descriptive** - Use clear, meaningful key names
3. **Maintain consistency** - Use same keys across all language files
4. **Test all languages** - Verify translations work correctly
5. **Handle long text** - Ensure UI accommodates different text lengths
6. **Use context** - Provide context for translators (comments in JSON)

## Dependencies Added

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  shared_preferences: ^2.2.2  # Already present
```

## Migration Guide for Existing Screens

To migrate an existing screen to use translations:

### Before:
```dart
Text('Welcome')
Text('Login')
ElevatedButton(
  child: Text('Continue'),
)
```

### After:
```dart
import '../../core/services/localization_service.dart';

Text(context.tr('welcome'))
Text(context.tr('login'))
ElevatedButton(
  child: Text(context.tr('continue')),
)
```

## Troubleshooting

### Language not changing
- Check if LocalizationService is initialized in main.dart
- Verify translation files exist in assets/translations/
- Ensure pubspec.yaml includes translations folder in assets

### Missing translations
- Check if key exists in all language JSON files
- Verify JSON syntax is correct
- Run `flutter clean` and rebuild

### Language selection not showing
- Check if LocalizationService.isLanguageSelected() returns false
- Verify splash screen navigation logic
- Check router configuration

## Future Enhancements

1. **RTL Support** - Add support for right-to-left languages
2. **Dynamic Loading** - Load translations from server
3. **Pluralization** - Handle singular/plural forms
4. **Date/Time Formatting** - Locale-specific formatting
5. **Number Formatting** - Locale-specific number formats
6. **More Languages** - Add Tamil, Kannada, Malayalam, etc.

## Summary

The multi-language system is now fully integrated into the SKS mobile app. Users can:
- Select their preferred language on first launch
- Change language anytime from profile settings
- Experience the entire app in their chosen language
- Have their language preference saved automatically

All new features should use the translation system to maintain consistency across the app.
