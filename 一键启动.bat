@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
echo.
echo ==========================================
echo   XingShu Platform - One Click Setup
echo ==========================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\one-click.ps1"
echo.
echo Finished. Press any key to close...
pause >nul
endlocal
