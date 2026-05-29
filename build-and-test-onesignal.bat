@echo off
echo ========================================
echo OneSignal Fix - Build and Test
echo ========================================
echo.

echo Step 1: Cleaning previous build...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Step 3: Building release APK...
call flutter build apk --release
if errorlevel 1 (
    echo ERROR: Flutter build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next Steps:
echo 1. Install APK on device: adb install -r build\app\outputs\flutter-apk\app-release.apk
echo 2. Test login flow and notification permission
echo 3. Send test notification from backend
echo.
echo To test backend:
echo   cd s:\Backup\sks-notification-service
echo   node test-onesignal.js YOUR-FIREBASE-UID
echo.
pause
