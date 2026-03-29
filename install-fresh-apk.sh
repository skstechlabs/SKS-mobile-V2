#!/bin/bash

# Fresh APK Installation Script
# This script completely uninstalls the old app and installs the fresh APK

echo "🚀 SKS App - Fresh Installation Script"
echo "========================================"
echo ""

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: ADB not found!"
    echo "Please install Android SDK Platform Tools"
    exit 1
fi

# Check if device is connected
echo "📱 Checking for connected devices..."
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)

if [ "$DEVICES" -eq 0 ]; then
    echo "❌ No devices connected!"
    echo "Please connect your Android device via USB"
    echo "And enable USB debugging"
    exit 1
fi

echo "✅ Device connected"
echo ""

# Step 1: Uninstall old version
echo "🗑️  Step 1: Uninstalling old version..."
adb uninstall com.spiritual.app 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Old version uninstalled"
else
    echo "ℹ️  No previous version found (this is OK)"
fi
echo ""

# Step 2: Clear app data
echo "🧹 Step 2: Clearing app data..."
adb shell pm clear com.spiritual.app 2>/dev/null
echo "✅ App data cleared"
echo ""

# Step 3: Verify APK exists
APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "📦 Step 3: Checking for fresh APK..."

if [ ! -f "$APK_PATH" ]; then
    echo "❌ Error: APK not found at $APK_PATH"
    echo "Please build the APK first:"
    echo "  flutter build apk --release --split-per-abi"
    exit 1
fi

echo "✅ Fresh APK found"
APK_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
APK_DATE=$(ls -l "$APK_PATH" | awk '{print $6, $7, $8}')
echo "   Size: $APK_SIZE"
echo "   Date: $APK_DATE"
echo ""

# Step 4: Install fresh APK
echo "📲 Step 4: Installing fresh APK..."
adb install "$APK_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Fresh APK installed successfully!"
else
    echo "❌ Installation failed!"
    echo "Try manually:"
    echo "  adb install $APK_PATH"
    exit 1
fi
echo ""

# Step 5: Verify installation
echo "🔍 Step 5: Verifying installation..."
INSTALLED=$(adb shell pm list packages | grep "com.spiritual.app")

if [ -n "$INSTALLED" ]; then
    echo "✅ App installed: $INSTALLED"
else
    echo "❌ App not found after installation"
    exit 1
fi
echo ""

# Step 6: Launch app
echo "🚀 Step 6: Launching app..."
adb shell am start -n com.spiritual.app/.MainActivity

if [ $? -eq 0 ]; then
    echo "✅ App launched successfully!"
else
    echo "⚠️  Could not launch app automatically"
    echo "Please open the app manually on your device"
fi
echo ""

# Success message
echo "========================================"
echo "✅ Installation Complete!"
echo "========================================"
echo ""
echo "📝 Next Steps:"
echo "1. App should be open on your device"
echo "2. Login or skip"
echo "3. Click 'Allow Notifications'"
echo "4. Grant system permission"
echo "5. Should work without 'Missing Plugin Exception'!"
echo ""
echo "🐛 If you still get the error:"
echo "1. Restart your device"
echo "2. Run this script again"
echo ""
echo "📚 Documentation: docs/FINAL_INSTALLATION_STEPS.md"
echo ""
