# Fix Build Errors Script
# This script fixes common Gradle build errors on Windows

Write-Host "Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean

Write-Host "Removing problematic build directories..." -ForegroundColor Yellow
$buildDirs = @(
    "build",
    "android\.gradle",
    "android\build",
    "android\app\build"
)

foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        Write-Host "Removing $dir..." -ForegroundColor Cyan
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Invalidating Gradle cache..." -ForegroundColor Yellow
Set-Location android
if (Test-Path ".gradle") {
    Remove-Item -Path ".gradle" -Recurse -Force -ErrorAction SilentlyContinue
}
Set-Location ..

Write-Host "`nBuild cleanup complete!" -ForegroundColor Green
Write-Host "`nIf the issue persists, try:" -ForegroundColor Yellow
Write-Host "1. Close all IDE instances (VS Code, Android Studio, etc.)" -ForegroundColor White
Write-Host "2. Temporarily pause OneDrive sync for the build folder" -ForegroundColor White
Write-Host "3. Disable antivirus real-time scanning for the project folder" -ForegroundColor White
Write-Host "4. Run: flutter build apk --release" -ForegroundColor White
