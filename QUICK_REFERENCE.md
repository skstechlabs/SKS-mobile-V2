# Quick Reference - Environment Configuration

## 🎯 Current Setup

**✅ `.env.local.json` now points to PRODUCTION backend**

```
Mobile App → https://app.sivakundalini.org → Production Database
```

## 🚀 Quick Commands

### Test with Production Backend (Current)
```bash
flutter run --dart-define-from-file=.env.local.json
```
- Uses production backend
- Real user data
- Requires internet

### Test with Local Backend
```bash
flutter run --dart-define-from-file=.env.localhost.json
```
- Uses local backend (port 3012)
- Test data only
- Requires local services running

### Build Production APK
```bash
flutter build apk --release --dart-define-from-file=.env.classes-service.json
```

## 📁 Configuration Files

| File | Backend | Use Case |
|------|---------|----------|
| `.env.local.json` | **Production** | Testing with production data |
| `.env.localhost.json` | Local | Testing with local backend |
| `.env.classes-service.json` | Production | Production builds |

## 🔄 Switching Environments

### To Production Backend
```bash
flutter run --dart-define-from-file=.env.local.json
```

### To Local Backend
```bash
# 1. Start local services
pm2 status

# 2. Run app
flutter run --dart-define-from-file=.env.localhost.json
```

## ⚠️ Important

### Production Backend
- ✅ Real data
- ✅ All features work
- ⚠️ Be careful with changes
- 🌐 Requires internet

### Local Backend
- ✅ Safe to test
- ✅ Fast response
- ⚠️ Services must be running
- 🏠 Works offline (except Firebase)

## 🎯 What Changed

**Before:**
```json
"API_BASE_URL": "http://10.0.2.2:3012"  // Local backend
```

**After:**
```json
"API_BASE_URL": "https://app.sivakundalini.org"  // Production backend
```

## ✅ Ready to Test

Your app is now configured to use the production backend, just like in production!

```bash
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.local.json
```

---

**Need local backend?** Use `.env.localhost.json` instead!
