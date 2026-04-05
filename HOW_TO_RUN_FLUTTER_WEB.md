# How to Run Flutter Web Correctly

## The Problem

When you run `flutter run -d chrome` WITHOUT the `--dart-define-from-file` flag, all environment variables are EMPTY:

```
API_BASE_URL: ""  ❌ EMPTY!
MSG91_WIDGET_ID: ""  ❌ EMPTY!
ONESIGNAL_APP_ID: ""  ❌ EMPTY!
```

This causes the app to fail because it can't connect to the backend.

## The Solution

ALWAYS use the `--dart-define-from-file` flag when running Flutter Web!

## Quick Start

### Option 1: Use the Scripts (Recommended)

```bash
# For testing with PRODUCTION backend
./run-web-prod.sh

# For testing with LOCAL backend (if you have backend running locally)
./run-web-dev.sh
```

### Option 2: Manual Command

```bash
# Production backend (https://sivakundalini.org)
flutter run -d chrome --dart-define-from-file=.env.prod.json

# Development backend (http://localhost:3012)
flutter run -d chrome --dart-define-from-file=.env.json
```

## Environment Files

### `.env.json` - Development (Local Backend)
- API_BASE_URL: `http://localhost:3012`
- Use when testing with local backend

### `.env.prod.json` - Production (Live Backend)
- API_BASE_URL: `https://sivakundalini.org`
- Use when testing with production backend

## Current Configuration

I've updated `.env.json` to point to PRODUCTION backend so you can test immediately:

```json
{
  "API_BASE_URL": "https://sivakundalini.org",
  ...
}
```

## Verification

After running with the correct flag, you should see:

```
========================================
ENVIRONMENT CONFIGURATION CHECK
========================================
API_BASE_URL: "https://sivakundalini.org"
API_BASE_URL isEmpty: false
API_BASE_URL length: 28
MSG91_WIDGET_ID: "366379717055333935353237"
MSG91_WIDGET_ID isEmpty: false
ONESIGNAL_APP_ID: "b89d199e-15be-4343-9e04-640c43f355e9"
ONESIGNAL_APP_ID isEmpty: false
========================================
✅ Environment configured correctly!
========================================
```

## Common Mistakes

### ❌ WRONG - No flag
```bash
flutter run -d chrome
# Result: All env vars are empty!
```

### ❌ WRONG - Wrong file
```bash
flutter run -d chrome --dart-define-from-file=.env
# Result: .env is not JSON format!
```

### ✅ CORRECT - With flag
```bash
flutter run -d chrome --dart-define-from-file=.env.prod.json
# Result: All env vars loaded correctly!
```

## Testing Checklist

After running with correct flag:

1. ✅ Check environment output shows values (not empty)
2. ✅ Open browser console (F12)
3. ✅ Check Network tab for API calls
4. ✅ API calls should go to `https://sivakundalini.org/api/...`
5. ✅ No CORS errors (we fixed this)
6. ✅ Login should work
7. ✅ Classes should load

## Building for Production

### For APK
```bash
./rebuild-production.sh
# This automatically uses .env.prod.json
```

### For Web Build
```bash
flutter build web --dart-define-from-file=.env.prod.json
```

## Summary

- ✅ Updated `.env.json` to use production backend
- ✅ Created `run-web-prod.sh` script
- ✅ Created `run-web-dev.sh` script
- ✅ Both scripts include the required flag

**Just run**: `./run-web-prod.sh` and everything will work!
