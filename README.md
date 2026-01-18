# Divine Path - Spiritual Mobile Application

A production-ready spiritual mobile application built with Flutter for Android and iOS.

## 🌟 Features

### Core Screens
- **Home**: Guruji section, daily quotes, meditation music, bhajans, experience videos, and upcoming programs
- **Learnings**: Placeholder for future courses and educational content
- **Guruji's Connect**: Placeholder for direct communication features
- **Events**: Browse and register for spiritual events
- **Notifications**: Stay updated with announcements and reminders

### UI/UX Highlights
- ✨ Spiritual color palette (saffron, beige, gold, white)
- 🎨 Smooth gradients and animations
- 📱 Bottom navigation with 4 tabs
- 🔔 Notification bell in app bar
- 🖼️ Lazy loading images with shimmer effects
- 🎯 Clean, minimal, premium design
- ♿ Accessibility-friendly

## 🏗️ Architecture

### Clean Architecture Pattern
```
lib/
├── core/
│   ├── theme/          # App theme, colors, typography
│   ├── constants/      # App constants and mock data
│   ├── widgets/        # Reusable widgets
│   ├── utils/          # Utility functions
│   └── router.dart     # Navigation configuration
├── features/
│   ├── home/           # Home screen
│   ├── learnings/      # Learnings screen (placeholder)
│   ├── guruji_connect/ # Connect screen (placeholder)
│   ├── events/         # Events screen
│   └── notifications/  # Notifications screen
└── main.dart           # App entry point
```

### Tech Stack
- **Framework**: Flutter 3.0+
- **State Management**: flutter_bloc (ready for implementation)
- **Navigation**: go_router
- **Image Caching**: cached_network_image
- **UI Components**: carousel_slider, shimmer
- **Typography**: google_fonts (Playfair Display, Lora, Open Sans)
- **Audio**: just_audio (ready for implementation)
- **Sharing**: share_plus
- **HTTP**: dio (ready for API integration)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for platform-specific builds

### Installation

1. **Clone the repository**
```bash
cd "e:\Mobile app"
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For specific device
flutter devices
flutter run -d <device_id>
cd "/Users/srinath/SKS Techlabs/SKS-mobile-V2" && flutter run -d chrome --web-port 8083 --web-hostname 0.0.0.0
```

### Build for Production

**Android APK**
```bash
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

## 🎨 Design System

### Color Palette
- **Saffron**: `#FF9933` - Primary brand color
- **Light Saffron**: `#FFB366` - Gradient accent
- **Beige**: `#F5E6D3` - Background
- **White**: `#FFFBF5` - Surface
- **Gold**: `#D4AF37` - Accent
- **Dark Brown**: `#4A3728` - Text

### Typography
- **Display**: Playfair Display (serif, elegant)
- **Headings**: Lora (serif, spiritual)
- **Body**: Open Sans (sans-serif, readable)

### Components
- Cards with soft shadows
- Gradient backgrounds
- Shimmer loading states
- Smooth animations (fade, slide)
- Glow effects on Guruji image

## 📱 Screens Overview

### Home Page
1. **Guruji Section**: Large image with animated glow effect
2. **About Guruji**: Expandable text section
3. **Daily Quotes**: Auto-playing carousel with share functionality
4. **Meditation Music**: Horizontal scrollable list with play controls
5. **Songs & Bhajans**: Card-based layout with artwork
6. **Experience Videos**: Video thumbnails with play button
7. **Recommended**: Personalization-ready section
8. **Upcoming Programs**: Event cards with registration CTA

### Events Page
- Filter chips (All, Upcoming, This Month, Past)
- Event cards with image, date, location
- Register and Details buttons
- Formatted dates with intl package

### Notifications Page
- Categorized notifications (event, content, reminder)
- Unread indicators
- Time stamps
- Empty state design

### Learnings & Guruji's Connect
- Coming soon placeholders
- Feature previews
- Architecture-ready for future implementation

## 🔮 Future-Ready Features

### Authentication (Ready to Implement)
- Login/Signup screens
- Firebase Auth integration
- Role-based access control

### Backend Integration
- Dio HTTP client configured
- API service layer ready
- Mock data easily replaceable

### State Management
- flutter_bloc dependency added
- Clean architecture supports BLoC pattern
- Event-driven state updates

### Analytics
- Ready for Firebase Analytics
- Event tracking structure in place

### Multi-language Support
- Intl package included
- String externalization ready

### Push Notifications
- FCM integration ready
- Notification handling structure in place

## 🎯 Performance Optimizations

- **Image Caching**: CachedNetworkImage for efficient loading
- **Lazy Loading**: Images load on-demand
- **Shimmer Effects**: Skeleton loaders for better UX
- **Optimized Builds**: Minification and shrinking enabled
- **Smooth Animations**: 60 FPS animations with AnimationController
- **Efficient Scrolling**: ListView.builder for large lists

## ♿ Accessibility

- Semantic labels on interactive elements
- Sufficient color contrast ratios
- Touch targets meet minimum size requirements
- Font scaling support
- Screen reader compatible

## 📦 Dependencies

### Production
```yaml
flutter_bloc: ^8.1.3          # State management
go_router: ^12.0.0            # Navigation
cached_network_image: ^3.3.0  # Image caching
shimmer: ^3.0.0               # Loading effects
carousel_slider: ^4.2.1       # Carousels
google_fonts: ^6.1.0          # Typography
share_plus: ^7.2.1            # Sharing
just_audio: ^0.9.36           # Audio playback
dio: ^5.4.0                   # HTTP client
get_it: ^7.6.4                # Dependency injection
```

## 🔧 Configuration

### Android
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

### iOS
- **Deployment Target**: iOS 12.0+
- **Swift Version**: 5.0

## 📝 Development Guidelines

### Code Style
- Follow Flutter style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep widgets small and focused

### Git Workflow
- Feature branches for new features
- Descriptive commit messages
- Pull requests for code review

### Testing (Ready to Implement)
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

## 🐛 Known Issues & Limitations

- Mock data currently used (API integration pending)
- Audio playback not implemented (structure ready)
- Video player not implemented (structure ready)
- Authentication not implemented (architecture ready)

## 📄 License

This project is proprietary and confidential.

## 👥 Support

For support and queries, contact the development team.

---

**Built with ❤️ using Flutter**
