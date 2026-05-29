# Flutter Web Development Runner
# Ensures environment variables are properly loaded

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Web Development Mode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env.json exists
if (-not (Test-Path ".env.json")) {
    Write-Host "❌ Error: .env.json not found!" -ForegroundColor Red
    Write-Host "Please create .env.json with:" -ForegroundColor Yellow
    Write-Host '{
  "API_BASE_URL": "http://localhost:3000",
  "MSG91_WIDGET_ID": "your_widget_id",
  "MSG91_AUTH_TOKEN": "your_auth_token",
  "GOOGLE_CLIENT_ID": "your_client_id",
  "ONESIGNAL_APP_ID": "your_app_id"
}' -ForegroundColor White
    exit 1
}

# Read .env.json
$envContent = Get-Content ".env.json" | ConvertFrom-Json
$apiBaseUrl = $envContent.API_BASE_URL

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  API_BASE_URL: $apiBaseUrl" -ForegroundColor White
Write-Host ""

# Verify API Gateway is running
Write-Host "Checking API Gateway..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ API Gateway is running on port 3000" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ API Gateway is NOT running!" -ForegroundColor Red
    Write-Host "Please start API Gateway first:" -ForegroundColor Yellow
    Write-Host "  cd s:\Backup\api-gateway" -ForegroundColor White
    Write-Host "  npm start" -ForegroundColor White
    Write-Host ""
    $response = Read-Host "Continue anyway? (y/n)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        exit 1
    }
}

Write-Host ""
Write-Host "Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Flutter Web App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The app will open in Chrome..." -ForegroundColor Green
Write-Host "Check the console for:" -ForegroundColor Yellow
Write-Host "  📍 Base URL: http://localhost:3000" -ForegroundColor White
Write-Host ""

# Run Flutter with explicit environment variables
flutter run -d chrome `
    --dart-define=API_BASE_URL=http://localhost:3000 `
    --dart-define=MSG91_WIDGET_ID=$($envContent.MSG91_WIDGET_ID) `
    --dart-define=MSG91_AUTH_TOKEN=$($envContent.MSG91_AUTH_TOKEN) `
    --dart-define=GOOGLE_CLIENT_ID=$($envContent.GOOGLE_CLIENT_ID) `
    --dart-define=ONESIGNAL_APP_ID=$($envContent.ONESIGNAL_APP_ID)
