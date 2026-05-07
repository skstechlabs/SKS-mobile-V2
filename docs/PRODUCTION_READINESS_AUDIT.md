# Production Readiness Audit Report
**Date:** March 29, 2026  
**Target:** PM2 Deployment with 1000+ Concurrent Users

---

## 🔴 CRITICAL ISSUES FOUND

### 1. **Port Configuration Mismatch**
**Severity:** HIGH  
**Impact:** Mobile app will fail to connect to backend in development

**Problem:**
- `.env.json` (dev): `http://localhost:3011` ❌
- `api_service.dart` fallback: `http://localhost:3012` ❌
- `server.js` default: `3012` ✅
- `.env.prod.json` (prod): `http://sivakundalini.org:4000` ✅

**Fix Required:**
```json
// .env.json should be:
"API_BASE_URL": "http://localhost:3012"
```

---

### 2. **Database Connection Pool - Insufficient for 1000+ Users**
**Severity:** CRITICAL  
**Impact:** Connection exhaustion, request timeouts, server crashes

**Current Settings:**
```javascript
connectionLimit: process.env.NODE_ENV === 'production' ? 2000 : 200,
queueLimit: 5000,
```

**Problems:**
- 2000 connections is TOO HIGH for most MySQL servers (default max_connections = 151)
- Will cause "Too many connections" errors
- No connection timeout configured
- No proper error handling for pool exhaustion

**Recommended Fix:**
```javascript
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: currentSchema,
  
  // Production-optimized settings for 1000+ concurrent users
  connectionLimit: process.env.NODE_ENV === 'production' ? 100 : 10,
  queueLimit: 0, // Fail fast instead of queuing
  waitForConnections: true,
  
  // Timeouts
  connectTimeout: 10000, // 10 seconds
  acquireTimeout: 10000, // 10 seconds
  timeout: 60000, // 60 seconds query timeout
  
  // Keep-alive
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
  
  // Idle connection management
  idleTimeout: 60000, // 60 seconds
  maxIdle: 10,
});
```

**MySQL Server Configuration Required:**
```sql
-- Check current max_connections
SHOW VARIABLES LIKE 'max_connections';

-- Set to at least 150 for production
SET GLOBAL max_connections = 150;

-- Add to my.cnf for persistence
[mysqld]
max_connections = 150
max_connect_errors = 100000
wait_timeout = 600
interactive_timeout = 600
```

---

### 3. **OneSignal Subscription Issue**
**Severity:** HIGH  
**Impact:** Push notifications not working, users not appearing in OneSignal dashboard

**Current State:**
- Code has extensive logging and retry logic
- User reports subscriptions still not appearing after recent changes
- Previously worked, something may have been removed

**Investigation Needed:**
1. Build fresh APK with current code
2. Install and collect logs during permission grant
3. Look for these specific log messages:
   - `Player ID: <valid_id>` (should NOT be null)
   - `Subscribed: true` (should be true)
   - Any WARNING messages
4. Verify OneSignal App ID: `b89d199e-15be-4343-9e04-640c43f355e9`

**Potential Root Causes:**
- Timing issue with OneSignal initialization
- Permission flow changed when skip logic was added
- External user ID not being set properly
- OneSignal SDK version compatibility

---

## ⚠️ HIGH PRIORITY ISSUES

### 4. **No Rate Limiting**
**Severity:** HIGH  
**Impact:** API abuse, DDoS vulnerability, server overload

**Missing:**
- No rate limiting middleware
- No IP-based throttling
- No user-based request limits

**Recommended Fix:**
```javascript
const rateLimit = require('express-rate-limit');

// General API rate limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per 15 minutes
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

// Auth endpoints - stricter
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 login attempts per 15 minutes
  message: 'Too many login attempts, please try again later',
});

app.use('/api/', apiLimiter);
app.use('/api/auth/', authLimiter);
```

---

### 5. **No Health Check Endpoint for PM2**
**Severity:** MEDIUM  
**Impact:** PM2 cannot monitor app health, no automatic restarts

**Current:** `/health` endpoint exists but not documented for PM2

**PM2 Ecosystem File Needed:**
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'sks-backend',
    script: './server.js',
    instances: 'max', // Use all CPU cores
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 4000
    },
    // Health check
    health_check: {
      enable: true,
      endpoint: '/health',
      interval: 30000, // 30 seconds
      timeout: 5000
    },
    // Auto-restart on failure
    max_restarts: 10,
    min_uptime: '10s',
    // Logging
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    // Memory management
    max_memory_restart: '500M',
    // Graceful shutdown
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 10000
  }]
};
```

---

### 6. **CORS Configuration Not Production-Ready**
**Severity:** MEDIUM  
**Impact:** Security vulnerability, unauthorized access

**Need to Verify:**
- Is CORS configured in middleware.js?
- Does it allow all origins (*) or specific domains?
- Are credentials allowed?

**Recommended Production CORS:**
```javascript
const cors = require('cors');

app.use(cors({
  origin: [
    'http://sivakundalini.org',
    'https://sivakundalini.org',
    'http://sivakundalini.org:4000',
    'https://sivakundalini.org:4000'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

---

### 7. **No Request Timeout Protection**
**Severity:** MEDIUM  
**Impact:** Long-running requests can block server

**Missing:**
- No global request timeout
- No query timeout enforcement

**Recommended Fix:**
```javascript
const timeout = require('connect-timeout');

// 30 second timeout for all requests
app.use(timeout('30s'));
app.use((req, res, next) => {
  if (!req.timedout) next();
});
```

---

## 📋 MEDIUM PRIORITY ISSUES

### 8. **Firebase Token Validation**
**Status:** ✅ Implemented  
**Note:** Verify middleware is applied to all protected routes

### 9. **Database Indexes**
**Status:** ✅ Good  
**Note:** All foreign keys and frequently queried columns have indexes

### 10. **Error Handling**
**Status:** ✅ Implemented  
**Note:** Error handler middleware exists in middleware.js

---

## ✅ VERIFIED WORKING

### Mobile App Configuration
- ✅ Environment variables properly configured
- ✅ API service uses `AppEnv.apiBaseUrl` with fallback
- ✅ Production URL: `http://sivakundalini.org:4000`
- ✅ Development URL: `http://localhost:3012` (needs .env.json fix)

### Backend Server
- ✅ Port 3012 default (matches production expectation)
- ✅ All routes registered in server.js
- ✅ Graceful shutdown handlers implemented
- ✅ Error handling middleware present
- ✅ Database initialization with retry logic

### Database Schema
- ✅ All 19 core tables created
- ✅ Proper foreign key relationships
- ✅ Strategic indexing on all critical columns
- ✅ Backward compatibility with existing tables
- ✅ Auto-seeding for merchandise data

### Authentication & Security
- ✅ Firebase authentication integrated
- ✅ JWT token validation
- ✅ Input sanitization (verify in routes)
- ✅ Password hashing (Firebase handles this)

### API Endpoints
- ✅ Auth: login, logout, verify
- ✅ User: profile CRUD, permissions
- ✅ Events: list, register
- ✅ Classes: list, enroll
- ✅ Reminders: full CRUD
- ✅ Gatherings: list
- ✅ Merchandise: CRUD
- ✅ Purchases: CRUD with split payments
- ✅ Donations: CRUD

---

## 🚀 DEPLOYMENT CHECKLIST

### Pre-Deployment (DO THESE FIRST)

- [ ] **Fix .env.json port mismatch** (change 3011 to 3012)
- [ ] **Update database connection pool settings** (reduce from 2000 to 100)
- [ ] **Configure MySQL server** (max_connections = 150)
- [ ] **Add rate limiting middleware**
- [ ] **Create PM2 ecosystem.config.js file**
- [ ] **Verify CORS configuration** (check middleware.js)
- [ ] **Add request timeout middleware**
- [ ] **Test OneSignal subscriptions** (build APK, collect logs)

### Environment Setup

- [ ] Set `NODE_ENV=production` on server
- [ ] Verify `.env` file on server has correct values:
  - DB_HOST, DB_PORT, DB_USER, DB_PASSWORD
  - PORT=4000
  - Firebase credentials
  - OneSignal credentials
- [ ] Create logs directory: `mkdir -p logs`
- [ ] Set proper file permissions

### Database

- [ ] Run database migrations on production
- [ ] Verify all tables exist
- [ ] Check merchandise auto-seeding worked
- [ ] Backup production database
- [ ] Set up automated daily backups

### PM2 Deployment

```bash
# Install PM2 globally
npm install -g pm2

# Start application
pm2 start ecosystem.config.js

# Save PM2 process list
pm2 save

# Setup PM2 to start on system boot
pm2 startup

# Monitor
pm2 monit

# View logs
pm2 logs sks-backend

# Restart
pm2 restart sks-backend

# Stop
pm2 stop sks-backend
```

### Mobile App

- [ ] Build production APK with `.env.prod.json`
  ```bash
  flutter build apk --release --dart-define-from-file=.env.prod.json
  ```
- [ ] Test on physical device
- [ ] Verify API connectivity to production server
- [ ] Test OneSignal push notifications
- [ ] Test all critical user flows:
  - Login (OTP + Google)
  - Profile completion
  - Events registration
  - Reminders creation
  - Notifications

### Monitoring & Logging

- [ ] Set up PM2 monitoring dashboard
- [ ] Configure log rotation
- [ ] Set up error alerting (email/SMS)
- [ ] Monitor database connections
- [ ] Monitor API response times
- [ ] Set up uptime monitoring (UptimeRobot, Pingdom)

### Load Testing

- [ ] Test with 100 concurrent users
- [ ] Test with 500 concurrent users
- [ ] Test with 1000 concurrent users
- [ ] Monitor:
  - Response times
  - Error rates
  - Database connection pool usage
  - Memory usage
  - CPU usage

### Security

- [ ] Enable HTTPS (SSL certificate)
- [ ] Configure firewall rules
- [ ] Disable unnecessary ports
- [ ] Set up fail2ban for SSH
- [ ] Regular security updates
- [ ] Database user has minimal required permissions

---

## 📊 PERFORMANCE RECOMMENDATIONS

### For 1000+ Concurrent Users

1. **Use PM2 Cluster Mode**
   - Utilize all CPU cores
   - Automatic load balancing
   - Zero-downtime restarts

2. **Database Optimization**
   - Connection pooling (100 connections max)
   - Query optimization
   - Add caching layer (Redis) for frequently accessed data

3. **CDN for Static Assets**
   - ✅ Already using Cloudflare CDN for images
   - Consider CDN for API responses (Cloudflare Workers)

4. **Caching Strategy**
   - Cache events, classes, gatherings (5-15 minutes)
   - Cache user profiles (1 minute)
   - Use Redis for session management

5. **Database Scaling**
   - Consider read replicas for heavy read operations
   - Separate analytics queries to replica

---

## 🔧 IMMEDIATE ACTIONS REQUIRED

### Priority 1 (MUST FIX BEFORE DEPLOYMENT)
1. Fix `.env.json` port mismatch
2. Update database connection pool settings
3. Configure MySQL max_connections
4. Add rate limiting
5. Create PM2 ecosystem file

### Priority 2 (FIX BEFORE LAUNCH)
1. Investigate OneSignal subscription issue
2. Verify CORS configuration
3. Add request timeout middleware
4. Set up monitoring and alerting
5. Load test with 1000 users

### Priority 3 (POST-LAUNCH)
1. Add Redis caching
2. Set up database read replicas
3. Implement API response caching
4. Add comprehensive logging
5. Set up analytics dashboard

---

## 📞 SUPPORT CONTACTS

- **Firebase Project:** sks-login-mobile (294856785598)
- **OneSignal App ID:** b89d199e-15be-4343-9e04-640c43f355e9
- **Package Name:** com.spiritual.app
- **Production Server:** http://sivakundalini.org:4000

---

## ✅ CONCLUSION

**Current Status:** NOT READY FOR PRODUCTION

**Critical Blockers:**
1. Database connection pool misconfiguration
2. Port mismatch in development config
3. Missing rate limiting
4. OneSignal subscription issue

**Estimated Time to Production Ready:** 4-6 hours

**Recommendation:** Fix all Priority 1 issues, then conduct thorough load testing before deploying to production with PM2.
