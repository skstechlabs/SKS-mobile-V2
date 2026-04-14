#!/bin/bash

echo "🔧 Rebuilding APK with Cloudflare Stream fix..."
echo ""

# Clean previous build
echo "1️⃣ Cleaning previous build..."
flutter clean

# Get dependencies
echo ""
echo "2️⃣ Getting dependencies..."
flutter pub get

# Build release APK
echo ""
echo "3️⃣ Building release APK..."
flutter build apk --release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    
    # Check if device is connected
    if adb devices | grep -q "device$"; then
        echo "📱 Android device detected!"
        read -p "Install APK now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "📲 Installing APK..."
            adb install -r build/app/outputs/flutter-apk/app-release.apk
            
            if [ $? -eq 0 ]; then
                echo ""
                echo "✅ APK installed successfully!"
                echo ""
                echo "🎬 Now test the video:"
                echo "   1. Open app"
                echo "   2. Go to Classes → Level 1 → Day 1"
                echo "   3. Play video"
                echo "   4. Watch for toast at 50%"
                echo "   5. Watch for completion dialog at 90%+"
                echo ""
                echo "📊 Check backend logs for:"
                echo "   - Progress updates"
                echo "   - Milestone tracking"
                echo "   - Day completion"
            else
                echo ""
                echo "❌ Installation failed!"
                echo "Try manually: adb install -r build/app/outputs/flutter-apk/app-release.apk"
            fi
        fi
    else
        echo "⚠️ No Android device connected"
        echo ""
        echo "To install manually:"
        echo "1. Copy build/app/outputs/flutter-apk/app-release.apk to your device"
        echo "2. Open file manager on device"
        echo "3. Tap the APK file"
        echo "4. Allow installation from unknown sources"
        echo "5. Install"
    fi
else
    echo ""
    echo "❌ Build failed!"
    echo "Check the error messages above"
fi
