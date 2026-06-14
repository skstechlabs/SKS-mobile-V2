@echo off
REM Quick test and build script for Flutter app

echo ========================================
echo SKS Mobile V2 - Test and Build
echo ========================================
echo.

echo Step 1: Clean build cache...
call flutter clean
echo.

echo Step 2: Get dependencies...
call flutter pub get
echo.

echo Step 3: Check for errors...
call flutter analyze
echo.

echo Step 4: Run tests (if any)...
call flutter test
echo.

echo Step 5: Build release APK...
call flutter build apk --release
echo.

echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next steps:
echo 1. Test the APK on device
echo 2. Deploy backend: cd s:\Backup\sks-classes-service ^&^& pm2 restart sks-classes-service
echo 3. Test video playback
echo.

pause
