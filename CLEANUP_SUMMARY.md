# SKS Mobile Backend Service - Cleanup Summary

## 🎯 Executive Summary

After analyzing the SKS-mobile-V2 Flutter application, we identified that **sks-mobile-backend-service** contains many routes that are **NOT used** by the mobile app. These are likely for web or admin interfaces.

---

## 📊 Key Findings

### Mobile App Uses Only 49 API Endpoints Total:

| Service | Endpoints | Status |
|---------|-----------|--------|
| **Google Login Service** | 3 | ✅ Separate Service |
| **OTP Login Service** | 2 | ✅ Separate Service |
| **Notification Service** | 5 | ✅ Separate Service |
| **Classes Service** | 13 | ✅ Separate Service |
| **Mobile Backend Service** | 26 | ⚠️ Needs Cleanup |

### Mobile Backend Service Analysis:

| Category | Current | Should Have | Action |
|----------|---------|-------------|--------|
| Route Files | 33 files | 9 files | Delete 24 files |
| Endpoints | ~100+ | 26 | Remove ~74 endpoints |
| Purpose | Mixed | Mobile Only | Refocus |

---

## ✅ What Mobile Backend Service SHOULD Keep (26 Endpoints)

### 1. User Profile Management (6 endpoints)
```
POST   /api/user/profile
GET    /api/user/profile
PATCH  /api/user/profile
POST   /api/user/permissions
POST   /api/user/upload-profile-photo
DELETE /api/user/profile-photo
```

### 2. Multi-Profile System (8 endpoints)
```
GET    /api/profiles/config
GET    /api/profiles
POST   /api/profiles
PUT    /api/profiles/:profileUid
DELETE /api/profiles/:profileUid
POST   /api/profiles/:profileUid/switch
GET    /api/profiles/sessions
DELETE /api/profiles/sessions/:sessionId
```

### 3. Meditation Tracking (5 endpoints)
```
POST   /api/meditation/sessions
GET    /api/meditation/sessions
GET    /api/meditation/stats
GET    /api/meditation/streak
DELETE /api/meditation/sessions/:sessionId
```

### 4. Events & Gatherings (3 endpoints)
```
GET    /api/events
POST   /api/events/:id/register
GET    /api/gatherings
```

### 5. Content (2 endpoints)
```
GET    /api/wallpapers
GET    /api/quotes
```

### 6. Notifications (1 endpoint)
```
GET    /api/notifications/push-status
```

### 7. Health Check (1 endpoint)
```
GET    /health
```

---

## ❌ What Should Be REMOVED (24 Route Files)

### Delete These Files from `routes/` folder:

```
❌ admin-requests.js          (Admin only - not used by mobile)
❌ admin-user-blocking.js     (Admin only - not used by mobile)
❌ admin.js                   (Admin only - not used by mobile)
❌ auth.js                    (Duplicate - use login services)
❌ classes-video.js           (Duplicate - use classes service)
❌ classes.js                 (Duplicate - use classes service)
❌ donations.js               (Not used by mobile)
❌ dynamic-forms.js           (Not used by mobile)
❌ event-attendance-old.js    (Not used by mobile)
❌ event-attendance.js        (Not used by mobile)
❌ event-seat-registration.js (Not used by mobile)
❌ event-violations.js        (Not used by mobile)
❌ kalpataru-experiences.js   (Not used by mobile)
❌ level-progression.js       (Duplicate - use classes service)
❌ level5.js                  (Not used by mobile)
❌ maha-sivaratri-travel.js   (Not used by mobile)
❌ maha-sivaratri.js          (Not used by mobile)
❌ mahaSivaratriTravelDetails.js (Not used by mobile)
❌ merchandise.js             (Not used by mobile)
❌ otp.js                     (Duplicate - use otp login service)
❌ purchases.js               (Not used by mobile)
❌ reminders.js               (Duplicate - use notification service)
❌ search.js                  (Not used by mobile)
❌ spot-registrations.js      (Not used by mobile)
```

### Keep and Modify These Files:

```
✅ events.js          (Keep only 2 endpoints - see cleanup plan)
✅ gatherings.js      (Keep as is)
✅ health.js          (Keep as is)
✅ meditation.js      (Keep as is)
✅ notifications.js   (Keep only 1 endpoint - see cleanup plan)
✅ profiles.js        (Keep as is)
✅ quotes.js          (Keep as is)
✅ user.js            (Keep as is)
✅ wallpapers.js      (Keep as is)
```

---

## 📋 Implementation Steps

### Quick Start:

1. **Backup the service:**
   ```bash
   cd s:\Backup
   xcopy sks-mobile-backend-service sks-mobile-backend-service-backup\ /E /I /H
   ```

2. **Follow the detailed cleanup plan:**
   - See: `s:\Backup\sks-mobile-backend-service\CLEANUP_PLAN.md`

3. **Delete 24 unused route files**

4. **Modify 2 route files:**
   - `events.js` - Keep only 2 endpoints
   - `notifications.js` - Keep only 1 endpoint

5. **Update `server.js`:**
   - Remove imports for deleted routes
   - Update route registrations

6. **Update `swagger.js`:**
   - Remove references to deleted routes

7. **Test everything:**
   ```bash
   npm start
   # Open http://localhost:3008/api-docs
   # Test with mobile app
   ```

---

## 🎯 Benefits of Cleanup

### 1. **Clarity**
- Service purpose is clear: "Mobile app backend"
- No confusion about which endpoints are for mobile vs web

### 2. **Maintainability**
- 73% fewer endpoints to maintain
- 73% fewer route files to manage
- Easier to find and fix bugs

### 3. **Performance**
- Faster service startup
- Reduced memory footprint
- Fewer database connections

### 4. **Security**
- Smaller attack surface
- Fewer endpoints to secure
- Clear separation of concerns

### 5. **Documentation**
- Cleaner Swagger docs
- Easier for mobile developers to understand
- Better API discoverability

---

## 🏗️ Recommended Architecture (After Cleanup)

```
┌─────────────────────────────────────────┐
│         API GATEWAY (Port 3000)         │
│         Routes all requests             │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Google  │  │   OTP    │  │Notification│
│  Login   │  │  Login   │  │  Service  │
│  (3010)  │  │  (3011)  │  │  (3012)   │
└──────────┘  └──────────┘  └──────────┘
        │           │           │
        └───────────┼───────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Classes  │  │  Mobile  │  │ Firebase │
│ Service  │  │ Backend  │  │   Auth   │
│  (3013)  │  │  (3008)  │  │          │
└──────────┘  └──────────┘  └──────────┘
        │           │
        └───────────┼───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   MSSQL Database      │
        └───────────────────────┘
```

### Service Responsibilities:

| Service | Purpose | Endpoints |
|---------|---------|-----------|
| **API Gateway** | Route requests | N/A |
| **Google Login** | Google OAuth | 3 |
| **OTP Login** | Phone auth | 2 |
| **Notification** | Reminders | 5 |
| **Classes** | Video learning | 13 |
| **Mobile Backend** | Core mobile features | 26 |

---

## 📝 Where Do Removed Features Go?

### Option 1: Create Separate Services (Recommended)
```
sks-web-backend-service (Port 3009)
├── Admin features
├── Advanced event management
├── E-commerce (merchandise, purchases, donations)
├── Dynamic forms
└── Search functionality

sks-admin-service (Port 3014)
├── User management
├── Content management
├── Analytics
└── System configuration
```

### Option 2: Keep in Original Monolith
- Keep `sks-backend` for web/admin features
- Use only for web dashboard
- Don't use for mobile app

---

## ✅ Verification Checklist

After cleanup, verify:

- [ ] Service starts without errors
- [ ] Swagger docs load at http://localhost:3008/api-docs
- [ ] All 26 endpoints are documented
- [ ] No 404 errors for mobile app requests
- [ ] User profile CRUD works
- [ ] Multi-profile system works
- [ ] Meditation tracking works
- [ ] Events listing works
- [ ] Wallpapers load
- [ ] Quotes display
- [ ] Mobile app functions normally

---

## 📊 Impact Analysis

### Code Reduction:
- **Route Files:** 33 → 9 (73% reduction)
- **Endpoints:** ~100 → 26 (74% reduction)
- **Lines of Code:** ~5000 → ~1500 (70% reduction)

### Maintenance Effort:
- **Before:** High complexity, mixed purposes
- **After:** Low complexity, single purpose

### Performance:
- **Startup Time:** Faster (fewer routes to register)
- **Memory Usage:** Lower (fewer loaded modules)
- **Response Time:** Same or better

---

## 🚀 Next Steps

1. **Review the cleanup plan:**
   - Read: `s:\Backup\sks-mobile-backend-service\CLEANUP_PLAN.md`

2. **Create backup:**
   - Backup current service before making changes

3. **Execute cleanup:**
   - Delete unused route files
   - Update server.js
   - Update swagger.js

4. **Test thoroughly:**
   - Start service
   - Check Swagger docs
   - Test with mobile app

5. **Update documentation:**
   - Update README.md
   - Update API documentation
   - Update deployment guides

6. **Deploy:**
   - Deploy cleaned service
   - Monitor for issues
   - Verify mobile app works

---

## 📞 Support

If you encounter issues during cleanup:

1. Check the backup: `sks-mobile-backend-service-backup`
2. Review the cleanup plan step-by-step
3. Test each endpoint individually
4. Check server logs for errors

---

**Document Version:** 1.0  
**Last Updated:** May 20, 2026  
**Status:** Ready for Implementation  
**Priority:** High - Improves maintainability and clarity
