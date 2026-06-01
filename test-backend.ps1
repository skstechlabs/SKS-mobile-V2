# Test Backend Connectivity
# Run this to verify your backend is accessible

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Testing Backend Connectivity" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Test localhost (from computer)
Write-Host "1. Testing localhost:3000..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Localhost OK" -ForegroundColor Green
        Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Localhost FAILED: $_" -ForegroundColor Red
}

Write-Host ""

# Test 10.0.2.2 (Android emulator access)
Write-Host "2. Testing 10.0.2.2:3000 (Android Emulator)..." -ForegroundColor Yellow
Write-Host "   Note: This will fail from your computer (only works from emulator)" -ForegroundColor Gray
Write-Host ""

# Test local IP (physical device access)
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress
Write-Host "3. Testing $localIP:3000 (Physical Device)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://${localIP}:3000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Local IP OK" -ForegroundColor Green
        Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Local IP FAILED: $_" -ForegroundColor Red
    Write-Host "   Check Windows Firewall settings" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Backend Services Status" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

pm2 list

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  - For Android Emulator: http://10.0.2.2:3000" -ForegroundColor Gray
Write-Host "  - For Physical Device:  http://${localIP}:3000" -ForegroundColor Gray
Write-Host ""
