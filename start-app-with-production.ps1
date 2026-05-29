# Complete Solution: Start Flutter App with Production Server (No CORS Issues)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SKS Mobile App - Production Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill all Chrome processes
Write-Host "Step 1: Closing all Chrome instances..." -ForegroundColor Yellow
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "✓ Chrome closed" -ForegroundColor Green
Write-Host ""

# Step 2: Create Chrome dev session directory
Write-Host "Step 2: Setting up Chrome dev session..." -ForegroundColor Yellow
$chromeDataDir = "C:\chrome-dev-session"
if (-not (Test-Path $chromeDataDir)) {
    New-Item -ItemType Directory -Path $chromeDataDir -Force | Out-Null
}
Write-Host "✓ Chrome dev session ready" -ForegroundColor Green
Write-Host ""

# Step 3: Start Chrome with CORS disabled
Write-Host "Step 3: Starting Chrome with CORS disabled..." -ForegroundColor Yellow
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

if (-not (Test-Path $chromePath)) {
    Write-Host "❌ Chrome not found at: $chromePath" -ForegroundColor Red
    Write-Host "Please install Chrome or update the path." -ForegroundColor Yellow
    pause
    exit 1
}

$chromeArgs = @(
    "--disable-web-security",
    "--disable-gpu",
    "--user-data-dir=`"$chromeDataDir`"",
    "--disable-site-isolation-trials",
    "--disable-features=IsolateOrigins,site-per-process",
    "--no-first-run",
    "--no-default-browser-check"
)

Start-Process -FilePath $chromePath -ArgumentList $chromeArgs
Start-Sleep -Seconds 3
Write-Host "✓ Chrome started (you should see a warning banner - this is normal)" -ForegroundColor Green
Write-Host ""

# Step 4: Clean Flutter build
Write-Host "Step 4: Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "✓ Flutter cleaned" -ForegroundColor Green
Write-Host ""

# Step 5: Get Flutter dependencies
Write-Host "Step 5: Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get | Out-Null
Write-Host "✓ Dependencies ready" -ForegroundColor Green
Write-Host ""

# Step 6: Start Flutter app
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Flutter App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  API URL: http://app.sivakundalini.org" -ForegroundColor White
Write-Host "  CORS: Disabled (via Chrome flags)" -ForegroundColor White
Write-Host ""
Write-Host "The app will open in the Chrome window with CORS disabled..." -ForegroundColor Green
Write-Host ""

# Run Flutter with production URL
flutter run -d chrome `
    --dart-define=API_BASE_URL=http://app.sivakundalini.org `
    --dart-define=MSG91_WIDGET_ID=366379717055333935353237 `
    --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 `
    --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com `
    --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  App Stopped" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
