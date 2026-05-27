#!/bin/bash

# Set Java 17 for Android builds
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"

echo "========================================"
echo "  Firebase Initialization Fix"
echo "========================================"
echo ""
echo "Using Java version:"
java -version
echo ""

echo "Step 1: Cleaning Flutter build cache..."
flutter clean
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter clean failed"
    exit 1
fi
echo "✅ Flutter clean complete"
echo ""

echo "Step 2: Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter pub get failed"
    exit 1
fi
echo "✅ Dependencies downloaded"
echo ""

echo "Step 3: Cleaning Android build..."
cd android
./gradlew clean
if [ $? -ne 0 ]; then
    echo "ERROR: Gradle clean failed"
    cd ..
    exit 1
fi
cd ..
echo "✅ Android build cleaned"
echo ""

echo "========================================"
echo "  Fix Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Connect your Android device or start emulator"
echo "2. Run: flutter run"
echo "3. Test Google Sign-In"
echo ""
echo "If still not working, check FIREBASE_FIX_GUIDE.md"
echo ""
