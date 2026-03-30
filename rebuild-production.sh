#!/bin/bash

# Production APK Rebuild Script
# CRITICAL: Builds with --dart-define-from-file flag to inject environment variables

echo "========================================="
echo "  SKS Mobile - Production APK Builder"
echo "========================================="
echo ""
echo "⚠️  IMPORTANT: This script uses --dart-define-from-file"
echo "   to inject API_BASE_URL and other environment variables."
echo "   Without this flag, the app will try to connect to"
echo "   localhost:3012 and will continuously load!"
echo ""

# Check if we're in the right directory
if [ ! -f ".env.prod.json" ]; then
    echo "❌ Error: .env.prod.json not found"
    echo "Please run this script from SKS-mobile-V2 directory"
    exit 1
fi

# Show current API URL
echo "Current API_BASE_URL in .env.prod.json:"
grep "API_BASE_URL" .env.prod.json
echo ""

# Verify HTTPS
if grep -q '"API_BASE_URL": "https://sivakundalini.org"' .env.prod.json; then
    echo "✅ API_BASE_URL correctly set to HTTPS"
elif grep -q '"API_BASE_URL": "http://sivakundalini.org"' .env.prod.json; then
    echo "⚠️  Warning: Using HTTP instead of HTTPS"
    echo "   Backend is on HTTPS, but config shows HTTP"
    echo "   This might work if server redirects, but HTTPS is recommended"
else
    echo "⚠️  Warning: API_BASE_URL may not be correct"
    echo "Current value:"
    grep "API_BASE_URL" .env.prod.json
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Step 1: Cleaning previous build..."
flutter clean

echo ""
echo "Step 2: Getting dependencies..."
flutter pub get

echo ""
echo "Step 3: Building production APK..."
echo "⚠️  Using: --dart-define-from-file=.env.prod.json"
echo "This may take 2-5 minutes..."
echo ""
flutter build apk --release --dart-define-from-file=.env.prod.json

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "  ✅ BUILD SUCCESSFUL!"
    echo "========================================="
    echo ""
    echo "APK Location:"
    echo "  build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "File Size:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print "  " $5}'
    echo ""
    echo "Environment Variables Injected:"
    echo "  ✅ API_BASE_URL from .env.prod.json"
    echo "  ✅ FIREBASE_* from .env.prod.json"
    echo "  ✅ ONESIGNAL_APP_ID from .env.prod.json"
    echo ""
    echo "Next Steps:"
    echo "  1. Install on device:"
    echo "     adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "  2. Or copy to device and install manually"
    echo ""
    echo "  3. Verify in logs (after opening app):"
    echo "     adb logcat | grep 'API Base URL'"
    echo "     Should show: https://sivakundalini.org"
    echo ""
    echo "========================================="
else
    echo ""
    echo "========================================="
    echo "  ❌ BUILD FAILED"
    echo "========================================="
    echo ""
    echo "Check the error messages above."
    echo "Common issues:"
    echo "  - Missing dependencies (run: flutter pub get)"
    echo "  - Android SDK not configured"
    echo "  - Java version issues"
    echo ""
    exit 1
fi
