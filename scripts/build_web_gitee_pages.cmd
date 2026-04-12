@echo off
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_web_gitee_pages.ps1"
exit /b %ERRORLEVEL%
