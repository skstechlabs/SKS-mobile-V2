# SKS Mobile App - Development Environment Startup Script
# This script starts all backend services and the Flutter web app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SKS Mobile App - Dev Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found! Please install Node.js first." -ForegroundColor Red
    exit 1
}

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "✓ Flutter installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found! Please install Flutter first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting backend services..." -ForegroundColor Yellow
Write-Host ""

# Start API Gateway (Port 3000)
Write-Host "Starting API Gateway (Port 3000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\api-gateway; Write-Host 'API Gateway Starting...' -ForegroundColor Green; npm start"
Start-Sleep -Seconds 3

# Start Mobile Backend Service (Port 3008)
Write-Host "Starting Mobile Backend Service (Port 3008)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-mobile-backend-service; Write-Host 'Mobile Backend Starting...' -ForegroundColor Green; npm start"
Start-Sleep -Seconds 3

# Start Classes Service (Port 3014)
Write-Host "Starting Classes Service (Port 3014)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-classes-service; Write-Host 'Classes Service Starting...' -ForegroundColor Green; npm start"
Start-Sleep -Seconds 3

# Start Notification Service (Port 3007)
Write-Host "Starting Notification Service (Port 3007)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-notification-service; Write-Host 'Notification Service Starting...' -ForegroundColor Green; npm start"
Start-Sleep -Seconds 3

# Start Google Login Service (Port 4000)
Write-Host "Starting Google Login Service (Port 4000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-google-login-service; Write-Host 'Google Login Service Starting...' -ForegroundColor Green; npm start"
Start-Sleep -Seconds 3

# Start OTP Login Service (Port 4001)
Write-Host "Starting OTP Login Service (Port 4001)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd s:\Backup\sks-otp-login-service; Write-Host 'OTP Login Service Starting...' -ForegroundColor Green; npm start"
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Checking service health..." -ForegroundColor Yellow

# Check API Gateway
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ API Gateway is running" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ API Gateway health check failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All services started!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Yellow
Write-Host "  API Gateway:        http://localhost:3000" -ForegroundColor White
Write-Host "  Mobile Backend:     http://localhost:3008" -ForegroundColor White
Write-Host "  Classes Service:    http://localhost:3014" -ForegroundColor White
Write-Host "  Notification Svc:   http://localhost:3007" -ForegroundColor White
Write-Host "  Google Login:       http://localhost:4000" -ForegroundColor White
Write-Host "  OTP Login:          http://localhost:4001" -ForegroundColor White
Write-Host ""
Write-Host "API Documentation:" -ForegroundColor Yellow
Write-Host "  http://localhost:3000/api-docs" -ForegroundColor White
Write-Host ""

# Ask if user wants to start Flutter app
Write-Host "Do you want to start the Flutter web app now? (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-Host "Starting Flutter web app..." -ForegroundColor Cyan
    Write-Host ""
    
    cd s:\SKS-mobile-V2
    
    # Clean and get dependencies
    Write-Host "Running flutter clean..." -ForegroundColor Yellow
    flutter clean
    
    Write-Host "Running flutter pub get..." -ForegroundColor Yellow
    flutter pub get
    
    Write-Host ""
    Write-Host "Launching app in Chrome..." -ForegroundColor Green
    Write-Host ""
    
    # Run Flutter app
    flutter run -d chrome --dart-define-from-file=.env.json
} else {
    Write-Host ""
    Write-Host "To start the Flutter app manually, run:" -ForegroundColor Yellow
    Write-Host "  cd s:\SKS-mobile-V2" -ForegroundColor White
    Write-Host "  flutter run -d chrome --dart-define-from-file=.env.json" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
