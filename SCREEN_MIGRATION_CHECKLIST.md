# Screen Migration Checklist

This checklist helps you migrate existing screens to use the translation system.

## Quick Migration Steps

### 1. Import Localization Service
Add this import to your screen file:
```dart
import '../../core/services/localization_service.dart';
```

### 2. Find All Hardcoded Strings
Search for these patterns in your file:
- `Text('`
- `'title':`
- `'label':`
- `'hintText':`
- `'content':`

### 3. Replace Each String
For each hardcoded string:
```dart
// Before
Text('Welcome')

// After
Text(context.tr('welcome'))
```

### 4. Add Missing Keys
If a translation key doesn't exist:
1. Add it to `assets/translations/en.json`
2. Add it to `assets/translations/te.json`
3. Add it to `assets/translations/hi.json`

### 5. Test
- Change language to English - verify all text
- Change language to Telugu - verify all text
- Change language to Hindi - verify all text

## Screen-by-Screen Checklist

### ✅ Completed Screens
- [x] Splash Screen
- [x] Language Selection Screen
- [x] Profile Screen (partial - language option added)

### 🔄 Screens to Migrate

#### Authentication Screens
- [ ] Login Screen
  - [ ] Title: "Login"
  - [ ] Subtitle: "Enter your mobile number to continue"
  - [ ] Button: "Send OTP"
  - [ ] Button: "Login with Google"
  - [ ] Label: "Mobile Number"
  
- [ ] Profile Setup Screen
  - [ ] Title: "Setup Profile"
  - [ ] Fields: Name, Email, Gender, DOB
  - [ ] Button: "Continue"
  
- [ ] Permission Screen
  - [ ] Title: "Permissions"
  - [ ] Description text
  - [ ] Button: "Allow"

#### Home & Navigation
- [ ] Home Page
  - [ ] Section titles
  - [ ] Card labels
  - [ ] Button text
  
- [ ] Main Scaffold
  - [ ] Bottom navigation labels
  - [ ] Tab names

#### Feature Screens
- [ ] Learnings Page
  - [ ] Title: "Learnings"
  - [ ] Section headers
  - [ ] Card text
  
- [ ] Guruji Connect Page
  - [ ] Title: "Guruji Connect"
  - [ ] Content text
  
- [ ] Events Page
  - [ ] Title: "Events"
  - [ ] Event details
  
- [ ] Notifications Page
  - [ ] Title: "Notifications"
  - [ ] Empty state: "No notifications yet"
  - [ ] Actions: "Mark as Read", "Delete"

#### Meditation
- [ ] Meditation Timer Page
  - [ ] Title: "Meditation Timer"
  - [ ] Buttons: "Start", "Pause", "Resume", "Stop"
  - [ ] Labels: "Duration"
  
- [ ] Meditation History Page
  - [ ] Title: "Meditation History"
  - [ ] Stats labels
  - [ ] Empty state

#### Reminders
- [ ] Reminders Screen
  - [ ] Title: "Reminders"
  - [ ] Button: "Add Reminder"
  - [ ] Empty state
  
- [ ] Reminder Form Screen
  - [ ] Title: "Add Reminder" / "Edit Reminder"
  - [ ] Fields: Title, Time, Repeat
  - [ ] Options: Daily, Weekly, Custom
  - [ ] Buttons: Save, Cancel

#### Profile
- [ ] Profile Screen (complete migration)
  - [ ] Title: "Profile"
  - [ ] Section: "Personal Information"
  - [ ] Section: "Address"
  - [ ] Section: "Account"
  - [ ] Labels: Name, Email, Mobile, etc.
  - [ ] Actions: Edit, Manage Profiles, Help, Logout
  
- [ ] Profile Edit Screen
  - [ ] Title: "Edit Profile"
  - [ ] Form fields
  - [ ] Buttons: Save, Cancel
  
- [ ] Profiles List Screen
  - [ ] Title: "Manage Profiles"
  - [ ] Actions: Add, Edit, Delete
  
- [ ] Profile Selection Screen
  - [ ] Title: "Select Profile"
  - [ ] Button: "Add Profile"

#### Settings
- [ ] Wallpaper Settings Page
  - [ ] Title: "Wallpaper Settings"
  - [ ] Options
  - [ ] Buttons
  
- [ ] Ringtone Settings Page
  - [ ] Title: "Ringtone Settings"
  - [ ] Options
  - [ ] Buttons

#### Other Features
- [ ] Classes/Learnings
  - [ ] Class Days List Screen
  - [ ] Day Video Screen
  
- [ ] Songs Page
  - [ ] Title: "Songs"
  - [ ] Player controls
  
- [ ] Benefits Page
  - [ ] Title: "Benefits"
  - [ ] Content
  
- [ ] Chakras Page
  - [ ] Title: "Chakras"
  - [ ] Descriptions
  
- [ ] Kundalini Science Page
  - [ ] Title: "Kundalini Science"
  - [ ] Content
  
- [ ] Guru Journey Page
  - [ ] Title: "Guru Journey"
  - [ ] Content

## Common Patterns to Replace

### AppBar Titles
```dart
// Before
AppBar(title: Text('Profile'))

// After
AppBar(title: Text(context.tr('profile')))
```

### Button Labels
```dart
// Before
ElevatedButton(child: Text('Continue'))

// After
ElevatedButton(child: Text(context.tr('continue')))
```

### Form Fields
```dart
// Before
TextFormField(
  decoration: InputDecoration(labelText: 'Name'),
)

// After
TextFormField(
  decoration: InputDecoration(labelText: context.tr('name')),
)
```

### Dialog Text
```dart
// Before
AlertDialog(
  title: Text('Logout'),
  content: Text('Are you sure?'),
)

// After
AlertDialog(
  title: Text(context.tr('logout')),
  content: Text(context.tr('logout_confirmation')),
)
```

### SnackBar Messages
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Success')),
)

// After
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(context.tr('success'))),
)
```

### Empty States
```dart
// Before
Center(child: Text('No items found'))

// After
Center(child: Text(context.tr('no_items_found')))
```

### Error Messages
```dart
// Before
Text('Failed to load data')

// After
Text(context.tr('error_loading'))
```

## Translation Keys Needed

### Priority 1 (Most Common)
- [x] welcome, continue, save, cancel, ok, yes, no
- [x] loading, error, success, retry
- [x] login, logout, profile, settings
- [x] home, notifications, search

### Priority 2 (Feature Specific)
- [x] meditation_timer, meditation_start, meditation_pause
- [x] add_reminder, edit_reminder, reminder_title
- [x] daily_wisdom, classes, songs, benefits
- [x] name, email, mobile, gender, date_of_birth

### Priority 3 (Less Common)
- [x] error_loading, error_network, error_server
- [x] feature_coming_soon, update_available
- [x] total_time, sessions, streak, achievements

### Custom Keys to Add
Add these to translation files as you migrate screens:
- `enter_name` - "Enter your name"
- `enter_email` - "Enter your email"
- `select_gender` - "Select gender"
- `select_date` - "Select date"
- `no_items_found` - "No items found"
- `confirm` - "Confirm"
- `are_you_sure` - "Are you sure?"
- `manage_notifications` - "Manage notifications"
- `get_help` - "Get help"
- etc.

## Testing Each Screen

After migrating a screen:

1. **Visual Test**
   - Open the screen
   - Change language to English - check all text
   - Change language to Telugu - check all text
   - Change language to Hindi - check all text

2. **Interaction Test**
   - Test all buttons
   - Test all forms
   - Test all dialogs
   - Test all error states

3. **Edge Cases**
   - Long text in Telugu/Hindi
   - Text overflow
   - Multi-line text
   - Empty states

4. **Checklist**
   - [ ] All text is translated
   - [ ] No hardcoded strings remain
   - [ ] UI looks good in all languages
   - [ ] No text overflow
   - [ ] All interactions work

## Progress Tracking

### Overall Progress
- Total Screens: ~30
- Completed: 3
- In Progress: 0
- Remaining: ~27

### By Category
- Authentication: 0/3
- Home & Navigation: 0/2
- Features: 0/6
- Meditation: 0/2
- Reminders: 0/2
- Profile: 1/4 (partial)
- Settings: 0/2
- Other: 0/9

## Tips

1. **Start with high-traffic screens** - Home, Profile, Login
2. **Batch similar screens** - All auth screens together
3. **Test frequently** - Don't migrate too many screens before testing
4. **Keep translations consistent** - Use same keys for same concepts
5. **Document new keys** - Add comments in JSON files
6. **Review with native speakers** - Verify translations are correct

## Next Steps

1. Choose a screen to migrate
2. Follow the migration steps
3. Add any missing translation keys
4. Test in all languages
5. Mark as complete in this checklist
6. Move to next screen

## Need Help?

- See `TRANSLATION_USAGE_EXAMPLES.md` for code examples
- See `MULTI_LANGUAGE_IMPLEMENTATION.md` for detailed guide
- See `LANGUAGE_FEATURE_SUMMARY.md` for overview

Happy migrating! 🚀
