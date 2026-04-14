# Translation System Architecture

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Interface                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Home    │  │ Profile  │  │ Settings │  │ Language │   │
│  │  Screen  │  │  Screen  │  │  Screen  │  │ Selection│   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│       └─────────────┴──────────────┴─────────────┘          │
│                          │                                   │
│                   context.tr('key')                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              LocalizationService (Singleton)                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • ChangeNotifier (notifies on language change)      │  │
│  │  • Singleton pattern (one instance app-wide)         │  │
│  │  • Manages current locale                            │  │
│  │  • Loads translation JSON files                      │  │
│  │  • Provides translate() method                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Current State:                                              │
│  ├─ _currentLocale: Locale('en'|'te'|'hi')                 │
│  ├─ _localizedStrings: Map<String, String>                 │
│  └─ _isInitialized: bool                                    │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│   SharedPreferences      │    │   Asset Bundle           │
│  ┌────────────────────┐  │    │  ┌────────────────────┐ │
│  │ selected_language  │  │    │  │ en.json (189 keys) │ │
│  │ = 'en'|'te'|'hi'   │  │    │  │ te.json (189 keys) │ │
│  └────────────────────┘  │    │  │ hi.json (189 keys) │ │
│                          │    │  └────────────────────┘ │
│  Persists language       │    │  Bundled with app      │
│  across app restarts     │    │  (via pubspec.yaml)    │
└──────────────────────────┘    └──────────────────────────┘
```

## 🔄 Language Change Flow

```
User Selects Language
        │
        ▼
┌───────────────────────────────────────────────────────┐
│ LanguageSelectionScreen                               │
│  • User taps language option (EN/TE/HI)              │
│  • Calls: LocalizationService().changeLanguage('te') │
└───────────────────┬───────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────┐
│ LocalizationService.changeLanguage()                  │
│  1. Validate language code                            │
│  2. Load translation JSON file                        │
│  3. Update _currentLocale                             │
│  4. Save to SharedPreferences                         │
│  5. Call notifyListeners()                            │
└───────────────────┬───────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────┐
│ notifyListeners() triggers rebuilds                   │
│  ├─ MaterialApp rebuilds (key: ValueKey(locale))     │
│  ├─ Router rebuilds (refreshListenable)              │
│  └─ All listening widgets rebuild                    │
└───────────────────┬───────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────┐
│ UI Updates                                            │
│  • All Text(context.tr('key')) widgets update        │
│  • Bottom navigation updates                         │
│  • AppBars update                                     │
│  • All screens show new language                     │
└───────────────────────────────────────────────────────┘
```

## 🚀 App Initialization Flow

```
main()
  │
  ├─ WidgetsFlutterBinding.ensureInitialized()
  │
  ├─ Firebase.initializeApp()
  │
  ├─ LocalizationService().initialize()
  │   │
  │   ├─ Load saved language from SharedPreferences
  │   │   └─ If null, use default 'en'
  │   │
  │   ├─ Load translation JSON file
  │   │   └─ rootBundle.loadString('assets/translations/xx.json')
  │   │
  │   ├─ Parse JSON to Map<String, String>
  │   │
  │   └─ Set _isInitialized = true
  │
  └─ runApp(SpiritualApp())
      │
      └─ MaterialApp.router(
          locale: LocalizationService().currentLocale,
          key: ValueKey(locale),  // Forces rebuild on locale change
          routerConfig: appRouter,
        )
```

## 🎯 Translation Lookup Flow

```
Widget Build
  │
  └─ Text(context.tr('home'))
      │
      └─ LocalizationExtension.tr('home')
          │
          └─ LocalizationService().translate('home')
              │
              ├─ Lookup in _localizedStrings['home']
              │
              ├─ If found: return translation
              │   └─ 'en': "Home"
              │   └─ 'te': "హోమ్"
              │   └─ 'hi': "होम"
              │
              └─ If not found: 
                  ├─ Log warning: "Missing translation for key: home"
                  └─ Return key itself: "home"
```

## 📦 Asset Loading Flow

```
App Build Process
  │
  ├─ Read pubspec.yaml
  │   └─ Find: assets: - assets/translations/
  │
  ├─ Bundle assets into app
  │   ├─ Create AssetManifest.json
  │   ├─ Include en.json
  │   ├─ Include te.json
  │   └─ Include hi.json
  │
  └─ App Runtime
      │
      └─ rootBundle.loadString('assets/translations/en.json')
          │
          ├─ Read from AssetManifest
          ├─ Load file content
          └─ Return JSON string
```

## 🔐 State Management

```
┌─────────────────────────────────────────────────────┐
│ LocalizationService extends ChangeNotifier          │
│                                                      │
│  Listeners:                                          │
│  ├─ MaterialApp (_SpiritualAppState)               │
│  │   └─ Rebuilds entire app on locale change       │
│  │                                                   │
│  └─ GoRouter (via refreshListenable)                │
│      └─ Rebuilds routes on locale change            │
│                                                      │
│  When changeLanguage() called:                       │
│  └─ notifyListeners()                               │
│      ├─ All listeners receive notification          │
│      └─ Trigger setState() / rebuild                │
└─────────────────────────────────────────────────────┘
```

## 🗂️ Data Flow

```
┌──────────────┐
│ JSON Files   │
│ (Assets)     │
└──────┬───────┘
       │ Load at runtime
       ▼
┌──────────────────────────┐
│ LocalizationService      │
│ _localizedStrings Map    │
│ {                        │
│   "home": "Home",        │
│   "profile": "Profile",  │
│   ...189 keys            │
│ }                        │
└──────┬───────────────────┘
       │ translate()
       ▼
┌──────────────────────────┐
│ UI Widgets               │
│ Text(context.tr('home')) │
│ → Displays: "Home"       │
└──────────────────────────┘
```

## 🔄 Persistence Flow

```
Language Change
  │
  ├─ User selects language
  │
  ├─ LocalizationService.changeLanguage('te')
  │   │
  │   └─ SharedPreferences.setString('selected_language', 'te')
  │       └─ Saved to device storage
  │
  └─ App Restart
      │
      └─ LocalizationService.initialize()
          │
          └─ SharedPreferences.getString('selected_language')
              │
              ├─ If found: Load that language
              └─ If null: Load default 'en'
```

## 🎨 Component Interaction

```
┌─────────────────────────────────────────────────────────┐
│                      MaterialApp                         │
│  • Provides BuildContext                                │
│  • Manages locale                                        │
│  • Rebuilds on locale change                            │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌──────────────────┐
│   GoRouter    │         │ LocalizationExt  │
│ • Routes      │         │ • context.tr()   │
│ • Navigation  │         │ • Easy access    │
└───────┬───────┘         └────────┬─────────┘
        │                          │
        │         ┌────────────────┘
        │         │
        ▼         ▼
┌─────────────────────────────────┐
│    LocalizationService          │
│  • Singleton                    │
│  • ChangeNotifier               │
│  • Translation logic            │
└─────────────────────────────────┘
```

## 📊 Performance Considerations

```
Initialization (One-time)
  ├─ Load JSON file: ~10-50ms
  ├─ Parse JSON: ~5-20ms
  └─ Total: ~15-70ms

Translation Lookup (Per widget)
  ├─ Map lookup: O(1) - ~0.001ms
  └─ Very fast, no performance impact

Language Change
  ├─ Load new JSON: ~10-50ms
  ├─ Parse JSON: ~5-20ms
  ├─ Save preference: ~5-10ms
  ├─ Rebuild UI: ~16-100ms (depends on complexity)
  └─ Total: ~36-180ms (smooth transition)

Memory Usage
  ├─ One Map<String, String> per language
  ├─ ~189 keys × ~20 chars avg = ~3.8KB per language
  └─ Minimal memory footprint
```

## 🔍 Error Handling Flow

```
Translation Request
  │
  └─ context.tr('some_key')
      │
      └─ LocalizationService.translate('some_key')
          │
          ├─ Key exists?
          │   ├─ YES → Return translation
          │   └─ NO → 
          │       ├─ Log warning
          │       └─ Return key itself (fallback)
          │
          └─ Service initialized?
              ├─ YES → Continue
              └─ NO → Return key (safe fallback)
```

## 🛡️ Robustness Features

```
┌─────────────────────────────────────────────────────┐
│ Fallback Mechanisms                                  │
│                                                      │
│ 1. Missing Translation Key                          │
│    └─ Return key itself (visible to developer)      │
│                                                      │
│ 2. Failed to Load Language File                     │
│    └─ Try loading default 'en'                      │
│                                                      │
│ 3. Default Language Load Fails                      │
│    └─ Mark as initialized anyway (don't block app)  │
│                                                      │
│ 4. Invalid Language Code                            │
│    └─ Fall back to default 'en'                     │
│                                                      │
│ 5. SharedPreferences Error                          │
│    └─ Use default language, continue without saving │
└─────────────────────────────────────────────────────┘
```

## 🎯 Key Design Decisions

### 1. Singleton Pattern
- **Why**: One instance manages all translations
- **Benefit**: Consistent state across app
- **Trade-off**: Global state (acceptable for this use case)

### 2. ChangeNotifier
- **Why**: Notify widgets when language changes
- **Benefit**: Automatic UI updates
- **Trade-off**: Rebuilds entire app (acceptable, happens rarely)

### 3. Extension Method
- **Why**: Easy access via `context.tr()`
- **Benefit**: Clean, readable code
- **Trade-off**: Requires BuildContext (acceptable in Flutter)

### 4. JSON Files
- **Why**: Simple, human-readable, easy to edit
- **Benefit**: Non-developers can add translations
- **Trade-off**: Not as efficient as binary (acceptable for 189 keys)

### 5. Asset Bundle
- **Why**: Translations bundled with app
- **Benefit**: Works offline, fast loading
- **Trade-off**: Can't update without app update (acceptable for now)

---

**Architecture Version**: 1.0.0
**Last Updated**: 2026-04-07
**Status**: Production Ready
