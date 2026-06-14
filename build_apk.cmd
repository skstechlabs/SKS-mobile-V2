@echo off
REM ========================================
REM Flutter APK Build Script
REM For machines with Android SDK installed
REM ========================================

echo.
echo ====================================
echo Flutter APK Build - SKS Mobile V2
echo ====================================
echo.

REM Check if Android SDK is available
echo [1/6] Checking Android SDK...
flutter doctor -v | findstr "Android toolchain" > nul
if errorlevel 1 (
    echo.
    echo ERROR: Android SDK not found!
    echo Please install Android Studio and Android SDK first.
    echo Visit: https://developer.android.com/studio
    echo.
    pause
    exit /b 1
)
echo     Android SDK found!

REM Pull latest changes
echo.
echo [2/6] Pulling latest changes from git...
git pull
if errorlevel 1 (
    echo     Warning: Git pull failed or no changes. Continuing...
)

REM Clean build
echo.
echo [3/6] Cleaning previous build...
flutter clean
if errorlevel 1 (
    echo     ERROR: Flutter clean failed!
    pause
    exit /b 1
)

REM Get dependencies
echo.
echo [4/6] Getting Flutter dependencies...
flutter pub get
if errorlevel 1 (
    echo     ERROR: Flutter pub get failed!
    pause
    exit /b 1
)

REM Build APK
echo.
echo [5/6] Building release APK...
echo     This may take 5-10 minutes...
flutter build apk --release
if errorlevel 1 (
    echo.
    echo     ERROR: APK build failed!
    echo     Check the error messages above.
    pause
    exit /b 1
)

REM Display result
echo.
echo [6/6] Build complete!
echo.
echo ====================================
echo SUCCESS!
echo ====================================
echo.
echo APK Location:
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
echo.

REM Get APK size
for %%I in (build\app\outputs\flutter-apk\app-release.apk) do (
    echo APK Size: %%~zI bytes ^(~%%~zI / 1048576 MB^)
)

echo.
echo ====================================
echo Next Steps:
echo ====================================
echo.
echo 1. Install APK on device:
echo    adb install -r build\app\outputs\flutter-apk\app-release.apk
echo.
echo 2. Or copy APK to device:
echo    - Connect device via USB
echo    - Copy app-release.apk to device
echo    - Tap to install
echo.
echo 3. Test all features:
echo    - Video playback (all levels/languages)
echo    - Quality switching
echo    - Wallpaper loading
echo    - Meditation sessions
echo.
echo ====================================
echo.
pause
