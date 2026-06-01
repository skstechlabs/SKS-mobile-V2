@echo off
echo ========================================
echo Production Server Diagnostic
echo ========================================
echo.

echo Step 1: Check PM2 Services
pm2 list
echo.

echo Step 2: Check Listening Ports
netstat -ano | findstr "LISTENING" | findstr /C:":3013" /C:":6000" /C:":3008"
echo.

echo Step 3: Check API Gateway Configuration
cd /d C:\path\to\api-gateway
type .env | findstr "MOBILE_BACKEND_SERVICE_URL"
type .env | findstr "^PORT="
echo.

echo Step 4: Check Mobile Backend Configuration
cd /d C:\path\to\sks-mobile-backend-service
type .env | findstr "^PORT="
echo.

echo Step 5: Test API Gateway Health
curl http://localhost:6000/health
echo.

echo Step 6: Test Mobile Backend Health
curl http://localhost:3013/health
echo.

echo Step 7: Test API Gateway to Mobile Backend Proxy
curl http://localhost:6000/api/events
echo.

echo Step 8: Check API Gateway Logs
pm2 logs api-gateway --lines 20 --nostream
echo.

echo ========================================
echo Diagnostic Complete
echo ========================================
pause
