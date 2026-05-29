# SKS Mobile Application - Complete Service Map

## Service Dependency Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                          MOBILE APPLICATION (Flutter)                        │
│                                                                              │
│  Features: Auth, Home, Learnings, Events, Notifications, Profile,           │
│            Meditation, Reminders, Settings                                   │
│                                                                              │
│  API Client: Dio with Firebase token authentication                          │
│  Base URL: https://app.sivakundalini.org                                    │
│                                                                              │
└──────────────────────────────────┬───────────────────────────────────────────┘
                                   │
                                   │ HTTPS + Bearer Token
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                          API GATEWAY (Port 3000)                             │
│                                                                              │
│  Middleware: Helmet, CORS, Rate Limiting, Body Parser, Request Logger       │
│  Documentation: Swagger UI at /api-docs                                     │
│                                                                              │
│  Route Mapping:                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ /api/auth/login/google → Google Login Service (4000)              │    │
│  │ /api/auth/login/phone  → OTP Login Service (4001)                 │    │
│  │ /api/otp/*             → OTP Login Service (4001)                 │    │
│  │ /api/notifications/*   → Notification Service (3007)              │    │
│  │ /api/reminders/*       → Notification Service (3007)              │    │
│  │ /api/classes/*         → Classes Service (3014)                   │    │
│  │ /api/level-progression/* → Classes Service (3014)                 │    │
│  │ /api/events/*          → Mobile Backend Service (3008)            │    │
│  │ /api/merchandise/*     → Mobile Backend Service (3008)            │    │
│  │ /api/user/*            → Mobile Backend Service (3008)            │    │
│  │ /api/profiles/*        → Mobile Backend Service (3008)            │    │
│  │ /api/meditation/*      → Mobile Backend Service (3008)            │    │
│  │ /api/gatherings/*      → Mobile Backend Service (3008)            │    │
│  │ /api/quotes/*          → Mobile Backend Service (3008)            │    │
│  │ /api/wallpapers/*      → Mobile Backend Service (3008)            │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└───┬──────────┬──────────┬──────────┬──────────┬──────────┬─────────────────┘
    │          │          │          │          │          │
    │          │          │          │          │          │
    ▼          ▼          ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ Google │ │  OTP   │ │Classes │ │ Notif  │ │ Mobile │ │ Notif  │
│ Login  │ │ Login  │ │Service │ │Service │ │Backend │ │Dashboard│
│ :4000  │ │ :4001  │ │ :3014  │ │ :3007  │ │ :3008  │ │ :3008  │
└───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘
    │          │          │          │          │          │
    │          │          │          │          │          │
    └──────────┴──────────┴──────────┴──────────┴──────────┘
                          │
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                    MICROSOFT SQL SERVER DATABASES                            │
│                                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────┐ │
│  │   sivoham            │  │   classes            │  │ sivoham_         │ │
│  │                      │  │                      │  │ notifications    │ │
│  │ • users              │  │ • classes            │  │                  │ │
│  │ • events             │  │ • class_days         │  │ • user_          │ │
│  │ • merchandise        │  │ • user_class_        │  │   notifications  │ │
│  │ • purchases          │  │   enrollments        │  │ • reminders      │ │
│  │ • donations          │  │ • user_day_progress  │  │                  │ │
│  │ • gatherings         │  │ • user_level_access  │  │                  │ │
│  │ • quotes             │  │ • video_watch_events │  │                  │ │
│  │ • wallpapers         │  │ • video_analytics    │  │                  │ │
│  │ • meditation_        │  │ • meditation_tests   │  │                  │ │
│  │   sessions           │  │                      │  │                  │ │
│  │                      │  │                      │  │                  │ │
│  │ Used By:             │  │ Used By:             │  │ Used By:         │ │
│  │ • Mobile Backend     │  │ • Classes Service    │  │ • Notification   │ │
│  │ • Google Login       │  │                      │  │   Service        │ │
│  │ • OTP Login          │  │                      │  │ • Dashboard      │ │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                          EXTERNAL SERVICES                                   │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Firebase   │  │  OneSignal   │  │    MSG91     │  │  Cloudflare  │  │
│  │     Auth     │  │     Push     │  │     OTP      │  │    Stream    │  │
│  │              │  │              │  │              │  │              │  │
│  │ • Google     │  │ • Push       │  │ • OTP Widget │  │ • HLS Video  │  │
│  │   Sign-In    │  │   Notif      │  │ • SMS        │  │ • Multi-lang │  │
│  │ • Token      │  │ • User       │  │ • Verify API │  │ • Signed URL │  │
│  │   Verify     │  │   Targeting  │  │              │  │              │  │
│  │              │  │              │  │              │  │              │  │
│  │ Used By:     │  │ Used By:     │  │ Used By:     │  │ Used By:     │  │
│  │ • Mobile App │  │ • Mobile App │  │ • Mobile App │  │ • Classes    │  │
│  │ • Google     │  │ • Notif Svc  │  │ • OTP Login  │  │   Service    │  │
│  │   Login Svc  │  │              │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐                                        │
│  │   AWS S3     │  │    Redis     │                                        │
│  │              │  │    Cache     │                                        │
│  │ • Images     │  │              │                                        │
│  │ • Wallpapers │  │ • Session    │                                        │
│  │ • Files      │  │ • API Cache  │                                        │
│  │              │  │ • Rate Limit │                                        │
│  │              │  │              │                                        │
│  │ Used By:     │  │ Used By:     │                                        │
│  │ • Mobile     │  │ • Classes    │                                        │
│  │   Backend    │  │   Service    │                                        │
│  └──────────────┘  └──────────────┘                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Service Breakdown

### 1. Google Login Service (Port 4000)

**Purpose**: Handle Google OAuth authentication

**Dependencies**:
- Firebase Admin SDK (token verification)
- sivoham database (user storage)
- Redis (optional session caching)

**Endpoints**:
```
POST   /auth/google/login    - Authenticate with Google
POST   /auth/google/logout   - Logout user
GET    /auth/google/verify   - Verify session
GET    /auth/profile         - Get user profile
PUT    /auth/profile         - Update user profile
PATCH  /auth/profile         - Partial update
```

**Data Flow**:
```
Mobile App → Firebase Auth → Get ID Token → Send to Service
→ Verify with Firebase Admin SDK → Create/Update User in DB
→ Return User Data → Mobile App
```

---

### 2. OTP Login Service (Port 4001)

**Purpose**: Handle phone number authentication via OTP

**Dependencies**:
- MSG91 API (OTP sending and verification)
- sivoham database (user storage)
- Firebase Admin SDK (optional)

**Endpoints**:
```
POST /api/auth/login/phone  - Phone OTP login
POST /api/otp/send          - Send OTP
POST /api/otp/verify        - Verify OTP
```

**Data Flow**:
```
Mobile App → MSG91 Widget → User Enters OTP → Widget Verifies
→ Returns access_token → Send to Service → Verify with MSG91 API
→ Create/Update User in DB → Return User Data → Mobile App
```

---

### 3. Classes Service (Port 3014)

**Purpose**: Video streaming and progressive learning platform

**Dependencies**:
- classes database (video metadata, progress)
- Redis (caching)
- Cloudflare Stream (video hosting)
- Firebase Admin SDK (authentication)

**Endpoints**:
```
GET  /api/classes                    - List all levels
GET  /api/classes/:id/days           - Get days for level
GET  /api/classes/:id/days/:dayId    - Get day details
POST /api/classes/:id/enroll         - Enroll in level
GET  /api/classes/:id/progress       - Get user progress
POST /api/classes/days/:dayId/start  - Start watching
POST /api/classes/days/:dayId/progress - Update progress
POST /api/classes/days/:dayId/complete - Mark complete
GET  /api/level-progression          - Get progression status
POST /api/level-progression/unlock   - Unlock next level
```

**Key Features**:
- HLS video streaming
- Progressive unlocking (day-by-day, level-by-level)
- Multi-language audio tracks
- Watch analytics
- Redis caching for performance

**Data Flow**:
```
Mobile App → Request Video → Service Generates Signed URL
→ Cloudflare Stream → Video Delivered → Progress Tracked
→ Completion Detected → Unlock Next Day/Level → Notification Sent
```

---

### 4. Notification Service (Port 3007)

**Purpose**: Push notifications and reminders

**Dependencies**:
- sivoham_notifications database
- OneSignal API (push delivery)
- Firebase Admin SDK (authentication)
- Redis (optional caching)

**Endpoints**:
```
GET  /api/notifications              - List user notifications
PUT  /api/notifications/:id/read     - Mark as read
PUT  /api/notifications/read-all     - Mark all read
POST /api/notifications/test         - Test notification
POST /api/notifications/send-to-segment - Segment targeting

GET  /api/reminders                  - List reminders
POST /api/reminders                  - Create reminder
PUT  /api/reminders/:id              - Update reminder
DELETE /api/reminders/:id            - Delete reminder
PATCH /api/reminders/:id/toggle      - Toggle active status
```

**Notification Types**:
- day_unlocked
- level_unlocked
- reminder
- event
- class
- achievement
- system
- announcement

**Data Flow**:
```
Backend Event → Create Notification in DB → Call OneSignal API
→ OneSignal Delivers to Device → User Taps → Navigate to Action URL
→ Mark as Read in DB
```

---

### 5. Mobile Backend Service (Port 3008)

**Purpose**: Core business logic for mobile app

**Dependencies**:
- sivoham database (all core tables)
- Firebase Admin SDK (authentication)
- AWS S3 (file storage)

**Modules**:
```
User Management:
  /api/user/*           - Profile CRUD
  /api/profiles/*       - Multi-profile system

Events:
  /api/events/*         - Event listings, registration
  /api/event-attendance/* - Attendance tracking
  /api/event-seat-registration/* - Seat allocation

E-Commerce:
  /api/merchandise/*    - Product catalog
  /api/purchases/*      - Order management
  /api/donations/*      - Donation tracking

Content:
  /api/gatherings/*     - Past gatherings
  /api/quotes/*         - Daily quotes
  /api/wallpapers/*     - Wallpaper downloads

Meditation:
  /api/meditation/*     - Session tracking, stats
  /api/reminders/*      - Meditation reminders

Admin:
  /api/admin/*          - Admin operations
  /api/admin/users/*    - User blocking
```

**Middleware**:
- firebaseAuth.js (token verification)
- checkUserBlocked.js (block status check)
- errorHandler.js (global error handling)

---

### 6. Notification Dashboard (Port 3008)

**Purpose**: Admin interface for managing notifications

**Technology**:
- Frontend: React.js
- Backend: Express.js
- Database: sivoham_notifications

**Features**:
- View all notifications
- Send targeted notifications
- User segment filtering
- Notification history
- Analytics dashboard

---

## Service Communication Patterns

### Synchronous Communication (HTTP/REST)
```
Mobile App ←→ API Gateway ←→ Microservices ←→ Databases
```

### Asynchronous Communication (Events)
```
Backend Service → Create Notification → OneSignal API → Mobile Device
```

### Caching Strategy
```
Request → Check Redis Cache → If Hit: Return Cached Data
                            → If Miss: Query Database → Cache Result → Return
```

---

## Database Access Patterns

### sivoham Database (Shared)
```
┌──────────────────┐
│ Google Login Svc │ ──┐
└──────────────────┘   │
┌──────────────────┐   │    ┌──────────────┐
│ OTP Login Svc    │ ──┼───→│   sivoham    │
└──────────────────┘   │    │   Database   │
┌──────────────────┐   │    └──────────────┘
│ Mobile Backend   │ ──┘
└──────────────────┘
```

### classes Database (Dedicated)
```
┌──────────────────┐    ┌──────────────┐
│ Classes Service  │───→│   classes    │
└──────────────────┘    │   Database   │
                        └──────────────┘
```

### sivoham_notifications Database (Dedicated)
```
┌──────────────────┐    ┌──────────────────┐
│ Notification Svc │───→│ sivoham_         │
└──────────────────┘    │ notifications    │
┌──────────────────┐    │ Database         │
│ Notif Dashboard  │───→│                  │
└──────────────────┘    └──────────────────┘
```

---

## Security Flow

### Authentication
```
Mobile App → Firebase Auth → Get ID Token → Add to Request Header
→ API Gateway → Microservice → Verify Token with Firebase Admin SDK
→ Extract UID → Check User Blocked → Execute Business Logic
```

### Authorization
```
Request → Verify Token → Extract User UID → Check Permissions
→ Validate Resource Ownership → Allow/Deny Access
```

---

## Monitoring & Logging

### Application Logs
```
Each Service → Winston Logger → Console/File → Log Aggregation (ELK/CloudWatch)
```

### Error Tracking
```
Exception Thrown → Sentry SDK → Sentry Dashboard → Alert Notification
```

### Performance Monitoring
```
Request → Response Time Tracked → Application Insights/New Relic → Dashboard
```

---

## Deployment Topology

### Development
```
localhost:3000 (API Gateway)
localhost:3007 (Notification Service)
localhost:3008 (Mobile Backend + Dashboard)
localhost:3014 (Classes Service)
localhost:4000 (Google Login Service)
localhost:4001 (OTP Login Service)
localhost\SQLEXPRESS (SQL Server)
```

### Production
```
Cloudflare CDN → Load Balancer (Nginx/ALB)
    → API Gateway (Multiple Instances)
        → Microservices (Auto-scaled)
            → Azure SQL Database / AWS RDS
            → Redis Cluster
```

---

**Last Updated**: January 2024
