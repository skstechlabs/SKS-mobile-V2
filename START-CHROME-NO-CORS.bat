@echo off
echo ========================================
echo Starting Chrome with CORS Disabled
echo ========================================
echo.
echo This will:
echo 1. Close all Chrome instances
echo 2. Start Chrome with CORS disabled for local development
echo.
echo WARNING: Only use this for local development!
echo.
pause

echo.
echo Closing all Chrome instances...
taskkill /F /IM chrome.exe 2>nul
timeout /t 2 /nobreak >nul

echo Starting Chrome with CORS disabled...
echo.
echo You should see a warning banner in Chrome saying:
echo "You are using an unsupported command-line flag: --disable-web-security"
echo.
echo This is normal and expected for local development.
echo.

start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --disable-gpu --user-data-dir="%TEMP%\chrome-dev-session" --disable-features=IsolateOrigins,site-per-process http://localhost:8080

echo.
echo Chrome started! Now run your Flutter app:
echo.
echo   flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:6000
echo.
pause
