@echo off
echo ============================================
echo Quick Fix - Audio Integration
echo ============================================
echo.

echo Step 1: Cleaning Flutter...
call flutter clean
echo.

echo Step 2: Getting dependencies...
call flutter pub get
echo.

echo Step 3: Building APK with production config...
call flutter build apk --release --dart-define-from-file=.env.prod.json
echo.

echo ============================================
echo Build Complete!
echo ============================================
echo.
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next Steps:
echo 1. Install APK on your device
echo 2. Test if songs load
echo 3. Check console logs
echo.
pause
