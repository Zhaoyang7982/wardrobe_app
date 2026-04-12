# Gitee Pages build for repo: https://gitee.com/zxy1778828562/wardrobe_app
# After deploy: https://zxy1778828562.gitee.io/wardrobe_app/

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host ">>> flutter build web --release --base-href=/wardrobe_app/"
flutter build web --release --base-href=/wardrobe_app/

Write-Host ">>> copy 404.html for SPA"
& (Join-Path $PSScriptRoot "copy_web_spa_404.ps1")

$webDir = Join-Path $repoRoot "build\web"
$zipPath = Join-Path $repoRoot "wardrobe_app-web.zip"
if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $webDir "*") -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Static folder: $webDir"
Write-Host "Zip (upload to Gitee Pages): $zipPath"
Write-Host "URL after deploy: https://zxy1778828562.gitee.io/wardrobe_app/"
Write-Host ""
Write-Host "Next: Gitee repo -> Services -> Gitee Pages, upload zip or bind branch (see docs/web-deploy.md)."
