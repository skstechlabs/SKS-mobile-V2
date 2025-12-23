# Quick Start Guide - Divine Path

## 🚀 Setup in 5 Minutes

### Step 1: Prerequisites
Ensure you have installed:
- Flutter SDK 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)
- VS Code or Android Studio IDE

### Step 2: Verify Flutter Installation
```bash
flutter doctor
```
Fix any issues reported by Flutter Doctor.

### Step 3: Get Dependencies
```bash
cd "e:\Mobile app"
flutter pub get
```

### Step 4: Run the App
```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

### Step 5: Hot Reload
While the app is running:
- Press `r` to hot reload
- Press `R` to hot restart
- Press `q` to quit

---

## 📱 Platform-Specific Setup

### Android Setup

1. **Install Android Studio**
   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install Android SDK and tools

2. **Create Virtual Device (Emulator)**
   - Open Android Studio
   - Tools → Device Manager
   - Create Device → Select device → Download system image
   - Start emulator

3. **Run on Android**
   ```bash
   flutter run -d android
   ```

4. **Build APK**
   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk
   ```

### iOS Setup (macOS only)

1. **Install Xcode**
   - Download from Mac App Store
   - Install command line tools:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

2. **Install CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

3. **Setup iOS Simulator**
   ```bash
   open -a Simulator
   ```

4. **Run on iOS**
   ```bash
   flutter run -d ios
   ```

5. **Build IPA**
   ```bash
   flutter build ios --release
   ```

---

## 🎨 Project Structure Overview

```
e:\Mobile app\
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── theme/                   # Colors, typography, theme
│   │   ├── constants/               # App constants, mock data
│   │   ├── widgets/                 # Reusable widgets
│   │   └── router.dart              # Navigation setup
│   └── features/
│       ├── home/                    # Home screen
│       ├── events/                  # Events screen
│       ├── notifications/           # Notifications screen
│       ├── learnings/               # Learnings (placeholder)
│       └── guruji_connect/          # Connect (placeholder)
├── assets/                          # Images, icons, audio
├── android/                         # Android-specific files
├── ios/                             # iOS-specific files
├── pubspec.yaml                     # Dependencies
└── README.md                        # Documentation
```

---

## 🛠️ Common Commands

### Development
```bash
# Run with hot reload
flutter run

# Run on specific device
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS

# Clear cache and rebuild
flutter clean
flutter pub get
flutter run
```

### Building
```bash
# Android
flutter build apk              # Debug APK
flutter build apk --release    # Release APK
flutter build appbundle        # App Bundle for Play Store

# iOS
flutter build ios              # iOS build
flutter build ipa              # IPA for App Store
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check for outdated packages
flutter pub outdated
```

---

## 🎯 Key Features to Explore

### 1. Home Screen
- Guruji section with animated glow
- Daily quotes carousel
- Meditation music player
- Bhajans gallery
- Experience videos
- Upcoming events

### 2. Navigation
- Bottom navigation bar (4 tabs)
- Notification bell in app bar
- Smooth transitions

### 3. Events
- Filter events by category
- Event cards with images
- Registration functionality

### 4. Notifications
- Categorized notifications
- Unread indicators
- Empty state design

---

## 🎨 Customization Guide

### Change Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color saffron = Color(0xFFFF9933);  // Change primary color
static const Color gold = Color(0xFFD4AF37);     // Change accent color
```

### Update Mock Data
Edit `lib/core/constants/app_constants.dart`:
```dart
static const List<String> dailyQuotes = [
  'Your custom quote here',
  // Add more quotes
];
```

### Add New Screen
1. Create folder: `lib/features/new_feature/`
2. Create file: `new_feature_page.dart`
3. Add route in `lib/core/router.dart`
4. Add navigation item if needed

### Change Fonts
Edit `lib/core/theme/app_theme.dart`:
```dart
displayLarge: GoogleFonts.yourFont(
  fontSize: 32,
  fontWeight: FontWeight.bold,
),
```

---

## 🐛 Troubleshooting

### Issue: "Waiting for another flutter command to release the startup lock"
```bash
# Delete lock file
rm -rf "C:\Users\<username>\AppData\Local\Temp\flutter_tools_lock"
```

### Issue: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

### Issue: "Unable to load asset"
```bash
# Ensure assets are listed in pubspec.yaml
flutter clean
flutter pub get
flutter run
```

### Issue: "Hot reload not working"
- Press `R` for hot restart instead of `r`
- Or stop and restart the app

---

## 📚 Learning Resources

### Flutter Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Widget Catalog](https://flutter.dev/docs/development/ui/widgets)
- [Cookbook](https://flutter.dev/docs/cookbook)

### State Management
- [BLoC Pattern](https://bloclibrary.dev/)
- [Provider](https://pub.dev/packages/provider)

### UI/UX
- [Material Design](https://material.io/design)
- [Flutter UI Challenges](https://github.com/lohanidamodar/flutter_ui_challenges)

### Video Tutorials
- [Flutter Official YouTube](https://www.youtube.com/c/flutterdev)
- [The Net Ninja Flutter Tutorial](https://www.youtube.com/playlist?list=PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ)

---

## 🤝 Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes
# Test thoroughly

# Commit changes
git add .
git commit -m "Add new feature"

# Push to remote
git push origin feature/new-feature
```

### 2. Code Review
- Create pull request
- Request review from team
- Address feedback
- Merge to main

### 3. Testing
- Write unit tests for business logic
- Write widget tests for UI components
- Test on multiple devices
- Test different screen sizes

### 4. Release
- Update version in `pubspec.yaml`
- Build release version
- Test release build
- Deploy to stores

---

## 💡 Pro Tips

1. **Use Hot Reload**: Press `r` to see changes instantly
2. **Widget Inspector**: Use Flutter DevTools for debugging UI
3. **Performance Overlay**: Press `P` while running to see performance metrics
4. **Const Constructors**: Use `const` for better performance
5. **Extract Widgets**: Keep widgets small and reusable
6. **Use Shortcuts**: Learn IDE shortcuts for faster development

---

## 📞 Support

For issues or questions:
1. Check documentation in `README.md` and `DESIGN_ARCHITECTURE.md`
2. Search Flutter documentation
3. Check Stack Overflow
4. Contact development team

---

**Happy Coding! 🚀**
