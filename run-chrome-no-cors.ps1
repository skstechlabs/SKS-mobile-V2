# Start Chrome with CORS Disabled for Development Testing

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Chrome with CORS Disabled" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will allow testing against production server" -ForegroundColor Yellow
Write-Host "from localhost without CORS issues." -ForegroundColor Yellow
Write-Host ""

# Kill all Chrome processes
Write-Host "Closing all Chrome instances..." -ForegroundColor Yellow
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Create temp directory for Chrome user data
$chromeDataDir = "C:\chrome-dev-session"
if (-not (Test-Path $chromeDataDir)) {
    New-Item -ItemType Directory -Path $chromeDataDir -Force | Out-Null
}

Write-Host ""
Write-Host "Starting Chrome with web security disabled..." -ForegroundColor Yellow
Write-Host ""

# Chrome executable path
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Check if Chrome exists
if (-not (Test-Path $chromePath)) {
    Write-Host "❌ Chrome not found at: $chromePath" -ForegroundColor Red
    Write-Host "Please update the path in this script." -ForegroundColor Yellow
    pause
    exit 1
}

# Start Chrome with CORS disabled
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

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Chrome Started Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You should see a warning banner in Chrome:" -ForegroundColor Yellow
Write-Host '"You are using an unsupported command-line flag"' -ForegroundColor White
Write-Host ""
Write-Host "This is NORMAL and means CORS is disabled." -ForegroundColor Green
Write-Host ""
Write-Host "Now run your Flutter app in a NEW terminal:" -ForegroundColor Cyan
Write-Host ""
Write-Host "cd s:\SKS-mobile-V2" -ForegroundColor White
Write-Host "flutter run -d chrome --dart-define=API_BASE_URL=http://app.sivakundalini.org --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  NO MORE CORS ERRORS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
