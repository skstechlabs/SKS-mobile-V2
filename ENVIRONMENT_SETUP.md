# Environment Configuration Guide

## 📋 Overview

This guide explains how to configure the mobile app for different environments.

## 🔧 Configuration Files

### 1. `.env.local.json` - Local Development (Now: Production Backend)
**Current Configuration**: Points to **PRODUCTION** backend
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org"
}
```

**Use this when:**
- Testing mobile app locally with production data
- Debugging production issues
- Testing new features against production backend

**Run with:**
```bash
flutter run --dart-define-from-file=.env.local.json
```

### 2. `.env.classes-service.json` - Production
**Configuration**: Points to production backend
```json
{
  "API_BASE_URL": "https://app.sivakundalini.org"
}
```

**Use this when:**
- Building production APK/IPA
- Release builds
- App Store/Play Store submissions

**Run with:**
```bash
flutter run --dart-define-from-file=.env.classes-service.json
```

### 3. `.env.localhost.json` - Local Backend (Create if needed)
**Configuration**: Points to local backend
```json
{
  "MSG91_WIDGET_ID": "366379717055333935353237",
  "MSG91_AUTH_TOKEN": "503409TcpVDVCsWuiQ69c418f1P1",
  "API_BASE_URL": "http://10.0.2.2:3012",
  "FIREBASE_API_KEY": "AIzaSyBXUN42KBq3eGoMgib4ZWDbYYFFc0Ft458",
  "FIREBASE_AUTH_DOMAIN": "sks-login-mobile.firebaseapp.com",
  "FIREBASE_PROJECT_ID": "sks-login-mobile",
  "FIREBASE_STORAGE_BUCKET": "sks-login-mobile.firebasestorage.app",
  "FIREBASE_MESSAGING_SENDER_ID": "294856785598",
  "FIREBASE_WEB_APP_ID": "1:294856785598:web:placeholder",
  "ONESIGNAL_APP_ID": "b89d199e-15be-4343-9e04-640c43f355e9",
  "GOOGLE_CLIENT_ID": "294856785598-qivhqf2ehn5p0rs1830dt9mt030ort9p.apps.googleusercontent.com",
  "IOS_NOTIFICATIONS_API_KEY": "AIzaSyBKh7tIinn5KBcZIzZlFfWMkfh6CR8IwXc",
  "R2_ENDPOINT": "https://dfca0f529df9f308d904bbd559e88b81.r2.cloudflarestorage.com",
  "R2_ACCESS_KEY_ID": "9b9b28d52733816213e08beb193fc415",
  "R2_SECRET_ACCESS_KEY": "655c82825795342f1eb8ce5aa662cac849854e8cc869e7b794a377b451daf7bc",
  "R2_BUCKET_NAME": "sadhaks",
  "R2_PUBLIC_URL": "https://pub-dd90b1233fb04abcb6ca3930721e7056.r2.dev"
}
```

**Use this when:**
- Testing with local backend services
- Developing new backend features
- Debugging backend issues

**Run with:**
```bash
flutter run --dart-define-from-file=.env.localhost.json
```

## 🚀 Quick Commands

### Test with Production Backend (Current Setup)
```bash
flutter run --dart-define-from-file=.env.local.json
```

### Test with Local Backend
```bash
# First, make sure local services are running
pm2 status

# Then run app
flutter run --dart-define-from-file=.env.localhost.json
```

### Build Production APK
```bash
flutter build apk --release --dart-define-from-file=.env.classes-service.json
```

### Build Production App Bundle
```bash
flutter build appbundle --release --dart-define-from-file=.env.classes-service.json
```

## 🔍 How to Check Current Configuration

### In App Code
The app reads the configuration from `AppEnv`:

```dart
import '../../../core/constants/app_env.dart';

// Check current API base URL
print('API Base URL: ${AppEnv.apiBaseUrl}');
```

### At Runtime
Add this to your app's debug screen or splash screen:

```dart
debugPrint('🌐 Environment Configuration:');
debugPrint('API Base URL: ${AppEnv.apiBaseUrl}');
debugPrint('Firebase Project: ${AppEnv.firebaseProjectId}');
debugPrint('OneSignal App ID: ${AppEnv.oneSignalAppId}');
```

## 📊 Environment Comparison

| Feature | Local Backend | Production Backend |
|---------|---------------|-------------------|
| API URL | `http://10.0.2.2:3012` | `https://app.sivakundalini.org` |
| Data | Test/Development | Real User Data |
| Database | Local SQL Server | Production Database |
| Speed | Fast (local) | Depends on network |
| Safety | Safe to test | ⚠️ Be careful! |
| Users | Test users only | Real users |

## ⚠️ Important Notes

### When Using Production Backend

1. **Be Careful with Data**
   - You're working with REAL user data
   - Any changes affect real users
   - Test thoroughly before making changes

2. **Network Required**
   - Need internet connection
   - May be slower than local
   - Check production server status

3. **Authentication**
   - Uses production Firebase
   - Real Google accounts
   - Real user sessions

4. **Monitoring**
   - Check production logs
   - Monitor error rates
   - Watch for issues

### When Using Local Backend

1. **Services Must Be Running**
   ```bash
   pm2 status
   # All services should show "online"
   ```

2. **Database Must Be Accessible**
   - SQL Server running
   - Correct connection string
   - Test data available

3. **No Internet Required**
   - Works offline (except Firebase)
   - Fast response times
   - Safe to experiment

## 🔄 Switching Between Environments

### Quick Switch Script (PowerShell)

Create `switch-env.ps1`:
```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('local', 'localhost', 'production')]
    [string]$Environment
)

switch ($Environment) {
    'local' {
        Write-Host "🌐 Switching to PRODUCTION backend..." -ForegroundColor Green
        flutter run --dart-define-from-file=.env.local.json
    }
    'localhost' {
        Write-Host "🏠 Switching to LOCAL backend..." -ForegroundColor Yellow
        flutter run --dart-define-from-file=.env.localhost.json
    }
    'production' {
        Write-Host "🚀 Building for PRODUCTION..." -ForegroundColor Cyan
        flutter build apk --release --dart-define-from-file=.env.classes-service.json
    }
}
```

**Usage:**
```bash
# Test with production backend
.\switch-env.ps1 local

# Test with local backend
.\switch-env.ps1 localhost

# Build production APK
.\switch-env.ps1 production
```

## 🧪 Testing Checklist

### Before Testing with Production Backend
- [ ] Understand you're using real data
- [ ] Have a plan for what to test
- [ ] Know how to check logs
- [ ] Have rollback plan if needed

### Before Testing with Local Backend
- [ ] All services running (`pm2 status`)
- [ ] Database accessible
- [ ] Test data loaded
- [ ] Logs accessible (`pm2 logs`)

## 📱 Current Setup

**✅ Your current configuration:**
- `.env.local.json` → **Production Backend** (`https://app.sivakundalini.org`)
- Ready to test with production data
- All production features available

**To run:**
```bash
cd s:\SKS-mobile-V2
flutter run --dart-define-from-file=.env.local.json
```

## 🎯 Recommendations

### For Development
1. Create `.env.localhost.json` for local backend testing
2. Use `.env.local.json` for production backend testing
3. Keep `.env.classes-service.json` for production builds

### For Testing
1. **New Features**: Test with local backend first
2. **Bug Fixes**: Test with production backend to reproduce
3. **Integration**: Test with both environments

### For Production
1. Always use `.env.classes-service.json`
2. Test thoroughly before release
3. Monitor production logs after deployment

## 🔗 Related Documentation

- `QUICK_START.md` - Quick start guide
- `FINAL_SUMMARY.md` - Google login explanation
- `GOOGLE_LOGIN_ARCHITECTURE.md` - System architecture

## 📞 Need Help?

If you need to switch back to local backend:
1. Create `.env.localhost.json` with local backend URL
2. Run: `flutter run --dart-define-from-file=.env.localhost.json`
3. Make sure local services are running: `pm2 status`

---

**Last Updated**: 2026-05-25
**Current Config**: Production Backend
**Status**: ✅ Ready to Test
