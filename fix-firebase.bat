@echo off
echo ========================================
echo   Firebase Initialization Fix
echo ========================================
echo.

echo Step 1: Cleaning Flutter build cache...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)
echo ✅ Flutter clean complete
echo.

echo Step 2: Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)
echo ✅ Dependencies downloaded
echo.

echo Step 3: Cleaning Android build...
cd android
call gradlew clean
if errorlevel 1 (
    echo ERROR: Gradle clean failed
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Android build cleaned
echo.

echo ========================================
echo   Fix Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Connect your Android device or start emulator
echo 2. Run: flutter run
echo 3. Test Google Sign-In
echo.
echo If still not working, check FIREBASE_FIX_GUIDE.md
echo.
pause
