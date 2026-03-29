# Quick Start - Production Deployment

**Last Updated:** March 29, 2026  
**Status:** Ready for deployment after OneSignal fix

---

## 🚀 5-Minute Quick Start

### Backend Deployment

```bash
# 1. Configure MySQL
mysql -u root -p < sks-backend/mysql_production_config.sql

# 2. Create .env file
cd sks-backend
cp .env.example .env
# Edit .env with your credentials

# 3. Install dependencies
npm install --production

# 4. Create logs directory
mkdir -p logs

# 5. Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Follow instructions

# 6. Verify
pm2 status
curl http://localhost:4000/health
```

### Mobile App Build

```bash
# 1. Clean and get dependencies
cd SKS-mobile-V2
flutter clean
flutter pub get

# 2. Build production APK
flutter build apk --release --dart-define-from-file=.env.prod.json

# 3. Install and test
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep -E "flutter|OneSignal"
```

---

## 📋 Critical Fixes Applied

✅ **Database Connection Pool** - Optimized for 1000+ users (100 connections)  
✅ **Port Configuration** - Fixed .env.json (3011 → 3012)  
✅ **Rate Limiting** - 100 req/15min general, 5 req/15min auth  
✅ **CORS Security** - Production domains only  
✅ **PM2 Configuration** - Cluster mode, auto-restart, logging  

---

## ⚠️ Before Going Live

### 1. Fix OneSignal Subscription Issue
```bash
# Build APK with logging
flutter build apk --release --dart-define-from-file=.env.prod.json

# Install and check logs
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep "OneSignal\|Player ID\|Subscribed"

# Look for:
# ✅ Player ID: <valid_id> (NOT null)
# ✅ Subscribed: true
# ❌ WARNING messages
```

### 2. Configure MySQL
```sql
-- Check current settings
SHOW VARIABLES LIKE 'max_connections';

-- Should be at least 150
SET GLOBAL max_connections = 150;

-- Make persistent in my.cnf
[mysqld]
max_connections = 150
```

### 3. Load Test
```bash
# Use Apache Bench or similar
ab -n 10000 -c 100 http://sivakundalini.org:4000/api/events

# Monitor during test
pm2 monit
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `PRODUCTION_READINESS_AUDIT.md` | Complete audit report |
| `sks-backend/DEPLOYMENT_GUIDE.md` | Detailed backend deployment |
| `SKS-mobile-V2/PRODUCTION_BUILD_GUIDE.md` | Mobile app build guide |
| `PRODUCTION_FIXES_APPLIED.md` | Summary of all fixes |
| `sks-backend/mysql_production_config.sql` | MySQL optimization |

---

## 🔍 Health Checks

### Backend
```bash
# Health endpoint
curl http://sivakundalini.org:4000/health
# Expected: {"status":"ok","timestamp":"..."}

# PM2 status
pm2 status
# Expected: sks-backend | online | 0 | cluster

# Logs
pm2 logs sks-backend --lines 50
# Expected: No critical errors
```

### Mobile App
```bash
# Install APK
adb install app-release.apk

# Check logs
adb logcat | grep -E "flutter|OneSignal|Firebase"

# Test flows:
# ✅ Login (OTP + Google)
# ✅ Permissions
# ✅ OneSignal subscription
# ✅ API calls
# ✅ Images from CDN
```

---

## 🆘 Quick Troubleshooting

### Backend won't start
```bash
# Check port
lsof -i :4000

# Check MySQL
mysql -u root -p -e "SELECT 1"

# Check logs
pm2 logs sks-backend --err
```

### Database connection errors
```bash
# Check MySQL is running
sudo systemctl status mysql

# Check max_connections
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections'"

# Check current connections
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected'"
```

### Mobile app can't connect
```bash
# Test backend
curl http://sivakundalini.org:4000/health

# Check .env.prod.json
cat SKS-mobile-V2/.env.prod.json | grep API_BASE_URL

# Check device internet
adb shell ping -c 3 sivakundalini.org
```

### OneSignal not working
```bash
# Check logs for:
adb logcat | grep "Player ID"
# Should show: Player ID: <valid_id>

# Check subscription
adb logcat | grep "Subscribed"
# Should show: Subscribed: true

# Check OneSignal dashboard
# https://dashboard.onesignal.com/apps/b89d199e-15be-4343-9e04-640c43f355e9
```

---

## 📊 Performance Targets

| Metric | Target | How to Check |
|--------|--------|--------------|
| Response Time | < 200ms | `pm2 monit` |
| Error Rate | < 0.1% | `pm2 logs` |
| Uptime | > 99.9% | `pm2 status` |
| Memory Usage | < 500MB/instance | `pm2 list` |
| CPU Usage | < 80% | `pm2 monit` |
| DB Connections | < 100 | MySQL processlist |

---

## 🔒 Security Checklist

- [ ] MySQL max_connections configured
- [ ] Rate limiting enabled
- [ ] CORS configured for production
- [ ] Firewall rules set (ports 22, 80, 443, 4000)
- [ ] SSH key-based auth enabled
- [ ] fail2ban installed
- [ ] SSL certificate installed (recommended)
- [ ] Database user has minimal permissions
- [ ] Environment variables secured
- [ ] Regular backups configured

---

## 📞 Support

- **Firebase:** sks-login-mobile (294856785598)
- **OneSignal:** b89d199e-15be-4343-9e04-640c43f355e9
- **Package:** com.spiritual.app
- **Production:** http://sivakundalini.org:4000
- **Development:** http://localhost:3012

---

## ✅ Go-Live Checklist

### Backend
- [ ] MySQL configured (max_connections = 150)
- [ ] .env file created with production values
- [ ] PM2 started and saved
- [ ] PM2 startup configured
- [ ] Health endpoint responding
- [ ] All API endpoints tested
- [ ] Logs directory created
- [ ] Monitoring set up

### Mobile App
- [ ] .env.prod.json verified
- [ ] Production APK built
- [ ] Tested on physical device
- [ ] OneSignal subscriptions working
- [ ] All API calls working
- [ ] Images loading from CDN
- [ ] Authentication flows working
- [ ] No console errors

### Infrastructure
- [ ] Firewall configured
- [ ] SSL certificate installed (optional)
- [ ] Backups configured
- [ ] Monitoring/alerting set up
- [ ] Load tested
- [ ] Documentation updated

---

## 🎯 Next Steps After Launch

1. **Monitor Closely** (First 24 hours)
   - Check PM2 logs every hour
   - Monitor error rates
   - Watch memory/CPU usage
   - Check OneSignal dashboard

2. **Gather Feedback** (First Week)
   - User reports
   - Performance metrics
   - Error logs
   - Feature requests

3. **Optimize** (First Month)
   - Add Redis caching
   - Optimize slow queries
   - Add read replicas
   - Improve monitoring

---

## 🎉 Ready to Launch!

All critical issues have been fixed. After resolving the OneSignal subscription issue and configuring MySQL, you're ready for production deployment with PM2.

**Estimated Time to Production:** 2-4 hours

Good luck! 🚀
