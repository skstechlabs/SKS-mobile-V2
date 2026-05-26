# Production Server Issue - Diagnosis & Solution

## 🚨 Problem

When trying to use production backend (`https://app.sivakundalini.org`), you get:
```
502 - Web server received an invalid response while acting as a gateway or proxy server
```

## 🔍 Root Cause

The production server is experiencing a **502 Bad Gateway** error, which means:

1. ✅ **Domain is accessible** - DNS is working
2. ✅ **Web server is running** - nginx/IIS is responding
3. ❌ **Backend services are DOWN** - Not responding to requests

### What's Happening

```
Mobile App → https://app.sivakundalini.org → nginx/IIS → ❌ Backend Services (DOWN)
                                                ↓
                                           502 Error
```

## 🔧 Solution Applied

**Switched back to LOCAL backend** for testing:

### Updated Configuration
File: `s:\SKS-mobile-V2\.env.local.json`
```json
{
  "API_BASE_URL": "http://10.0.2.2:3012"  // ← Back to local backend
}
```

### Local Services Status
```
✅ API Gateway:            Port 3012 - ONLINE
✅ Google Login Service:   Port 3010 - ONLINE
✅ OTP Login Service:      Port 3011 - ONLINE
✅ Classes Service:        Port 3014 - ONLINE
✅ Mobile Backend Service: Port 3015 - ONLINE
✅ Notification Service:   Port 3016 - ONLINE
```

## 🚀 How to Test Now

### Run Mobile App with Local Backend
```bash
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.local.json
```

**Your app will:**
- ✅ Connect to local backend (port 3012)
- ✅ Use local database
- ✅ Work with test data
- ✅ Fast response times

## 🔧 Fixing Production Server

To fix the production server, you need to:

### 1. Check Production Server Status

**SSH into production server:**
```bash
ssh user@app.sivakundalini.org
```

**Check if services are running:**
```bash
pm2 status
# or
systemctl status api-gateway
systemctl status google-login-service
```

### 2. Check Logs

**PM2 logs:**
```bash
pm2 logs --lines 100
```

**System logs:**
```bash
journalctl -u api-gateway -n 100
journalctl -u google-login-service -n 100
```

### 3. Common Issues & Fixes

#### Issue: Services Crashed
```bash
# Restart all services
pm2 restart all

# Or restart specific service
pm2 restart api-gateway
```

#### Issue: Database Connection Failed
```bash
# Check database is running
systemctl status mssql-server
# or
systemctl status postgresql

# Check connection string in .env files
cat /path/to/api-gateway/.env
```

#### Issue: Port Already in Use
```bash
# Find process using port
netstat -tulpn | grep :3012

# Kill process
kill -9 <PID>

# Restart service
pm2 restart api-gateway
```

#### Issue: Out of Memory
```bash
# Check memory usage
free -h

# Restart services to free memory
pm2 restart all
```

#### Issue: Nginx Configuration
```bash
# Check nginx status
systemctl status nginx

# Test nginx config
nginx -t

# Restart nginx
systemctl restart nginx
```

### 4. Verify Fix

**Test health endpoint:**
```bash
curl https://app.sivakundalini.org/health
```

**Expected response:**
```json
{
  "status": "OK",
  "timestamp": "2026-05-25T18:30:00.000Z",
  "services": {
    "googleLogin": {"status": "UP"},
    "notification": {"status": "UP"},
    "classes": {"status": "UP"}
  }
}
```

## 🔄 Switching Between Environments

### Use Local Backend (Current)
```bash
# .env.local.json already configured
flutter run --dart-define-from-file=.env.local.json
```

### Use Production Backend (When Fixed)
```bash
# Edit .env.local.json
# Change: "API_BASE_URL": "https://app.sivakundalini.org"

flutter run --dart-define-from-file=.env.local.json
```

### Quick Switch
```bash
# Local backend
flutter run --dart-define-from-file=.env.localhost.json

# Production backend (when fixed)
flutter run --dart-define-from-file=.env.classes-service.json
```

## 📊 Environment Status

| Environment | Status | URL | Use For |
|-------------|--------|-----|---------|
| **Local** | ✅ ONLINE | `http://10.0.2.2:3012` | Development & Testing |
| **Production** | ❌ DOWN (502) | `https://app.sivakundalini.org` | Production |

## ⚠️ Important Notes

### Why Local Backend is Better for Testing

1. **Fast Response Times**
   - No network latency
   - Instant responses
   - Better debugging

2. **Safe to Test**
   - Test data only
   - No risk to production
   - Can break things safely

3. **Full Control**
   - Can restart services
   - Can check logs
   - Can modify code

4. **No Dependencies**
   - Works offline (except Firebase)
   - No production server needed
   - Independent testing

### When to Use Production Backend

1. **Testing Production Issues**
   - Reproducing user-reported bugs
   - Verifying production data
   - Testing with real users

2. **Pre-Release Testing**
   - Final testing before release
   - Verify production integration
   - Check production performance

3. **Production Server is UP**
   - Server must be accessible
   - Services must be running
   - Database must be available

## 🎯 Current Recommendation

**✅ Use LOCAL backend for testing**

Reasons:
1. Production server is down (502 error)
2. Local backend is working perfectly
3. Faster development cycle
4. Safe to test and experiment
5. Full control over services

## 🚀 Next Steps

### For Testing (Now)
```bash
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.local.json
```

### For Production Server (Later)
1. SSH into production server
2. Check service status: `pm2 status`
3. Check logs: `pm2 logs`
4. Restart services: `pm2 restart all`
5. Verify: `curl https://app.sivakundalini.org/health`

### After Production is Fixed
1. Update `.env.local.json` to use production URL
2. Test with production backend
3. Verify all features work
4. Deploy new version if needed

## 📞 Production Server Checklist

When fixing production server, check:

- [ ] Services running (`pm2 status`)
- [ ] Database accessible
- [ ] Nginx/IIS running
- [ ] Firewall rules correct
- [ ] SSL certificates valid
- [ ] Disk space available
- [ ] Memory available
- [ ] CPU not overloaded
- [ ] Logs for errors
- [ ] Environment variables set

## ✅ Summary

**Current Status:**
- ❌ Production server: DOWN (502 error)
- ✅ Local backend: WORKING
- ✅ Mobile app: Configured for local backend
- ✅ Ready to test

**Action Taken:**
- Switched `.env.local.json` back to local backend
- Verified local services are running
- Tested local API Gateway (working)

**Next Steps:**
- Test mobile app with local backend
- Fix production server separately
- Switch to production when ready

---

**Created**: 2026-05-25
**Status**: ✅ RESOLVED (Using Local Backend)
**Production Server**: ❌ DOWN (Needs Attention)
