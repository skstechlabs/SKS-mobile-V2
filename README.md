# SKS - Spiritual Mobile Application

A production-ready spiritual mobile application built with Flutter for Android and iOS.

## 📚 Documentation

**Complete documentation is available in the [docs](docs/) folder.**

### Quick Links
- **[Setup Guide](docs/setup/INSTALLATION_GUIDE.md)** - Get started with development
- **[Build APK](docs/guides/BUILD_APK_GUIDE.md)** - Create APK for testing
- **[Troubleshooting](docs/troubleshooting/)** - Fix common issues
- **[API Integration](docs/guides/API_INTEGRATION_GUIDE.md)** - Backend integration
- **[Push Notifications](docs/guides/ONESIGNAL_INTEGRATION_GUIDE.md)** - OneSignal setup

### Documentation Structure
```
docs/
├── setup/              # Installation & configuration guides
├── guides/             # How-to guides and tutorials
├── troubleshooting/    # Problem solutions and fixes
└── reference/          # Technical reference and architecture
```

**See [docs/README.md](docs/README.md) for complete documentation index.**

---

## 🌟 Features

### Core Screens
- **Home**: Guruji section, daily quotes, meditation music, bhajans, experience videos, and upcoming programs
- **Learnings**: Placeholder for future courses and educational content
- **Guruji's Connect**: Placeholder for direct communication features
- **Events**: Browse and register for spiritual events
- **Notifications**: Stay updated with announcements and reminders

### Authentication
- ✅ Phone OTP authentication (Firebase)
- ✅ Google Sign-In
- ✅ Profile setup and management
- ✅ Guest mode (skip login)

### Push Notifications
- ✅ OneSignal integration
- ✅ Mandatory notification permission
- ✅ Notification storage and display
- ✅ User tracking and targeting
- ✅ Tag-based segmentation

### UI/UX Highlights
- ✨ Spiritual color palette (saffron, beige, gold, white)
- 🎨 Smooth gradients and animations
- 📱 Bottom navigation with 4 tabs
- 🔔 Notification bell in app bar
- 🖼️ Lazy loading images with shimmer effects
- 🎯 Clean, minimal, premium design
- ♿ Accessibility-friendly

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0 or higher
- Android Studio (for Android development)
- Xcode (for iOS development - Mac only)

### Installation

1. **Clone the repository**
```bash
cd "/path/to/SKS-mobile-V2"
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For Android emulator
flutter run

# For web (limited functionality)
flutter run -d chrome

# For specific device
flutter devices
flutter run -d <device_id>
```

### Build APK

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (optimized)
flutter build apk --release --split-per-abi
```

**See [Build APK Guide](docs/guides/BUILD_APK_GUIDE.md) for detailed instructions.**

---

## 🏗️ Architecture

### Clean Architecture Pattern
```
lib/
├── core/
│   ├── theme/          # App theme, colors, typography
│   ├── constants/      # App constants and configuration
│   ├── widgets/        # Reusable widgets
│   ├── services/       # API, OneSignal, storage services
│   └── router.dart     # Navigation configuration
├── features/
│   ├── auth/           # Authentication (login, profile)
│   ├── home/           # Home screen
│   ├── learnings/      # Learnings screen
│   ├── guruji_connect/ # Connect screen
│   ├── events/         # Events screen
│   └── notifications/  # Notifications screen
└── main.dart           # App entry point
```

### Tech Stack
- **Framework**: Flutter 3.0+
- **State Management**: flutter_bloc
- **Navigation**: go_router
- **Authentication**: Firebase Auth
- **Push Notifications**: OneSignal
- **Backend**: REST API (Node.js/Express)
- **Image Caching**: cached_network_image
- **Audio**: just_audio
- **HTTP**: dio

**See [Design Architecture](docs/reference/DESIGN_ARCHITECTURE.md) for details.**

---

## 📱 Current Status

### ✅ Implemented
- Phone OTP authentication
- Google Sign-In
- Profile setup and management
- OneSignal push notifications
- Notification permission flow
- Notification storage and display
- Backend API integration
- Guest mode
- All core screens

### ⚠️ Known Issues
- Backend returns 503 (Firebase Admin SDK not configured)
- iOS APNs configuration pending
- reCAPTCHA disabled for testing

**See [Troubleshooting](docs/troubleshooting/) for solutions.**

---

## 🔧 Configuration

### Environment Variables
Configuration is in `.env.json`:
```json
{
  "API_BASE_URL": "http://localhost:3011",
  "ONESIGNAL_APP_ID": "your-onesignal-app-id",
  "FIREBASE_PROJECT_ID": "sks-login-mobile"
}
```

### Firebase Projects
1. **sks-login-mobile** - Authentication
2. **sks-mobile-notifications** - Push notifications

**See [Firebase Setup](docs/setup/BACKEND_FIREBASE_SETUP.md) for configuration.**

---

## 📦 Build Information

### APK Sizes
- Debug APK: ~218 MB (includes debug symbols)
- Release APK: ~92 MB (optimized)
- Release APK (split): ~92 MB per architecture

### Optimization
- Code minification enabled
- Resource shrinking enabled
- ProGuard rules configured
- Tree-shaking enabled

**See [APK Size Optimization](docs/guides/APK_SIZE_OPTIMIZATION.md) for details.**

---

## 🐛 Troubleshooting

### Common Issues

**OneSignal Plugin Exception**
- Solution: [OneSignal ProGuard Fix](docs/troubleshooting/ONESIGNAL_PROGUARD_FIX.md)

**Login Loop After Google Sign-In**
- Solution: [Critical Fixes Applied](docs/troubleshooting/CRITICAL_FIXES_APPLIED.md)

**Notification Permission Issues**
- Solution: [Notification Permission Troubleshooting](docs/troubleshooting/NOTIFICATION_PERMISSION_TROUBLESHOOTING.md)

**Web Platform Issues**
- Solution: [Web vs Mobile OneSignal](docs/troubleshooting/WEB_VS_MOBILE_ONESIGNAL.md)

**See [Troubleshooting](docs/troubleshooting/) folder for all solutions.**

---

## 📚 Documentation

Complete documentation is organized in the `docs/` folder:

- **[Setup Guides](docs/setup/)** - Installation and configuration
- **[User Guides](docs/guides/)** - How-to tutorials
- **[Troubleshooting](docs/troubleshooting/)** - Problem solutions
- **[Reference](docs/reference/)** - Technical documentation

**Start with [docs/README.md](docs/README.md) for the complete index.**

---

## 🎯 Next Steps

1. **For Development**
   - Follow [Installation Guide](docs/setup/INSTALLATION_GUIDE.md)
   - Complete [Setup Checklist](docs/setup/SETUP_CHECKLIST.md)

2. **For Testing**
   - Build APK: [Build APK Guide](docs/guides/BUILD_APK_GUIDE.md)
   - Test notifications: [Notification Testing](docs/guides/NOTIFICATION_TESTING_GUIDE.md)

3. **For Deployment**
   - Configure backend: [Backend Setup](docs/setup/BACKEND_FIREBASE_SETUP.md)
   - Set up iOS: [Firebase OneSignal Setup](docs/setup/FIREBASE_ONESIGNAL_SETUP_GUIDE.md)

---

## 📄 License

This project is proprietary and confidential.

## 👥 Support

For support and queries:
- Check [Documentation](docs/)
- Review [Troubleshooting](docs/troubleshooting/)
- Contact the development team

---

## Deloyment
- Run ./build-release.sh  


- flutter build apk --release --dart-define-from-file=.env.prod.json

## If you want a split APK per ABI (smaller file size, recommended for distribution):

- flutter build apk --release --split-per-abi --dart-define-from-file=.env.prod.json

## This produces three smaller APKs:
- build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   ← most modern devices
- build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← older 32-bit devices
- build/app/outputs/flutter-apk/app-x86_64-release.apk      ← emulators


- flutter build apk --release --dart-define-from-file=.env.prod.json


created 
keytool -genkey -v -keystore sks-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sks
CN=sks, OU=sks, O=sks, L=hyderabad, ST=telangana, C=in
pwd=jaigurudev

**Built with ❤️ using Flutter**
