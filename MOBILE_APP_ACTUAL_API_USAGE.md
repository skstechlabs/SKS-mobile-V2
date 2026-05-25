# SKS Mobile V2 - Actual API Usage Analysis

## 📱 APIs Actually Used by Mobile App

This document lists **ONLY** the API endpoints that are actually called by the SKS-mobile-V2 Flutter application.

**Analysis Date:** May 20, 2026  
**Source:** Complete scan of `lib/core/services/api_service.dart` and `lib/core/services/classes_service.dart`

---

## ✅ Complete List of APIs Used by Mobile App (33 Endpoints)

### 1. AUTHENTICATION (5 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 1 | `/api/auth/login/google` | POST | Google Login Service | api_service.dart |
| 2 | `/api/auth/login/phone` | POST | OTP Login Service | api_service.dart |
| 3 | `/api/auth/logout` | POST | Google Login Service | api_service.dart |
| 4 | `/api/auth/verify` | GET | Google Login Service | api_service.dart |
| 5 | `/api/otp/verify` | POST | OTP Login Service | api_service.dart |

---

### 2. USER PROFILE (6 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 6 | `/api/user/profile` | POST | Mobile Backend | api_service.dart |
| 7 | `/api/user/profile` | GET | Mobile Backend | api_service.dart |
| 8 | `/api/user/profile` | PATCH | Mobile Backend | api_service.dart |
| 9 | `/api/user/permissions` | POST | Mobile Backend | api_service.dart |
| 10 | `/api/user/upload-profile-photo` | POST | Mobile Backend | api_service.dart |
| 11 | `/api/user/profile-photo` | DELETE | Mobile Backend | api_service.dart |

---

### 3. MULTI-PROFILE SYSTEM (8 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 12 | `/api/profiles/config` | GET | Mobile Backend | api_service.dart |
| 13 | `/api/profiles` | GET | Mobile Backend | api_service.dart |
| 14 | `/api/profiles` | POST | Mobile Backend | api_service.dart |
| 15 | `/api/profiles/:profileUid` | PUT | Mobile Backend | api_service.dart |
| 16 | `/api/profiles/:profileUid` | DELETE | Mobile Backend | api_service.dart |
| 17 | `/api/profiles/:profileUid/switch` | POST | Mobile Backend | api_service.dart |
| 18 | `/api/profiles/sessions` | GET | Mobile Backend | api_service.dart |
| 19 | `/api/profiles/sessions/:sessionId` | DELETE | Mobile Backend | api_service.dart |

---

### 4. REMINDERS (5 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 20 | `/api/reminders` | GET | Notification Service | api_service.dart |
| 21 | `/api/reminders` | POST | Notification Service | api_service.dart |
| 22 | `/api/reminders/:id` | PUT | Notification Service | api_service.dart |
| 23 | `/api/reminders/:id` | DELETE | Notification Service | api_service.dart |
| 24 | `/api/reminders/:id/toggle` | PATCH | Notification Service | api_service.dart |

---

### 5. MEDITATION (5 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 25 | `/api/meditation/sessions` | POST | Mobile Backend | api_service.dart |
| 26 | `/api/meditation/sessions` | GET | Mobile Backend | api_service.dart |
| 27 | `/api/meditation/stats` | GET | Mobile Backend | api_service.dart |
| 28 | `/api/meditation/streak` | GET | Mobile Backend | api_service.dart |
| 29 | `/api/meditation/sessions/:sessionId` | DELETE | Mobile Backend | api_service.dart |

---

### 6. EVENTS & GATHERINGS (3 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 30 | `/api/events` | GET | Mobile Backend | api_service.dart |
| 31 | `/api/events/:id/register` | POST | Mobile Backend | api_service.dart |
| 32 | `/api/gatherings` | GET | Mobile Backend | api_service.dart |

---

### 7. CONTENT (2 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 33 | `/api/quotes` | GET | Mobile Backend | api_service.dart |
| 34 | `/api/wallpapers` | GET | Mobile Backend | wallpaper_service.dart |

---

### 8. NOTIFICATIONS (1 endpoint)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 35 | `/api/notifications/push-status` | GET | Mobile Backend | api_service.dart |

---

### 9. CLASSES & VIDEO (13 endpoints)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 36 | `/api/classes` | GET | Classes Service | classes_service.dart |
| 37 | `/api/classes/:id` | GET | Classes Service | classes_service.dart |
| 38 | `/api/classes/:id/enroll` | POST | Classes Service | classes_service.dart |
| 39 | `/api/classes/my/enrollments` | GET | Classes Service | classes_service.dart |
| 40 | `/api/classes/:classId/days` | GET | Classes Service | classes_service.dart |
| 41 | `/api/classes/:classId/progress` | GET | Classes Service | classes_service.dart |
| 42 | `/api/classes/days/:dayId/start` | POST | Classes Service | classes_service.dart |
| 43 | `/api/classes/days/:dayId/track` | POST | Classes Service | classes_service.dart |
| 44 | `/api/classes/days/:dayId/video-config` | GET | Classes Service | classes_service.dart |
| 45 | `/api/classes/days/:dayId/security-event` | POST | Classes Service | classes_service.dart |
| 46 | `/api/classes/analytics/summary` | GET | Classes Service | classes_service.dart |
| 47 | `/api/level-progression/access` | GET | Classes Service | classes_service.dart |
| 48 | `/api/level-progression/meditation-test` | POST | Classes Service | classes_service.dart |

---

### 10. HEALTH CHECK (1 endpoint)

| # | Endpoint | Method | Service | Used By |
|---|----------|--------|---------|---------|
| 49 | `/health` | GET | All Services | classes_service.dart |

---

## 📊 Summary by Service

### **Mobile Backend Service Should Have:**
- ✅ User Profile (6 endpoints)
- ✅ Multi-Profile System (8 endpoints)
- ✅ Meditation (5 endpoints)
- ✅ Events & Gatherings (3 endpoints)
- ✅ Content - Quotes & Wallpapers (2 endpoints)
- ✅ Notifications (1 endpoint)
- ✅ Health Check (1 endpoint)

**Total: 26 endpoints**

### **Other Services:**
- Google Login Service: 3 endpoints
- OTP Login Service: 2 endpoints
- Notification Service: 5 endpoints (Reminders)
- Classes Service: 13 endpoints

---

## ❌ APIs in sks-mobile-backend-service That Should Be REMOVED

The following routes exist in `sks-mobile-backend-service` but are **NOT used** by the mobile app:

### 1. Admin Routes (NOT USED BY MOBILE)
- ❌ `/api/admin/*` - All admin routes
- ❌ `/api/admin/users/*` - User blocking/management
- ❌ `/api/admin-requests/*` - Admin request handling

### 2. Event Management Extended (NOT USED BY MOBILE)
- ❌ `/api/event-attendance/*` - Event attendance tracking
- ❌ `/api/spot-registrations/*` - Spot registration management
- ❌ `/api/event-seat-registration/*` - Seat registration
- ❌ `/api/event-violations/*` - Event violation tracking

### 3. Special Events (NOT USED BY MOBILE)
- ❌ `/api/maha-sivaratri/*` - Maha Sivaratri event management
- ❌ `/api/maha-sivaratri-travel/*` - Travel details

### 4. E-Commerce (NOT USED BY MOBILE)
- ❌ `/api/merchandise/*` - Merchandise catalog
- ❌ `/api/purchases/*` - Purchase management
- ❌ `/api/donations/*` - Donation processing

### 5. Advanced Features (NOT USED BY MOBILE)
- ❌ `/api/level5/*` - Level 5 specific features
- ❌ `/api/dynamic-forms/*` - Dynamic form builder
- ❌ `/api/kalpataru/experiences/*` - Kalpataru experience submissions

### 6. Search (NOT USED BY MOBILE)
- ❌ `/api/search` - Global search functionality

### 7. Classes Routes (DUPLICATE - Already in Classes Service)
- ❌ `/api/classes/*` - Should be removed from mobile backend
- ❌ `/api/level-progression/*` - Should be removed from mobile backend

### 8. Auth Routes (DUPLICATE - Already in Login Services)
- ❌ `/api/auth/*` - Should be removed from mobile backend
- ❌ `/api/otp/*` - Should be removed from mobile backend

### 9. Reminders (DUPLICATE - Already in Notification Service)
- ❌ `/api/reminders/*` - Should be removed from mobile backend

---

## ✅ Final Mobile Backend Service Routes (CLEAN VERSION)

The `sks-mobile-backend-service` should **ONLY** have these routes:

```javascript
// ============================================
// ROUTES FOR MOBILE BACKEND SERVICE
// ============================================

// Health check
app.use('/health', healthRoutes);

// User Management
app.use('/api/user', userRoutes);

// Multi-Profile System
app.use('/api/profiles', profilesRoutes);

// Meditation Tracking
app.use('/api/meditation', meditationRoutes);

// Events & Gatherings
app.use('/api/events', eventsRoutes);
app.use('/api/gatherings', gatheringsRoutes);

// Content
app.use('/api/wallpapers', wallpapersRoutes);
app.use('/api/quotes', quotesRoutes);

// Notifications
app.use('/api/notifications', notificationsRoutes);
```

---

## 🗑️ Routes to DELETE from sks-mobile-backend-service

Delete these route files:

```
routes/
├── ❌ admin-requests.js
├── ❌ admin-user-blocking.js
├── ❌ admin.js
├── ❌ auth.js (duplicate - use login services)
├── ❌ classes-video.js (duplicate - use classes service)
├── ❌ classes.js (duplicate - use classes service)
├── ❌ donations.js
├── ❌ dynamic-forms.js
├── ❌ event-attendance-old.js
├── ❌ event-attendance.js
├── ❌ event-seat-registration.js
├── ❌ event-violations.js
├── ❌ kalpataru-experiences.js
├── ❌ level-progression.js (duplicate - use classes service)
├── ❌ level5.js
├── ❌ maha-sivaratri-travel.js
├── ❌ maha-sivaratri.js
├── ❌ mahaSivaratriTravelDetails.js
├── ❌ merchandise.js
├── ❌ otp.js (duplicate - use otp login service)
├── ❌ purchases.js
├── ❌ reminders.js (duplicate - use notification service)
├── ❌ search.js
├── ❌ spot-registrations.js
└── ✅ KEEP ONLY:
    ├── ✅ events.js (but only GET /api/events and POST /api/events/:id/register)
    ├── ✅ gatherings.js
    ├── ✅ health.js
    ├── ✅ meditation.js
    ├── ✅ notifications.js (only push-status endpoint)
    ├── ✅ profiles.js
    ├── ✅ quotes.js
    ├── ✅ user.js
    └── ✅ wallpapers.js
```

---

## 📝 Action Items

### 1. Clean Up sks-mobile-backend-service
- [ ] Remove all unused route files listed above
- [ ] Update `server.js` to remove unused route imports
- [ ] Remove unused middleware and utilities
- [ ] Clean up database models for removed features
- [ ] Update Swagger documentation

### 2. Verify Events Route
- [ ] Check `routes/events.js` - keep only:
  - `GET /api/events` (list events)
  - `POST /api/events/:id/register` (register for event)
- [ ] Remove all other event-related endpoints (attendance, violations, etc.)

### 3. Verify Notifications Route
- [ ] Check `routes/notifications.js` - keep only:
  - `GET /api/notifications/push-status`
- [ ] Remove any other notification endpoints (reminders are in notification service)

### 4. Update API Gateway
- [ ] Remove routes for deleted endpoints
- [ ] Update Swagger documentation
- [ ] Test all remaining routes

### 5. Testing
- [ ] Test all 26 mobile backend endpoints
- [ ] Verify mobile app works with cleaned service
- [ ] Check no broken references

---

## 🎯 Benefits of Cleanup

1. **Reduced Complexity** - Service focuses only on mobile app needs
2. **Easier Maintenance** - Less code to maintain and debug
3. **Better Performance** - Smaller codebase, faster startup
4. **Clear Separation** - Each service has distinct responsibility
5. **Reduced Database Load** - Fewer unused tables and queries

---

## 📦 Service Responsibilities (After Cleanup)

### **Mobile Backend Service**
- User profile management
- Multi-profile system
- Meditation tracking
- Basic event listing and registration
- Gatherings information
- Wallpapers and quotes
- Push notification status

### **Google Login Service**
- Google OAuth authentication
- User creation/update for Google users
- Session management

### **OTP Login Service**
- Phone OTP authentication
- MSG91 integration
- User creation for phone users

### **Notification Service**
- Meditation reminders CRUD
- Scheduled notifications
- OneSignal integration

### **Classes Service**
- Class management and enrollment
- Video streaming and progress tracking
- Level progression
- Cloudflare Stream integration

---

**Document Version:** 1.0  
**Last Updated:** May 20, 2026  
**Status:** Ready for Implementation
