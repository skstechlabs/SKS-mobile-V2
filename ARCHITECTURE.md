# SKS Mobile Application - Complete Architecture Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Mobile Application](#mobile-application)
4. [Backend Services](#backend-services)
5. [Database Architecture](#database-architecture)
6. [Authentication Flows](#authentication-flows)
7. [Key User Flows](#key-user-flows)
8. [External Integrations](#external-integrations)
9. [Deployment Architecture](#deployment-architecture)

---

## 1. System Overview

**SKS Mobile Application** is a spiritual learning platform built with Flutter (mobile) and Node.js microservices (backend). The system enables users to:
- Learn through progressive video courses (Level 1-5)
- Track meditation sessions and streaks
- Receive push notifications and reminders
- Register for events and gatherings
- Purchase spiritual merchandise
- Access daily quotes and wallpapers

### Technology Stack

**Mobile App:**
- Framework: Flutter 3.0+
- Language: Dart
- State Management: flutter_bloc, ChangeNotifier
- Navigation: go_router
- HTTP Client: dio with retry logic

**Backend:**
- Runtime: Node.js 18+
- Framework: Express.js
- Database: Microsoft SQL Server
- Cache: Redis
- Authentication: Firebase Admin SDK

**External Services:**
- Firebase (Authentication)
- OneSignal (Push Notifications)
- MSG91 (OTP Service)
- Cloudflare Stream (Video Hosting)

---

## 2. High-Level Architecture


```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MOBILE APPLICATION (Flutter)                        │
│                                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   Home   │  │Learnings │  │  Events  │  │  Guruji  │  │ Profile  │    │
│  │          │  │ (Videos) │  │          │  │ Connect  │  │          │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │              API Service (Dio + Firebase Auth)                     │    │
│  │              Base URL: https://app.sivakundalini.org               │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │ HTTPS + Firebase ID Token
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY (Port 3000)                               │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  Rate Limiting │ CORS │ JWT Verification │ Request Routing         │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└───┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬───────────┘
    │         │         │         │         │         │         │
    ▼         ▼         ▼         ▼         ▼         ▼         ▼
┌─────────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────────┐
│ Google  │ │ OTP │ │Notif│ │Class│ │Event│ │User │ │ Mobile  │
│ Login   │ │Login│ │ Svc │ │ Svc │ │ Svc │ │ Svc │ │ Backend │
│ :4000   │ │:4001│ │:3007│ │:3014│ │     │ │     │ │  :3008  │
└────┬────┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └────┬────┘
     │         │        │        │        │        │         │
     └─────────┴────────┴────────┴────────┴────────┴─────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MICROSOFT SQL SERVER DATABASES                            │
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌─────────────────────┐          │
│  │   sivoham    │    │   classes    │    │ sivoham_notifications│          │
│  │              │    │              │    │                     │          │
│  │ • users      │    │ • classes    │    │ • user_notifications│          │
│  │ • events     │    │ • class_days │    │ • reminders         │          │
│  │ • merchandise│    │ • enrollments│    │                     │          │
│  │ • purchases  │    │ • progress   │    │                     │          │
│  │ • donations  │    │ • analytics  │    │                     │          │
│  └──────────────┘    └──────────────┘    └─────────────────────┘          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL INTEGRATIONS                                 │
│                                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Firebase │  │ OneSignal│  │  MSG91   │  │Cloudflare│  │   AWS    │    │
│  │   Auth   │  │   Push   │  │   OTP    │  │  Stream  │  │    S3    │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Mobile Application

### 3.1 Application Structure


```
SKS-mobile-V2/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── router.dart              # Navigation configuration (go_router)
│   │   ├── theme/
│   │   │   └── app_theme.dart       # App-wide theming
│   │   ├── services/
│   │   │   ├── api_service.dart     # Centralized API client (Dio)
│   │   │   ├── auth_state.dart      # Global auth state management
│   │   │   ├── onesignal_service.dart  # Push notifications
│   │   │   ├── audio_handler.dart   # Background audio playback
│   │   │   ├── connectivity_service.dart  # Network monitoring
│   │   │   └── localization_service.dart  # Multi-language support
│   │   ├── constants/
│   │   │   └── app_env.dart         # Environment configuration
│   │   └── widgets/
│   │       └── main_scaffold.dart   # Bottom navigation
│   └── features/
│       ├── splash/                  # Splash screen
│       ├── language/                # Language selection
│       ├── auth/                    # Login, profile setup, permissions
│       ├── home/                    # Dashboard
│       ├── learnings/               # Video classes (Level 1-5)
│       ├── guruji_connect/          # Guru journey, gatherings
│       ├── events/                  # Event listings & registration
│       ├── notifications/           # In-app notifications
│       ├── profile/                 # User profile & multi-profile
│       ├── reminders/               # Meditation reminders
│       ├── meditation/              # Timer, history, streaks
│       ├── settings/                # App settings
│       └── audio/                   # Songs & chants playback
```

### 3.2 Key Dependencies

```yaml
dependencies:
  # Core
  flutter: sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Navigation
  go_router: ^12.0.0
  
  # HTTP & API
  dio: ^5.4.0
  http: ^1.1.0
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  
  # Push Notifications
  onesignal_flutter: ^5.2.5
  
  # Audio
  just_audio: ^0.9.36
  audio_service: ^0.18.12
  
  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI & Media
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  
  # Connectivity
  connectivity_plus: ^5.0.2
  
  # Localization
  flutter_localizations: sdk: flutter
  intl: ^0.18.1
```

### 3.3 API Service Architecture


```
┌─────────────────────────────────────────────────────────────────┐
│                      ApiService (Singleton)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Base URL: https://app.sivakundalini.org                        │
│  Timeout: 45 seconds                                             │
│  Retry Logic: 2 retries with exponential backoff (1s, 2s)       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Request Interceptor                       │    │
│  │  1. Get Firebase ID Token (cached or refreshed)       │    │
│  │  2. Add Authorization: Bearer <token>                 │    │
│  │  3. Add Content-Type: application/json                │    │
│  └────────────────────────────────────────────────────────┘    │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              HTTP Request (Dio)                        │    │
│  └────────────────────────────────────────────────────────┘    │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Error Interceptor                         │    │
│  │  • Connection timeout → Retry                          │    │
│  │  • Send timeout → Retry                                │    │
│  │  • Receive timeout → Retry                             │    │
│  │  • 401 Unauthorized → Refresh token & retry            │    │
│  │  • Other errors → Throw exception                      │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

API Methods:
├── loginWithGoogle(mobile, email, name, photo, idToken)
├── loginWithPhone(accessToken)
├── updateProfile(uid, profileData)
├── getClasses()
├── getClassDays(classId)
├── getVideoStreamUrl(dayId)
├── updateDayProgress(dayId, progressData)
├── getEvents()
├── registerForEvent(eventId)
├── getMerchandise()
├── createPurchase(purchaseData)
├── getNotifications()
├── markNotificationRead(notificationId)
├── getReminders()
├── createReminder(reminderData)
├── saveMeditationSession(sessionData)
└── getMeditationStats()
```

### 3.4 Authentication State Management

```
┌─────────────────────────────────────────────────────────────────┐
│                   AuthState (ChangeNotifier)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  State Variables:                                                │
│  • User? currentUser                                             │
│  • bool isAuthenticated                                          │
│  • bool isLoading                                                │
│  • String? errorMessage                                          │
│                                                                  │
│  Methods:                                                        │
│  • setUser(User user)                                            │
│  • clearUser()                                                   │
│  • updateUser(Map<String, dynamic> updates)                      │
│  • checkAuthStatus()                                             │
│  • logout()                                                      │
│                                                                  │
│  Persistence:                                                    │
│  • SharedPreferences (user data caching)                         │
│  • FlutterSecureStorage (sensitive tokens)                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Backend Services

### 4.1 Service Overview

| Service | Port | Purpose | Database | Key Routes |
|---------|------|---------|----------|------------|
| **API Gateway** | 3000 | Central routing, rate limiting | None | All /api/* routes |
| **Google Login Service** | 4000 | Google OAuth authentication | sivoham | /auth/google/login |
| **OTP Login Service** | 4001 | Phone OTP authentication | sivoham | /api/otp/send, /api/otp/verify |
| **Notification Service** | 3007 | Push notifications, reminders | sivoham_notifications | /api/notifications, /api/reminders |
| **Classes Service** | 3014 | Video streaming, progression | classes | /api/classes, /api/level-progression |
| **Mobile Backend** | 3008 | Core business logic | sivoham | /api/events, /api/merchandise, /api/user |
| **Notification Dashboard** | 3008 | Admin notification UI | sivoham_notifications | Web interface |

### 4.2 API Gateway Architecture


```
┌─────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY (Port 3000)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Middleware Stack:                                                       │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ 1. Helmet (Security Headers)                                   │    │
│  │ 2. CORS (Cross-Origin Resource Sharing)                        │    │
│  │ 3. Body Parser (JSON, URL-encoded)                             │    │
│  │ 4. Rate Limiter (100 req/15min per IP)                         │    │
│  │ 5. Request Logger (Morgan)                                     │    │
│  │ 6. JWT Verification (Optional)                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Route Mapping (http-proxy-middleware):                                 │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ /api/auth/login/google → http://localhost:4000                 │    │
│  │ /api/auth/login/phone  → http://localhost:4001                 │    │
│  │ /api/otp/*             → http://localhost:4001                 │    │
│  │ /api/notifications/*   → http://localhost:3007                 │    │
│  │ /api/reminders/*       → http://localhost:3007                 │    │
│  │ /api/classes/*         → http://localhost:3014                 │    │
│  │ /api/classes-v2/*      → http://localhost:3014                 │    │
│  │ /api/level-progression/* → http://localhost:3014               │    │
│  │ /api/events/*          → http://localhost:3008                 │    │
│  │ /api/merchandise/*     → http://localhost:3008                 │    │
│  │ /api/purchases/*       → http://localhost:3008                 │    │
│  │ /api/donations/*       → http://localhost:3008                 │    │
│  │ /api/user/*            → http://localhost:3008                 │    │
│  │ /api/profiles/*        → http://localhost:3008                 │    │
│  │ /api/gatherings/*      → http://localhost:3008                 │    │
│  │ /api/meditation/*      → http://localhost:3008                 │    │
│  │ /api/wallpapers/*      → http://localhost:3008                 │    │
│  │ /api/quotes/*          → http://localhost:3008                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Features:                                                               │
│  • Swagger Documentation (/api-docs)                                    │
│  • Health Check (/health)                                               │
│  • Request/Response Logging                                             │
│  • Error Handling                                                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Mobile Backend Service (Port 3008)

**Core Modules:**

```
sks-mobile-backend-service/
├── server.js                        # Main entry point
├── config/
│   ├── database.js                  # MSSQL connection pool
│   ├── schema.js                    # Database schema initialization
│   └── firebase.js                  # Firebase Admin SDK
├── middleware/
│   ├── firebaseAuth.js              # Token verification
│   ├── checkUserBlocked.js          # User blocking check
│   └── errorHandler.js              # Global error handling
├── routes/
│   ├── user.js                      # User profile CRUD
│   ├── profiles.js                  # Multi-profile system
│   ├── events.js                    # Event management
│   ├── event-attendance.js          # Attendance tracking
│   ├── event-seat-registration.js   # Seat allocation
│   ├── merchandise.js               # Product catalog
│   ├── purchases.js                 # Order management
│   ├── donations.js                 # Donation tracking
│   ├── gatherings.js                # Past gatherings
│   ├── meditation.js                # Session tracking
│   ├── reminders.js                 # Meditation reminders
│   ├── quotes.js                    # Daily quotes
│   ├── wallpapers.js                # Wallpaper downloads
│   ├── kalpataru-experiences.js     # User experiences
│   ├── admin.js                     # Admin operations
│   └── health.js                    # Health check
└── utils/
    ├── logger.js                    # Winston logger
    └── processHandlers.js           # Graceful shutdown
```

**Key Features:**
- Firebase token authentication on all routes
- User blocking middleware
- File upload handling (multer)
- Swagger API documentation
- Comprehensive error handling
- Database connection pooling

### 4.4 Classes Service (Port 3014)


**Video Streaming & Progressive Learning Platform**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CLASSES SERVICE ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Video Storage: Cloudflare Stream (HLS)                                 │
│  Cache Layer: Redis                                                     │
│  Database: classes (MSSQL)                                              │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    LEVEL STRUCTURE                             │    │
│  │                                                                │    │
│  │  Level 1 (Auto-unlocked)                                       │    │
│  │  ├── Day 1 (Unlocked)                                          │    │
│  │  ├── Day 2 (Unlocked after Day 1 + 24h)                        │    │
│  │  └── Day 3 (Unlocked after Day 2 + 24h)                        │    │
│  │                                                                │    │
│  │  Level 2 (Unlocked after Level 1 complete + 24h)               │    │
│  │  ├── Day 1                                                     │    │
│  │  ├── Day 2                                                     │    │
│  │  └── Day 3                                                     │    │
│  │                                                                │    │
│  │  Level 3 (Unlocked after Level 2 + Meditation Test)            │    │
│  │  ├── Day 1                                                     │    │
│  │  ├── Day 2                                                     │    │
│  │  └── Day 3                                                     │    │
│  │                                                                │    │
│  │  Level 4 (Unlocked after Level 3 complete + 24h)               │    │
│  │  ├── Day 1                                                     │    │
│  │  ├── Day 2                                                     │    │
│  │  └── Day 3                                                     │    │
│  │                                                                │    │
│  │  Level 5 (Unlocked after Level 4 complete + 24h)               │    │
│  │  ├── Day 1                                                     │    │
│  │  ├── Day 2                                                     │    │
│  │  └── Day 3                                                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Video Features:                                                         │
│  • Multi-language audio tracks (Telugu, Hindi, English)                 │
│  • HLS adaptive streaming                                               │
│  • Signed URLs with expiration                                          │
│  • 90% completion requirement                                           │
│  • Anti-download protection                                             │
│  • Watch analytics tracking                                             │
│                                                                          │
│  API Endpoints:                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ GET  /api/classes                    # List all levels        │    │
│  │ GET  /api/classes/:id/days           # Get days for level     │    │
│  │ GET  /api/classes/:id/days/:dayId    # Get day details        │    │
│  │ POST /api/classes/:id/enroll         # Enroll in level        │    │
│  │ GET  /api/classes/:id/progress       # Get user progress      │    │
│  │ POST /api/classes/days/:dayId/start  # Start watching         │    │
│  │ POST /api/classes/days/:dayId/progress # Update progress      │    │
│  │ POST /api/classes/days/:dayId/complete # Mark complete        │    │
│  │ GET  /api/level-progression          # Get progression status │    │
│  │ POST /api/level-progression/unlock   # Unlock next level      │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Database Tables:**

```sql
-- Core tables
classes                    -- Level configuration (5 levels)
class_days                 -- Day videos (3 days × 5 levels = 15 videos)
user_class_enrollments     -- User enrollment tracking
user_day_progress          -- Day completion status (HOT TABLE)
user_level_access          -- Level unlock status

-- Analytics tables
video_watch_events         -- Detailed event log (start, pause, seek, complete)
video_watch_sessions       -- Session tracking
video_analytics_summary    -- Aggregated metrics
video_security_events      -- Security violations

-- Progression
meditation_tests           -- Level 2→3 progression test
```

### 4.5 Notification Service (Port 3007)


```
┌─────────────────────────────────────────────────────────────────────────┐
│                   NOTIFICATION SERVICE (Port 3007)                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Push Provider: OneSignal                                                │
│  Database: sivoham_notifications (MSSQL)                                │
│  Cache: Redis (optional)                                                │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │              NOTIFICATION FLOW                                 │    │
│  │                                                                │    │
│  │  1. Backend Event Trigger                                      │    │
│  │     (Day unlocked, Level unlocked, Event reminder, etc.)       │    │
│  │                    ▼                                           │    │
│  │  2. Create Notification in Database                            │    │
│  │     INSERT INTO user_notifications                             │    │
│  │                    ▼                                           │    │
│  │  3. Call OneSignal API                                         │    │
│  │     POST https://api.onesignal.com/notifications               │    │
│  │     Body: {                                                    │    │
│  │       app_id: "b89d199e-15be-4343-9e04-640c43f355e9",         │    │
│  │       include_external_user_ids: ["user_uid"],                │    │
│  │       contents: { en: "message" },                            │    │
│  │       headings: { en: "title" },                              │    │
│  │       data: { action_url: "/path" }                           │    │
│  │     }                                                          │    │
│  │                    ▼                                           │    │
│  │  4. OneSignal Delivers to Device                               │    │
│  │                    ▼                                           │    │
│  │  5. User Taps Notification                                     │    │
│  │                    ▼                                           │    │
│  │  6. App Navigates to action_url                                │    │
│  │                    ▼                                           │    │
│  │  7. Mark Notification as Read                                  │    │
│  │     PUT /api/notifications/:id/read                            │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Notification Types:                                                     │
│  • day_unlocked       - New day available                               │
│  • level_unlocked     - New level available                             │
│  • reminder           - Meditation reminder                             │
│  • event              - Event registration/update                       │
│  • class              - Class announcement                              │
│  • achievement        - User milestone                                  │
│  • system             - System message                                  │
│  • announcement       - General announcement                            │
│                                                                          │
│  API Endpoints:                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ GET  /api/notifications              # List user notifications │    │
│  │ PUT  /api/notifications/:id/read     # Mark as read           │    │
│  │ PUT  /api/notifications/read-all     # Mark all read          │    │
│  │ POST /api/notifications/test         # Test notification      │    │
│  │ POST /api/notifications/send-to-segment # Segment targeting   │    │
│  │                                                                │    │
│  │ GET  /api/reminders                  # List reminders         │    │
│  │ POST /api/reminders                  # Create reminder        │    │
│  │ PUT  /api/reminders/:id              # Update reminder        │    │
│  │ DELETE /api/reminders/:id            # Delete reminder        │    │
│  │ PATCH /api/reminders/:id/toggle      # Toggle active status   │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.6 Authentication Services

**Google Login Service (Port 4000):**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   GOOGLE LOGIN SERVICE (Port 4000)                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Authentication: Firebase Admin SDK                                      │
│  Database: sivoham (MSSQL)                                              │
│  Cache: Redis (session caching)                                         │
│                                                                          │
│  Routes:                                                                 │
│  • POST /auth/google/login    - Google OAuth login                      │
│  • POST /auth/google/logout   - Logout                                  │
│  • GET  /auth/google/verify   - Verify session                          │
│  • GET  /auth/profile         - Get user profile                        │
│  • PUT  /auth/profile         - Update profile                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**OTP Login Service (Port 4001):**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    OTP LOGIN SERVICE (Port 4001)                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  OTP Provider: MSG91                                                     │
│  Database: sivoham (MSSQL)                                              │
│                                                                          │
│  Routes:                                                                 │
│  • POST /api/auth/login/phone - Phone OTP login                         │
│  • POST /api/otp/send         - Send OTP via MSG91                      │
│  • POST /api/otp/verify       - Verify OTP                              │
│                                                                          │
│  MSG91 Integration:                                                      │
│  • Widget ID: Embedded in mobile app                                    │
│  • Auth Key: Server-side verification                                   │
│  • Flow: Widget → OTP → access_token → Backend verification             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Database Architecture

### 5.1 Database Overview


```
┌─────────────────────────────────────────────────────────────────────────┐
│              MICROSOFT SQL SERVER (localhost\SQLEXPRESS)                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │                    DATABASE: sivoham                         │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │                                                              │      │
│  │  Core Tables:                                                │      │
│  │  • users                  - User accounts & profiles         │      │
│  │  • user_permissions       - Permission tracking              │      │
│  │  • user_block_history     - User blocking records            │      │
│  │                                                              │      │
│  │  Events:                                                     │      │
│  │  • events                 - Event listings                   │      │
│  │  • event_registrations    - User registrations               │      │
│  │  • event_attendance       - Attendance tracking              │      │
│  │  • event_seat_registration - Seat allocation                 │      │
│  │  • event_violations       - Violation tracking               │      │
│  │  • spot_registrations     - Spot registration                │      │
│  │  • maha_sivaratri_*       - Special event tables             │      │
│  │                                                              │      │
│  │  E-Commerce:                                                 │      │
│  │  • merchandise            - Product catalog (29 items)       │      │
│  │  • purchases              - Order management                 │      │
│  │  • donations              - Donation tracking                │      │
│  │                                                              │      │
│  │  Content:                                                    │      │
│  │  • gatherings             - Past gatherings                  │      │
│  │  • quotes                 - Daily quotes                     │      │
│  │  • wallpapers             - Wallpaper downloads              │      │
│  │  • kalpataru_experiences  - User experiences                 │      │
│  │                                                              │      │
│  │  Meditation:                                                 │      │
│  │  • meditation_sessions    - Session tracking                 │      │
│  │  • meditation_stats       - User statistics                  │      │
│  │                                                              │      │
│  │  Profiles:                                                   │      │
│  │  • profiles               - Multi-profile system             │      │
│  │                                                              │      │
│  │  Utilities:                                                  │      │
│  │  • mobile_searches        - Search history                   │      │
│  │  • dynamic_forms          - Form configurations              │      │
│  │                                                              │      │
│  │  Used By:                                                    │      │
│  │  • sks-mobile-backend-service (Port 3008)                    │      │
│  │  • sks-google-login-service (Port 4000)                      │      │
│  │  • sks-otp-login-service (Port 4001)                         │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │                    DATABASE: classes                         │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │                                                              │      │
│  │  Core Tables:                                                │      │
│  │  • classes                - Level configuration (5 levels)   │      │
│  │  • class_days             - Day videos (15 videos total)     │      │
│  │  • user_class_enrollments - Enrollment tracking              │      │
│  │  • user_day_progress      - Day completion (HOT TABLE)       │      │
│  │  • user_level_access      - Level unlock status              │      │
│  │                                                              │      │
│  │  Analytics:                                                  │      │
│  │  • video_watch_events     - Event log (start, pause, etc.)   │      │
│  │  • video_watch_sessions   - Session tracking                 │      │
│  │  • video_analytics_summary - Aggregated metrics              │      │
│  │  • video_security_events  - Security violations              │      │
│  │                                                              │      │
│  │  Progression:                                                │      │
│  │  • meditation_tests       - Level 2→3 test                   │      │
│  │                                                              │      │
│  │  Used By:                                                    │      │
│  │  • sks-classes-service (Port 3014)                           │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │              DATABASE: sivoham_notifications                 │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │                                                              │      │
│  │  Tables:                                                     │      │
│  │  • user_notifications     - In-app notifications             │      │
│  │  • reminders              - Meditation reminders             │      │
│  │                                                              │      │
│  │  Used By:                                                    │      │
│  │  • sks-notification-service (Port 3007)                      │      │
│  │  • sks-notification-dashboard (Port 3008)                    │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Key Table Schemas

**users table (sivoham):**

```sql
CREATE TABLE users (
    uid NVARCHAR(128) PRIMARY KEY,              -- Firebase UID or "phone_<mobile>"
    mobile NVARCHAR(20) NULL,                   -- Phone number
    email NVARCHAR(100) NULL UNIQUE,            -- Email address
    name NVARCHAR(100) NULL,                    -- Full name
    photo NVARCHAR(500) NULL,                   -- Profile photo URL
    gender NVARCHAR(10) NULL,                   -- Male/Female/Other
    date_of_birth DATE NULL,                    -- DOB
    age INT NULL,                               -- Calculated age
    address NVARCHAR(MAX) NULL,                 -- Address
    city NVARCHAR(100) NULL,                    -- City
    state NVARCHAR(100) NULL,                   -- State
    pincode NVARCHAR(6) NULL,                   -- Pincode
    country NVARCHAR(100) DEFAULT 'India',      -- Country
    profession NVARCHAR(100) NULL,              -- Profession
    preferred_language NVARCHAR(50) NULL,       -- Language preference
    how_did_you_know NVARCHAR(200) NULL,        -- Referral source
    referrer_name NVARCHAR(100) NULL,           -- Referrer name
    referrer_mobile NVARCHAR(20) NULL,          -- Referrer mobile
    auth_provider NVARCHAR(20) NOT NULL,        -- 'phone' or 'google'
    is_profile_complete BIT DEFAULT 0,          -- Profile completion flag
    permissions_granted BIT DEFAULT 0,          -- Permissions flag
    is_active BIT DEFAULT 1,                    -- Active status
    is_blocked BIT DEFAULT 0,                   -- Blocked status
    block_reason NVARCHAR(MAX) NULL,            -- Block reason
    created_at DATETIME2 DEFAULT GETDATE(),     -- Creation timestamp
    updated_at DATETIME2 DEFAULT GETDATE(),     -- Update timestamp
    last_login_at DATETIME2 NULL                -- Last login timestamp
);

-- Indexes
CREATE INDEX idx_users_mobile ON users(mobile);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);
```

**classes table (classes):**

```sql
CREATE TABLE classes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    level NVARCHAR(50) NOT NULL,                -- "Level 1", "Level 2", etc.
    title NVARCHAR(200) NOT NULL,               -- Class title
    description NVARCHAR(MAX) NOT NULL,         -- Description
    duration NVARCHAR(100),                     -- Duration text
    prerequisites NVARCHAR(MAX),                -- Prerequisites
    is_online BIT DEFAULT 1,                    -- Online flag
    is_residential BIT DEFAULT 0,               -- Residential flag
    image_url NVARCHAR(500),                    -- Thumbnail URL
    video_url NVARCHAR(500),                    -- Intro video URL
    price DECIMAL(10, 2) DEFAULT 0.00,          -- Price
    max_participants INT NULL,                  -- Max participants
    is_active BIT DEFAULT 1,                    -- Active status
    display_order INT DEFAULT 0,                -- Display order
    level_number INT NOT NULL DEFAULT 1,        -- Level number (1-5)
    total_days INT NOT NULL DEFAULT 3,          -- Total days per level
    cloudflare_account_id NVARCHAR(255),        -- Cloudflare account
    completion_criteria NVARCHAR(MAX),          -- JSON criteria
    day_unlock_hours INT DEFAULT 24,            -- Hours to unlock next day
    level_unlock_hours INT DEFAULT 24,          -- Hours to unlock next level
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
```

**user_notifications table (sivoham_notifications):**

```sql
CREATE TABLE user_notifications (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_uid NVARCHAR(128) NOT NULL,            -- User UID
    type NVARCHAR(50) NOT NULL,                 -- Notification type
    title NVARCHAR(255) NOT NULL,               -- Title
    message NVARCHAR(MAX) NOT NULL,             -- Message body
    action_url NVARCHAR(500) NULL,              -- Deep link URL
    action_data NVARCHAR(MAX) NULL,             -- JSON action data
    is_read BIT DEFAULT 0,                      -- Read status
    push_sent BIT DEFAULT 0,                    -- Push sent flag
    created_at DATETIME2 DEFAULT GETDATE(),
    read_at DATETIME2 NULL                      -- Read timestamp
);

-- Indexes
CREATE INDEX idx_notifications_user_uid ON user_notifications(user_uid);
CREATE INDEX idx_notifications_is_read ON user_notifications(is_read);
CREATE INDEX idx_notifications_created_at ON user_notifications(created_at);
```

---

## 6. Authentication Flows

### 6.1 Google Sign-In Flow


```
┌─────────────────────────────────────────────────────────────────────────┐
│                      GOOGLE SIGN-IN FLOW                                 │
└─────────────────────────────────────────────────────────────────────────┘

Mobile App                    Firebase                Backend Service
    │                            │                          │
    │  1. User taps "Google"     │                          │
    │─────────────────────────>  │                          │
    │                            │                          │
    │  2. GoogleSignIn.signIn()  │                          │
    │─────────────────────────>  │                          │
    │                            │                          │
    │  3. Google OAuth Dialog    │                          │
    │<─────────────────────────  │                          │
    │                            │                          │
    │  4. User authenticates     │                          │
    │─────────────────────────>  │                          │
    │                            │                          │
    │  5. Google Credential      │                          │
    │<─────────────────────────  │                          │
    │                            │                          │
    │  6. signInWithCredential() │                          │
    │─────────────────────────>  │                          │
    │                            │                          │
    │  7. Firebase User + Token  │                          │
    │<─────────────────────────  │                          │
    │                            │                          │
    │  8. POST /api/auth/login/google                       │
    │     Authorization: Bearer <firebase_token>            │
    │     Body: { mobile, email, name, photo }              │
    │───────────────────────────────────────────────────────>
    │                            │                          │
    │                            │  9. Verify Token         │
    │                            │<─────────────────────────│
    │                            │                          │
    │                            │  10. Token Valid + UID   │
    │                            │─────────────────────────>│
    │                            │                          │
    │                            │  11. Upsert User in DB   │
    │                            │     (uid, email, name)   │
    │                            │                          │
    │  12. User Data + is_new_user                          │
    │<───────────────────────────────────────────────────────
    │                            │                          │
    │  13. AuthState.setUser()   │                          │
    │  14. Save to SharedPrefs   │                          │
    │                            │                          │
    │  15. OneSignal.login(uid)  │                          │
    │     (Link device to user)  │                          │
    │                            │                          │
    │  16. Navigate to:          │                          │
    │      - Profile Setup (new) │                          │
    │      - Home (existing)     │                          │
    │                            │                          │
```

### 6.2 Phone OTP Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PHONE OTP FLOW                                    │
└─────────────────────────────────────────────────────────────────────────┘

Mobile App                    MSG91                   Backend Service
    │                            │                          │
    │  1. User enters phone      │                          │
    │                            │                          │
    │  2. Show MSG91 Widget      │                          │
    │─────────────────────────>  │                          │
    │                            │                          │
    │  3. Widget sends OTP       │                          │
    │                            │─────> SMS to User        │
    │                            │                          │
    │  4. User enters OTP        │                          │
    │─────────────────────────>  │                          │
    │                            │                          │
    │  5. MSG91 verifies OTP     │                          │
    │                            │                          │
    │  6. access_token returned  │                          │
    │<─────────────────────────  │                          │
    │                            │                          │
    │  7. POST /api/auth/login/phone                        │
    │     Body: { access_token }                            │
    │───────────────────────────────────────────────────────>
    │                            │                          │
    │                            │  8. Verify access_token  │
    │                            │<─────────────────────────│
    │                            │                          │
    │                            │  9. Mobile number        │
    │                            │─────────────────────────>│
    │                            │                          │
    │                            │  10. Upsert User in DB   │
    │                            │      uid = "phone_<mobile>"
    │                            │                          │
    │  11. User Data + is_new_user                          │
    │<───────────────────────────────────────────────────────
    │                            │                          │
    │  12. AuthState.setUser()   │                          │
    │  13. Save to SharedPrefs   │                          │
    │                            │                          │
    │  14. OneSignal.login(uid)  │                          │
    │                            │                          │
    │  15. Navigate to:          │                          │
    │      - Profile Setup (new) │                          │
    │      - Home (existing)     │                          │
    │                            │                          │
```

### 6.3 Authenticated API Request Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   AUTHENTICATED API REQUEST FLOW                         │
└─────────────────────────────────────────────────────────────────────────┘

Mobile App              API Gateway           Microservice         Firebase
    │                       │                      │                   │
    │  1. API call          │                      │                   │
    │  (e.g., getClasses()) │                      │                   │
    │                       │                      │                   │
    │  2. Get Firebase      │                      │                   │
    │     ID Token (cached) │                      │                   │
    │                       │                      │                   │
    │  3. Add Authorization │                      │                   │
    │     Bearer <token>    │                      │                   │
    │                       │                      │                   │
    │  4. HTTP Request      │                      │                   │
    │──────────────────────>│                      │                   │
    │                       │                      │                   │
    │                       │  5. Rate Limit Check │                   │
    │                       │  6. CORS Check       │                   │
    │                       │                      │                   │
    │                       │  7. Forward Request  │                   │
    │                       │─────────────────────>│                   │
    │                       │                      │                   │
    │                       │                      │  8. Verify Token  │
    │                       │                      │──────────────────>│
    │                       │                      │                   │
    │                       │                      │  9. Decoded Token │
    │                       │                      │     (uid, email)  │
    │                       │                      │<──────────────────│
    │                       │                      │                   │
    │                       │                      │  10. Check if     │
    │                       │                      │      user blocked │
    │                       │                      │                   │
    │                       │                      │  11. Execute      │
    │                       │                      │      business     │
    │                       │                      │      logic        │
    │                       │                      │                   │
    │                       │  12. Response        │                   │
    │                       │<─────────────────────│                   │
    │                       │                      │                   │
    │  13. Response         │                      │                   │
    │<──────────────────────│                      │                   │
    │                       │                      │                   │
    │  14. Handle Response  │                      │                   │
    │      (success/error)  │                      │                   │
    │                       │                      │                   │
```

---

## 7. Key User Flows

### 7.1 First-Time User Registration


```
┌─────────────────────────────────────────────────────────────────────────┐
│                   FIRST-TIME USER REGISTRATION FLOW                      │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Splash Screen│  (Check auth status, initialize services)
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Language Selection│  (Select preferred language: English/Telugu/Hindi)
└──────┬───────────┘
       │
       ▼
┌──────────────┐
│ Login Screen │  (Choose: Google Sign-In or Phone OTP)
└──────┬───────┘
       │
       ├─────────────────────────────────────┐
       │                                     │
       ▼                                     ▼
┌──────────────┐                    ┌──────────────┐
│ Google OAuth │                    │  Phone OTP   │
│ (Firebase)   │                    │  (MSG91)     │
└──────┬───────┘                    └──────┬───────┘
       │                                     │
       └─────────────┬───────────────────────┘
                     │
                     ▼
            ┌────────────────┐
            │ Backend Login  │  (Create user account)
            │ is_new_user=true│
            └────────┬───────┘
                     │
                     ▼
            ┌────────────────────┐
            │ Profile Setup      │  (Name, DOB, Gender, Address, etc.)
            │ is_profile_complete│
            └────────┬───────────┘
                     │
                     ▼
            ┌────────────────────┐
            │ Permission Screen  │  (Camera, Microphone, Notifications)
            │ permissions_granted│
            └────────┬───────────┘
                     │
                     ▼
            ┌────────────────────┐
            │ OneSignal Setup    │  (Link device to user UID)
            │ OneSignal.login()  │
            └────────┬───────────┘
                     │
                     ▼
            ┌────────────────────┐
            │   Home Screen      │  (Dashboard with features)
            └────────────────────┘
```

### 7.2 Video Learning Flow (Progressive Unlocking)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      VIDEO LEARNING FLOW                                 │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│  Home Screen │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Learnings Tab    │  (View all levels: Level 1-5)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Select Level 1   │  (Auto-unlocked for all users)
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Days List Screen                                                 │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐               │
│  │  Day 1     │  │  Day 2     │  │  Day 3     │               │
│  │  Unlocked  │  │  Locked    │  │  Locked    │               │
│  │  ✓ Watch   │  │  🔒        │  │  🔒        │               │
│  └────────────┘  └────────────┘  └────────────┘               │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Video Player Screen (Day 1)                                      │
│                                                                  │
│  • HLS streaming (Cloudflare)                                   │
│  • Multi-language audio tracks (Telugu/Hindi/English)           │
│  • Progress tracking (every 10 seconds)                         │
│  • 90% completion required                                      │
│  • Anti-download protection                                     │
│                                                                  │
│  [========================================] 90%                  │
│                                                                  │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────┐
│ Day 1 Completed  │  (Mark complete, update progress)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Wait 24 Hours    │  (Day unlock timer)
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Day 2 Unlocked                                                   │
│  • Push notification sent                                        │
│  • In-app notification created                                   │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────┐
│ Watch Day 2      │  (Repeat process)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Watch Day 3      │  (Complete Level 1)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Wait 24 Hours    │  (Level unlock timer)
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Level 2 Unlocked                                                 │
│  • Push notification sent                                        │
│  • Congratulations message                                       │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────┐
│ Continue to      │  (Repeat for Level 2-5)
│ Level 2          │
└──────────────────┘

Special Case: Level 2 → Level 3
┌──────────────────────────────────────────────────────────────────┐
│ Complete Level 2 → Take Meditation Test → Pass → Level 3 Unlocked│
└──────────────────────────────────────────────────────────────────┘
```

### 7.3 Push Notification Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      PUSH NOTIFICATION FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

Backend Event                OneSignal              Mobile App
    │                            │                      │
    │  1. Trigger Event          │                      │
    │  (Day unlocked, etc.)      │                      │
    │                            │                      │
    │  2. Create Notification    │                      │
    │     in Database            │                      │
    │                            │                      │
    │  3. POST /notifications    │                      │
    │     to OneSignal API       │                      │
    │─────────────────────────>  │                      │
    │                            │                      │
    │  4. OneSignal processes    │                      │
    │     and delivers           │                      │
    │                            │                      │
    │                            │  5. Push delivered   │
    │                            │─────────────────────>│
    │                            │                      │
    │                            │  6. User sees        │
    │                            │     notification     │
    │                            │                      │
    │                            │  7. User taps        │
    │                            │                      │
    │                            │  8. App opens        │
    │                            │     (foreground/     │
    │                            │      background)     │
    │                            │                      │
    │                            │  9. Navigate to      │
    │                            │     action_url       │
    │                            │     (e.g., /learnings│
    │                            │      /class/1/day/2) │
    │                            │                      │
    │  10. PUT /api/notifications/:id/read              │
    │<───────────────────────────────────────────────────
    │                            │                      │
    │  11. Mark as read in DB    │                      │
    │                            │                      │
```

### 7.4 Meditation Session Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      MEDITATION SESSION FLOW                             │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│  Home Screen │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Meditation Timer │  (Select duration: 5, 10, 15, 20, 30, 45, 60 min)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Start Session    │  (Background audio plays, timer starts)
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Session Running                                                  │
│                                                                  │
│  • Background audio service (audio_service)                      │
│  • Timer countdown                                               │
│  • Notification shows progress                                   │
│  • App can be minimized                                          │
│                                                                  │
│  [========================================] 15:00                 │
│                                                                  │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────┐
│ Session Complete │  (Audio stops, show completion screen)
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Save Session to Backend                                          │
│  POST /api/meditation/sessions                                   │
│  Body: {                                                         │
│    duration_minutes: 15,                                         │
│    completed_at: "2024-01-15T10:30:00Z"                         │
│  }                                                               │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Update Statistics                                                │
│  • Total sessions count                                          │
│  • Total meditation time                                         │
│  • Current streak (consecutive days)                             │
│  • Longest streak                                                │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────┐
│ Show Stats       │  (Display achievements, streaks)
└──────────────────┘
```

---

## 8. External Integrations

### 8.1 Firebase Authentication


```
┌─────────────────────────────────────────────────────────────────────────┐
│                      FIREBASE INTEGRATION                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Purpose: User authentication (Google Sign-In)                           │
│                                                                          │
│  Mobile App:                                                             │
│  • firebase_core: ^2.24.2                                               │
│  • firebase_auth: ^4.16.0                                               │
│  • google_sign_in: ^6.1.5                                               │
│                                                                          │
│  Backend:                                                                │
│  • firebase-admin: ^11.11.0                                             │
│  • Service Account Credentials (JSON)                                   │
│                                                                          │
│  Configuration:                                                          │
│  • Project ID: sivakundalini-app                                        │
│  • API Key: (Mobile app configuration)                                  │
│  • Service Account: (Backend verification)                              │
│                                                                          │
│  Token Flow:                                                             │
│  1. User signs in with Google                                           │
│  2. Firebase returns ID token (1-hour expiry)                           │
│  3. Mobile app sends token to backend                                   │
│  4. Backend verifies token with Firebase Admin SDK                      │
│  5. Backend extracts uid, email from decoded token                      │
│  6. Token auto-refreshes on expiry                                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.2 OneSignal Push Notifications

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ONESIGNAL INTEGRATION                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Purpose: Push notifications to mobile devices                           │
│                                                                          │
│  Configuration:                                                          │
│  • App ID: b89d199e-15be-4343-9e04-640c43f355e9                         │
│  • REST API Key: os_v2_app_...                                          │
│  • API Endpoint: https://api.onesignal.com                              │
│                                                                          │
│  Mobile App Setup:                                                       │
│  1. OneSignal.initialize(appId)                                         │
│  2. OneSignal.requestPermission()                                       │
│  3. OneSignal.login(uid) - Link device to user                          │
│                                                                          │
│  Backend Integration:                                                    │
│  POST https://api.onesignal.com/notifications                           │
│  Headers:                                                                │
│    Authorization: Key os_v2_app_...                                     │
│    Content-Type: application/json                                       │
│  Body:                                                                   │
│    {                                                                     │
│      "app_id": "b89d199e-15be-4343-9e04-640c43f355e9",                 │
│      "include_external_user_ids": ["user_uid"],                         │
│      "contents": { "en": "Day 2 is now unlocked!" },                   │
│      "headings": { "en": "New Day Available" },                        │
│      "data": {                                                          │
│        "action_url": "/learnings/class/1/day/2",                       │
│        "notification_id": 123                                           │
│      }                                                                   │
│    }                                                                     │
│                                                                          │
│  Notification Handling:                                                  │
│  • Foreground: Show in-app notification                                 │
│  • Background: System notification                                      │
│  • Tap: Navigate to action_url                                          │
│                                                                          │
│  User Targeting:                                                         │
│  • External User ID (Firebase UID)                                      │
│  • Segments (Level 1 users, Active users, etc.)                         │
│  • Tags (custom user properties)                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.3 MSG91 OTP Service

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MSG91 INTEGRATION                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Purpose: Phone number authentication via OTP                            │
│                                                                          │
│  Configuration:                                                          │
│  • Auth Key: (Server-side verification)                                 │
│  • Widget ID: (Embedded in mobile app)                                  │
│  • API Endpoint: https://control.msg91.com/api/v5                       │
│                                                                          │
│  Mobile App Integration:                                                 │
│  1. User enters phone number                                            │
│  2. MSG91 Widget displays (embedded WebView)                            │
│  3. Widget sends OTP via SMS                                            │
│  4. User enters OTP in widget                                           │
│  5. Widget verifies OTP with MSG91                                      │
│  6. Widget returns access_token to app                                  │
│                                                                          │
│  Backend Verification:                                                   │
│  POST https://control.msg91.com/api/v5/otp/verify                       │
│  Headers:                                                                │
│    authkey: <MSG91_AUTH_KEY>                                            │
│  Body:                                                                   │
│    {                                                                     │
│      "access_token": "<token_from_widget>"                              │
│    }                                                                     │
│  Response:                                                               │
│    {                                                                     │
│      "type": "success",                                                 │
│      "message": "OTP verified successfully",                            │
│      "mobile": "+919876543210"                                          │
│    }                                                                     │
│                                                                          │
│  User Creation:                                                          │
│  • UID: "phone_<mobile_number>"                                         │
│  • Auth Provider: "phone"                                               │
│  • Mobile: Extracted from MSG91 response                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.4 Cloudflare Stream

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE STREAM INTEGRATION                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Purpose: Video hosting and HLS streaming                                │
│                                                                          │
│  Configuration:                                                          │
│  • Account ID: <cloudflare_account_id>                                  │
│  • API Token: <cloudflare_api_token>                                    │
│  • Stream URL: https://customer-<code>.cloudflarestream.com             │
│                                                                          │
│  Video Storage:                                                          │
│  • Format: HLS (HTTP Live Streaming)                                    │
│  • Multi-language audio tracks (Telugu, Hindi, English)                 │
│  • Adaptive bitrate streaming                                           │
│  • Thumbnail generation                                                  │
│                                                                          │
│  Video Access:                                                           │
│  1. Backend generates signed URL                                        │
│  2. URL includes expiration timestamp                                   │
│  3. Mobile app requests video with signed URL                           │
│  4. Cloudflare validates signature                                      │
│  5. Stream delivered to mobile app                                      │
│                                                                          │
│  Signed URL Format:                                                      │
│  https://customer-<code>.cloudflarestream.com/<video_id>/manifest/video.m3u8
│  ?token=<signed_token>&exp=<expiration>                                 │
│                                                                          │
│  Mobile Player:                                                          │
│  • video_player: ^2.8.1                                                 │
│  • HLS support (native iOS, ExoPlayer Android)                          │
│  • Audio track selection                                                │
│  • Quality selection (auto/manual)                                      │
│                                                                          │
│  Security:                                                               │
│  • Signed URLs (prevent unauthorized access)                            │
│  • Token expiration (1-hour validity)                                   │
│  • Domain restrictions                                                  │
│  • Download prevention                                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.5 AWS S3 / Cloudflare R2

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      AWS S3 / CLOUDFLARE R2                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Purpose: File storage (images, wallpapers, documents)                   │
│                                                                          │
│  Configuration:                                                          │
│  • Bucket Name: sks-mobile-assets                                       │
│  • Region: ap-south-1 (Mumbai)                                          │
│  • Access Key ID: <aws_access_key>                                      │
│  • Secret Access Key: <aws_secret_key>                                  │
│                                                                          │
│  Backend SDK:                                                            │
│  • @aws-sdk/client-s3                                                   │
│  • @aws-sdk/s3-request-presigner                                        │
│                                                                          │
│  File Upload Flow:                                                       │
│  1. Mobile app requests presigned URL                                   │
│  2. Backend generates presigned POST URL                                │
│  3. Mobile app uploads directly to S3                                   │
│  4. S3 returns file URL                                                 │
│  5. Mobile app sends URL to backend                                     │
│  6. Backend saves URL in database                                       │
│                                                                          │
│  File Types:                                                             │
│  • User profile photos                                                  │
│  • Event images                                                         │
│  • Wallpapers                                                           │
│  • Merchandise images                                                   │
│  • Gathering photos                                                     │
│                                                                          │
│  CDN:                                                                    │
│  • CloudFront distribution                                              │
│  • Global edge locations                                                │
│  • HTTPS delivery                                                       │
│  • Cache control headers                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Deployment Architecture

### 9.1 Development Environment

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT ENVIRONMENT                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Operating System: Windows                                               │
│  Database: Microsoft SQL Server (localhost\SQLEXPRESS)                  │
│  Node.js: v18.0.0+                                                      │
│  Flutter: SDK 3.0.0+                                                    │
│  Redis: Optional (caching)                                              │
│                                                                          │
│  Service Ports:                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ 3000 - API Gateway                                             │    │
│  │ 3007 - Notification Service                                    │    │
│  │ 3008 - Mobile Backend Service / Notification Dashboard         │    │
│  │ 3014 - Classes Service                                         │    │
│  │ 4000 - Google Login Service                                    │    │
│  │ 4001 - OTP Login Service                                       │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Database Connections:                                                   │
│  • Server: localhost\SQLEXPRESS                                         │
│  • Authentication: SQL Server Authentication                            │
│  • Username: sa                                                         │
│  • Password: Sivoham@26                                                 │
│  • Databases: sivoham, classes, sivoham_notifications                   │
│                                                                          │
│  Mobile App:                                                             │
│  • Base URL: http://localhost:3000 (development)                        │
│  • Base URL: https://app.sivakundalini.org (production)                │
│  • Build: flutter build apk / flutter build ios                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Production Architecture (Recommended)


```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION ARCHITECTURE                               │
└─────────────────────────────────────────────────────────────────────────┘

                              Internet
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Cloudflare CDN       │
                    │   (SSL/TLS, DDoS)      │
                    └────────────┬───────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Load Balancer        │
                    │   (Nginx / AWS ALB)    │
                    └────────────┬───────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
                 ▼               ▼               ▼
        ┌────────────┐  ┌────────────┐  ┌────────────┐
        │ API Gateway│  │ API Gateway│  │ API Gateway│
        │ Instance 1 │  │ Instance 2 │  │ Instance 3 │
        └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │  Google    │  │    OTP     │  │   Classes  │
     │  Login     │  │   Login    │  │   Service  │
     │  Service   │  │  Service   │  │            │
     └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │   Mobile   │  │Notification│  │   Redis    │
     │  Backend   │  │  Service   │  │  Cluster   │
     │  Service   │  │            │  │  (Cache)   │
     └─────┬──────┘  └─────┬──────┘  └────────────┘
           │               │
           └───────────────┼───────────────┐
                           │               │
                           ▼               ▼
              ┌────────────────┐  ┌────────────────┐
              │  Azure SQL DB  │  │  Azure SQL DB  │
              │   (sivoham)    │  │   (classes)    │
              └────────────────┘  └────────────────┘

External Services:
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Firebase │  │ OneSignal│  │  MSG91   │  │Cloudflare│
│   Auth   │  │   Push   │  │   OTP    │  │  Stream  │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

### 9.3 Infrastructure Components

**Load Balancer:**
- Nginx or AWS Application Load Balancer
- SSL/TLS termination
- Health checks
- Session affinity (sticky sessions)
- Rate limiting

**Application Servers:**
- Node.js services running on PM2
- Auto-scaling based on CPU/memory
- Graceful shutdown handling
- Log aggregation (Winston → CloudWatch)

**Database:**
- Azure SQL Database or AWS RDS (SQL Server)
- Read replicas for scaling
- Automated backups
- Point-in-time recovery
- Connection pooling

**Cache Layer:**
- Redis Cluster (3+ nodes)
- Session storage
- API response caching
- Rate limit counters
- Real-time data

**Monitoring:**
- Application Insights / CloudWatch
- Error tracking (Sentry)
- Performance monitoring (New Relic)
- Uptime monitoring (Pingdom)
- Log aggregation (ELK Stack)

**CI/CD Pipeline:**
```
GitHub → GitHub Actions → Build → Test → Deploy
                                    │
                                    ├─> Dev Environment
                                    ├─> Staging Environment
                                    └─> Production Environment
```

### 9.4 Environment Variables

**API Gateway (.env):**
```bash
PORT=3000
NODE_ENV=production
CORS_ORIGINS=https://app.sivakundalini.org

# Service URLs
GOOGLE_LOGIN_SERVICE_URL=http://localhost:4000
OTP_LOGIN_SERVICE_URL=http://localhost:4001
NOTIFICATION_SERVICE_URL=http://localhost:3007
CLASSES_SERVICE_URL=http://localhost:3014
MOBILE_BACKEND_SERVICE_URL=http://localhost:3008

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

**Mobile Backend Service (.env):**
```bash
PORT=3008
NODE_ENV=production
SERVICE_NAME=sks-mobile-backend-service

# Database
DB_SERVER=localhost\SQLEXPRESS
DB_DATABASE=sivoham
DB_USER=sa
DB_PASSWORD=Sivoham@26
DB_AUTH_MODE=sql
DB_POOL_MIN=10
DB_POOL_MAX=200
DB_CONNECTION_TIMEOUT=30000
DB_REQUEST_TIMEOUT=30000

# Firebase
FIREBASE_PROJECT_ID=sivakundalini-app
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@sivakundalini-app.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n

# AWS S3
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=ap-south-1
AWS_BUCKET_NAME=sks-mobile-assets

# CORS
CORS_ORIGIN=*
```

**Classes Service (.env):**
```bash
PORT=3014
NODE_ENV=production

# Database
DB_SERVER=localhost\SQLEXPRESS
DB_DATABASE=classes
DB_USER=sa
DB_PASSWORD=Sivoham@26
DB_AUTH_MODE=sql

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Cloudflare Stream
CLOUDFLARE_ACCOUNT_ID=...
CLOUDFLARE_API_TOKEN=...

# Cache
CACHE_TTL_SECONDS=3600
CACHE_ENABLED=true
```

**Notification Service (.env):**
```bash
PORT=3007
NODE_ENV=production
SERVICE_NAME=sks-notification-service

# Database
DB_SERVER=localhost\SQLEXPRESS
DB_DATABASE=sivoham_notifications
DB_USER=sa
DB_PASSWORD=Sivoham@26

# OneSignal
ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
ONESIGNAL_REST_API_KEY=os_v2_app_...

# Firebase
FIREBASE_PROJECT_ID=sivakundalini-app
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
```

**Google Login Service (.env):**
```bash
PORT=4000
NODE_ENV=production

# Database
DB_SERVER=localhost\SQLEXPRESS
DB_DATABASE=sivoham
DB_USER=sa
DB_PASSWORD=Sivoham@26

# Firebase
FIREBASE_PROJECT_ID=sivakundalini-app
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

**OTP Login Service (.env):**
```bash
PORT=4001
NODE_ENV=production

# Database
DB_SERVER=localhost\SQLEXPRESS
DB_DATABASE=sivoham
DB_USER=sa
DB_PASSWORD=Sivoham@26

# MSG91
MSG91_AUTH_KEY=...
MSG91_WIDGET_ID=...

# Firebase
FIREBASE_PROJECT_ID=sivakundalini-app
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
```

---

## 10. Security Considerations

### 10.1 Authentication & Authorization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      SECURITY MEASURES                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Authentication:                                                         │
│  • Firebase ID tokens (1-hour expiry)                                   │
│  • Token refresh on expiry                                              │
│  • Secure token storage (flutter_secure_storage)                        │
│  • Server-side token verification (Firebase Admin SDK)                  │
│                                                                          │
│  Authorization:                                                          │
│  • User blocking system (is_blocked flag)                               │
│  • Role-based access control (admin routes)                             │
│  • Resource ownership validation                                        │
│  • Permission checks (middleware)                                       │
│                                                                          │
│  Video Security:                                                         │
│  • Signed URLs with expiration                                          │
│  • Token-based access                                                   │
│  • Anti-download protection                                             │
│  • Session tracking                                                     │
│  • Security event logging                                               │
│                                                                          │
│  API Security:                                                           │
│  • Rate limiting (100 req/15min per IP)                                 │
│  • CORS configuration                                                   │
│  • Helmet.js security headers                                           │
│  • Input validation                                                     │
│  • SQL injection prevention (parameterized queries)                     │
│  • XSS protection                                                       │
│                                                                          │
│  Data Protection:                                                        │
│  • HTTPS in production                                                  │
│  • Encrypted database connections                                       │
│  • Secure environment variables                                         │
│  • No sensitive data in logs                                            │
│  • Password hashing (bcrypt)                                            │
│                                                                          │
│  Network Security:                                                       │
│  • Cloudflare DDoS protection                                           │
│  • WAF (Web Application Firewall)                                       │
│  • SSL/TLS certificates                                                 │
│  • VPC isolation (production)                                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Performance Optimizations

### 11.1 Mobile App

- **Image Caching**: cached_network_image for efficient image loading
- **API Response Caching**: SharedPreferences for frequently accessed data
- **Lazy Loading**: Pagination for lists (events, notifications)
- **Background Services**: audio_service for meditation audio
- **Connectivity Monitoring**: connectivity_plus for offline handling
- **Code Splitting**: Lazy loading of feature modules

### 11.2 Backend

- **Redis Caching**: Classes service uses Redis for video metadata
- **Database Connection Pooling**: Min 10, Max 200 connections
- **Query Optimization**: Indexed columns (uid, mobile, email, class_id)
- **Compression**: gzip compression middleware
- **CDN**: CloudFront for static assets
- **Horizontal Scaling**: Multiple instances behind load balancer

### 11.3 Database

- **Indexes**: 
  - users(uid, mobile, email, is_active)
  - user_notifications(user_uid, is_read, created_at)
  - user_day_progress(user_uid, class_id, day_id)
  - video_watch_events(user_uid, day_id, event_timestamp)

- **Partitioning**: video_watch_events partitioned by date
- **Query Optimization**: Avoid SELECT *, use specific columns
- **Connection Pooling**: Reuse connections across requests

---

## 12. Monitoring & Logging

### 12.1 Application Monitoring

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      MONITORING STACK                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Application Insights / CloudWatch:                                      │
│  • Request/response times                                               │
│  • Error rates                                                          │
│  • CPU/Memory usage                                                     │
│  • Database query performance                                           │
│                                                                          │
│  Error Tracking (Sentry):                                               │
│  • Exception tracking                                                   │
│  • Stack traces                                                         │
│  • User context                                                         │
│  • Release tracking                                                     │
│                                                                          │
│  Logging (Winston):                                                     │
│  • Structured JSON logs                                                 │
│  • Log levels (error, warn, info, debug)                                │
│  • Daily log rotation                                                   │
│  • Centralized log aggregation                                          │
│                                                                          │
│  Uptime Monitoring (Pingdom):                                           │
│  • Health check endpoints                                               │
│  • Response time monitoring                                             │
│  • Alert notifications                                                  │
│                                                                          │
│  Analytics:                                                              │
│  • User engagement metrics                                              │
│  • Video watch analytics                                                │
│  • Feature usage tracking                                               │
│  • Conversion funnels                                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 13. Disaster Recovery & Backup

### 13.1 Backup Strategy

**Database Backups:**
- Full backup: Daily at 2 AM
- Differential backup: Every 6 hours
- Transaction log backup: Every 15 minutes
- Retention: 30 days
- Offsite storage: Azure Blob Storage / AWS S3

**Application Backups:**
- Code: Git repository (GitHub)
- Configuration: Encrypted environment files
- Logs: Archived to S3 after 7 days

**Recovery Procedures:**
- RTO (Recovery Time Objective): 1 hour
- RPO (Recovery Point Objective): 15 minutes
- Automated restore scripts
- Regular disaster recovery drills

---

## 14. API Documentation

All services expose Swagger documentation at `/api-docs`:

- API Gateway: http://localhost:3000/api-docs
- Mobile Backend: http://localhost:3008/api-docs
- Classes Service: http://localhost:3014/api-docs
- Notification Service: http://localhost:3007/api-docs
- Google Login: http://localhost:4000/api-docs
- OTP Login: http://localhost:4001/api-docs

---

## 15. Future Enhancements

### Planned Features

1. **Offline Mode**: Download videos for offline viewing
2. **Social Features**: User profiles, following, sharing
3. **Gamification**: Badges, leaderboards, achievements
4. **Live Streaming**: Live meditation sessions
5. **Community Forum**: Discussion boards
6. **Payment Gateway**: In-app purchases, subscriptions
7. **Multi-language**: Expand to more languages
8. **Accessibility**: Screen reader support, high contrast mode
9. **Analytics Dashboard**: Admin analytics portal
10. **AI Recommendations**: Personalized content recommendations

---

## 16. Contact & Support

**Development Team:**
- Backend: Node.js microservices
- Mobile: Flutter (Android/iOS)
- Database: Microsoft SQL Server
- DevOps: CI/CD, monitoring, deployment

**Documentation:**
- API Docs: Swagger UI at /api-docs
- Database Schema: See CREATE_*.sql files
- Mobile App: See lib/ directory structure

---

**Last Updated:** January 2024
**Version:** 1.0.0
**Status:** Production
