#!/bin/bash

echo "🚀 SKS App - Complete Reinstallation Script"
echo "============================================"
echo ""

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: ADB not found!"
    echo "Please install Android SDK Platform Tools"
    exit 1
fi

# Check if device is connected
echo "📱 Checking for connected devices..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device" | wc -l | tr -d ' ')

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No Android devices connected!"
    echo ""
    echo "Please connect your device via USB and enable USB debugging:"
    echo "1. Go to Settings > About Phone"
    echo "2. Tap 'Build Number' 7 times to enable Developer Options"
    echo "3. Go to Settings > Developer Options"
    echo "4. Enable 'USB Debugging'"
    echo "5. Connect device via USB and accept the debugging prompt"
    exit 1
fi

echo "✅ Found $DEVICE_COUNT device(s)"
echo ""

# Show connected devices
echo "Connected devices:"
adb devices
echo ""

# Uninstall old app
echo "🗑️  Uninstalling old app (com.spiritual.app)..."
adb uninstall com.spiritual.app 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Old app uninstalled successfully"
else
    echo "ℹ️  App not found (this is OK if first install)"
fi

echo ""

# Check if APK exists
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at: $APK_PATH"
    echo ""
    echo "Building APK..."
    flutter build apk --release
    
    if [ $? -ne 0 ]; then
        echo "❌ APK build failed!"
        exit 1
    fi
fi

# Install new APK
echo "📦 Installing fresh APK..."
adb install "$APK_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "🎉 You can now test the app on your device"
    echo ""
    echo "Testing checklist:"
    echo "  1. Open the app"
    echo "  2. Complete login/profile setup"
    echo "  3. Click 'Allow Notifications' on permission screen"
    echo "  4. Verify no 'Missing Plugin Exception' appears"
    echo "  5. Check that permission dialog appears"
    echo "  6. Grant permission and verify navigation to home"
    echo ""
    echo "To view logs: adb logcat | grep -i onesignal"
else
    echo ""
    echo "❌ Installation failed!"
    echo ""
    echo "Try manual installation:"
    echo "1. Copy APK to device"
    echo "2. Open file manager on device"
    echo "3. Tap the APK file"
    echo "4. Follow installation prompts"
fi
