@echo off
echo ========================================
echo SKS Mobile App - Quick Start
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed!
    echo Please install Flutter from https://flutter.dev/
    pause
    exit /b 1
)

echo [1/4] Checking Flutter version...
flutter --version
echo.

REM Get dependencies
echo [2/4] Getting Flutter dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies!
    pause
    exit /b 1
)
echo.

REM Check if .env.local.json exists
echo [3/4] Checking environment configuration...
if not exist .env.local.json (
    echo [WARNING] .env.local.json file not found!
    echo Please create .env.local.json with API configuration.
    pause
    exit /b 1
)
echo [OK] .env.local.json file found!
echo.

REM Run app
echo [4/4] Starting Flutter app...
echo.
echo ========================================
echo Choose run mode:
echo   1. Debug mode (hot reload enabled)
echo   2. Release mode (optimized)
echo ========================================
set /p mode="Enter choice (1 or 2): "

if "%mode%"=="2" (
    echo.
    echo Starting in RELEASE mode...
    flutter run --release
) else (
    echo.
    echo Starting in DEBUG mode...
    flutter run
)

pause
