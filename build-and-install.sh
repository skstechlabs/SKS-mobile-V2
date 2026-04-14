#!/bin/bash

# Build and Install APK with Video Tracking Fixes
# This script builds a new APK and installs it on connected Android device

set -e  # Exit on error

echo "🚀 Building APK with Video Tracking Fixes..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Please run this script from SKS-mobile-V2 directory${NC}"
    exit 1
fi

# Step 1: Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
flutter clean
rm -rf build/

# Step 2: Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Step 3: Ask user which build type
echo ""
echo "Select build type:"
echo "1) Release APK (smaller, optimized, recommended)"
echo "2) Debug APK (larger, with debugging, faster build)"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    BUILD_TYPE="release"
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    echo -e "${YELLOW}🔨 Building RELEASE APK...${NC}"
    flutter build apk --release
elif [ "$choice" = "2" ]; then
    BUILD_TYPE="debug"
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    echo -e "${YELLOW}🔨 Building DEBUG APK...${NC}"
    flutter build apk --debug
else
    echo -e "${RED}❌ Invalid choice. Exiting.${NC}"
    exit 1
fi

# Step 4: Check if build succeeded
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ Build failed! APK not found at $APK_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo -e "APK location: ${GREEN}$APK_PATH${NC}"

# Get APK size
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "APK size: ${GREEN}$APK_SIZE${NC}"

# Step 5: Ask if user wants to install
echo ""
read -p "Do you want to install on connected device? (y/n): " install_choice

if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
    # Check if device is connected
    echo -e "${YELLOW}📱 Checking for connected devices...${NC}"
    
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}❌ ADB not found. Please install Android SDK Platform Tools.${NC}"
        echo "You can manually install the APK from: $APK_PATH"
        exit 1
    fi
    
    DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    
    if [ "$DEVICES" -eq 0 ]; then
        echo -e "${RED}❌ No devices connected. Please connect your device via USB.${NC}"
        echo "You can manually install the APK from: $APK_PATH"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found $DEVICES device(s)${NC}"
    
    # Uninstall old version first
    echo -e "${YELLOW}🗑️  Uninstalling old version...${NC}"
    adb uninstall com.spiritual.app 2>/dev/null || echo "No previous installation found"
    
    # Install new APK
    echo -e "${YELLOW}📲 Installing new APK...${NC}"
    adb install "$APK_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Installation successful!${NC}"
        echo ""
        echo -e "${GREEN}🎉 Done! You can now open the app and test video tracking.${NC}"
        echo ""
        echo "Testing steps:"
        echo "1. Open the app"
        echo "2. Go to Classes → Level 1 → Day 1"
        echo "3. Play the video"
        echo "4. Watch for toast messages at 50% and 90%"
        echo "5. Completion dialog should appear at 90%+"
    else
        echo -e "${RED}❌ Installation failed!${NC}"
        echo "You can manually install the APK from: $APK_PATH"
        exit 1
    fi
else
    echo ""
    echo -e "${GREEN}✅ Build complete!${NC}"
    echo "You can manually install the APK from: $APK_PATH"
    echo ""
    echo "To install manually:"
    echo "1. Copy APK to your device"
    echo "2. Open file manager and tap the APK"
    echo "3. Allow installation from unknown sources if prompted"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                    BUILD COMPLETE                           ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
