# Stops IDE/Java Gradle processes that lock ~/.gradle/wrapper/dists, clears broken
# Gradle 8.14 wrapper cache, downloads + extracts the distribution, then builds APK.
# Run from PowerShell:  powershell -ExecutionPolicy Bypass -File scripts/fix_gradle_wrapper_cache.ps1

$ErrorActionPreference = "Stop"
$dest = "$env:USERPROFILE\.gradle\wrapper\dists\gradle-8.14-all\c2qonpi39x1mddn7hk5gh9iqj"
$zip = Join-Path $dest "gradle-8.14-all.zip"

Write-Host "Stopping Java processes that commonly hold Gradle wrapper locks (IDE Gradle / JDT)..."
Get-CimInstance Win32_Process -Filter "name = 'java.exe'" -ErrorAction SilentlyContinue |
  Where-Object {
    $c = $_.CommandLine
    if (-not $c) { return $false }
    return $c -match 'gradle|GradleWrapper|gradle-server|badsyntax\.gradle|jdt\.ls|equinox\.launcher'
  } |
  ForEach-Object {
    Write-Host "  Stop PID $($_.ProcessId)"
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }

Start-Sleep -Seconds 3

if (Test-Path $dest) {
  Write-Host "Removing incomplete wrapper dist: $dest"
  Remove-Item -LiteralPath $dest -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$urls = @(
  "https://mirrors.cloud.tencent.com/gradle/gradle-8.14-all.zip",
  "https://services.gradle.org/distributions/gradle-8.14-all.zip"
)

$ok = $false
foreach ($u in $urls) {
  try {
    Write-Host "Downloading: $u"
    Invoke-WebRequest -Uri $u -OutFile $zip -UseBasicParsing -TimeoutSec 900
    if ((Get-Item $zip).Length -gt 10MB) {
      $ok = $true
      break
    }
    Write-Host "Download too small, retrying next mirror..."
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
  } catch {
    Write-Host "Failed: $_"
  }
}

if (-not $ok) {
  throw "Could not download gradle-8.14-all.zip from mirrors."
}

Write-Host "Extracting (may take a minute)..."
Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force

$gradleBat = Join-Path $dest "gradle-8.14-all\bin\gradle.bat"
if (-not (Test-Path $gradleBat)) {
  throw "Extracted layout unexpected; missing $gradleBat"
}

Write-Host "Gradle dist ready. Building APK..."
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not (Test-Path (Join-Path $root "pubspec.yaml"))) {
  throw "pubspec.yaml not found under $root"
}
Set-Location $root
flutter build apk --release --target-platform android-arm64
