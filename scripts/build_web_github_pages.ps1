# Local build for GitHub Pages project site: https://<user>.github.io/<repo>/
# Default repo folder name matches this project; override if your GitHub repo name differs.
# Usage: .\scripts\build_web_github_pages.ps1
#         .\scripts\build_web_github_pages.ps1 my_repo_name
#         $env:GITHUB_PAGES_REPO = "my_repo"; .\scripts\build_web_github_pages.ps1
# Optional: -Zip -> wardrobe_app-github-pages.zip at repo root

param(
  [Parameter(Position = 0)]
  [string]$RepoName = "wardrobe_app",
  [switch]$Zip
)

$ErrorActionPreference = "Stop"
if ($env:GITHUB_PAGES_REPO) {
  $RepoName = $env:GITHUB_PAGES_REPO
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$base = "/$($RepoName.Trim('/'))/"
Write-Host ">>> flutter build web --release --base-href=$base"
flutter build web --release --base-href=$base

Write-Host ">>> copy 404.html for SPA"
& (Join-Path $PSScriptRoot "copy_web_spa_404.ps1")

if ($Zip) {
  $webDir = Join-Path $repoRoot "build\web"
  $zipPath = Join-Path $repoRoot "wardrobe_app-github-pages.zip"
  if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
  }
  Compress-Archive -Path (Join-Path $webDir "*") -DestinationPath $zipPath -Force
  Write-Host "Zip: $zipPath"
}

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Static folder: $(Join-Path $repoRoot 'build\web')"
Write-Host "After push + Actions deploy, open: https://<your-github-username>.github.io/$($RepoName.Trim('/'))/"
Write-Host "Set GitHub Pages source to GitHub Actions (Settings -> Pages) on first use."
Write-Host ""
