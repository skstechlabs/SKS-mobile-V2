#!/bin/bash

# Script to generate SHA-1 and SHA-256 certificates for Firebase
# Run this from SKS-mobile-V2 directory

echo "========================================="
echo "  Firebase SHA Certificate Generator"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "android" ]; then
    echo "❌ Error: android directory not found"
    echo "Please run this script from SKS-mobile-V2 directory"
    exit 1
fi

echo "📱 Generating SHA certificates for Android app..."
echo ""

# Method 1: Using Gradle (Recommended)
echo "Method 1: Using Gradle signingReport"
echo "-------------------------------------"
cd android
./gradlew signingReport 2>&1 | grep -A 3 "Variant: debug" | grep "SHA"
cd ..
echo ""

# Method 2: Using keytool for debug keystore
echo "Method 2: Using keytool (Debug Keystore)"
echo "----------------------------------------"
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "Debug keystore found at: $DEBUG_KEYSTORE"
    echo ""
    echo "SHA-1:"
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:"
    echo ""
    echo "SHA-256:"
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA256:"
else
    echo "⚠️  Debug keystore not found at: $DEBUG_KEYSTORE"
    echo "Run the app once in debug mode to generate it"
fi

echo ""
echo "========================================="
echo "  Next Steps:"
echo "========================================="
echo ""
echo "1. Copy the SHA-1 value (the long string with colons)"
echo "2. Go to https://console.firebase.google.com/"
echo "3. Select project: sks-login-mobile"
echo "4. Go to Project Settings → Your Apps → Android App"
echo "5. Scroll to 'SHA certificate fingerprints'"
echo "6. Click 'Add fingerprint' and paste the SHA-1"
echo "7. Download new google-services.json"
echo "8. Replace android/app/google-services.json"
echo "9. Rebuild: flutter clean && flutter build apk"
echo ""
echo "========================================="
