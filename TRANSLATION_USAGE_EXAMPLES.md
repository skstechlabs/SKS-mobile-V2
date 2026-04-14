# Translation Usage Examples

## Quick Start Guide

### 1. Import the Localization Service
```dart
import '../../core/services/localization_service.dart';
```

### 2. Use Translations in Your Widget

#### Simple Text
```dart
// Before
Text('Welcome')

// After
Text(context.tr('welcome'))
```

#### Button Text
```dart
// Before
ElevatedButton(
  onPressed: () {},
  child: Text('Continue'),
)

// After
ElevatedButton(
  onPressed: () {},
  child: Text(context.tr('continue')),
)
```

#### AppBar Title
```dart
// Before
AppBar(
  title: Text('Profile'),
)

// After
AppBar(
  title: Text(context.tr('profile')),
)
```

#### Dialog
```dart
// Before
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Logout'),
    content: Text('Are you sure you want to logout?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Logout'),
      ),
    ],
  ),
)

// After
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.tr('logout')),
    content: Text(context.tr('logout_confirmation')),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('cancel')),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(context.tr('logout')),
      ),
    ],
  ),
)
```

#### SnackBar
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Feature coming soon')),
)

// After
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(context.tr('feature_coming_soon'))),
)
```

#### Form Fields
```dart
// Before
TextFormField(
  decoration: InputDecoration(
    labelText: 'Name',
    hintText: 'Enter your name',
  ),
)

// After
TextFormField(
  decoration: InputDecoration(
    labelText: context.tr('name'),
    hintText: context.tr('enter_name'), // Add this key to translations
  ),
)
```

## Complete Screen Example

### Before (Hardcoded Strings)
```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text('Change app language'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage notifications'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            subtitle: Text('Get help'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
```

### After (With Translations)
```dart
import 'package:flutter/material.dart';
import '../../core/services/localization_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text(context.tr('language')),
            subtitle: Text(context.tr('change_language')),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text(context.tr('notifications')),
            subtitle: Text(context.tr('manage_notifications')),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text(context.tr('help_support')),
            subtitle: Text(context.tr('get_help')),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
```

## Common Patterns

### 1. Loading States
```dart
if (isLoading) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(context.tr('loading')),
      ],
    ),
  );
}
```

### 2. Error States
```dart
if (hasError) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(context.tr('error')),
        SizedBox(height: 8),
        Text(context.tr('error_loading')),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: retry,
          child: Text(context.tr('retry')),
        ),
      ],
    ),
  );
}
```

### 3. Empty States
```dart
if (items.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(context.tr('no_notifications')),
      ],
    ),
  );
}
```

### 4. Confirmation Dialogs
```dart
Future<bool?> showConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('confirm')),
      content: Text(context.tr('are_you_sure')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('no')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr('yes')),
        ),
      ],
    ),
  );
}
```

### 5. Bottom Sheets
```dart
void showLanguageBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('select_language'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ListTile(
            title: Text(context.tr('english')),
            onTap: () => changeLanguage('en'),
          ),
          ListTile(
            title: Text(context.tr('telugu')),
            onTap: () => changeLanguage('te'),
          ),
          ListTile(
            title: Text(context.tr('hindi')),
            onTap: () => changeLanguage('hi'),
          ),
        ],
      ),
    ),
  );
}
```

## Tips for Migration

### 1. Find All Hardcoded Strings
Search your codebase for:
- `Text('`
- `title: '`
- `label: '`
- `hintText: '`

### 2. Create Translation Keys
For each hardcoded string:
1. Create a meaningful key (e.g., 'welcome_message')
2. Add it to all three translation files
3. Replace the hardcoded string with `context.tr('key')`

### 3. Test Each Language
After migration:
1. Change language to English - verify all text appears
2. Change language to Telugu - verify all text appears
3. Change language to Hindi - verify all text appears
4. Check for any missing translations (keys showing instead of text)

### 4. Handle Dynamic Content
For content that comes from the backend:
```dart
// Backend should return translated content based on user's language preference
// Or store translations in backend and fetch based on language

// Example API call with language parameter
final response = await apiService.getData(
  language: LocalizationService().currentLocale.languageCode,
);
```

## Common Mistakes to Avoid

### ❌ Don't Do This
```dart
// Hardcoded string
Text('Welcome to SKS')

// String concatenation
Text('Hello ' + userName)

// Inline translations
Text(language == 'en' ? 'Welcome' : 'స్వాగతం')
```

### ✅ Do This Instead
```dart
// Use translation key
Text(context.tr('welcome_message'))

// Use string interpolation (if supported) or separate keys
Text('${context.tr('hello')} $userName')

// Use translation service
Text(context.tr('welcome'))
```

## Adding New Translation Keys

When you need a new translation:

1. **Add to en.json:**
```json
{
  "new_feature_title": "New Feature",
  "new_feature_description": "This is a new feature"
}
```

2. **Add to te.json:**
```json
{
  "new_feature_title": "కొత్త ఫీచర్",
  "new_feature_description": "ఇది కొత్త ఫీచర్"
}
```

3. **Add to hi.json:**
```json
{
  "new_feature_title": "नई सुविधा",
  "new_feature_description": "यह एक नई सुविधा है"
}
```

4. **Use in code:**
```dart
Text(context.tr('new_feature_title'))
Text(context.tr('new_feature_description'))
```

## Testing Translations

```dart
// Test in your widget tests
testWidgets('Shows translated text', (tester) async {
  // Set language
  await LocalizationService().changeLanguage('en');
  
  await tester.pumpWidget(MyApp());
  
  // Verify English text appears
  expect(find.text('Welcome'), findsOneWidget);
  
  // Change language
  await LocalizationService().changeLanguage('te');
  await tester.pump();
  
  // Verify Telugu text appears
  expect(find.text('స్వాగతం'), findsOneWidget);
});
```

## Summary

1. Always import `localization_service.dart`
2. Use `context.tr('key')` for all user-facing text
3. Add keys to all three translation files
4. Test in all languages
5. Never hardcode strings

This ensures a consistent, maintainable, and truly multi-language app!
