@echo off
echo ========================================
echo Starting SKS Mobile App - Local Development
echo ========================================
echo.
echo This script will:
echo 1. Close all Chrome instances
echo 2. Start Chrome with CORS disabled
echo 3. Start Flutter web app pointing to localhost:6000
echo.
echo IMPORTANT: Make sure API Gateway is running on port 6000
echo.
pause

echo.
echo [Step 1/3] Closing all Chrome instances...
taskkill /F /IM chrome.exe 2>nul
timeout /t 2 /nobreak >nul

echo [Step 2/3] Starting Chrome with CORS disabled...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --disable-gpu --user-data-dir="%TEMP%\chrome-dev-session" --disable-features=IsolateOrigins,site-per-process http://localhost:8080

echo [Step 3/3] Starting Flutter web app...
echo.
echo Flutter is starting... This may take a minute...
echo.

flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:6000 --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9

echo.
echo ========================================
echo Development session ended
echo ========================================
pause
