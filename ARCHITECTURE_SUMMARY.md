# SKS Mobile Application - Architecture Summary

## Quick Reference Guide

### System Overview

**SKS Mobile Application** is a microservices-based spiritual learning platform with:
- **Mobile App**: Flutter (Android/iOS)
- **Backend**: 7 Node.js microservices
- **Databases**: 3 Microsoft SQL Server databases
- **External Services**: Firebase, OneSignal, MSG91, Cloudflare Stream

---

## Service Architecture

```
Mobile App (Flutter)
        ↓
API Gateway (Port 3000)
        ↓
    ┌───┴───┬───────┬──────────┬──────────┬─────────┐
    ↓       ↓       ↓          ↓          ↓         ↓
Google   OTP    Classes   Notification  Mobile   Dashboard
Login   Login   Service    Service     Backend
:4000   :4001    :3014      :3007       :3008     :3008
```

---

## Key Services

### 1. API Gateway (Port 3000)
- **Purpose**: Central routing, rate limiting, CORS
- **Routes**: Proxies to all microservices
- **Features**: Swagger docs, health checks, logging

### 2. Mobile Backend Service (Port 3008)
- **Purpose**: Core business logic
- **Features**: Events, merchandise, donations, user management
- **Database**: sivoham (MSSQL)

### 3. Classes Service (Port 3014)
- **Purpose**: Video streaming, progressive learning
- **Features**: HLS streaming, level unlocking, analytics
- **Database**: classes (MSSQL)
- **Cache**: Redis

### 4. Notification Service (Port 3007)
- **Purpose**: Push notifications, reminders
- **Features**: OneSignal integration, scheduled notifications
- **Database**: sivoham_notifications (MSSQL)

### 5. Google Login Service (Port 4000)
- **Purpose**: Google OAuth authentication
- **Features**: Firebase token verification
- **Database**: sivoham (MSSQL)

### 6. OTP Login Service (Port 4001)
- **Purpose**: Phone OTP authentication
- **Features**: MSG91 integration
- **Database**: sivoham (MSSQL)

---

## Database Structure

### sivoham Database
**Tables**: users, events, merchandise, purchases, donations, gatherings, quotes, wallpapers, meditation_sessions

**Used By**: Mobile Backend, Google Login, OTP Login services

### classes Database
**Tables**: classes, class_days, user_class_enrollments, user_day_progress, video_watch_events, video_analytics_summary

**Used By**: Classes Service

### sivoham_notifications Database
**Tables**: user_notifications, reminders

**Used By**: Notification Service, Notification Dashboard

---

## Mobile App Structure

```
lib/
├── main.dart
├── core/
│   ├── router.dart (go_router navigation)
│   ├── services/
│   │   ├── api_service.dart (Dio HTTP client)
│   │   ├── auth_state.dart (Authentication state)
│   │   └── onesignal_service.dart (Push notifications)
│   └── theme/
│       └── app_theme.dart
└── features/
    ├── auth/ (Login, profile setup)
    ├── home/ (Dashboard)
    ├── learnings/ (Video classes)
    ├── events/ (Event listings)
    ├── notifications/ (In-app notifications)
    ├── profile/ (User profile)
    ├── meditation/ (Timer, history)
    └── reminders/ (Meditation reminders)
```

---

## Key Features

### 1. Progressive Video Learning
- 5 levels, 3 days each (15 videos total)
- Day-by-day unlocking (24-hour wait)
- Level-by-level progression
- 90% completion requirement
- Multi-language audio (Telugu, Hindi, English)

### 2. Authentication
- Google Sign-In (Firebase)
- Phone OTP (MSG91)
- Firebase ID token verification
- User blocking system

### 3. Push Notifications
- OneSignal integration
- Day/Level unlock notifications
- Event reminders
- Custom meditation reminders

### 4. Meditation Tracking
- Timer with background audio
- Session history
- Streak tracking
- Statistics dashboard

### 5. Events & Registration
- Event listings
- Online registration
- Seat allocation
- Attendance tracking

### 6. E-Commerce
- Merchandise catalog (29 items)
- Order management
- Donation tracking

---

## Authentication Flows

### Google Sign-In
1. User taps "Sign in with Google"
2. Google OAuth dialog
3. Firebase authentication
4. Get Firebase ID token
5. Send token to backend
6. Backend verifies with Firebase Admin SDK
7. Create/update user in database
8. Return user data
9. Navigate to Profile Setup (new) or Home (existing)

### Phone OTP
1. User enters phone number
2. MSG91 widget sends OTP
3. User enters OTP
4. MSG91 verifies and returns access_token
5. Send access_token to backend
6. Backend verifies with MSG91 API
7. Create/update user in database
8. Return user data
9. Navigate to Profile Setup (new) or Home (existing)

---

## API Request Flow

```
Mobile App
    ↓ (Get Firebase ID token)
    ↓ (Add Authorization: Bearer <token>)
API Gateway
    ↓ (Rate limiting, CORS)
    ↓ (Forward to microservice)
Microservice
    ↓ (Verify Firebase token)
    ↓ (Check user blocked status)
    ↓ (Execute business logic)
    ↓ (Return response)
Mobile App
```

---

## External Integrations

### Firebase
- **Purpose**: Authentication (Google Sign-In)
- **Mobile**: firebase_core, firebase_auth
- **Backend**: firebase-admin (token verification)

### OneSignal
- **Purpose**: Push notifications
- **App ID**: b89d199e-15be-4343-9e04-640c43f355e9
- **Integration**: OneSignal.login(uid) links device to user

### MSG91
- **Purpose**: Phone OTP authentication
- **Integration**: Widget for OTP, API for verification

### Cloudflare Stream
- **Purpose**: Video hosting and HLS streaming
- **Features**: Multi-language audio, signed URLs, adaptive bitrate

### AWS S3
- **Purpose**: File storage (images, wallpapers)
- **Integration**: Presigned URLs for uploads

---

## Environment Configuration

### Development
- **Database**: localhost\SQLEXPRESS
- **API Base URL**: http://localhost:3000
- **Services**: Running on localhost with different ports

### Production
- **Database**: Azure SQL Database / AWS RDS
- **API Base URL**: https://app.sivakundalini.org
- **Load Balancer**: Nginx / AWS ALB
- **CDN**: Cloudflare
- **Monitoring**: Application Insights / CloudWatch

---

## Security Features

- Firebase ID token authentication (1-hour expiry)
- Token refresh on expiry
- Secure token storage (flutter_secure_storage)
- Rate limiting (100 req/15min per IP)
- CORS configuration
- Helmet.js security headers
- SQL injection prevention (parameterized queries)
- Video security (signed URLs, anti-download)
- User blocking system

---

## Performance Optimizations

### Mobile App
- Image caching (cached_network_image)
- API response caching (SharedPreferences)
- Lazy loading (pagination)
- Background audio service
- Connectivity monitoring

### Backend
- Redis caching (Classes service)
- Database connection pooling
- Query optimization (indexes)
- Compression middleware
- CDN for static assets

---

## Key Metrics

- **Total Services**: 7 microservices
- **Total Databases**: 3 MSSQL databases
- **Video Levels**: 5 levels
- **Videos per Level**: 3 days
- **Total Videos**: 15 videos
- **Merchandise Items**: 29 products
- **Supported Languages**: 3 (English, Telugu, Hindi)

---

## Documentation Links

- **Full Architecture**: See ARCHITECTURE.md
- **System Flows**: See SYSTEM_FLOWS.md
- **API Documentation**: http://localhost:3000/api-docs (Swagger)
- **Database Schemas**: See CREATE_*.sql files in each service

---

## Quick Start

### Mobile App
```bash
cd SKS-mobile-V2
flutter pub get
flutter run
```

### Backend Services
```bash
# API Gateway
cd api-gateway
npm install
npm start

# Mobile Backend
cd sks-mobile-backend-service
npm install
npm start

# Classes Service
cd sks-classes-service
npm install
npm start

# Notification Service
cd sks-notification-service
npm install
npm start

# Google Login Service
cd sks-google-login-service
npm install
npm start

# OTP Login Service
cd sks-otp-login-service
npm install
npm start
```

---

**Last Updated**: January 2024
**Version**: 1.0.0
