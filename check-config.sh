#!/bin/bash

echo "🔍 Configuration Check"
echo "====================="
echo ""

echo "1️⃣ Package Name in build.gradle.kts:"
grep "applicationId" android/app/build.gradle.kts | head -1
echo ""

echo "2️⃣ Package Name in google-services.json:"
grep "package_name" android/app/google-services.json
echo ""

echo "3️⃣ MainActivity package:"
head -1 android/app/src/main/kotlin/com/spiritual/app/MainActivity.kt
echo ""

echo "4️⃣ OneSignal App ID in AndroidManifest:"
grep -A 1 "onesignal_app_id" android/app/src/main/AndroidManifest.xml
echo ""

echo "5️⃣ OneSignal App ID in .env.json:"
grep "ONESIGNAL_APP_ID" .env.json
echo ""

echo "📊 Analysis:"
echo "============"

APP_ID=$(grep "applicationId" android/app/build.gradle.kts | sed 's/.*"\(.*\)".*/\1/')
GOOGLE_PKG=$(grep "package_name" android/app/google-services.json | sed 's/.*"\(.*\)".*/\1/')

echo "App uses: $APP_ID"
echo "Firebase configured for: $GOOGLE_PKG"
echo ""

if [ "$APP_ID" = "$GOOGLE_PKG" ]; then
    echo "✅ Package names MATCH - Configuration is correct"
else
    echo "❌ Package names DON'T MATCH - This is the problem!"
    echo ""
    echo "🔧 Fix required:"
    echo "1. Go to Firebase Console"
    echo "2. Find Android app with package: $APP_ID"
    echo "3. Download google-services.json for that app"
    echo "4. Replace android/app/google-services.json"
    echo "5. Rebuild APK"
fi
