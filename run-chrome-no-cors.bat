@echo off
echo ========================================
echo   Starting Chrome with CORS Disabled
echo ========================================
echo.
echo This will allow testing against production server
echo from localhost without CORS issues.
echo.

REM Kill all Chrome processes
echo Closing all Chrome instances...
taskkill /F /IM chrome.exe >nul 2>&1
timeout /t 2 /nobreak >nul

REM Create temp directory for Chrome user data
if not exist "C:\chrome-dev-session" mkdir "C:\chrome-dev-session"

echo.
echo Starting Chrome with web security disabled...
echo.

REM Start Chrome with CORS disabled
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" ^
    --disable-web-security ^
    --disable-gpu ^
    --user-data-dir="C:\chrome-dev-session" ^
    --disable-site-isolation-trials ^
    --disable-features=IsolateOrigins,site-per-process

timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo   Chrome Started Successfully!
echo ========================================
echo.
echo You should see a warning banner in Chrome:
echo "You are using an unsupported command-line flag"
echo.
echo This is NORMAL and means CORS is disabled.
echo.
echo Now run your Flutter app in a NEW terminal:
echo.
echo   cd s:\SKS-mobile-V2
echo   flutter run -d chrome --dart-define=API_BASE_URL=http://app.sivakundalini.org --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9
echo.
echo ========================================
echo   NO MORE CORS ERRORS!
echo ========================================
echo.
pause
