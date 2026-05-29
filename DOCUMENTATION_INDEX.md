# SKS Mobile Application - Documentation Index

Welcome to the complete documentation for the SKS Mobile Application system. This documentation provides detailed information about the architecture, services, APIs, and flows of the entire application.

---

## 📚 Documentation Files

### 1. **ARCHITECTURE.md** - Complete System Architecture
**What's Inside:**
- High-level architecture diagrams
- Mobile application structure
- Backend services overview
- Database architecture
- Authentication flows
- Key user flows
- External integrations
- Deployment architecture
- Security considerations
- Performance optimizations

**When to Use:**
- Understanding the overall system design
- Learning how services communicate
- Planning new features
- Onboarding new developers
- System design reviews

---

### 2. **ARCHITECTURE_SUMMARY.md** - Quick Reference Guide
**What's Inside:**
- System overview
- Service architecture summary
- Key services breakdown
- Database structure
- Mobile app structure
- Key features list
- Authentication flows (simplified)
- External integrations summary
- Environment configuration
- Quick start commands

**When to Use:**
- Quick reference during development
- Understanding service responsibilities
- Finding service ports and URLs
- Getting started quickly
- Daily development reference

---

### 3. **SERVICE_MAP.md** - Complete Service Dependency Map
**What's Inside:**
- Visual service dependency diagrams
- Detailed service breakdown
- Service communication patterns
- Database access patterns
- Security flow
- Monitoring & logging
- Deployment topology

**When to Use:**
- Understanding service dependencies
- Debugging inter-service issues
- Planning service updates
- Understanding data flow
- Troubleshooting communication issues

---

### 4. **SYSTEM_FLOWS.md** - Detailed User & System Flows
**What's Inside:**
- Complete user journey (first-time registration)
- Video learning flow with progressive unlocking
- Push notification flow
- Event registration flow
- E-commerce flow
- Meditation tracking flow

**When to Use:**
- Understanding user experience
- Implementing new features
- Testing user flows
- Debugging user issues
- UX/UI design reference

---

### 5. **API_REFERENCE.md** - Complete API Documentation
**What's Inside:**
- All API endpoints
- Request/response formats
- Authentication requirements
- Error codes
- Rate limiting
- Pagination
- Query parameters

**When to Use:**
- Implementing API calls
- Testing APIs
- Debugging API issues
- Frontend development
- API integration

---

## 🚀 Quick Navigation

### For New Developers
1. Start with **ARCHITECTURE_SUMMARY.md** for a quick overview
2. Read **ARCHITECTURE.md** for detailed understanding
3. Refer to **SERVICE_MAP.md** to understand service dependencies
4. Use **API_REFERENCE.md** for API implementation

### For Frontend Developers
1. **API_REFERENCE.md** - All API endpoints and formats
2. **SYSTEM_FLOWS.md** - User flows and UI interactions
3. **ARCHITECTURE_SUMMARY.md** - Mobile app structure

### For Backend Developers
1. **SERVICE_MAP.md** - Service dependencies and communication
2. **ARCHITECTURE.md** - Database schemas and service details
3. **API_REFERENCE.md** - API specifications

### For DevOps/Infrastructure
1. **ARCHITECTURE.md** - Deployment architecture section
2. **SERVICE_MAP.md** - Deployment topology
3. **ARCHITECTURE_SUMMARY.md** - Environment configuration

### For Product Managers
1. **SYSTEM_FLOWS.md** - User journeys and features
2. **ARCHITECTURE_SUMMARY.md** - Key features and capabilities
3. **ARCHITECTURE.md** - System capabilities and limitations

---

## 📊 System Overview

### Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                  Mobile App (Flutter)                        │
│  Features: Auth, Learning, Events, Meditation, Profile      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  API Gateway (Port 3000)                     │
│  Routing, Rate Limiting, CORS, Authentication               │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Google     │  │     OTP      │  │   Classes    │
│   Login      │  │    Login     │  │   Service    │
│   :4000      │  │    :4001     │  │   :3014      │
└──────────────┘  └──────────────┘  └──────────────┘
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Notification  │  │    Mobile    │  │   Notif      │
│  Service     │  │   Backend    │  │  Dashboard   │
│  :3007       │  │   :3008      │  │   :3008      │
└──────────────┘  └──────────────┘  └──────────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Microsoft SQL Server Databases                  │
│  • sivoham (users, events, merchandise)                     │
│  • classes (videos, progress, analytics)                    │
│  • sivoham_notifications (notifications, reminders)         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Technologies

### Mobile App
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: flutter_bloc, ChangeNotifier
- **Navigation**: go_router
- **HTTP Client**: dio
- **Authentication**: Firebase Auth

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: Microsoft SQL Server
- **Cache**: Redis
- **Authentication**: Firebase Admin SDK

### External Services
- **Firebase** - Authentication
- **OneSignal** - Push Notifications
- **MSG91** - OTP Service
- **Cloudflare Stream** - Video Hosting
- **AWS S3** - File Storage

---

## 📈 Key Metrics

- **Total Services**: 7 microservices
- **Total Databases**: 3 MSSQL databases
- **Video Levels**: 5 levels
- **Videos per Level**: 3 days
- **Total Videos**: 15 videos
- **Merchandise Items**: 29 products
- **Supported Languages**: 3 (English, Telugu, Hindi)

---

## 🔐 Security Features

- Firebase ID token authentication
- Token refresh on expiry
- Secure token storage
- Rate limiting (100 req/15min)
- CORS configuration
- SQL injection prevention
- Video security (signed URLs)
- User blocking system

---

## 🎯 Key Features

### 1. Progressive Video Learning
- 5 levels with 3 days each
- Day-by-day unlocking (24-hour wait)
- 90% completion requirement
- Multi-language audio tracks

### 2. Authentication
- Google Sign-In (Firebase)
- Phone OTP (MSG91)
- Profile setup flow
- Permission management

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
- Merchandise catalog
- Order management
- Donation tracking

---

## 🛠️ Development Setup

### Prerequisites
- Node.js 18+
- Flutter SDK 3.0+
- Microsoft SQL Server
- Redis (optional)

### Quick Start

**1. Clone Repository**
```bash
git clone <repository-url>
```

**2. Setup Databases**
```bash
# Run SQL scripts in each service
# - sks-mobile-backend-service/config/schema.js
# - sks-classes-service/CREATE_CLASSES_DATABASE.sql
# - sks-notification-service/migrations/001_create_notifications_tables.sql
```

**3. Install Dependencies**
```bash
# For each service
cd <service-directory>
npm install
```

**4. Configure Environment**
```bash
# Copy .env.example to .env in each service
# Update with your credentials
```

**5. Start Services**
```bash
# Start each service in separate terminals
npm start
```

**6. Run Mobile App**
```bash
cd SKS-mobile-V2
flutter pub get
flutter run
```

---

## 📞 Support & Contact

For questions or issues:
1. Check the relevant documentation file
2. Review API documentation at `/api-docs`
3. Check service logs
4. Contact development team

---

## 📝 Documentation Maintenance

**Last Updated**: January 2024
**Version**: 1.0.0
**Maintained By**: Development Team

### Update Guidelines
- Update documentation when adding new features
- Keep API reference in sync with code
- Update diagrams when architecture changes
- Review documentation quarterly

---

## 🗺️ Documentation Roadmap

### Planned Additions
- [ ] Deployment guide
- [ ] Testing guide
- [ ] Troubleshooting guide
- [ ] Performance tuning guide
- [ ] Security best practices
- [ ] Monitoring & alerting setup
- [ ] Disaster recovery procedures

---

## 📖 Additional Resources

### Swagger Documentation
- API Gateway: http://localhost:3000/api-docs
- Mobile Backend: http://localhost:3008/api-docs
- Classes Service: http://localhost:3014/api-docs
- Notification Service: http://localhost:3007/api-docs
- Google Login: http://localhost:4000/api-docs
- OTP Login: http://localhost:4001/api-docs

### Database Schemas
- Mobile Backend: `sks-mobile-backend-service/config/schema.js`
- Classes Service: `sks-classes-service/CREATE_CLASSES_DATABASE.sql`
- Notification Service: `sks-notification-service/migrations/`

### Code Repositories
- Mobile App: `SKS-mobile-V2/`
- API Gateway: `api-gateway/`
- Services: `sks-*-service/`

---

**Happy Coding! 🚀**
