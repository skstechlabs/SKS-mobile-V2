@echo off
echo ========================================
echo   Flutter Web Development Mode
echo ========================================
echo.

REM Clean previous build
echo Cleaning Flutter build...
call flutter clean

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo ========================================
echo   Starting Flutter Web App
echo ========================================
echo.
echo The app will open in Chrome...
echo Check the console for:
echo   Base URL: http://localhost:3000
echo.

REM Run Flutter with explicit environment variables
call flutter run -d chrome ^
    --dart-define=API_BASE_URL=http://localhost:3000 ^
    --dart-define=MSG91_WIDGET_ID=366379717055333935353237 ^
    --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 ^
    --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com ^
    --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9

pause
