# Copy index.html to 404.html for SPA (GitHub/Gitee Pages deep links).
# Run after: flutter build web --release
#   scripts\copy_web_spa_404.ps1   (use .cmd wrapper if execution policy blocks .ps1)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$webOut = Join-Path $root "build\web"
$index = Join-Path $webOut "index.html"
$notFound = Join-Path $webOut "404.html"

if (-not (Test-Path $index)) {
    Write-Error "Missing $index . Run: flutter build web --release"
}

Copy-Item -Path $index -Destination $notFound -Force
Write-Host "Wrote: $notFound"
