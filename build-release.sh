#!/bin/bash

# SKS Mobile App - Production Build Script
# This script automates the process of building a production APK

set -e  # Exit on error

echo "🏗️  SKS Mobile App - Production Build"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found!${NC}"
    echo "Please run this script from the SKS-mobile-V2 directory"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter is not installed!${NC}"
    echo "Please install Flutter first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo -e "${YELLOW}⚠️  Warning: android/key.properties not found!${NC}"
    echo "You need to configure app signing first."
    echo "See BUILD_PRODUCTION_APK.md for instructions."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check environment file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Warning: .env file not found!${NC}"
    echo "Make sure to configure environment variables."
    echo ""
fi

# Ask for build type
echo "Select build type:"
echo "1) Universal APK (works on all devices, larger size)"
echo "2) Split APKs (smaller size, one per architecture) - RECOMMENDED"
echo "3) App Bundle (for Google Play Store)"
echo ""
read -p "Enter choice (1-3): " BUILD_TYPE

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo ""
echo "📦 Getting dependencies..."
flutter pub get

# Build based on selection
echo ""
case $BUILD_TYPE in
    1)
        echo "🔨 Building universal APK..."
        flutter build apk --release
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    2)
        echo "🔨 Building split APKs..."
        flutter build apk --split-per-abi --release
        APK_PATH="build/app/outputs/flutter-apk/"
        ;;
    3)
        echo "🔨 Building app bundle..."
        flutter build appbundle --release
        APK_PATH="build/app/outputs/bundle/release/app-release.aab"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice!${NC}"
        exit 1
        ;;
esac

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "📦 Output files:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$BUILD_TYPE" == "2" ]; then
        ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print $9, "(" $5 ")"}'
    else
        ls -lh $APK_PATH | awk '{print $9, "(" $5 ")"}'
    fi
    
    echo ""
    echo "📍 Location: $APK_PATH"
    echo ""
    
    # Calculate total size
    if [ "$BUILD_TYPE" == "2" ]; then
        TOTAL_SIZE=$(du -sh build/app/outputs/flutter-apk/ | awk '{print $1}')
        echo "📊 Total size: $TOTAL_SIZE"
    else
        FILE_SIZE=$(ls -lh $APK_PATH | awk '{print $5}')
        echo "📊 File size: $FILE_SIZE"
    fi
    
    echo ""
    echo "🎉 Next steps:"
    echo "  1. Test the APK on a real device"
    echo "  2. Verify all features work correctly"
    echo "  3. Check for crashes or errors"
    echo "  4. Distribute to users or upload to Play Store"
    echo ""
    
    # Ask if user wants to install on connected device
    if command -v adb &> /dev/null; then
        DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
        if [ $DEVICES -gt 0 ]; then
            echo ""
            read -p "📱 Install on connected device? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if [ "$BUILD_TYPE" == "2" ]; then
                    # Install arm64 version (most common)
                    adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
                elif [ "$BUILD_TYPE" == "1" ]; then
                    adb install -r build/app/outputs/flutter-apk/app-release.apk
                else
                    echo "Cannot install app bundle directly. Upload to Play Store instead."
                fi
            fi
        fi
    fi
    
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    echo "Check the error messages above for details."
    exit 1
fi
