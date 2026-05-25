# Flutter Installation Script for Windows
# Run this script as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Installation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Step 1: Check if Flutter is already installed
Write-Host "📋 Step 1: Checking if Flutter is installed..." -ForegroundColor Cyan
$flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterInstalled) {
    Write-Host "✅ Flutter is already installed!" -ForegroundColor Green
    flutter --version
    Write-Host ""
}
else {
    Write-Host "❌ Flutter not found. Installing..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if winget is available
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    
    if ($wingetInstalled) {
        Write-Host "📦 Installing Flutter using winget..." -ForegroundColor Cyan
        winget install --id=Google.Flutter -e --accept-package-agreements --accept-source-agreements
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "✅ Flutter installed!" -ForegroundColor Green
    }
    else {
        Write-Host "❌ winget not found. Please install Flutter manually:" -ForegroundColor Red
        Write-Host "   1. Download from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        Write-Host "   2. Extract to C:\src\flutter" -ForegroundColor Yellow
        Write-Host "   3. Add C:\src\flutter\bin to PATH" -ForegroundColor Yellow
        pause
        exit
    }
}

Write-Host ""

# Step 2: Run Flutter Doctor
Write-Host "📋 Step 2: Running Flutter Doctor..." -ForegroundColor Cyan
flutter doctor -v
Write-Host ""

# Step 3: Accept Android Licenses
Write-Host "📋 Step 3: Accepting Android Licenses..." -ForegroundColor Cyan
Write-Host "Press 'y' to accept all licenses when prompted" -ForegroundColor Yellow
flutter doctor --android-licenses
Write-Host ""

# Step 4: Navigate to project and install dependencies
Write-Host "📋 Step 4: Installing Flutter dependencies..." -ForegroundColor Cyan
Set-Location "s:\SKS-mobile-V2"
flutter clean
flutter pub get
Write-Host "✅ Dependencies installed!" -ForegroundColor Green
Write-Host ""

# Step 5: Check for devices
Write-Host "📋 Step 5: Checking for connected devices..." -ForegroundColor Cyan
flutter devices
Write-Host ""

# Step 6: Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Connect an Android device or start an emulator" -ForegroundColor White
Write-Host "2. Run: flutter run --dart-define-from-file=.env.local.json" -ForegroundColor White
Write-Host ""
Write-Host "For local development, create .env.local.json with:" -ForegroundColor Yellow
Write-Host '  { "API_BASE_URL": "http://localhost:3012" }' -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
pause
