@echo off
echo ========================================
echo SKS Mobile V2 - Start with Classes Service
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/
    pause
    exit /b 1
)

echo [1/4] Checking Classes Service...
if not exist "s:\sks-classes-service-\server.js" (
    echo ERROR: Classes service not found at s:\sks-classes-service-
    pause
    exit /b 1
)

echo [2/4] Starting Classes Service in background...
start "SKS Classes Service" cmd /k "cd /d s:\sks-classes-service- && npm run dev"
echo Waiting for service to start...
timeout /t 5 /nobreak >nul

echo [3/4] Checking Flutter environment...
if not exist ".env.json" (
    echo WARNING: .env.json not found!
    echo Please create .env.json with your configuration.
    echo Example:
    echo {
    echo   "API_BASE_URL": "http://localhost:3013",
    echo   "MSG91_WIDGET_ID": "your_widget_id",
    echo   "MSG91_AUTH_TOKEN": "your_auth_token",
    echo   "GOOGLE_CLIENT_ID": "your_client_id",
    echo   "ONESIGNAL_APP_ID": "your_onesignal_id"
    echo }
    echo.
    pause
)

echo [4/4] Starting Flutter App...
echo.
echo ========================================
echo Services Status:
echo - Classes Service: http://localhost:3013
echo - API Docs: http://localhost:3013/api-docs
echo - Flutter App: Starting...
echo ========================================
echo.

REM Start Flutter app
flutter run --dart-define-from-file=.env.json

echo.
echo ========================================
echo Shutting down...
echo ========================================
pause
