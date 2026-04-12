@echo off
setlocal
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_web_github_pages.ps1" %*
exit /b %ERRORLEVEL%
