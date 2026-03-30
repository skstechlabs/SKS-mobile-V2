#!/bin/bash

echo "========================================="
echo "  APK Configuration Diagnostic Tool"
echo "========================================="
echo ""

# Check if .env.prod.json exists
if [ ! -f ".env.prod.json" ]; then
    echo "❌ ERROR: .env.prod.json NOT FOUND!"
    echo "   Create this file with production configuration"
    exit 1
fi

echo "✅ .env.prod.json exists"
echo ""

# Show API_BASE_URL
echo "Configuration in .env.prod.json:"
echo "--------------------------------"
grep "API_BASE_URL" .env.prod.json
echo ""

# Verify it's HTTPS
if grep -q '"API_BASE_URL": "https://sivakundalini.org"' .env.prod.json; then
    echo "✅ API_BASE_URL is correctly set to HTTPS"
elif grep -q '"API_BASE_URL": "http://sivakundalini.org"' .env.prod.json; then
    echo "⚠️  WARNING: Using HTTP instead of HTTPS"
else
    echo "⚠️  WARNING: API_BASE_URL may not be correct"
fi
echo ""

# Check if APK exists
if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "❌ APK NOT FOUND!"
    echo "   You need to build the APK first"
    echo ""
    echo "   Run: ./rebuild-production.sh"
    echo "   Or:  flutter build apk --release --dart-define-from-file=.env.prod.json"
    exit 1
fi

echo "✅ APK exists"
echo ""

# Show APK info
echo "APK Information:"
echo "----------------"
ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print "Size: " $5 "\nDate: " $6 " " $7 " " $8}'
echo ""

# Check if device is connected
echo "Checking for connected devices..."
if ! adb devices | grep -q "device$"; then
    echo "❌ No device connected!"
    echo "   Connect your device via USB and enable USB debugging"
    echo ""
    echo "   Steps:"
    echo "   1. Connect device via USB"
    echo "   2. Enable Developer Options on device"
    echo "   3. Enable USB Debugging"
    echo "   4. Accept USB debugging prompt on device"
    exit 1
fi

echo "✅ Device connected"
echo ""

# Show connected devices
echo "Connected Devices:"
echo "------------------"
adb devices
echo ""

# Ask if user wants to install
read -p "Install APK on device? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing APK..."
    echo "----------------"
    adb install -r build/app/outputs/flutter-apk/app-release.apk
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ APK installed successfully!"
        echo ""
        echo "========================================="
        echo "  Next Steps"
        echo "========================================="
        echo ""
        echo "1. Open the app on your device"
        echo ""
        echo "2. In another terminal, run:"
        echo "   adb logcat | grep -E 'ENVIRONMENT|API_BASE_URL'"
        echo ""
        echo "3. Look for this line:"
        echo "   ✅ API_BASE_URL is configured: https://sivakundalini.org"
        echo ""
        echo "4. If you see:"
        echo "   ❌ CRITICAL: API_BASE_URL is EMPTY!"
        echo "   Then rebuild with: ./rebuild-production.sh"
        echo ""
        echo "5. Test the app:"
        echo "   - Login should work"
        echo "   - Gatherings should load (no continuous loader)"
        echo "   - Events should load (no continuous loader)"
        echo ""
        echo "========================================="
    else
        echo ""
        echo "❌ Installation failed!"
        echo "   Check the error message above"
    fi
else
    echo ""
    echo "Installation cancelled"
    echo ""
    echo "To install manually:"
    echo "  adb install -r build/app/outputs/flutter-apk/app-release.apk"
fi

echo ""
