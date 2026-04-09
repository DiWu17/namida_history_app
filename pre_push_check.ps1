Write-Host "========== Pre-Push Check ==========" -ForegroundColor Cyan

Write-Host "`n[1/2] Running flutter analyze..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n FAILED: flutter analyze found issues. Fix them before pushing." -ForegroundColor Red
    exit 1
}
Write-Host " Analyze passed!" -ForegroundColor Green

Write-Host "`n[2/2] Running flutter test..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n FAILED: flutter test has failures. Fix them before pushing." -ForegroundColor Red
    exit 1
}
Write-Host " Tests passed!" -ForegroundColor Green

Write-Host "`n========== All checks passed! Safe to push. ==========" -ForegroundColor Cyan
