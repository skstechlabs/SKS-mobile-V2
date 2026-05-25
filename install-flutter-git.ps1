# Flutter Installation Script using Git
# This script clones Flutter from GitHub and sets it up

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Installation via Git" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is already installed
$flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterInstalled) {
    Write-Host "✅ Flutter is already installed!" -ForegroundColor Green
    flutter --version
    Write-Host ""
    Write-Host "Skipping installation. Proceeding to project setup..." -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "📥 Flutter not found. Installing via Git..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if Git is available
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
    
    if (-not $gitInstalled) {
        Write-Host "❌ Git is not installed!" -ForegroundColor Red
        Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
        pause
        exit
    }
    
    Write-Host "✅ Git found: $(git --version)" -ForegroundColor Green
    Write-Host ""
    
    # Create installation directory
    $flutterPath = "C:\src\flutter"
    
    if (Test-Path $flutterPath) {
        Write-Host "⚠️  Flutter directory already exists at $flutterPath" -ForegroundColor Yellow
        Write-Host "Removing old installation..." -ForegroundColor Yellow
        Remove-Item -Path $flutterPath -Recurse -Force
    }
    
    # Create parent directory
    $parentPath = "C:\src"
    if (-not (Test-Path $parentPath)) {
        Write-Host "📁 Creating directory: $parentPath" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }
    
    # Clone Flutter repository
    Write-Host "📦 Cloning Flutter repository (this may take a few minutes)..." -ForegroundColor Cyan
    Write-Host "   Repository: https://github.com/flutter/flutter.git" -ForegroundColor White
    Write-Host "   Branch: stable" -ForegroundColor White
    Write-Host ""
    
    Set-Location $parentPath
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to clone Flutter repository!" -ForegroundColor Red
        pause
        exit
    }
    
    Write-Host ""
    Write-Host "✅ Flutter cloned successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Add Flutter to PATH
    Write-Host "🔧 Adding Flutter to PATH..." -ForegroundColor Cyan
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $flutterBinPath = "$flutterPath\bin"
    
    if ($currentPath -notlike "*$flutterBinPath*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$currentPath;$flutterBinPath",
            "Machine"
        )
        Write-Host "✅ Flutter added to PATH" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Flutter already in PATH" -ForegroundColor Green
    }
    
    # Refresh environment variables for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host ""
    Write-Host "🔄 Running Flutter precache..." -ForegroundColor Cyan
    & "$flutterBinPath\flutter" precache
    
    Write-Host ""
    Write-Host "✅ Flutter installed successfully!" -ForegroundColor Green
    Write-Host ""
}

# Navigate back to project
Set-Location "s:\SKS-mobile-V2"

# Run Flutter Doctor
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Running Flutter Doctor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
flutter doctor -v
Write-Host ""

# Accept Android Licenses
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Accepting Android Licenses" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Press 'y' to accept all licenses when prompted" -ForegroundColor Yellow
Write-Host ""
flutter doctor --android-licenses
Write-Host ""

# Install project dependencies
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installing Project Dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
flutter clean
flutter pub get
Write-Host ""
Write-Host "✅ Dependencies installed!" -ForegroundColor Green
Write-Host ""

# Check for devices
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Checking for Devices" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
flutter devices
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Flutter installed at: C:\src\flutter" -ForegroundColor Green
Write-Host "✅ Project dependencies installed" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Connect an Android device or start an emulator" -ForegroundColor White
Write-Host "   2. Run: flutter run --dart-define-from-file=.env.local.json" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Useful Commands:" -ForegroundColor Yellow
Write-Host "   flutter devices          - List connected devices" -ForegroundColor White
Write-Host "   flutter emulators        - List available emulators" -ForegroundColor White
Write-Host "   flutter doctor           - Check environment" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
pause
