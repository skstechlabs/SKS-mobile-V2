#!/bin/bash

# White Screen Fix - Test Script
# This script tests if the white screen issue is fixed

echo "🧪 Testing White Screen Fix..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if device is connected
echo "📱 Checking for connected device..."
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}❌ No device connected${NC}"
    echo "Please connect a device or start an emulator"
    exit 1
fi
echo -e "${GREEN}✅ Device connected${NC}"
echo ""

# Uninstall old version
echo "🗑️  Uninstalling old version..."
adb uninstall com.spiritual.app 2>/dev/null
echo -e "${GREEN}✅ Old version uninstalled${NC}"
echo ""

# Install new version
echo "📦 Installing new version..."
if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo -e "${RED}❌ APK not found${NC}"
    echo "Please build the APK first:"
    echo "flutter build apk --release --dart-define-from-file=.env.json"
    exit 1
fi

adb install build/app/outputs/flutter-apk/app-release.apk
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Installation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ New version installed${NC}"
echo ""

# Clear logcat
echo "🧹 Clearing logs..."
adb logcat -c
echo -e "${GREEN}✅ Logs cleared${NC}"
echo ""

# Start app
echo "🚀 Starting app..."
adb shell am start -n com.spiritual.app/.MainActivity
sleep 2
echo ""

# Check logs for initialization
echo "📋 Checking initialization logs..."
echo ""

# Check for critical error
if adb logcat -d | grep -q "CRITICAL: App initialization failed"; then
    echo -e "${RED}❌ CRITICAL ERROR FOUND${NC}"
    echo "App initialization failed completely"
    exit 1
fi

# Check for successful initializations
echo "Checking service initializations:"
echo ""

if adb logcat -d | grep -q "✅ Firebase initialized"; then
    echo -e "${GREEN}✅ Firebase initialized${NC}"
else
    echo -e "${YELLOW}⚠️  Firebase initialization not found in logs${NC}"
fi

if adb logcat -d | grep -q "✅ API Service initialized"; then
    echo -e "${GREEN}✅ API Service initialized${NC}"
else
    echo -e "${YELLOW}⚠️  API Service initialization not found in logs${NC}"
fi

if adb logcat -d | grep -q "✅ Notification Storage initialized"; then
    echo -e "${GREEN}✅ Notification Storage initialized${NC}"
else
    echo -e "${YELLOW}⚠️  Notification Storage initialization not found in logs${NC}"
fi

if adb logcat -d | grep -q "✅ AudioService initialized"; then
    echo -e "${GREEN}✅ AudioService initialized${NC}"
else
    echo -e "${YELLOW}⚠️  AudioService initialization not found in logs${NC}"
fi

if adb logcat -d | grep -q "🚀 Starting app"; then
    echo -e "${GREEN}✅ App started${NC}"
else
    echo -e "${RED}❌ App start message not found${NC}"
fi

echo ""

# Check for errors
echo "Checking for errors:"
echo ""

ERROR_COUNT=$(adb logcat -d | grep -c "❌")
if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $ERROR_COUNT error(s) in logs${NC}"
    echo "Errors:"
    adb logcat -d | grep "❌" | tail -5
else
    echo -e "${GREEN}✅ No errors found${NC}"
fi

echo ""

# Check for white screen indicators
echo "Checking for white screen indicators:"
echo ""

if adb logcat -d | grep -q "Widget Error"; then
    echo -e "${RED}❌ Widget errors found${NC}"
    adb logcat -d | grep "Widget Error" | tail -3
elif adb logcat -d | grep -q "Flutter Error"; then
    echo -e "${RED}❌ Flutter errors found${NC}"
    adb logcat -d | grep "Flutter Error" | tail -3
else
    echo -e "${GREEN}✅ No widget/flutter errors${NC}"
fi

echo ""

# Final verdict
echo "═══════════════════════════════════════"
echo "📊 Test Results:"
echo "═══════════════════════════════════════"
echo ""

if [ $ERROR_COUNT -eq 0 ] && adb logcat -d | grep -q "🚀 Starting app"; then
    echo -e "${GREEN}✅ WHITE SCREEN FIX SUCCESSFUL${NC}"
    echo ""
    echo "The app should be running without white screen."
    echo "Please verify visually on the device."
else
    echo -e "${YELLOW}⚠️  PARTIAL SUCCESS${NC}"
    echo ""
    echo "App started but some services may have failed."
    echo "Check the logs above for details."
    echo ""
    echo "To view full logs:"
    echo "adb logcat | grep -E 'flutter|✅|❌|🚀'"
fi

echo ""
echo "═══════════════════════════════════════"
echo ""

# Ask user for visual confirmation
echo "❓ Did the app load without white screen? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${GREEN}🎉 SUCCESS! White screen issue is fixed!${NC}"
else
    echo -e "${RED}❌ White screen still occurring${NC}"
    echo ""
    echo "Please check:"
    echo "1. Device logs: adb logcat | grep -E 'flutter|Exception|Error'"
    echo "2. Try restarting the app"
    echo "3. Try clearing app data: adb shell pm clear com.spiritual.app"
    echo "4. Check WHITE_SCREEN_FIX.md for more debugging steps"
fi

echo ""
