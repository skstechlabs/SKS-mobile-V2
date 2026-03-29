# Divine Path - Design & Architecture Document

## 📐 Design System Specifications

### Color System

#### Primary Colors
```dart
Saffron:       #FF9933  // Primary brand, CTAs, active states
Light Saffron: #FFB366  // Gradients, hover states
Gold:          #D4AF37  // Accents, highlights, premium elements
```

#### Neutral Colors
```dart
White:         #FFFBF5  // Surface, cards, backgrounds
Beige:         #F5E6D3  // Secondary background, subtle sections
Soft Gray:     #E8E0D5  // Borders, dividers, inactive states
Dark Brown:    #4A3728  // Primary text, icons
```

#### Semantic Colors
```dart
Success:       #4CAF50
Warning:       #FF9800
Error:         #F44336
Info:          #2196F3
```

### Typography Scale

#### Display (Playfair Display - Serif)
- **Display Large**: 32px, Bold, Dark Brown
- **Display Medium**: 28px, SemiBold, Dark Brown
- Used for: Hero titles, main headings

#### Headings (Lora - Serif)
- **Headline Medium**: 24px, SemiBold, Dark Brown
- **Title Large**: 20px, SemiBold, Dark Brown
- Used for: Section headers, card titles

#### Body (Open Sans - Sans Serif)
- **Body Large**: 16px, Regular, Dark Brown
- **Body Medium**: 14px, Regular, Dark Brown
- **Body Small**: 12px, Regular, Dark Brown (60% opacity)
- Used for: Content, descriptions, labels

### Spacing System
```
4px   - Micro spacing
8px   - Small spacing
12px  - Medium spacing
16px  - Standard spacing
24px  - Large spacing
32px  - XL spacing
48px  - XXL spacing
```

### Border Radius
```
8px   - Small elements (chips, tags)
12px  - Medium elements (buttons, inputs)
16px  - Large elements (cards, containers)
24px  - XL elements (modals, sheets)
```

### Elevation & Shadows

#### Soft Shadow (Cards, Buttons)
```dart
BoxShadow(
  color: darkBrown.withOpacity(0.08),
  blurRadius: 12,
  offset: Offset(0, 4),
)
```

#### Glow Shadow (Guruji Image, Special Elements)
```dart
BoxShadow(
  color: gold.withOpacity(0.3),
  blurRadius: 20,
  spreadRadius: 2,
)
```

### Gradients

#### Spiritual Gradient (Backgrounds)
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [beige, white, softGray.withOpacity(0.3)],
)
```

#### Saffron Gradient (CTAs, Highlights)
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [saffron, lightSaffron],
)
```

---

## 🎨 Component Library

### 1. Cards

#### Standard Card
- Background: White
- Border Radius: 16px
- Elevation: 2
- Padding: 16px
- Shadow: Soft shadow

#### Image Card
- Clip behavior: antiAlias
- Image aspect ratio: 16:9
- Overlay gradient for text readability
- Shimmer placeholder during load

### 2. Buttons

#### Primary Button (ElevatedButton)
- Background: Saffron gradient
- Text: White, 16px, SemiBold
- Padding: 12px vertical, 24px horizontal
- Border Radius: 12px
- Elevation: 2

#### Secondary Button (OutlinedButton)
- Border: 2px, Saffron
- Text: Saffron, 16px, SemiBold
- Padding: 12px vertical, 24px horizontal
- Border Radius: 12px

#### Icon Button
- Size: 48x48px (touch target)
- Icon size: 24px
- Color: Dark Brown / Saffron

### 3. Navigation

#### Bottom Navigation Bar
- Height: 56px
- Background: White
- Selected color: Saffron
- Unselected color: Dark Brown (60% opacity)
- Icons: 24px
- Labels: 12px, SemiBold when selected
- Top shadow for elevation

#### App Bar
- Height: 56px
- Background: Transparent
- Elevation: 0
- Title: Lora, 20px, SemiBold
- Icons: 24px, Dark Brown

### 4. Loading States

#### Shimmer Loading
- Base color: Grey 300
- Highlight color: Grey 100
- Animation duration: 1.5s
- Border radius matches content

#### Skeleton Screens
- Used for: Images, cards, lists
- Maintains layout structure
- Smooth transition to content

### 5. Carousels

#### Quote Carousel
- Auto-play: 5 seconds
- Enlarge center page: true
- Aspect ratio: 16:9
- Indicators: Dots, 8px, Saffron when active

#### Horizontal Scrollers
- Item spacing: 12px
- Padding: 16px horizontal
- Snap to items: false
- Show partial next item

---

## 📱 Screen Specifications

### Home Screen

#### Layout Structure
```
AppBar (56px)
├── Title: "Divine Path"
└── Notification Icon

ScrollView
├── Guruji Section (400px)
│   ├── Image with glow animation
│   └── Title overlay
├── About Section (Card)
│   ├── Title: "About Guruji"
│   ├── Text (expandable)
│   └── Read more button
├── Daily Quotes (Carousel, 200px)
│   ├── Quote cards with gradient
│   ├── Share button
│   └── Indicators
├── Meditation Music (Horizontal, 100px)
│   └── Music cards with play button
├── Bhajans (Horizontal, 200px)
│   └── Image cards with metadata
├── Experience Videos (Horizontal, 180px)
│   └── Video thumbnails with play overlay
├── Recommended Section (Card)
│   └── Placeholder content
└── Upcoming Programs (List)
    └── Event cards (2 items)

Bottom Navigation (56px)
```

#### Animations
1. **Guruji Glow**: 2s repeat, opacity 0.2-0.4
2. **Quote Carousel**: Auto-advance every 5s
3. **Card Entrance**: Fade in on scroll
4. **Button Press**: Scale 0.95 on tap

### Events Screen

#### Layout Structure
```
AppBar (56px)
Filter Chips (60px)
├── All, Upcoming, This Month, Past

ScrollView (Event Cards)
├── Event Image (200px)
├── Badge (Upcoming/Past)
├── Title
├── Date & Location
├── Description
└── Action Buttons
    ├── Register (Primary)
    └── Details (Secondary)
```

#### Interactions
- Filter selection updates list
- Card tap opens event details
- Register button shows confirmation
- Share event functionality

### Notifications Screen

#### Layout Structure
```
AppBar (56px)
├── Title: "Notifications"
└── "Mark all read" button

List View
├── Notification Item
│   ├── Icon (48px circle)
│   ├── Title (Bold if unread)
│   ├── Message
│   ├── Timestamp
│   └── Unread indicator (8px dot)
```

#### States
- Unread: Beige background, bold title, dot indicator
- Read: White background, normal title
- Empty: Center icon with message

### Placeholder Screens (Learnings, Connect)

#### Layout Structure
```
Center Content
├── Icon Circle (120px)
│   └── Gradient background
├── Title
├── "Coming Soon" badge
├── Description
└── Feature List Card
    └── Icon + Text rows
```

---

## 🎭 Animation Guidelines

### Micro-interactions
- **Duration**: 200-300ms
- **Curve**: easeInOut
- **Use cases**: Button press, card tap, icon change

### Page Transitions
- **Duration**: 300-400ms
- **Type**: Fade for bottom nav, Slide for modals
- **Curve**: easeOut

### Loading Animations
- **Shimmer**: 1500ms linear repeat
- **Glow**: 2000ms easeInOut repeat
- **Fade in**: 400ms easeIn

### Scroll Animations
- **Parallax**: Subtle, 0.5x scroll speed
- **Fade in**: Trigger at 80% visibility
- **Slide up**: 20px offset, 300ms

---

## 🏗️ Architecture Patterns

### Clean Architecture Layers

#### 1. Presentation Layer
```
features/
├── home/
│   ├── home_page.dart          // UI
│   ├── home_bloc.dart          // State management (future)
│   └── home_state.dart         // State definitions (future)
```

#### 2. Domain Layer (Future)
```
domain/
├── entities/                    // Business models
├── repositories/                // Abstract repositories
└── usecases/                    // Business logic
```

#### 3. Data Layer (Future)
```
data/
├── models/                      // Data models
├── repositories/                // Repository implementations
├── datasources/
│   ├── remote/                  // API calls
│   └── local/                   // Local storage
```

### State Management (BLoC Pattern - Ready)

#### Event Flow
```
User Action → Event → BLoC → State → UI Update
```

#### Example Structure
```dart
// Events
abstract class HomeEvent {}
class LoadHomeData extends HomeEvent {}

// States
abstract class HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<Quote> quotes;
  final List<Event> events;
}
class HomeError extends HomeState {}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // Business logic
}
```

### Dependency Injection (GetIt - Ready)

```dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Repositories
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  
  // Use cases
  getIt.registerLazySingleton<GetQuotesUseCase>(
    () => GetQuotesUseCase(getIt())
  );
  
  // BLoCs
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(getIt())
  );
}
```

---

## 🔌 API Integration (Future)

### Endpoint Structure
```
Base URL: https://api.divinepath.com/v1

GET  /quotes              // Daily quotes
GET  /events              // Upcoming events
GET  /music               // Meditation music
GET  /bhajans             // Songs & bhajans
GET  /videos              // Experience videos
GET  /notifications       // User notifications
POST /auth/login          // User login
POST /events/:id/register // Event registration
```

### Response Format
```json
{
  "success": true,
  "data": { ... },
  "message": "Success",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Error Handling
```dart
try {
  final response = await dio.get('/quotes');
  return QuoteModel.fromJson(response.data);
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    throw NetworkException('Connection timeout');
  }
  throw ServerException(e.message);
}
```

---

## 📊 Performance Targets

### Metrics
- **App Launch**: < 2 seconds (cold start)
- **Screen Transition**: < 300ms
- **Image Load**: < 1 second (with cache)
- **API Response**: < 2 seconds
- **Frame Rate**: 60 FPS (smooth animations)
- **Memory Usage**: < 150 MB (typical)
- **APK Size**: < 20 MB (release)

### Optimization Strategies
1. **Image Optimization**
   - Use WebP format
   - Implement progressive loading
   - Cache aggressively
   - Lazy load off-screen images

2. **Code Optimization**
   - Tree shaking enabled
   - Minification in release
   - Deferred loading for features
   - Const constructors where possible

3. **Network Optimization**
   - Request batching
   - Response caching
   - Retry logic with exponential backoff
   - Offline-first architecture

---

## ♿ Accessibility Checklist

### Visual
- ✅ Color contrast ratio ≥ 4.5:1 for text
- ✅ Text scaling support (up to 200%)
- ✅ Focus indicators visible
- ✅ No information conveyed by color alone

### Interactive
- ✅ Touch targets ≥ 48x48 dp
- ✅ Keyboard navigation support
- ✅ Screen reader labels (Semantics)
- ✅ Haptic feedback on actions

### Content
- ✅ Clear heading hierarchy
- ✅ Descriptive link text
- ✅ Alt text for images
- ✅ Error messages are clear

---

## 🧪 Testing Strategy (Future Implementation)

### Unit Tests
- Business logic in use cases
- Data transformations
- Utility functions
- Target: 80% coverage

### Widget Tests
- Individual widget behavior
- User interactions
- State changes
- Target: 70% coverage

### Integration Tests
- Complete user flows
- Navigation paths
- API integration
- Target: Key user journeys

### Performance Tests
- Frame rendering time
- Memory leaks
- Network efficiency
- Battery consumption

---

## 🚀 Deployment Checklist

### Pre-Release
- [ ] Update version number
- [ ] Test on multiple devices
- [ ] Check all permissions
- [ ] Verify API endpoints
- [ ] Test offline functionality
- [ ] Review analytics events
- [ ] Update screenshots
- [ ] Prepare release notes

### Android Release
- [ ] Generate signed APK/AAB
- [ ] Test on Android 5.0+
- [ ] Verify ProGuard rules
- [ ] Check app size
- [ ] Upload to Play Console
- [ ] Set up staged rollout

### iOS Release
- [ ] Archive and validate
- [ ] Test on iOS 12.0+
- [ ] Check App Store guidelines
- [ ] Prepare metadata
- [ ] Upload to App Store Connect
- [ ] Submit for review

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: Development Team
